import 'package:finc/src/helpers/authentication_service.dart';
import 'package:finc/src/helpers/firestore_service.dart';
import 'package:finc/src/helpers/hive_service.dart';
import 'package:finc/src/helpers/settings_service.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:finc/src/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:currency_picker/currency_picker.dart';

class AddTransactionView extends StatefulWidget {
  final SettingsService _settingsService;
  final TransactionModel? _transactionClone;

  const AddTransactionView({
    super.key,
    required SettingsService settingsService,
    TransactionModel? transactionClone,
  })  : _settingsService = settingsService,
        _transactionClone = transactionClone;

  @override
  AddTransactionViewState createState() => AddTransactionViewState();
}

class AddTransactionViewState extends State<AddTransactionView> {
  final FirestoreService _firestoreService = FirestoreService();
  final HiveService _hiveService = HiveService();
  final AuthenticationService _authService = AuthenticationService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _transactionNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _transactionTimeController = TextEditingController();
  late User _user;
  TransactionType _selectedTransactionType = TransactionType.expense;
  String _selectedAccount = "";
  String _selectedDestinationAccount = "";
  List<AccountModel> _accounts = [];
  List<String> _selectedTags = [];
  List<TagModel> _tags = [];

  @override
  void initState() {
    super.initState();
    _user = _authService.getCurrentUser();
    _currencyController.text = widget._settingsService.baseCurrency;
    _transactionTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // If a transaction is passed for cloning, prefill the details.
    if (widget._transactionClone != null) {
      _transactionNameController.text = widget._transactionClone!.transactionName;
      _amountController.text = widget._transactionClone!.amount.toString();
      _currencyController.text = widget._transactionClone!.currency;
      _descriptionController.text = widget._transactionClone!.description;
      _selectedAccount = widget._transactionClone!.accountId;
      _selectedTags = widget._transactionClone!.tags;
      _selectedTransactionType = widget._transactionClone!.transactionType;
      _selectedDestinationAccount = widget._transactionClone!.transactionName;
    }

    fetchData();
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        // Access the locally stored accounts and tags from Hive
        _accounts = _hiveService.accountsBox.values.toList();
        _tags = _hiveService.tagsBox.values.toList();
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
    _transactionNameController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _descriptionController.dispose();
    _transactionTimeController.dispose();
    super.dispose();
  }

  void addTransaction() async {
    String response = "";
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      if (_selectedAccount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an account')),
        );
        return;
      }

      if (_selectedTransactionType == TransactionType.transfer && _selectedDestinationAccount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a transfer account')),
        );
        return;
      }

      final TransactionModel newTransaction = TransactionModel(
        transactionId: _firestoreService.firestore.collection('Transactions').doc().id,
        userId: _user.uid,
        accountId: _selectedAccount,
        tags: _selectedTags,
        transactionName: _selectedTransactionType == TransactionType.transfer
            ? _selectedDestinationAccount
            : _transactionNameController.text,
        amount: double.parse(_amountController.text),
        currency: _currencyController.text,
        description: _descriptionController.text,
        transactionType: _selectedTransactionType,
        transactionTime: Timestamp.fromDate(
          DateFormat('yyyy-MM-dd HH:mm').parse(_transactionTimeController.text),
        ),
      );

      response = await _hiveService.setTransaction(newTransaction);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response)),
      );

      Navigator.pop(context);
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Transaction',
            onPressed: addTransaction,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            const Text(
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
                              label: Text(
                                t.toString().split('.').last[0].toUpperCase() +
                                    t.toString().split('.').last.substring(1).toLowerCase(),
                              ),
                              selected: _selectedTransactionType == t,
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedTransactionType = selected ? t : TransactionType.expense;
                                });
                              },
                            ))
                        .toList(),
                  );
                },
              ),
            ),
            if (_selectedTransactionType == TransactionType.transfer) ...[
              const Text(
                "Transfer from",
                style: TextStyle(fontSize: 16),
              ),
            ] else ...[
              const Text(
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
                    children: _accounts
                        .map((a) => ChoiceChip(
                              avatar: Icon(deserializeIcon(a.icon)?.data, color: Color(a.color)),
                              backgroundColor: Color(a.color).withAlpha(100),
                              selectedColor: Color(a.color).withAlpha(100),
                              label: Text(a.accountName),
                              selected: _selectedAccount == a.accountId,
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                side: _selectedAccount == a.accountId
                                    ? BorderSide(color: Color(a.color), width: 3)
                                    : BorderSide.none,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedAccount = selected ? a.accountId : "";
                                });
                              },
                            ))
                        .toList(),
                  );
                },
                validator: (value) {
                  if (_selectedAccount.isEmpty) {
                    return 'Please select an account';
                  }
                  return null;
                },
              ),
            ),
            if (_selectedTransactionType == TransactionType.transfer) ...[
              const Text(
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
                      children: _accounts
                          .map((a) => ChoiceChip(
                                avatar: Icon(deserializeIcon(a.icon)?.data, color: Color(a.color)),
                                backgroundColor: Color(a.color).withAlpha(100),
                                selectedColor: Color(a.color).withAlpha(100),
                                label: Text(a.accountName),
                                selected: _selectedDestinationAccount == a.accountId,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  side: _selectedDestinationAccount == a.accountId
                                      ? BorderSide(color: Color(a.color), width: 3)
                                      : BorderSide.none,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedDestinationAccount = selected ? a.accountId : "";
                                  });
                                },
                              ))
                          .toList(),
                    );
                  },
                  validator: (value) {
                    if (_selectedDestinationAccount.isEmpty) {
                      return 'Please select a destination account';
                    }
                    return null;
                  },
                ),
              ),
            ] else ...[
              const Text(
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
                      children: _tags
                          .map((c) => ChoiceChip(
                                avatar: Icon(deserializeIcon(c.icon)?.data, color: Color(c.color)),
                                backgroundColor: Color(c.color).withAlpha(100),
                                selectedColor: Color(c.color).withAlpha(100),
                                label: Text(c.tagName),
                                selected: _selectedTags.contains(c.tagId),
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  side: _selectedTags.contains(c.tagId)
                                      ? BorderSide(color: Color(c.color), width: 3)
                                      : BorderSide.none,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTags.add(c.tagId);
                                    } else {
                                      _selectedTags.remove(c.tagId);
                                    }
                                  });
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _transactionNameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  hintText: "e.g. Lunch",
                  border: OutlineInputBorder(),
                ),
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
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: "Amount",
                hintText: "e.g. 79.9",
                border: OutlineInputBorder(),
              ),
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
                if (_selectedTransactionType != TransactionType.adjustment && double.parse(value) < 0) {
                  return 'Negative amounts are only allowed for adjustments';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _currencyController,
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
                      _currencyController.text = currency.code;
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
            const Divider(height: 24),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: DateFormat('yyyy-MM-dd').format(
                        DateFormat('yyyy-MM-dd HH:mm').parse(_transactionTimeController.text),
                      ),
                    ),
                    decoration: const InputDecoration(
                      labelText: "Date",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateFormat('yyyy-MM-dd').parse(_transactionTimeController.text),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );

                      if (pickedDate != null) {
                        final currentTime = DateFormat('HH:mm').parse(
                          DateFormat('HH:mm').format(
                            DateFormat('yyyy-MM-dd HH:mm').parse(_transactionTimeController.text),
                          ),
                        );

                        final combinedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          currentTime.hour,
                          currentTime.minute,
                        );

                        setState(() {
                          _transactionTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: DateFormat('HH:mm').format(
                        DateFormat('yyyy-MM-dd HH:mm').parse(_transactionTimeController.text),
                      ),
                    ),
                    decoration: const InputDecoration(
                      labelText: "Time",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final initialTime = TimeOfDay.fromDateTime(
                        DateFormat('yyyy-MM-dd HH:mm').parse(_transactionTimeController.text),
                      );
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: initialTime,
                      );

                      if (pickedTime != null) {
                        final currentDate = DateFormat('yyyy-MM-dd').parse(
                          DateFormat('yyyy-MM-dd').format(
                            DateFormat('yyyy-MM-dd HH:mm').parse(_transactionTimeController.text),
                          ),
                        );

                        final combinedDateTime = DateTime(
                          currentDate.year,
                          currentDate.month,
                          currentDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );

                        setState(() {
                          _transactionTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
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
