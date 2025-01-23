import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String? email;

  UserModel({
    required this.userId,
    this.email,
  });

  factory UserModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;

    return UserModel(
      userId: snapshot.id,
      email: data?['email'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
    };
  }
}
