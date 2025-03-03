import 'package:finc/src/helpers/authentication_service.dart';
import 'package:finc/src/helpers/hive_service.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/services.dart';

class EditAccountView extends StatefulWidget {
  final AccountModel account;

  const EditAccountView({
    super.key,
    required this.account,
  });

  @override
  EditAccountViewState createState() => EditAccountViewState();
}

class EditAccountViewState extends State<EditAccountView> {
  final _hiveService = HiveService();
  final _authService = AuthenticationService();
  final _accountNameController = TextEditingController();
  final _balanceControllers = <TextEditingController>[];
  final _currencyControllers = <TextEditingController>[];
  late User _user;
  late Color _selectedColor;
  late IconPickerIcon? _selectedIcon;
  late AccountType _selectedAccountType;

  @override
  void initState() {
    super.initState();
    _user = _authService.getCurrentUser();
    _accountNameController.text = widget.account.accountName;
    _selectedColor = Color(widget.account.color);
    _selectedIcon = deserializeIcon(widget.account.icon);
    _selectedAccountType = widget.account.accountType;

    widget.account.balances.forEach((currency, balance) {
      _addCurrencyField(currency, balance.toString());
    });
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

  void _addCurrencyField(String currency, String balance) {
    final currencyController = TextEditingController(text: currency);
    final balanceController = TextEditingController(text: balance);
    setState(() {
      _currencyControllers.add(currencyController);
      _balanceControllers.add(balanceController);
    });
  }

  void _removeCurrencyField(int index) {
    setState(() {
      _currencyControllers[index].dispose();
      _balanceControllers[index].dispose();
      _currencyControllers.removeAt(index);
      _balanceControllers.removeAt(index);
    });
  }

  void _editAccount() async {
    try {
      final Map<String, double> balances = {};
      for (int i = 0; i < _currencyControllers.length; i++) {
        final currency = _currencyControllers[i].text;
        final balance = double.parse(_balanceControllers[i].text);
        balances[currency] = balance;
      }

      final AccountModel updatedAccount = AccountModel(
        accountId: widget.account.accountId,
        userId: _user.uid,
        accountType: _selectedAccountType,
        accountName: _accountNameController.text,
        balances: balances,
        icon: serializeIcon(_selectedIcon!) ?? {},
        // ignore: deprecated_member_use
        color: _selectedColor.value,
        createdAt: widget.account.createdAt,
      );

      await _hiveService.setAccount(updatedAccount);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account Updated Successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update account: $e')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await _hiveService.deleteAccount(widget.account.accountId, widget.account.accountName);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account Deleted Successfully')),
      );

      Navigator.pop(context); // Pass an integer indicating account deletion
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  void _pickColor() {
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

  void _pickIcon() async {
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
        title: const Text('Edit Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteAccount,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
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
              ListView.builder(
                shrinkWrap: true,
                itemCount: _currencyControllers.length,
                itemBuilder: (context, index) {
                  return Row(
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
                            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a balance';
                            }
                            if (value == '-') {
                              return 'Please enter a valid number';
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
                          _removeCurrencyField(index);
                        },
                      ),
                    ],
                  );
                },
              ),
              ElevatedButton(
                onPressed: () {
                  _addCurrencyField('', '0.0');
                },
                child: const Text("Add Currency"),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickColor,
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
                    onPressed: _pickIcon,
                    child: const Text('Pick Icon'),
                  ),
                  if (_selectedIcon != null) Icon(_selectedIcon!.data, color: _selectedColor),
                ],
              ),
              ElevatedButton(
                onPressed: _editAccount,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
