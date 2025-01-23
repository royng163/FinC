import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import '../../models/account_model.dart';
import '../../helpers/firestore_service.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:currency_picker/currency_picker.dart';
import '../../components/settings_controller.dart';

class AddAccountView extends StatefulWidget {
  final SettingsController settingsController;

  const AddAccountView({super.key, required this.settingsController});

  @override
  AddAccountViewState createState() => AddAccountViewState();
}

class AddAccountViewState extends State<AddAccountView> {
  final TextEditingController accountNameController = TextEditingController();
  final List<TextEditingController> balanceControllers = [];
  final List<TextEditingController> currencyControllers = [];
  Color selectedColor = Colors.grey;
  IconPickerIcon? selectedIcon;
  AccountType selectedAccountType = AccountType.bank;

  late FirestoreService firestore;

  @override
  void initState() {
    super.initState();
    firestore = FirestoreService();
    addCurrencyField(widget.settingsController.baseCurrency, '0.0');
  }

  @override
  void dispose() {
    accountNameController.dispose();
    for (var controller in balanceControllers) {
      controller.dispose();
    }
    for (var controller in currencyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void addCurrencyField(String currency, String balance) {
    final currencyController = TextEditingController(text: currency);
    final balanceController = TextEditingController(text: balance);
    setState(() {
      currencyControllers.add(currencyController);
      balanceControllers.add(balanceController);
    });
  }

  void removeCurrencyField(int index) {
    setState(() {
      currencyControllers[index].dispose();
      balanceControllers[index].dispose();
      currencyControllers.removeAt(index);
      balanceControllers.removeAt(index);
    });
  }

  void addAccount() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      final String userId = user.uid;
      final String accountId = firestore.db.collection('Accounts').doc().id;

      final Map<String, double> balances = {};
      for (int i = 0; i < currencyControllers.length; i++) {
        final currency = currencyControllers[i].text;
        final balance = double.parse(balanceControllers[i].text);
        balances[currency] = balance;
      }

      final AccountModel account = AccountModel(
        accountId: accountId,
        userId: userId,
        accountType: selectedAccountType,
        accountName: accountNameController.text,
        balances: balances,
        icon: serializeIcon(selectedIcon!) ?? {},
        color: selectedColor.value,
        createdAt: Timestamp.now(),
      );

      await firestore.setAccount(account);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account Added Successfully')),
      );

      // Clear the form
      accountNameController.clear();
      for (var controller in balanceControllers) {
        controller.clear();
      }
      for (var controller in currencyControllers) {
        controller.clear();
      }
      setState(() {
        selectedColor = Colors.grey;
        selectedAccountType = AccountType.bank;
      });

      Navigator.pop(context);
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
              color: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
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
    selectedIcon = await showIconPicker(
      context,
      configuration: SinglePickerConfiguration(
        iconPackModes: [IconPack.fontAwesomeIcons],
      ),
    );
    if (selectedIcon != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('New Account'),
        ),
        body: Padding(
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
                      selected: selectedAccountType == type,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedAccountType = type;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                TextFormField(
                  controller: accountNameController,
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
                  itemCount: currencyControllers.length,
                  itemBuilder: (context, index) {
                    return Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: currencyControllers[index],
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
                                    currencyControllers[index].text = currency.code;
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
                            controller: balanceControllers[index],
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
                    );
                  },
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
                      color: selectedColor,
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: pickIcon,
                      child: const Text('Pick Icon'),
                    ),
                    if (selectedIcon != null) Icon(selectedIcon!.data, color: selectedColor),
                  ],
                ),
                ElevatedButton(
                  onPressed: addAccount,
                  child: const Text("Add Account"),
                ),
              ],
            ),
          ),
        ));
  }
}
