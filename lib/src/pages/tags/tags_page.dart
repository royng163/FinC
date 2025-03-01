import 'package:finc/src/helpers/hive_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
      final fetchedTags = _hiveService.getTags();

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
      body: AnimatedBuilder(
        animation: Hive.box<TagModel>('tags').listenable(),
        builder: (context, _) {
          // Check if tags have changed
          final currentTags = _hiveService.getTags();
          if (_tags.length != currentTags.length || !listEquals(_tags, currentTags)) {
            _tags = currentTags;
          }

          if (_tags.isEmpty) {
            return const Center(
              child: Text('No tags found. Add some tags to get started!'),
            );
          }

          return ListView.builder(
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
          );
        },
      ),
    );
  }
}
