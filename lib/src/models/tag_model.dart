import 'package:cloud_firestore/cloud_firestore.dart';

enum TagType { categories, methods }

class TagModel {
  final String tagId;
  final String userId;
  final String tagName;
  final TagType tagType;
  final int icon;
  final int color;

  TagModel({
    required this.tagId,
    required this.userId,
    required this.tagName,
    required this.tagType,
    required this.icon,
    required this.color,
  });

  factory TagModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TagModel(
      tagId: doc.id,
      userId: data['userId'],
      tagName: data['tagName'],
      tagType: TagType.values[data['tagType']],
      icon: data['icon'],
      color: data['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tagName': tagName,
      'tagType': tagType.index,
      'icon': icon,
      'color': color,
    };
  }
}
