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

    return TagModel(
      tagId: snapshot.id,
      userId: data['userId'],
      tagName: data['tagName'],
      tagType: TagType.values[data['tagType']],
      icon: iconData,
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
