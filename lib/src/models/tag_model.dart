import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'tag_model.g.dart';

@HiveType(typeId: 4)
enum TagType {
  @HiveField(0)
  categories,
  @HiveField(1)
  methods
}

@HiveType(typeId: 5)
class TagModel {
  @HiveField(0)
  final String tagId;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String tagName;
  @HiveField(3)
  final TagType tagType;
  @HiveField(4)
  final Map<String, dynamic> icon;
  @HiveField(5)
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagModel &&
        other.tagId == tagId &&
        other.userId == userId &&
        other.tagName == tagName &&
        other.tagType == tagType &&
        mapEquals(other.icon, icon) &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(
        tagId,
        userId,
        tagName,
        tagType,
        Object.hashAll(icon.entries),
        color,
      );
}
