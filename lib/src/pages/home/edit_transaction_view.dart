import 'package:finc/src/helpers/authentication_service.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../components/app_routes.dart';
import '../../components/settings_controller.dart';
import '../../models/transaction_model.dart';
import '../../models/account_model.dart';
import '../../helpers/firestore_service.dart';
import 'package:flutter/services.dart';
import 'package:currency_picker/currency_picker.dart';

class EditTransactionView extends StatefulWidget {
  final SettingsController settingsController;
  final TransactionModel transaction;

  const EditTransactionView({
    super.key,
    required this.settingsController,
    required this.transaction,
  });

  @override
  EditTransactionViewState createState() => EditTransactionViewState();
}

class EditTransactionViewState extends State<EditTransactionView> {
  final FirestoreService firestoreService = FirestoreService();
  final AuthenticationService authService = AuthenticationService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController transactionNameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController transactionTimeController = TextEditingController();
  late User user;
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
    user = authService.getCurrentUser();
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
      accounts = await firestoreService.getAccounts(user.uid);
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
      if (!_formKey.currentState!.validate()) {
        return;
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
            tooltip: 'Delete Transaction',
            onPressed: deleteTransaction,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Clone Transaction',
            onPressed: () {
              context.pushReplacement(
                AppRoutes.addTransaction,
                extra: widget.transaction,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save_as),
            tooltip: 'Save Edited Transaction',
            onPressed: editTransaction,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            Text(
              "Transaction Type",
              style: TextStyle(fontSize: 16),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: FormField(
                builder: (FormFieldState<dynamic> field) {
                  return Wrap(
                    spacing: 4,
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
              Text(
                "Transfer from",
                style: TextStyle(fontSize: 16),
              ),
            ] else ...[
              Text(
                "Account",
                style: TextStyle(fontSize: 16),
              ),
            ],
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
                              selectedColor: Color(a.color).withAlpha(100),
                              label: Text(a.accountName),
                              selected: selectedAccount == a.accountId,
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                side: selectedAccount == a.accountId
                                    ? BorderSide(color: Color(a.color), width: 3)
                                    : BorderSide.none,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onSelected: (bool selected) {
                                setState(() {
                                  selectedAccount = selected ? a.accountId : "";
                                });
                              },
                            ))
                        .toList(),
                  );
                },
                validator: (value) {
                  if (selectedAccount.isEmpty) {
                    return 'Please select an account';
                  }
                  return null;
                },
              ),
            ),
            if (selectedTransactionType == TransactionType.transfer) ...[
              Text(
                "Transfer To",
                style: TextStyle(fontSize: 16),
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
                                selectedColor: Color(a.color).withAlpha(100),
                                label: Text(a.accountName),
                                selected: selectedDestinationAccount == a.accountId,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  side: selectedDestinationAccount == a.accountId
                                      ? BorderSide(color: Color(a.color), width: 3)
                                      : BorderSide.none,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedDestinationAccount = selected ? a.accountId : "";
                                  });
                                },
                              ))
                          .toList(),
                    );
                  },
                  validator: (value) {
                    if (selectedDestinationAccount.isEmpty) {
                      return 'Please select a destination account';
                    }
                    return null;
                  },
                ),
              ),
            ] else ...[
              Text(
                "Tags",
                style: TextStyle(fontSize: 16),
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
                                selectedColor: Color(c.color).withAlpha(100),
                                label: Text(c.tagName),
                                selected: selectedTags.contains(c.tagId),
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  side: selectedTags.contains(c.tagId)
                                      ? BorderSide(color: Color(c.color), width: 3)
                                      : BorderSide.none,
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
              Divider(
                height: 24,
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
            SizedBox(height: 10),
            TextFormField(
              controller: amountController,
              decoration:
                  const InputDecoration(labelText: "Amount", hintText: "e.g. 79.9", border: OutlineInputBorder()),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                // Allow only numbers and decimal point, and limit to two decimal places
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
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
                if (selectedTransactionType != TransactionType.adjustment && double.parse(value) < 0) {
                  return 'Negative amounts are only allowed for adjustments';
                }
                return null;
              },
            ),
            SizedBox(height: 10),
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
            Divider(
              height: 24,
            ),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
              keyboardType: TextInputType.text,
            ),
            Divider(
              height: 24,
            ),
            Row(
              spacing: 4,
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
          ],
        ),
      ),
    );
  }
}
