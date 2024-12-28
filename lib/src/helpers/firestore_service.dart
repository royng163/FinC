import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/tag_model.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Users Collection
  Future<void> createUser(UserModel user) {
    return db.collection('Users').doc(user.userId).set(user.toMap());
  }

  Future<UserModel> getUser(String userId) async {
    final doc = await db.collection('Users').doc(userId).get();
    return UserModel.fromDocument(doc);
  }

  // Accounts Collection
  Future<void> createAccount(AccountModel account) {
    return db
        .collection('Accounts')
        .doc(account.accountId)
        .set(account.toMap());
  }

  Future<AccountModel> getAccount(String accountId) async {
    final doc = await db.collection('Accounts').doc(accountId).get();
    return AccountModel.fromDocument(doc);
  }

  // Transactions Collection
  Future<void> createTransaction(TransactionModel transaction) {
    return db
        .collection('Transactions')
        .doc(transaction.transactionId)
        .set(transaction.toMap());
  }

  Future<TransactionModel> getTransaction(String transactionId) async {
    final doc = await db.collection('Transactions').doc(transactionId).get();
    return TransactionModel.fromDocument(doc);
  }

  // Tag Collection
  Future<void> createTag(TagModel tag) {
    return db.collection('Tags').doc(tag.tagId).set(tag.toMap());
  }

  Future<TagModel> getTag(String tagId) async {
    final doc = await db.collection('Tags').doc(tagId).get();
    return TagModel.fromDocument(doc);
  }
}
