import 'package:finc/src/models/tag_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
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
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController transactionNameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController transactionTimeController = TextEditingController();
  late TransactionType selectedTransactionType;
  late String selectedAccount;
  String selectedDestinationAccount = "";
  List<AccountModel> accounts = [];
  List<String> selectedTags = [];
  List<TagModel> tags = [];
  String response = "";

  @override
  void initState() {
    super.initState();
    transactionNameController.text = widget.transaction.transactionName;
    amountController.text = widget.transaction.amount.toString();
    currencyController.text = widget.transaction.currency;
    descriptionController.text = widget.transaction.description;
    transactionTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(widget.transaction.transactionTime.toDate());
    selectedAccount = widget.transaction.accountId;
    selectedTags = widget.transaction.tags;
    selectedTransactionType = widget.transaction.transactionType;
    selectedDestinationAccount = widget.transaction.transactionName;
    fetchDataFromFirestore();
  }

  Future<void> fetchDataFromFirestore() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      accounts = await firestoreService.getAccounts(user!.uid);
      tags = await firestoreService.getTags(user.uid);

      setState(() {});
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

      final oldTransaction = await firestoreService.getTransaction(widget.transaction.transactionId);

      // Create the updated transaction
      final newTransaction = TransactionModel(
        transactionId: oldTransaction.transactionId,
        userId: oldTransaction.userId,
        accountId: selectedAccount,
        tags: selectedTags,
        transactionName: selectedTransactionType == TransactionType.transfer
            ? selectedDestinationAccount
            : transactionNameController.text,
        amount: double.parse(amountController.text),
        currency: currencyController.text,
        description: descriptionController.text,
        transactionType: selectedTransactionType,
        transactionTime: Timestamp.fromDate(DateFormat('yyyy-MM-dd HH:mm').parse(transactionTimeController.text)),
      );

      response = await firestoreService.updateTransaction(newTransaction, oldTransaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response)),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response)),
      );
    }
  }

  Future<void> deleteTransaction() async {
    try {
      response = await firestoreService.deleteTransaction(widget.transaction);

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
                                avatar: Icon(deserializeIcon(a.icon)?.data, color: Color(a.color)),
                                backgroundColor: Color(a.color).withAlpha(100),
                                label: Text(a.accountName),
                                selected: selectedAccount == a.accountId,
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedAccount = selected ? a.accountId : "";
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
                                label: Text(t.toString().split('.').last[0].toUpperCase() +
                                    t.toString().split('.').last.substring(1).toLowerCase()),
                                selected: selectedTransactionType == t,
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedTransactionType = selected ? t : TransactionType.expense;
                                  });
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
              if (selectedTransactionType == TransactionType.transfer) ...[
                Row(
                  children: [
                    Text("Transfer To Account"),
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
                                  avatar: Icon(deserializeIcon(a.icon)?.data, color: Color(a.color)),
                                  backgroundColor: Color(a.color).withAlpha(100),
                                  label: Text(a.accountName),
                                  selected: selectedDestinationAccount == a.accountId,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      selectedDestinationAccount =
                                          selected ? a.accountId : widget.transaction.transactionName;
                                    });
                                  },
                                ))
                            .toList(),
                      );
                    },
                  ),
                ),
              ] else ...[
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
                                  avatar: Icon(deserializeIcon(c.icon)?.data, color: Color(c.color)),
                                  backgroundColor: Color(c.color).withAlpha(100),
                                  label: Text(c.tagName),
                                  selected: selectedTags.contains(c.tagId),
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedTags.add(c.tagId);
                                      } else {
                                        selectedTags.remove(c.tagId);
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
                  decoration:
                      const InputDecoration(labelText: "Name", hintText: "e.g. Lunch", border: OutlineInputBorder()),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a transaction name';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 10),
              TextFormField(
                controller: amountController,
                decoration:
                    const InputDecoration(labelText: "Amount", hintText: "e.g. 79.9", border: OutlineInputBorder()),
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
                decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd')
                              .format(DateFormat('yyyy-MM-dd HH:mm').parse(transactionTimeController.text))),
                      decoration: const InputDecoration(
                        labelText: "Date",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_month),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateFormat('yyyy-MM-dd').parse(transactionTimeController.text),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (pickedDate != null) {
                          final currentTime = DateFormat('HH:mm').parse(DateFormat('HH:mm')
                              .format(DateFormat('yyyy-MM-dd HH:mm').parse(transactionTimeController.text)));

                          final combinedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            currentTime.hour,
                            currentTime.minute,
                          );

                          setState(() {
                            transactionTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: TextEditingController(
                          text: DateFormat('HH:mm')
                              .format(DateFormat('yyyy-MM-dd HH:mm').parse(transactionTimeController.text))),
                      decoration: const InputDecoration(
                        labelText: "Time",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final initialTime = TimeOfDay.fromDateTime(
                          DateFormat('yyyy-MM-dd HH:mm').parse(transactionTimeController.text),
                        );
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                        );

                        if (pickedTime != null) {
                          final currentDate = DateFormat('yyyy-MM-dd').parse(DateFormat('yyyy-MM-dd')
                              .format(DateFormat('yyyy-MM-dd HH:mm').parse(transactionTimeController.text)));

                          final combinedDateTime = DateTime(
                            currentDate.year,
                            currentDate.month,
                            currentDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );

                          setState(() {
                            transactionTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
                          });
                        }
                      },
                    ),
                  ),
                ],
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
