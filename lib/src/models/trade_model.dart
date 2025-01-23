import 'package:cloud_firestore/cloud_firestore.dart';

class TradeModel {
  final String tradeId;
  final String userId;
  final String symbol;
  final double position;
  final double value;
  final String currency;
  final Timestamp tradeTime;

  TradeModel({
    required this.tradeId,
    required this.userId,
    required this.symbol,
    required this.position,
    required this.value,
    required this.currency,
    required this.tradeTime,
  });

  factory TradeModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return TradeModel(
      tradeId: snapshot.id,
      userId: data['userId'],
      symbol: data['instructmentName'],
      position: data['quantity'],
      value: data['cost'],
      currency: data['currency'],
      tradeTime: data['tradeTime'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'instructmentName': symbol,
      'quantity': position,
      'cost': value,
      'currency': currency,
      'tradeTime': tradeTime,
    };
  }
}
