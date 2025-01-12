import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:currency_converter_pro/currency_converter_pro.dart';
import '../models/account_model.dart';

class BalanceService {
  final CurrencyConverterPro currencyConverter = CurrencyConverterPro();
  User? _currentUser;

  Future<User?> getCurrentUser() async {
    if (_currentUser == null) {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser == null) {
        throw Exception('No user is currently signed in.');
      }
    }
    return _currentUser;
  }

  Future<double> getTotalBalance(String baseCurrency) async {
    final User? user = await getCurrentUser();

    final accountsSnapshot = await FirebaseFirestore.instance
        .collection('Accounts')
        .where('userId', isEqualTo: user!.uid)
        .get();

    double balance = 0.0;
    List<AccountModel> fetchedAccounts = accountsSnapshot.docs.map((doc) {
      return AccountModel.fromDocument(doc);
    }).toList();

    for (var account in fetchedAccounts) {
      if (account.accountType == AccountType.bank ||
          account.accountType == AccountType.creditCard ||
          account.accountType == AccountType.securities) {
        for (var entry in account.balances.entries) {
          var amount = await currencyConverter.convertCurrency(
            amount: entry.value,
            fromCurrency: entry.key.toLowerCase(),
            toCurrency: baseCurrency.toLowerCase(),
          );
          balance += amount;
        }
      }
    }

    return balance;
  }

  Future<double> getAccountBalance(
      Map<String, double> balances, String baseCurrency) async {
    double balance = 0.0;
    for (var entry in balances.entries) {
      var amount = await currencyConverter.convertCurrency(
        amount: entry.value,
        fromCurrency: entry.key.toLowerCase(),
        toCurrency: baseCurrency.toLowerCase(),
      );
      balance += amount;
    }

    return balance;
  }
}
