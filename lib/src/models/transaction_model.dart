import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  expense,
  @HiveField(1)
  income,
  @HiveField(2)
  transfer,
  @HiveField(3)
  adjustment
}

@HiveType(typeId: 3)
class TransactionModel {
  @HiveField(0)
  final String transactionId;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String accountId;
  @HiveField(3)
  final List<String> tags;
  @HiveField(4)
  final String transactionName;
  @HiveField(5)
  final double amount;
  @HiveField(6)
  final String currency;
  @HiveField(7)
  final String description;
  @HiveField(8)
  final TransactionType transactionType;
  @HiveField(9)
  final Timestamp transactionTime;

  TransactionModel({
    required this.transactionId,
    required this.userId,
    required this.accountId,
    required this.tags,
    required this.transactionName,
    required this.amount,
    required this.currency,
    required this.description,
    required this.transactionType,
    required this.transactionTime,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return TransactionModel(
      transactionId: snapshot.id,
      userId: data['userId'],
      accountId: data['accountId'],
      tags: List<String>.from(data['tags']),
      transactionName: data['transactionName'],
      amount: data['amount'],
      currency: data['currency'],
      description: data['description'],
      transactionType: TransactionType.values[data['transactionType']],
      transactionTime: data['transactionTime'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'accountId': accountId,
      'tags': tags,
      'transactionName': transactionName,
      'amount': amount,
      'currency': currency,
      'description': description,
      'transactionType': transactionType.index,
      'transactionTime': transactionTime,
    };
  }

  TransactionModel copyWith({
    String? transactionId,
    String? userId,
    String? accountId,
    List<String>? tags,
    String? transactionName,
    double? amount,
    String? currency,
    String? description,
    TransactionType? transactionType,
    Timestamp? transactionTime,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      tags: tags ?? this.tags,
      transactionName: transactionName ?? this.transactionName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      transactionType: transactionType ?? this.transactionType,
      transactionTime: transactionTime ?? this.transactionTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.transactionId == transactionId &&
        other.userId == userId &&
        other.accountId == accountId &&
        listEquals(other.tags, tags) &&
        other.transactionName == transactionName &&
        other.amount == amount &&
        other.currency == currency &&
        other.description == description &&
        other.transactionType == transactionType &&
        other.transactionTime == transactionTime;
  }

  @override
  int get hashCode => Object.hash(
        transactionId,
        userId,
        accountId,
        Object.hashAll(tags),
        transactionName,
        amount,
        currency,
        description,
        transactionType,
        transactionTime,
      );
}
