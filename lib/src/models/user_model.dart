import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String? email;

  UserModel({
    required this.userId,
    this.email,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    return UserModel(
      userId: doc.id,
      email: data?['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
    };
  }
}
