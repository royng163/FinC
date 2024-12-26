import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  int selectedType = 0;
  final List<String> type = [
    "Expense",
    "Income",
    "Investment",
    "Transfer",
    "Adjustment"
  ];

  String selectedAccount = "";
  final List<String> accounts = ["Cash", "Alipay", "HSBC", "MMP Card"];

  String selectedCategory = "";
  final List<String> categories = [
    "Food",
    "Transport",
    "Entertainment",
    "Shopping",
    "Health",
  ];

  final TextEditingController transactionNameController =
      TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController transactionTimeController =
      TextEditingController();

  late FirestoreService firestore;

  @override
  void initState() {
    super.initState();
    firestore = FirestoreService();
    currencyController.text = widget.settingsController.baseCurrency;
    // Initialize the dateTimeController with the current date
    transactionTimeController.text = DateTime.now().toString();
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
      final String userId = firestore.db.collection("Users").doc().id;
      final String transactionId =
          firestore.db.collection('Transactions').doc().id;

      final TransactionModel transaction = TransactionModel(
        transactionId: transactionId,
        userId: userId,
        accountId: selectedAccount, // Replace with actual account ID
        categoryId: selectedCategory, // Replace with actual category ID
        transactionName: transactionNameController.text,
        amount: double.parse(amountController.text),
        currency: currencyController.text,
        description: descriptionController.text,
        transactionType: type[selectedType],
        transactionTime: Timestamp.fromDate(
            DateFormat('yy-MM-dd HH:mm').parse(transactionTimeController.text)),
      );

      await firestore.createTransaction(transaction);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction Added Successfully')),
      );

      // Clear the form
      transactionNameController.clear();
      amountController.clear();
      descriptionController.clear();
      setState(() {
        selectedType = 0;
        selectedAccount = "";
        selectedCategory = "";
        transactionTimeController.text =
            DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      });

      // Optionally, navigate back or perform other actions
      // Navigator.pop(context);
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
                    Text("Transaction Type"),
                  ],
                ),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return Row(
                      spacing: 8,
                      children: type
                          .map((t) => ChoiceChip(
                                label: Text(t),
                                selected: selectedType == type.indexOf(t),
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedType =
                                        selected ? type.indexOf(t) : -1;
                                  });
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
                Row(
                  children: [
                    Text("Account"),
                  ],
                ),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return Row(
                      spacing: 8,
                      children: accounts
                          .map((a) => ChoiceChip(
                                label: Text(a),
                                selected: selectedAccount == a,
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedAccount = selected ? a : "";
                                  });
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
                Row(
                  children: [
                    Text("Category"),
                  ],
                ),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return Row(
                      spacing: 8,
                      children: categories
                          .map((c) => ChoiceChip(
                                label: Text(c),
                                selected: selectedCategory == c,
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedCategory = selected ? c : "";
                                  });
                                },
                              ))
                          .toList(),
                    );
                  },
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
                              DateFormat('yy-MM-dd HH:mm')
                                  .format(combinedDateTime);
                        });
                      }
                    }
                  },
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
