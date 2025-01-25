import 'package:cloud_firestore/cloud_firestore.dart';

enum TagType { categories, methods }

class TagModel {
  final String tagId;
  final String userId;
  final String tagName;
  final TagType tagType;
  final Map<String, dynamic> icon;
  final int color;

  TagModel({
    required this.tagId,
    required this.userId,
    required this.tagName,
    required this.tagType,
    required this.icon,
    required this.color,
  });

  factory TagModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return TagModel(
      tagId: snapshot.id,
      userId: data['userId'],
      tagName: data['tagName'],
      tagType: TagType.values[data['tagType']],
      icon: Map<String, dynamic>.from(data['icon']),
      color: data['color'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'tagName': tagName,
      'tagType': tagType.index,
      'icon': icon,
      'color': color,
    };
  }
}
