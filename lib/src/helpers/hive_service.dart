import 'package:finc/src/helpers/firestore_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account_model.dart';
import '../models/tag_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class HiveService {
  // Singleton instance
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  // Initialize FirestoreService lazily when needed, not during construction
  FirestoreService? _firestoreService;
  FirestoreService get firestoreService => _firestoreService ??= FirestoreService();

  late final Box<dynamic> settingsBox;
  late final Box<AccountModel> accountsBox;
  late final Box<TransactionModel> transactionsBox;
  late final Box<TagModel> tagsBox;

  Future<void> init() async {
    settingsBox = await Hive.openBox<dynamic>('settings');
    accountsBox = await Hive.openBox<AccountModel>('accounts');
    transactionsBox = await Hive.openBox<TransactionModel>('transactions');
    tagsBox = await Hive.openBox<TagModel>('tags');
  }

  Future<void> syncData() async {
    final accounts = await firestoreService.getAccounts();
    final transactions = await firestoreService.getTransactions();
    final tags = await firestoreService.getTags();

    await accountsBox.clear();
    await transactionsBox.clear();
    await tagsBox.clear();

    for (final account in accounts) {
      await accountsBox.put(account.accountId, account);
    }
    for (final transaction in transactions) {
      await transactionsBox.put(transaction.transactionId, transaction);
    }
    for (final tag in tags) {
      await tagsBox.put(tag.tagId, tag);
    }
  }

  Future<void> setUser(UserModel user) async {
    await settingsBox.put('user', user);
    await _firestoreService?.setUser(user);
  }

  Future<UserModel?> getUser() async {
    return settingsBox.get('user');
  }

  Future<void> setAccount(AccountModel account) async {
    await accountsBox.put(account.accountId, account);
    await _firestoreService?.setAccount(account);
  }

  Future<AccountModel> getAccount(String accountId) async {
    final account = accountsBox.get(accountId);
    if (account == null) {
      throw Exception('Account not found for id: $accountId');
    }
    return account;
  }

  Future<List<AccountModel>> getAccounts() async {
    return accountsBox.values.toList();
  }

  Future<String> deleteAccount(String accountId, String accountName) async {
    try {
      // 1. Update transfer transactions where the destination is this account
      final transferTransactions = transactionsBox.values
          .where((transaction) =>
              transaction.transactionType == TransactionType.transfer && transaction.transactionName == accountId)
          .toList();

      for (var transaction in transferTransactions) {
        // Create a copy with updated type and name
        final updatedTransaction = transaction.copyWith(
          transactionType: TransactionType.adjustment,
          transactionName: 'To $accountName',
          amount: -transaction.amount, // Make the amount negative
        );

        // Update in local storage
        await transactionsBox.put(transaction.transactionId, updatedTransaction);

        // Update in Firestore
        await _firestoreService?.setTransaction(updatedTransaction);
      }

      // 2. Get all transactions where the account is the source
      final sourceTransactions =
          transactionsBox.values.where((transaction) => transaction.accountId == accountId).toList();

      // Delete all source transactions
      for (var transaction in sourceTransactions) {
        await transactionsBox.delete(transaction.transactionId);

        // Delete from Firestore
        await _firestoreService?.deleteTransaction(transaction.transactionId);
      }

      // 3. Delete the account itself
      await accountsBox.delete(accountId);

      // Optionally delete from Firestore
      if (_firestoreService != null) {
        await _firestoreService!.deleteAccount(accountId);
      }

      return "Account deleted successfully!";
    } catch (e) {
      return "Failed to delete account: $e";
    }
  }

  Future<String> setTransaction(TransactionModel transaction) async {
    try {
      // Add the transaction to the local database
      await transactionsBox.put(transaction.transactionId, transaction);
      // Add the transaction to the Firestore
      await _firestoreService?.setTransaction(transaction);

      // Update the account balance
      final transactionAccount = await getAccount(transaction.accountId);
      double newBalance = transactionAccount.balances[transaction.currency] ?? 0.0;
      switch (transaction.transactionType) {
        case TransactionType.expense:
          newBalance -= transaction.amount;
          break;
        case TransactionType.income:
          newBalance += transaction.amount;
          break;
        case TransactionType.transfer:
          final destinationAccount =
              await getAccount(transaction.transactionName); // transactionName is the destination account id
          double destinationNewBalance = destinationAccount.balances[transaction.currency] ?? 0.0;
          newBalance -= transaction.amount;
          destinationNewBalance += transaction.amount;
          destinationAccount.balances[transaction.currency] = destinationNewBalance;
          await setAccount(destinationAccount);
          break;
        case TransactionType.adjustment:
          newBalance += transaction.amount;
          break;
      }
      transactionAccount.balances[transaction.currency] = newBalance;
      await setAccount(transactionAccount);
      return "Transaction added successfully!";
    } catch (e) {
      return "Failed to add transaction: $e";
    }
  }

  Future<TransactionModel> getTransaction(String transactionId) async {
    final transaction = transactionsBox.get(transactionId);
    if (transaction == null) {
      throw Exception('Transaction not found for id: $transactionId');
    }
    return transaction;
  }

  Future<List<TransactionModel>> getTransactions() async {
    final transactions = transactionsBox.values.toList();
    // Sort transactions by date (newest first)
    transactions.sort((a, b) => b.transactionTime.compareTo(a.transactionTime));
    return transactions;
  }

  Future<List<TransactionModel>> getAccountTransactions(String accountId) async {
    final List<TransactionModel> allTransactions = [];

    // Get transactions where the account is the source
    final sourceTransactions =
        transactionsBox.values.where((transaction) => transaction.accountId == accountId).toList();

    // Get transfer transactions where this account is the destination
    final transferTransactions = transactionsBox.values
        .where((transaction) =>
            transaction.transactionType == TransactionType.transfer && transaction.transactionName == accountId)
        .toList();

    // Combine both lists
    allTransactions.addAll(sourceTransactions);
    allTransactions.addAll(transferTransactions);

    // Sort transactions by date (newest first)
    allTransactions.sort((a, b) => b.transactionTime.compareTo(a.transactionTime));

    return allTransactions;
  }

  Future<String> updateTransaction(TransactionModel newTransaction, TransactionModel oldTransaction) async {
    try {
      // Fetch the corresponding account
      final oldAccount = await getAccount(oldTransaction.accountId);

      // Reverse the original transaction's effect
      double oldBalance = oldAccount.balances[oldTransaction.currency] ?? 0.0;
      switch (oldTransaction.transactionType) {
        case TransactionType.expense:
          oldBalance += oldTransaction.amount;
          break;
        case TransactionType.income:
          oldBalance -= oldTransaction.amount;
          break;
        case TransactionType.transfer:
          final destinationAccount = await getAccount(oldTransaction.transactionName);
          double destinationBalance = destinationAccount.balances[oldTransaction.currency] ?? 0.0;
          oldBalance += oldTransaction.amount;
          destinationBalance -= oldTransaction.amount;
          destinationAccount.balances[oldTransaction.currency] = destinationBalance;
          await setAccount(destinationAccount);
          break;
        case TransactionType.adjustment:
          oldBalance -= oldTransaction.amount;
          break;
      }
      oldAccount.balances[oldTransaction.currency] = oldBalance;
      await setAccount(oldAccount);

      // Apply the new transaction's effect
      await setTransaction(newTransaction);
      return "Transaction updated successfully!";
    } catch (e) {
      return "Failed to update transaction: $e";
    }
  }

  Future<String> deleteTransaction(TransactionModel transaction) async {
    try {
      // Fetch the corresponding account
      final account = await getAccount(transaction.accountId);

      // Reverse the transaction's effect
      double balance = account.balances[transaction.currency] ?? 0.0;
      switch (transaction.transactionType) {
        case TransactionType.expense:
          balance += transaction.amount;
          break;
        case TransactionType.income:
          balance -= transaction.amount;
          break;
        case TransactionType.transfer:
          final destinationAccount = await getAccount(transaction.transactionName);
          double destinationBalance = destinationAccount.balances[transaction.currency] ?? 0.0;
          balance += transaction.amount;
          destinationBalance -= transaction.amount;
          destinationAccount.balances[transaction.currency] = destinationBalance;
          await setAccount(destinationAccount);
          break;
        case TransactionType.adjustment:
          balance -= transaction.amount;
          break;
      }
      account.balances[transaction.currency] = balance;
      await setAccount(account);

      // Delete the transaction from Firestore
      await _firestoreService?.deleteTransaction(transaction.transactionId);
      // Delete the transaction from local storage
      await transactionsBox.delete(transaction.transactionId);
      return "Transaction deleted successfully!";
    } catch (e) {
      return "Failed to delete transaction: $e";
    }
  }

  Future<List<TransactionModel>> getMonthlyTransactions(DateTime thisMonth) async {
    final List<TransactionModel> allTransactions = transactionsBox.values.toList();

    // Calculate first and last day of the month
    final firstDayOfMonth = DateTime(thisMonth.year, thisMonth.month, 1);
    final lastDayOfMonth = DateTime(thisMonth.year, thisMonth.month + 1, 0, 23, 59, 59);

    final List<TransactionModel> filteredTransactions = allTransactions.where((transaction) {
      final transactionDate = transaction.transactionTime.toDate();
      // Include transaction if it falls within the month
      return transactionDate.isAfter(firstDayOfMonth) &&
          transactionDate.isBefore(lastDayOfMonth.add(const Duration(seconds: 1)));
    }).toList();

    // Sort transactions descending by transactionTime.
    filteredTransactions.sort((a, b) => b.transactionTime.compareTo(a.transactionTime));
    return filteredTransactions;
  }

  Future<void> setTag(TagModel tag) async {
    await tagsBox.put(tag.tagId, tag);
    await _firestoreService?.setTag(tag);
  }

  Future<List<TagModel>> getTags() async {
    return tagsBox.values.toList();
  }

  Future<void> deleteTag(String tagId) async {
    await tagsBox.delete(tagId);
  }

  Future<void> clearAllData() async {
    await settingsBox.clear();
    await accountsBox.clear();
    await transactionsBox.clear();
    await tagsBox.clear();
  }
}
