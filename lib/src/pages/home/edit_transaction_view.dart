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

  late FirestoreService firestore;
  late String selectedAccount;
  late List<String> selectedTags;
  late TransactionType selectedType;

  @override
  void initState() {
    super.initState();
    firestore = FirestoreService();
    transactionNameController.text = widget.transaction.transactionName;
    amountController.text = widget.transaction.amount.toString();
    currencyController.text = widget.transaction.currency;
    descriptionController.text = widget.transaction.description;
    transactionTimeController.text = DateFormat('yy-MM-dd HH:mm')
        .format(widget.transaction.transactionTime.toDate());
    selectedAccount = widget.transaction.accountId;
    selectedTags = widget.transaction.tags;
    selectedType = widget.transaction.transactionType;
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

      // Calculate the difference in amount
      final double amountDifference =
          double.parse(amountController.text) - originalTransaction.amount;

      // Fetch the corresponding account
      final accountDoc =
          await firestore.db.collection('Accounts').doc(selectedAccount).get();
      final account = AccountModel.fromDocument(accountDoc);

      // Update the account balance
      final updatedBalance = account.balance + amountDifference;
      await firestore.db
          .collection('Accounts')
          .doc(selectedAccount)
          .update({'balance': updatedBalance});

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
        transactionType: selectedType,
        transactionTime: Timestamp.fromDate(DateFormat('yyyy-MM-dd HH:mm')
            .parse(transactionTimeController.text)),
      );

      await firestore.db
          .collection('Transactions')
          .doc(widget.transaction.transactionId)
          .update(updatedTransaction.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction updated successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            children: [
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
