import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String transactionId;
  final String userId;
  final String accountId;
  final String categoryId;
  final String transactionName;
  final double amount;
  final String currency;
  final String description;
  final String transactionType;
  final Timestamp transactionTime;

  TransactionModel({
    required this.transactionId,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.transactionName,
    required this.amount,
    required this.currency,
    required this.description,
    required this.transactionType,
    required this.transactionTime,
  });

  factory TransactionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      transactionId: doc.id,
      userId: data['userId'],
      accountId: data['accountId'],
      categoryId: data['categoryId'],
      transactionName: data['transactionName'],
      amount: data['amount'],
      currency: data['currency'],
      description: data['description'],
      transactionType: data['transactionType'],
      transactionTime: data['transactionTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'accountId': accountId,
      'categoryId': categoryId,
      'transactionName': transactionName,
      'amount': amount,
      'currency': currency,
      'description': description,
      'transactionType': transactionType,
      'transactionTime': transactionTime,
    };
  }
}
