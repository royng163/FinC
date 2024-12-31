import 'package:cloud_firestore/cloud_firestore.dart';

enum AccountType { bank, creditCard, securities }

class AccountModel {
  final String accountId;
  final String userId;
  final AccountType accountType;
  final String accountName;
  final Map<String, double> balances;
  final int icon;
  final int color;
  final Timestamp createdAt;

  AccountModel({
    required this.accountId,
    required this.userId,
    required this.accountType,
    required this.accountName,
    required this.balances,
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
      balances: Map<String, double>.from(data['balances']),
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
      'balances': balances,
      'icon': icon,
      'color': color,
      'createdAt': createdAt,
    };
  }
}
