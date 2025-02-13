import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/tag_model.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  FirestoreService() {
    // Enable offline persistence and set cache size to unlimited.
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Users Collection
  Future<void> setUser(UserModel user) {
    return firestore.collection('Users').doc(user.userId).set(user.toFirestore());
  }

  Future<UserModel> getUser(String userId) async {
    final snapshot = await firestore.collection('Users').doc(userId).get();
    return UserModel.fromFirestore(snapshot);
  }

  // Accounts Collection
  Future<void> setAccount(AccountModel account) {
    return firestore.collection('Accounts').doc(account.accountId).set(account.toFirestore());
  }

  Future<AccountModel> getAccount(String accountId) async {
    final snapshot = await firestore.collection('Accounts').doc(accountId).get();
    return AccountModel.fromFirestore(snapshot);
  }

  Future<List<AccountModel>> getAccounts(String userId) async {
    final accountsSnapshot = await firestore.collection('Accounts').where('userId', isEqualTo: userId).get();
    return accountsSnapshot.docs.map((doc) => AccountModel.fromFirestore(doc)).toList();
  }

  Future<String> deleteAccount(String userId, String accountId, String accountName) async {
    try {
      final WriteBatch batch = firestore.batch();

      // 1. Update transfer transactions where the destination is this account.
      final QuerySnapshot transferSnapshot = await firestore
          .collection('Transactions')
          .where('userId', isEqualTo: userId)
          .where('transactionType', isEqualTo: TransactionType.transfer.index)
          .where('transactionName', isEqualTo: accountId)
          .get();

      for (var doc in transferSnapshot.docs) {
        batch.update(doc.reference, {
          'transactionType': TransactionType.expense.index,
          'transactionName': 'To $accountName',
        });
      }

      // 2. Delete all transactions where the account is the source.
      final QuerySnapshot sourceSnapshot = await firestore
          .collection('Transactions')
          .where('userId', isEqualTo: userId)
          .where('accountId', isEqualTo: accountId)
          .get();

      for (var doc in sourceSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3. Delete the account document.
      final DocumentReference accountRef = firestore.collection('Accounts').doc(accountId);
      batch.delete(accountRef);

      // Commit the batch.
      await batch.commit();

      return "Account deletion updates applied successfully!";
    } catch (e) {
      return "Failed to delete account transactions: $e";
    }
  }

  // Transactions Collection
  Future<String> setTransaction(TransactionModel transaction) async {
    try {
      await firestore.collection('Transactions').doc(transaction.transactionId).set(transaction.toFirestore());

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
          await firestore
              .collection('Accounts')
              .doc(transaction.transactionName)
              .update({'balances': destinationAccount.balances});
          break;
        case TransactionType.adjustment:
          newBalance += transaction.amount;
      }

      // Update the balances map
      transactionAccount.balances[transaction.currency] = newBalance;
      await firestore
          .collection('Accounts')
          .doc(transaction.accountId)
          .update({'balances': transactionAccount.balances});
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
          await firestore
              .collection('Accounts')
              .doc(oldTransaction.transactionName)
              .update({'balances': destinationAccount.balances});
          break;
        case TransactionType.adjustment:
          oldBalance -= oldTransaction.amount;
          break;
      }
      oldAccount.balances[oldTransaction.currency] = oldBalance;
      await firestore.collection('Accounts').doc(oldTransaction.accountId).update({'balances': oldAccount.balances});

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
          await firestore
              .collection('Accounts')
              .doc(transaction.transactionName)
              .update({'balances': destinationAccount.balances});
          break;
        case TransactionType.adjustment:
          balance -= transaction.amount;
          break;
      }
      account.balances[transaction.currency] = balance;
      await firestore.collection('Accounts').doc(transaction.accountId).update({'balances': account.balances});

      // Delete the transaction from Firestore
      await firestore.collection('Transactions').doc(transaction.transactionId).delete();
      return "Transaction deleted successfully!";
    } catch (e) {
      return "Failed to delete transaction: $e";
    }
  }

  Future<TransactionModel> getTransaction(String transactionId) async {
    final snapshot = await firestore.collection('Transactions').doc(transactionId).get();
    return TransactionModel.fromFirestore(snapshot);
  }

  Future<List<TransactionModel>> getMonthlyTransactions(String userId, DateTime thisMonth) async {
    final transactionsSnapshot = await firestore
        .collection('Transactions')
        .where('userId', isEqualTo: userId)
        .where('transactionTime', isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonth))
        .get();
    return transactionsSnapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
  }

  Future<List<TransactionModel>> getAccountTransactions(String userId, String accountId) async {
    // Query for transactions where accountId is the source.
    final QuerySnapshot sourceSnapshot = await firestore
        .collection('Transactions')
        .where('userId', isEqualTo: userId)
        .where('accountId', isEqualTo: accountId)
        .get();

    // Query for transfer transactions where the destination is this account.
    final QuerySnapshot transferSnapshot = await firestore
        .collection('Transactions')
        .where('userId', isEqualTo: userId)
        .where('transactionType', isEqualTo: TransactionType.transfer.index)
        .where('transactionName', isEqualTo: accountId)
        .get();

    final List<TransactionModel> allTransactions = [
      ...sourceSnapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)),
      ...transferSnapshot.docs.map((doc) => TransactionModel.fromFirestore(doc))
    ];

    // Sort the combined list by transactionTime descending.
    allTransactions.sort((a, b) => b.transactionTime.compareTo(a.transactionTime));
    return allTransactions;
  }

  // Tag Collection
  Future<void> setTag(TagModel tag) {
    return firestore.collection('Tags').doc(tag.tagId).set(tag.toFirestore());
  }

  Future<List<TagModel>> getTags(String userId) async {
    final tagsSnapshot = await firestore.collection('Tags').where('userId', isEqualTo: userId).get();
    return tagsSnapshot.docs.map((doc) => TagModel.fromFirestore(doc)).toList();
  }
}
