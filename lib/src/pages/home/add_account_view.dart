import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController balanceController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();

  late FirestoreService firestore;

  @override
  void initState() {
    super.initState();
    firestore = FirestoreService();
    currencyController.text = widget.settingsController.baseCurrency;
  }

  @override
  void dispose() {
    accountNameController.dispose();
    balanceController.dispose();
    currencyController.dispose();
    super.dispose();
  }

  void addAccount() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      final String userId = user.uid;
      final String accountId = firestore.db.collection('Accounts').doc().id;

      final AccountModel account = AccountModel(
        accountId: accountId,
        userId: userId,
        accountName: accountNameController.text,
        balance: double.parse(balanceController.text),
        currency: currencyController.text,
        createdAt: Timestamp.now(),
      );

      await firestore.createAccount(account);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account Added Successfully')),
      );

      // Clear the form
      accountNameController.clear();
      balanceController.clear();

      // Optionally, navigate back or perform other actions
      // Navigator.pop(context);
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add account: $e')),
      );
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
                TextFormField(
                  controller: accountNameController,
                  decoration: const InputDecoration(
                      labelText: "Account Name",
                      hintText: "e.g. Cash",
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an account name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: balanceController,
                  decoration: const InputDecoration(
                      labelText: "Balance",
                      hintText: "e.g. 1000.0",
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    // Allow only numbers and decimal point, and limit to two decimal places
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
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
