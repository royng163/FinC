import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:finc/src/models/transaction_model.dart';
import 'package:finc/src/models/user_model.dart';
import 'authentication_service.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final userId = AuthenticationService().getCurrentUser().uid;

  // Users Collection
  Future<void> setUser(UserModel user) {
    return firestore.collection('Users').doc(user.userId).set(user.toFirestore());
  }

  Future<UserModel> getUser() async {
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

  Future<List<AccountModel>> getAccounts() async {
    final accountsSnapshot = await firestore.collection('Accounts').where('userId', isEqualTo: userId).get();
    return accountsSnapshot.docs.map((doc) => AccountModel.fromFirestore(doc)).toList();
  }

  Future<void> deleteAccount(String accountId) async {
    return firestore.collection('Accounts').doc(accountId).delete();
  }

  // Transactions Collection
  Future<void> setTransaction(TransactionModel transaction) async {
    return firestore.collection('Transactions').doc(transaction.transactionId).set(transaction.toFirestore());
  }

  Future<void> deleteTransaction(String transactionId) async {
    return firestore.collection('Transactions').doc(transactionId).delete();
  }

  Future<TransactionModel> getTransaction(String transactionId) async {
    final snapshot = await firestore.collection('Transactions').doc(transactionId).get();
    return TransactionModel.fromFirestore(snapshot);
  }

  Future<List<TransactionModel>> getTransactions() async {
    final transactionsSnapshot = await firestore
        .collection('Transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('transactionTime', descending: true)
        .get();
    return transactionsSnapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
  }

  // Tag Collection
  Future<void> setTag(TagModel tag) {
    return firestore.collection('Tags').doc(tag.tagId).set(tag.toFirestore());
  }

  Future<List<TagModel>> getTags() async {
    final tagsSnapshot = await firestore.collection('Tags').where('userId', isEqualTo: userId).get();
    return tagsSnapshot.docs.map((doc) => TagModel.fromFirestore(doc)).toList();
  }
}
