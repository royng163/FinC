import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/tag_model.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Users Collection
  Future<void> setUser(UserModel user) {
    return db.collection('Users').doc(user.userId).set(user.toFirestore());
  }

  Future<UserModel> getUser(String userId) async {
    final snapshot = await db.collection('Users').doc(userId).get();
    return UserModel.fromFirestore(snapshot);
  }

  // Accounts Collection
  Future<void> setAccount(AccountModel account) {
    return db.collection('Accounts').doc(account.accountId).set(account.toFirestore());
  }

  Future<AccountModel> getAccount(String accountId) async {
    final snapshot = await db.collection('Accounts').doc(accountId).get();
    return AccountModel.fromFirestore(snapshot);
  }

  Future<List<AccountModel>> getAccounts(String userId) async {
    final accountsSnapshot = await db.collection('Accounts').where('userId', isEqualTo: userId).get();
    return accountsSnapshot.docs.map((doc) => AccountModel.fromFirestore(doc)).toList();
  }

  // Transactions Collection
  Future<String> setTransaction(TransactionModel transaction) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('No user is currently signed in.');
    }

    try {
      await db.collection('Transactions').doc(transaction.transactionId).set(transaction.toFirestore());

      // Update the account balance according to the currency
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
          // Handle transfer case
          final destinationAccount =
              await getAccount(transaction.transactionName); // Transfer's transactionName stores destination account ID
          double destinationNewBalance = destinationAccount.balances[transaction.currency] ?? 0.0;
          newBalance -= transaction.amount;
          destinationNewBalance += transaction.amount;
          destinationAccount.balances[transaction.currency] = destinationNewBalance;
          await db
              .collection('Accounts')
              .doc(transaction.transactionName)
              .update({'balances': destinationAccount.balances});
          break;
        case TransactionType.adjustment:
          newBalance += transaction.amount;
      }

      // Update the balances map
      transactionAccount.balances[transaction.currency] = newBalance;
      await db.collection('Accounts').doc(transaction.accountId).update({'balances': transactionAccount.balances});
      return "Transaction added successfully!";
    } catch (e) {
      return "Failed to add transaction: $e";
    }
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
          await db
              .collection('Accounts')
              .doc(oldTransaction.transactionName)
              .update({'balances': destinationAccount.balances});
          break;
        case TransactionType.adjustment:
          oldBalance -= oldTransaction.amount;
          break;
      }
      oldAccount.balances[oldTransaction.currency] = oldBalance;
      await db.collection('Accounts').doc(oldTransaction.accountId).update({'balances': oldAccount.balances});

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
          await db
              .collection('Accounts')
              .doc(transaction.transactionName)
              .update({'balances': destinationAccount.balances});
          break;
        case TransactionType.adjustment:
          balance -= transaction.amount;
          break;
      }
      account.balances[transaction.currency] = balance;
      await db.collection('Accounts').doc(transaction.accountId).update({'balances': account.balances});

      // Delete the transaction from Firestore
      await db.collection('Transactions').doc(transaction.transactionId).delete();
      return "Transaction deleted successfully!";
    } catch (e) {
      return "Failed to delete transaction: $e";
    }
  }

  Future<TransactionModel> getTransaction(String transactionId) async {
    final snapshot = await db.collection('Transactions').doc(transactionId).get();
    return TransactionModel.fromFirestore(snapshot);
  }

  // Tag Collection
  Future<void> setTag(TagModel tag) {
    return db.collection('Tags').doc(tag.tagId).set(tag.toFirestore());
  }

  Future<List<TagModel>> getTags(String userId) async {
    final tagsSnapshot = await db.collection('Tags').where('userId', isEqualTo: userId).get();
    return tagsSnapshot.docs.map((doc) => TagModel.fromFirestore(doc)).toList();
  }
}
