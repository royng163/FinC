import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { expense, income, transfer, adjustment }

class TransactionModel {
  final String transactionId;
  final String userId;
  final String accountId;
  final List<String> tags;
  final String transactionName;
  final double amount;
  final String currency;
  final String description;
  final TransactionType transactionType;
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
}
