import 'package:cloud_firestore/cloud_firestore.dart';

class TradeModel {
  final String tradeId;
  final String userId;
  final String instructmentName;
  final bool isPurchase;
  final double quantity;
  final double cost;
  final String currency;
  final Timestamp tradeTime;

  TradeModel({
    required this.tradeId,
    required this.userId,
    required this.instructmentName,
    required this.isPurchase,
    required this.quantity,
    required this.cost,
    required this.currency,
    required this.tradeTime,
  });

  factory TradeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TradeModel(
      tradeId: doc.id,
      userId: data['userId'],
      instructmentName: data['instructmentName'],
      isPurchase: data['isPurchase'],
      quantity: data['quantity'],
      cost: data['cost'],
      currency: data['currency'],
      tradeTime: data['tradeTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'instructmentName': instructmentName,
      'isPurchase': isPurchase,
      'quantity': quantity,
      'cost': cost,
      'currency': currency,
      'tradeTime': tradeTime,
    };
  }
}
