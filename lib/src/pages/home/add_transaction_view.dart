import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/transaction_model.dart';
import 'package:intl/intl.dart';
import '../../helpers/firestore_service.dart';
import 'package:flutter/services.dart';
import 'package:currency_picker/currency_picker.dart';
import '../../components/settings_controller.dart';

class AddTransactionView extends StatefulWidget {
  final SettingsController settingsController;

  const AddTransactionView({super.key, required this.settingsController});

  @override
  AddTransactionViewState createState() => AddTransactionViewState();
}

class AddTransactionViewState extends State<AddTransactionView> {
  TransactionType selectedTransactionType = TransactionType.expense;
  String selectedAccount = "";
  List<Map<String, dynamic>> accounts = [];
  List<String> selectedTags = [];
  List<Map<String, dynamic>> tags = [];
  final TextEditingController transactionNameController =
      TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController transactionTimeController =
      TextEditingController();

  final FirestoreService firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    currencyController.text = widget.settingsController.baseCurrency;
    transactionTimeController.text =
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    fetchDataFromFirestore();
  }

  Future<void> fetchDataFromFirestore() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final accountsSnapshot = await firestore.db
          .collection('Accounts')
          .where('userId', isEqualTo: user?.uid)
          .get();
      final tagsSnapshot = await firestore.db
          .collection('Tags')
          .where('userId', isEqualTo: user?.uid)
          .get();

      setState(() {
        tags = tagsSnapshot.docs
            .map((doc) => {
                  'tagId': doc.id,
                  'tagName': doc['tagName'],
                  'icon': IconData(doc['icon'], fontFamily: 'MaterialIcons'),
                  'color': Color(doc['color']),
                })
            .toList();
        accounts = accountsSnapshot.docs
            .map((doc) => {
                  'accountId': doc.id,
                  'accountName': doc['accountName'],
                  'balances': doc['balances'],
                  'icon': IconData(doc['icon'], fontFamily: 'MaterialIcons'),
                  'color': Color(doc['color']),
                })
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch data: $e')),
      );
    }
  }

  @override
  void dispose() {
    transactionNameController.dispose();
    amountController.dispose();
    currencyController.dispose();
    descriptionController.dispose();
    transactionTimeController.dispose();
    super.dispose();
  }

  void addTransaction() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      final String userId = user.uid;
      final String transactionId =
          firestore.db.collection('Transactions').doc().id;
      final double amount = double.parse(amountController.text);

      final TransactionModel transaction = TransactionModel(
        transactionId: transactionId,
        userId: userId,
        accountId: selectedAccount,
        tags: selectedTags,
        transactionName: transactionNameController.text,
        amount: amount,
        currency: currencyController.text,
        description: descriptionController.text,
        transactionType: selectedTransactionType,
        transactionTime: Timestamp.fromDate(DateFormat('yyyy-MM-dd HH:mm')
            .parse(transactionTimeController.text)),
      );

      await firestore.createTransaction(transaction);

      // Update the account balance according to the currency
      final account =
          accounts.firstWhere((a) => a['accountId'] == selectedAccount);
      double updatedBalance =
          account['balances'][currencyController.text] ?? 0.0;
      if (selectedTransactionType == TransactionType.expense) {
        updatedBalance -= amount;
      } else if (selectedTransactionType == TransactionType.income) {
        updatedBalance += amount;
      }

      // Update the balances map
      account['balances'][currencyController.text] = updatedBalance;

      await FirebaseFirestore.instance
          .collection('Accounts')
          .doc(selectedAccount)
          .update({'balances': account['balances']});

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction Added Successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('New Transaction'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Form(
            child: Column(
              spacing: 8,
              children: [
                Row(
                  children: [
                    Text("Account"),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: FormField(
                    builder: (FormFieldState<dynamic> field) {
                      return Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8,
                        children: accounts
                            .map((a) => ChoiceChip(
                                  avatar: Icon(a['icon']),
                                  backgroundColor: a['color'],
                                  label: Text(a['accountName']),
                                  selected: selectedAccount == a['accountId'],
                                  onSelected: (bool selected) {
                                    setState(() {
                                      selectedAccount =
                                          selected ? a['accountId'] : "";
                                    });
                                  },
                                ))
                            .toList(),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Text("Transaction Type"),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: FormField(
                    builder: (FormFieldState<dynamic> field) {
                      return Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8,
                        children: TransactionType.values
                            .map((t) => ChoiceChip(
                                  label: Text(t
                                          .toString()
                                          .split('.')
                                          .last[0]
                                          .toUpperCase() +
                                      t
                                          .toString()
                                          .split('.')
                                          .last
                                          .substring(1)
                                          .toLowerCase()),
                                  selected: selectedTransactionType == t,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      selectedTransactionType = selected
                                          ? t
                                          : TransactionType.expense;
                                    });
                                  },
                                ))
                            .toList(),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Text("Tags"),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: FormField(
                    builder: (FormFieldState<dynamic> field) {
                      return Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8,
                        children: tags
                            .map((c) => ChoiceChip(
                                  avatar: Icon(c['icon']),
                                  backgroundColor: c['color'],
                                  label: Text(c['tagName']),
                                  selected: selectedTags.contains(c['tagId']),
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedTags.add(c['tagId']);
                                      } else {
                                        selectedTags.remove(c['tagId']);
                                      }
                                    });
                                  },
                                ))
                            .toList(),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Text("Details"),
                  ],
                ),
                TextFormField(
                  controller: transactionNameController,
                  decoration: const InputDecoration(
                      labelText: "Name",
                      hintText: "e.g. Lunch",
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a transaction name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                      labelText: "Amount",
                      hintText: "e.g. 79.9",
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    // Allow only numbers and decimal point, and limit to two decimal places
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    final parts = value.split('.');
                    if (parts.length == 2 && parts[1].length > 2) {
                      return 'Amount cannot have more than two decimal places';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: currencyController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Currency",
                    border: OutlineInputBorder(),
                  ),
                  onTap: () {
                    showCurrencyPicker(
                      context: context,
                      showFlag: true,
                      showCurrencyName: true,
                      showCurrencyCode: true,
                      onSelect: (Currency currency) {
                        setState(() {
                          currencyController.text = currency.code;
                        });
                      },
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a currency';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                      labelText: "Description", border: OutlineInputBorder()),
                  keyboardType: TextInputType.text,
                ),
                Row(
                  children: [
                    Text("Date & Time"),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: TextEditingController(
                            text: DateFormat('yyyy-MM-dd').format(
                                DateFormat('yyyy-MM-dd HH:mm')
                                    .parse(transactionTimeController.text))),
                        decoration: const InputDecoration(
                          labelText: "Date",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_month),
                        ),
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null) {
                            final currentTime = DateFormat('HH:mm').parse(
                                DateFormat('HH:mm').format(
                                    DateFormat('yyyy-MM-dd HH:mm').parse(
                                        transactionTimeController.text)));

                            final combinedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              currentTime.hour,
                              currentTime.minute,
                            );

                            setState(() {
                              transactionTimeController.text =
                                  DateFormat('yyyy-MM-dd HH:mm')
                                      .format(combinedDateTime);
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: TextEditingController(
                            text: DateFormat('HH:mm').format(
                                DateFormat('yyyy-MM-dd HH:mm')
                                    .parse(transactionTimeController.text))),
                        decoration: const InputDecoration(
                          labelText: "Time",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );

                          if (pickedTime != null) {
                            final currentDate = DateFormat('yyyy-MM-dd').parse(
                                DateFormat('yyyy-MM-dd').format(
                                    DateFormat('yyyy-MM-dd HH:mm').parse(
                                        transactionTimeController.text)));

                            final combinedDateTime = DateTime(
                              currentDate.year,
                              currentDate.month,
                              currentDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );

                            setState(() {
                              transactionTimeController.text =
                                  DateFormat('yyyy-MM-dd HH:mm')
                                      .format(combinedDateTime);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: addTransaction,
                  child: const Text("Add"),
                ),
              ],
            ),
          ),
        ));
  }
}
