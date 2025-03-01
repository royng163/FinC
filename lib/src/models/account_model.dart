import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'account_model.g.dart';

@HiveType(typeId: 0)
enum AccountType {
  @HiveField(0)
  bank,
  @HiveField(1)
  creditCard,
  @HiveField(2)
  securities
}

@HiveType(typeId: 1)
class AccountModel {
  @HiveField(0)
  final String accountId;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final AccountType accountType;
  @HiveField(3)
  final String accountName;
  @HiveField(4)
  final Map<String, double> balances;
  @HiveField(5)
  final Map<String, dynamic> icon;
  @HiveField(6)
  final int color;
  @HiveField(7)
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

  factory AccountModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return AccountModel(
      accountId: snapshot.id,
      userId: data['userId'],
      accountType: AccountType.values[data['accountType']],
      accountName: data['accountName'],
      balances: Map<String, double>.from(data['balances']),
      icon: Map<String, dynamic>.from(data['icon']),
      color: data['color'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountModel &&
        other.accountId == accountId &&
        other.userId == userId &&
        other.accountType == accountType &&
        other.accountName == accountName &&
        mapEquals(other.balances, balances) &&
        mapEquals(other.icon, icon) &&
        other.color == color &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        accountId,
        userId,
        accountType,
        accountName,
        Object.hashAll(balances.entries),
        Object.hashAll(icon.entries),
        color,
        createdAt,
      );
}
