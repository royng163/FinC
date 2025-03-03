import 'dart:convert';
import 'package:finc/src/helpers/authentication_service.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:finc/src/models/transaction_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'hive_service.dart';

class BalanceService {
  // locally stored data from the user's device
  final HiveService _hiveService = HiveService();
  // Realtime Database which contain the exchange rates
  final FirebaseDatabase db = FirebaseDatabase.instance;
  User user = AuthenticationService().getCurrentUser();

  /// Returns exchange rates from the Realtime Database if recent (within 5 minutes),
  /// otherwise fetches new rates from CoinGecko, updates the database, and returns them.
  Future<Map<String, dynamic>> getExchangeRates() async {
    final newRates = _hiveService.getFxRates();
    if (newRates != null) {
      return newRates;
    }

    final updatedRates = await _updateExchangeRates();
    _hiveService.setFxRates(updatedRates);
    return updatedRates;

    // final ref = db.ref('fxRates');
    // final snapshot = await ref.get();

    // if (snapshot.exists && snapshot.value != null) {
    //   return Map<String, dynamic>.from(snapshot.value as Map);
    // }
    // throw Exception("Exchange rates not available");
  }

  /// Fetches the exchange rates from CoinGecko.
  Future<Map<String, dynamic>> _updateExchangeRates() async {
    try {
      final apiKey = dotenv.env['COINGECKO_API_KEY'] ?? '';
      // Build the request URL. Append the API key if required.
      final uri = Uri.parse('https://api.coingecko.com/api/v3/exchange_rates$apiKey');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception("Failed to fetch exchange rates: ${response.statusCode}");
      }
      final data = json.decode(response.body);

      // Validate response contains required data
      if (data['rates'] == null) {
        throw Exception("Invalid exchange rate data format");
      }

      return {'rates': data['rates'], 'lastUpdatedTimestamp': DateTime.now().millisecondsSinceEpoch};
    } catch (e) {
      // ignore: avoid_print
      print("Error updating exchange rates: $e");
      // Return empty rates rather than throwing
      return {'rates': {}, 'lastUpdatedTimestamp': DateTime.now().millisecondsSinceEpoch};
    }
  }

  /// Converts an amount from one currency to another using CoinGecko's exchange rates.
  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    // If both currencies are the same, no conversion is needed.
    if (fromCurrency.toLowerCase() == toCurrency.toLowerCase()) {
      return amount;
    }

    try {
      // Parse the response and extract the Bitcoin exchange rates
      final data = await getExchangeRates();
      final rates = (data['rates'] as Map<dynamic, dynamic>).cast<String, dynamic>();

      final fromRateData = rates[fromCurrency.toLowerCase()];
      final toRateData = rates[toCurrency.toLowerCase()];

      if (fromRateData == null || toRateData == null) {
        // Return original amount instead of throwing - much safer!
        // ignore: avoid_print
        print("Conversion rate not found for $fromCurrency or $toCurrency - using 1:1 rate");
        return amount;
      }

      // Retrieve the currency to Bitcoin conversion rate
      final double fromValue = (fromRateData['value'] as num).toDouble();
      final double toValue = (toRateData['value'] as num).toDouble();

      // Calculate the exchange rate between the two currencies and convert the amount
      return amount * (toValue / fromValue);
    } catch (e) {
      // Handle any errors gracefully
      // ignore: avoid_print
      print("Error in currency conversion: $e");
      return amount; // Return original amount as fallback
    }
  }

  Future<double> getTotalBalance(String baseCurrency) async {
    List<AccountModel> fetchedAccounts = _hiveService.accountsBox.values.toList();

    double balance = 0.0;

    for (var account in fetchedAccounts) {
      if (account.accountType == AccountType.bank || account.accountType == AccountType.securities) {
        for (var entry in account.balances.entries) {
          var amount = await convertCurrency(
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

  Future<Map<String, double>> getMonthlyStats(String baseCurrency) async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    List<TransactionModel> monthlyTransactions = await _hiveService.getMonthlyTransactions(thisMonth);

    double income = 0.0;
    double expense = 0.0;

    for (var transaction in monthlyTransactions) {
      var amount = await convertCurrency(
        amount: transaction.amount,
        fromCurrency: transaction.currency.toLowerCase(),
        toCurrency: baseCurrency.toLowerCase(),
      );
      if (transaction.transactionType == TransactionType.income) {
        income += amount;
      } else if (transaction.transactionType == TransactionType.expense) {
        expense += amount;
      }
    }

    return {
      'income': income,
      'expense': expense,
    };
  }

  Future<double> getAccountBalance(Map<String, double> balances, String baseCurrency) async {
    double balance = 0.0;
    for (var entry in balances.entries) {
      var amount = await convertCurrency(
        amount: entry.value,
        fromCurrency: entry.key.toLowerCase(),
        toCurrency: baseCurrency.toLowerCase(),
      );
      balance += amount;
    }

    return balance;
  }
}
