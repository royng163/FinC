import 'package:cloud_firestore/cloud_firestore.dart';

class AccountModel {
  final String accountId;
  final String userId;
  final String accountName;
  final double balance;
  final Timestamp createdAt;

  AccountModel({
    required this.accountId,
    required this.userId,
    required this.accountName,
    required this.balance,
    required this.createdAt,
  });

  factory AccountModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccountModel(
      accountId: doc.id,
      userId: data['userId'],
      accountName: data['accountName'],
      balance: data['balance'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'accountName': accountName,
      'balance': balance,
      'createdAt': createdAt,
    };
  }
}
