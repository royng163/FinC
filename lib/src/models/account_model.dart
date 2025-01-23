import 'package:cloud_firestore/cloud_firestore.dart';

enum AccountType { bank, creditCard, securities }

class AccountModel {
  final String accountId;
  final String userId;
  final AccountType accountType;
  final String accountName;
  final Map<String, double> balances;
  final Map<String, dynamic> icon;
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

  factory AccountModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    // Handle both old and new icon formats
    Map<String, dynamic> iconData;
    if (data['icon'] is int) {
      // Old format
      iconData = {
        'codePoint': data['icon'],
        'fontFamily': 'MaterialIcons', // Default font family for old icons
      };
    } else {
      // New format
      iconData = Map<String, dynamic>.from(data['icon']);
    }

    return AccountModel(
      accountId: snapshot.id,
      userId: data['userId'],
      accountType: AccountType.values[data['accountType']],
      accountName: data['accountName'],
      balances: Map<String, double>.from(data['balances']),
      icon: iconData,
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
}
