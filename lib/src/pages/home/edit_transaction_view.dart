import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../models/account_model.dart';
import '../../helpers/firestore_service.dart';
import 'package:flutter/services.dart';
import 'package:currency_picker/currency_picker.dart';

class EditTransactionView extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionView({
    super.key,
    required this.transaction,
  });

  @override
  EditTransactionViewState createState() => EditTransactionViewState();
}

class EditTransactionViewState extends State<EditTransactionView> {
  final TextEditingController transactionNameController =
      TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController transactionTimeController =
      TextEditingController();
  String selectedAccount = "";
  List<AccountModel> accounts = [];
  List<String> selectedTags = [];
  List<Map<String, dynamic>> tags = [];
  TransactionType selectedTransactionType = TransactionType.expense;
  final FirestoreService firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    transactionNameController.text = widget.transaction.transactionName;
    amountController.text = widget.transaction.amount.toString();
    currencyController.text = widget.transaction.currency;
    descriptionController.text = widget.transaction.description;
    transactionTimeController.text = DateFormat('yyyy-MM-dd HH:mm')
        .format(widget.transaction.transactionTime.toDate());
    selectedAccount = widget.transaction.accountId;
    selectedTags = widget.transaction.tags;
    selectedTransactionType = widget.transaction.transactionType;
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
            .map((doc) => AccountModel.fromDocument(doc))
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

  Future<void> editTransaction() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      // Fetch the original transaction from Firestore
      final originalTransactionDoc = await firestore.db
          .collection('Transactions')
          .doc(widget.transaction.transactionId)
          .get();
      final originalTransaction =
          TransactionModel.fromDocument(originalTransactionDoc);

      // Fetch the corresponding account
      final accountDoc =
          await firestore.db.collection('Accounts').doc(selectedAccount).get();
      final account = AccountModel.fromDocument(accountDoc);

      // Calculate the difference in the transaction amount
      final double difference =
          double.parse(amountController.text) - originalTransaction.amount;

      double updatedBalance = account.balances[currencyController.text] ?? 0.0;
      // If the transaction type has changed, reverse the original transaction's effect
      if (originalTransaction.transactionType != selectedTransactionType) {
        if (originalTransaction.transactionType == TransactionType.income) {
          updatedBalance -= originalTransaction.amount * 2;
        } else if (originalTransaction.transactionType ==
            TransactionType.expense) {
          updatedBalance += originalTransaction.amount * 2;
        }
      }

      // Apply the new transaction's effect
      if (selectedTransactionType == TransactionType.income) {
        updatedBalance += difference;
      } else if (selectedTransactionType == TransactionType.expense) {
        updatedBalance -= difference;
      }

      // Update the balance for the specific currency
      account.balances[currencyController.text] = updatedBalance;
      await firestore.db
          .collection('Accounts')
          .doc(selectedAccount)
          .update({'balances': account.balances});

      // Update the transaction in Firestore
      final updatedTransaction = TransactionModel(
        transactionId: widget.transaction.transactionId,
        userId: user.uid,
        accountId: selectedAccount,
        tags: selectedTags,
        transactionName: transactionNameController.text,
        amount: double.parse(amountController.text),
        currency: currencyController.text,
        description: descriptionController.text,
        transactionType: selectedTransactionType,
        transactionTime: Timestamp.fromDate(DateFormat('yyyy-MM-dd HH:mm')
            .parse(transactionTimeController.text)),
      );

      await firestore.db
          .collection('Transactions')
          .doc(widget.transaction.transactionId)
          .update(updatedTransaction.toMap());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction updated successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update transaction: $e')),
      );
    }
  }

  Future<void> deleteTransaction() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch the current account balance
      final accountDoc =
          await firestore.collection('Accounts').doc(selectedAccount).get();
      final account = AccountModel.fromDocument(accountDoc);

      // Update the account balance for the corresponding currency
      double updatedBalance =
          account.balances[widget.transaction.currency] ?? 0.0;
      if (widget.transaction.transactionType == TransactionType.income) {
        updatedBalance -= widget.transaction.amount;
      } else if (widget.transaction.transactionType ==
          TransactionType.expense) {
        updatedBalance += widget.transaction.amount;
      }

      account.balances[widget.transaction.currency] = updatedBalance;
      await FirebaseFirestore.instance
          .collection('Accounts')
          .doc(selectedAccount)
          .update({'balances': account.balances});

      // Delete the transaction from Firestore
      await firestore
          .collection('Transactions')
          .doc(widget.transaction.transactionId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction deleted successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: deleteTransaction,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
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
                                avatar: Icon(IconData(a.icon,
                                    fontFamily: 'MaterialIcons')),
                                backgroundColor: Color(a.color),
                                label: Text(a.accountName),
                                selected: selectedAccount == a.accountId,
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedAccount =
                                        selected ? a.accountId : "";
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
                                    selectedTransactionType =
                                        selected ? t : TransactionType.expense;
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
              const SizedBox(height: 10),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                    labelText: "Amount",
                    hintText: "e.g. 79.9",
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  // Allow only numbers and decimal point, and limit to two decimal places
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                    labelText: "Description", border: OutlineInputBorder()),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: transactionTimeController,
                decoration: const InputDecoration(
                  labelText: "Date & Time",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
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
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );

                    if (pickedTime != null) {
                      final combinedDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );

                      setState(() {
                        transactionTimeController.text =
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(combinedDateTime);
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: editTransaction,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
