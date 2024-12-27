import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String categoryId;
  final String userId;
  final String categoryName;
  final String transactionType;
  final int icon;
  final int color;

  CategoryModel({
    required this.categoryId,
    required this.userId,
    required this.categoryName,
    required this.transactionType,
    required this.icon,
    required this.color,
  });

  factory CategoryModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      categoryId: doc.id,
      userId: data['userId'],
      categoryName: data['categoryName'],
      transactionType: data['transactionType'],
      icon: data['icon'],
      color: data['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'categoryName': categoryName,
      'transactionType': transactionType,
      'icon': icon,
      'color': color,
    };
  }
}
