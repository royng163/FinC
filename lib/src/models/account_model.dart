import 'package:cloud_firestore/cloud_firestore.dart';

enum AccountType { bank, securities }

class AccountModel {
  final String accountId;
  final String userId;
  final AccountType accountType;
  final String accountName;
  final double balance;
  final String currency;
  final int icon;
  final int color;
  final Timestamp createdAt;

  AccountModel({
    required this.accountId,
    required this.userId,
    required this.accountType,
    required this.accountName,
    required this.balance,
    required this.currency,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  factory AccountModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccountModel(
      accountId: doc.id,
      userId: data['userId'],
      accountType: AccountType.values[data['accountType']],
      accountName: data['accountName'],
      balance: data['balance'],
      currency: data['currency'],
      icon: data['icon'],
      color: data['color'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'accountType': accountType.index,
      'accountName': accountName,
      'balance': balance,
      'currency': currency,
      'icon': icon,
      'color': color,
      'createdAt': createdAt,
    };
  }
}
