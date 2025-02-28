import 'package:finc/src/helpers/hive_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:go_router/go_router.dart';
import '../../components/app_routes.dart';
import '../../models/tag_model.dart';

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  TagsPageState createState() => TagsPageState();
}

class TagsPageState extends State<TagsPage> {
  final HiveService _hiveService = HiveService();
  List<TagModel> _tags = [];

  @override
  void initState() {
    super.initState();
    _fetchTags();
  }

  Future<void> _fetchTags() async {
    try {
      final fetchedTags = await _hiveService.getTags();

      setState(() {
        _tags = fetchedTags;
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
      body: ListView.builder(
        itemCount: _tags.length,
        itemBuilder: (context, index) {
          final tag = _tags[index];
          return ListTile(
            leading: Icon(deserializeIcon(tag.icon)?.data, color: Color(tag.color)),
            title: Text(tag.tagName),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final result = await context.push(
                  AppRoutes.editTag,
                  extra: tag,
                );

                if (result == true) {
                  _fetchTags(); // Refresh the tags list after editing
                }
              },
            ),
          );
        },
      ),
    );
  }
}
