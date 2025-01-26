import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:go_router/go_router.dart';
import '../../components/app_routes.dart';
import '../../models/tag_model.dart';
import '../../helpers/firestore_service.dart';

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  TagsPageState createState() => TagsPageState();
}

class TagsPageState extends State<TagsPage> {
  final FirestoreService firestore = FirestoreService();
  List<TagModel> tags = [];

  @override
  void initState() {
    super.initState();
    fetchTags();
  }

  Future<void> fetchTags() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final tagsSnapshot = await firestore.db.collection('Tags').where('userId', isEqualTo: user?.uid).get();

      setState(() {
        tags = tagsSnapshot.docs.map((doc) => TagModel.fromFirestore(doc)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch tags: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tags'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('${AppRoutes.tags}${AppRoutes.addTag}');
          if (result == true) {
            fetchTags(); // Refresh the tags list after adding a new tag
          }
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          return ListTile(
            leading: Icon(deserializeIcon(tag.icon)?.data, color: Color(tag.color)),
            title: Text(tag.tagName),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final result = await context.push(
                  '${AppRoutes.tags}${AppRoutes.editTag}',
                  extra: tag,
                );

                if (result == true) {
                  fetchTags(); // Refresh the tags list after editing
                }
              },
            ),
          );
        },
      ),
    );
  }
}
