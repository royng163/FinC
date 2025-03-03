import 'package:finc/src/components/app_routes.dart';
import 'package:finc/src/helpers/hive_service.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:finc/src/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:currency_picker/currency_picker.dart';

class EditTransactionView extends StatefulWidget {
  final TransactionModel _transaction;

  const EditTransactionView({
    super.key,
    required TransactionModel transaction,
  }) : _transaction = transaction;

  @override
  EditTransactionViewState createState() => EditTransactionViewState();
}

class EditTransactionViewState extends State<EditTransactionView> {
  final HiveService _hiveService = HiveService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _transactionNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _transactionTimeController = TextEditingController();
  late TransactionType _selectedTransactionType;
  late String _selectedAccount;
  String _selectedDestinationAccount = "";
  List<AccountModel> _accounts = [];
  List<String> _selectedTags = [];
  List<TagModel> _tags = [];
  String _response = "";

  @override
  void initState() {
    super.initState();
    _transactionNameController.text = widget._transaction.transactionName;
    _amountController.text = widget._transaction.amount.toString();
    _currencyController.text = widget._transaction.currency;
    _descriptionController.text = widget._transaction.description;
    _transactionTimeController.text =
        DateFormat('yyyy-MM-dd HH:mm').format(widget._transaction.transactionTime.toDate());
    _selectedAccount = widget._transaction.accountId;
    _selectedTags = widget._transaction.tags;
    _selectedTransactionType = widget._transaction.transactionType;
    _selectedDestinationAccount = widget._transaction.transactionName;
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final accounts = _hiveService.getAccounts();
      final tags = _hiveService.getTags();
      setState(() {
        _accounts = accounts;
        _tags = tags;
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

  Future<void> editTransaction() async {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      final oldTransaction = await _hiveService.getTransaction(widget._transaction.transactionId);

      // Create the updated transaction
      final newTransaction = TransactionModel(
        transactionId: oldTransaction.transactionId,
        userId: oldTransaction.userId,
        accountId: _selectedAccount,
        tags: _selectedTags,
        transactionName: _selectedTransactionType == TransactionType.transfer
            ? _selectedDestinationAccount
            : _transactionNameController.text,
        amount: double.parse(_amountController.text),
        currency: _currencyController.text,
        description: _descriptionController.text,
        transactionType: _selectedTransactionType,
        transactionTime: Timestamp.fromDate(DateFormat('yyyy-MM-dd HH:mm').parse(_transactionTimeController.text)),
      );

      _response = await _hiveService.updateTransaction(newTransaction, oldTransaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_response)),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_response)),
      );
    }
  }

  Future<void> deleteTransaction() async {
    try {
      _response = await _hiveService.deleteTransaction(widget._transaction);

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
                extra: widget._transaction,
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
              Divider(
                height: 24,
              ),
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
            SizedBox(height: 10),
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
            SizedBox(height: 10),
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
            Divider(
              height: 24,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            Divider(
              height: 24,
            ),
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
