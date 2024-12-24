import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String categoryId;
  final String userId;
  final String categoryName;

  CategoryModel({
    required this.categoryId,
    required this.userId,
    required this.categoryName,
  });

  factory CategoryModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      categoryId: doc.id,
      userId: data['userId'],
      categoryName: data['categoryName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'categoryName': categoryName,
    };
  }
}
