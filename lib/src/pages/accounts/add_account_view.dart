import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finc/src/helpers/hive_service.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import '../../helpers/authentication_service.dart';
import '../../models/account_model.dart';
import '../../helpers/firestore_service.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:currency_picker/currency_picker.dart';
import '../../helpers/settings_service.dart';

class AddAccountView extends StatefulWidget {
  final SettingsService settingsService;

  const AddAccountView({super.key, required this.settingsService});

  @override
  AddAccountViewState createState() => AddAccountViewState();
}

class AddAccountViewState extends State<AddAccountView> {
  final _firestoreService = FirestoreService();
  final _hiveService = HiveService();
  final _authService = AuthenticationService();
  final _accountNameController = TextEditingController();
  final List<TextEditingController> _balanceControllers = [];
  final List<TextEditingController> _currencyControllers = [];
  late User _user;
  Color _selectedColor = Colors.grey;
  IconPickerIcon? _selectedIcon;
  AccountType _selectedAccountType = AccountType.bank;

  @override
  void initState() {
    super.initState();
    _user = _authService.getCurrentUser();
    addCurrencyField(widget.settingsService.baseCurrency, '0.0');
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    for (var controller in _balanceControllers) {
      controller.dispose();
    }
    for (var controller in _currencyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void addCurrencyField(String currency, String balance) {
    final currencyController = TextEditingController(text: currency);
    final balanceController = TextEditingController(text: balance);
    setState(() {
      _currencyControllers.add(currencyController);
      _balanceControllers.add(balanceController);
    });
  }

  void removeCurrencyField(int index) {
    setState(() {
      _currencyControllers[index].dispose();
      _balanceControllers[index].dispose();
      _currencyControllers.removeAt(index);
      _balanceControllers.removeAt(index);
    });
  }

  void addAccount() async {
    try {
      final Map<String, double> balances = {};
      for (int i = 0; i < _currencyControllers.length; i++) {
        final currency = _currencyControllers[i].text;
        final balance = double.parse(_balanceControllers[i].text);
        balances[currency] = balance;
      }

      final AccountModel account = AccountModel(
        accountId: _firestoreService.firestore.collection('Accounts').doc().id,
        userId: _user.uid,
        accountType: _selectedAccountType,
        accountName: _accountNameController.text,
        balances: balances,
        icon: serializeIcon(_selectedIcon!) ?? {},
        // ignore: deprecated_member_use
        color: _selectedColor.value,
        createdAt: Timestamp.now(),
      );

      await _hiveService.setAccount(account);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account Added Successfully')),
      );

      // Clear the form
      _accountNameController.clear();
      for (var controller in _balanceControllers) {
        controller.clear();
      }
      for (var controller in _currencyControllers) {
        controller.clear();
      }
      setState(() {
        _selectedColor = Colors.grey;
        _selectedAccountType = AccountType.bank;
      });

      Navigator.pop(context, true);
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add account: $e')),
      );
    }
  }

  void pickColor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              heading: Text(
                'Select color',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              subheading: Text(
                'Select color shade',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text('Select'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void pickIcon() async {
    _selectedIcon = await showIconPicker(
      context,
      configuration: SinglePickerConfiguration(
        iconPackModes: [IconPack.fontAwesomeIcons],
      ),
    );
    if (_selectedIcon != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('New Account'),
        ),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Form(
              child: Column(
                spacing: 8,
                children: [
                  Wrap(
                    spacing: 8.0,
                    children: AccountType.values.map((AccountType type) {
                      return ChoiceChip(
                        label: Text(type
                            .toString()
                            .split('.')
                            .last
                            .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (Match m) => "${m[1]} ${m[2]}")
                            .replaceFirstMapped(RegExp(r'^[a-z]'), (Match m) => m[0]!.toUpperCase())),
                        selected: _selectedAccountType == type,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedAccountType = type;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  TextFormField(
                    controller: _accountNameController,
                    decoration: const InputDecoration(
                        labelText: "Account Name", hintText: "e.g. Cash", border: OutlineInputBorder()),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an account name';
                      }
                      return null;
                    },
                  ),
                  Column(
                    spacing: 8.0,
                    children: List.generate(_currencyControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _currencyControllers[index],
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: "Currency",
                                  border: OutlineInputBorder(),
                                ),
                                onTap: () {
                                  showCurrencyPicker(
                                    context: context,
                                    onSelect: (Currency currency) {
                                      setState(() {
                                        _currencyControllers[index].text = currency.code;
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
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _balanceControllers[index],
                                decoration: const InputDecoration(
                                    labelText: "Balance", hintText: "e.g. 1000.0", border: OutlineInputBorder()),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  // Allow only numbers and decimal point, and limit to two decimal places
                                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a balance';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  final parts = value.split('.');
                                  if (parts.length == 2 && parts[1].length > 2) {
                                    return 'Balance cannot have more than two decimal places';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle),
                              onPressed: () {
                                removeCurrencyField(index);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      addCurrencyField('', '0.0');
                    },
                    child: const Text("Add Currency"),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: pickColor,
                        child: const Text('Pick Color'),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        color: _selectedColor,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: pickIcon,
                        child: const Text('Pick Icon'),
                      ),
                      if (_selectedIcon != null) Icon(_selectedIcon!.data, color: _selectedColor),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: addAccount,
                    child: const Text("Add Account"),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
