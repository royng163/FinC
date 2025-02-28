import 'dart:convert';
import 'package:finc/src/helpers/authentication_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import 'hive_service.dart';

class BalanceService {
  // locally stored data from the user's device
  final HiveService _hiveService = HiveService();
  // Realtime Database which contain the exchange rates
  final FirebaseDatabase db = FirebaseDatabase.instance;
  User user = AuthenticationService().getCurrentUser();

  BalanceService() {
    db.setPersistenceEnabled(true);
  }

  /// Returns exchange rates from the Realtime Database if recent (within 5 minutes),
  /// otherwise fetches new rates from CoinGecko, updates the database, and returns them.
  Future<Map<String, dynamic>> getExchangeRates() async {
    final ref = db.ref('fxRates');
    final snapshot = await ref.get();
    final now = DateTime.now();

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final int storedTimestamp = data['lastUpdatedTimestamp'] ?? 0;
      final lastUpdated = DateTime.fromMillisecondsSinceEpoch(storedTimestamp);
      if (now.difference(lastUpdated) < Duration(minutes: 5)) {
        // Use cached rates from Realtime Database
        return data;
      }
    }
    // Rates missing or older than 5 minutes: fetch, update cloud, and return new rates.
    final newRates = await _updateExchangeRates();
    newRates['lastUpdatedTimestamp'] = now.millisecondsSinceEpoch;
    await ref.set(newRates);
    return newRates;
  }

  /// Fetches the exchange rates from CoinGecko.
  Future<Map<String, dynamic>> _updateExchangeRates() async {
    final apiKey = dotenv.env['COINGECKO_API_KEY'] ?? '';
    // Build the request URL. Append the API key if required.
    final uri = Uri.parse('https://api.coingecko.com/api/v3/exchange_rates$apiKey');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception("Failed to fetch exchange rates");
    }
    final data = json.decode(response.body);
    // Return only the rates part (adjust as needed).
    return {
      'rates': data['rates'],
    };
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

    // Parse the response and extract the Bitcoin exchange rates
    final data = await getExchangeRates();
    final rates = (data['rates'] as Map<dynamic, dynamic>).cast<String, dynamic>();

    final fromRateData = rates[fromCurrency.toLowerCase()];
    final toRateData = rates[toCurrency.toLowerCase()];

    if (fromRateData == null || toRateData == null) {
      throw Exception("Conversion rate not found for $fromCurrency or $toCurrency");
    }

    // Retrieve the currency to Bitcoin conversion rate
    final double fromValue = (fromRateData['value'] as num).toDouble();
    final double toValue = (toRateData['value'] as num).toDouble();

    // Calculate the exchange rate between the two currencies and convert the amount
    return amount * (toValue / fromValue);
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
