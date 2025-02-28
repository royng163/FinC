import 'package:finc/src/helpers/authentication_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import '../../helpers/hive_service.dart';
import '../../models/tag_model.dart';

class EditTagView extends StatefulWidget {
  final TagModel tag;

  const EditTagView({super.key, required this.tag});

  @override
  EditTagViewState createState() => EditTagViewState();
}

class EditTagViewState extends State<EditTagView> {
  final HiveService _hiveService = HiveService();
  final AuthenticationService _authService = AuthenticationService();
  final TextEditingController _tagNameController = TextEditingController();
  late User _user;
  late Color _selectedColor;
  late IconPickerIcon? _selectedIcon;
  late TagType _selectedTagType;

  @override
  void initState() {
    super.initState();
    _user = _authService.getCurrentUser();
    _tagNameController.text = widget.tag.tagName;
    _selectedColor = Color(widget.tag.color);
    _selectedIcon = deserializeIcon(widget.tag.icon);
    _selectedTagType = widget.tag.tagType;
  }

  @override
  void dispose() {
    _tagNameController.dispose();
    super.dispose();
  }

  Future<void> editTag() async {
    try {
      final TagModel updatedTag = TagModel(
        tagId: widget.tag.tagId,
        userId: _user.uid,
        tagName: _tagNameController.text,
        tagType: _selectedTagType,
        icon: serializeIcon(_selectedIcon!) ?? {},
        // ignore: deprecated_member_use
        color: _selectedColor.value,
      );

      await _hiveService.setTag(updatedTag);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tag Updated Successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update tag: $e')),
      );
    }
  }

  void pickColor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              heading: Text(
                'Select color',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              subheading: Text(
                'Select color shade',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text('Select'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void pickIcon() async {
    _selectedIcon = await showIconPicker(
      context,
      configuration: SinglePickerConfiguration(
        iconPackModes: [IconPack.fontAwesomeIcons],
      ),
    );
    if (_selectedIcon != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Tag'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Form(
            child: Column(
              spacing: 8,
              children: [
                Wrap(
                  spacing: 8.0,
                  children: [
                    ChoiceChip(
                      label: const Text('Category'),
                      selected: _selectedTagType == TagType.categories,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTagType = TagType.categories;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Method'),
                      selected: _selectedTagType == TagType.methods,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTagType = TagType.methods;
                        });
                      },
                    ),
                  ],
                ),
                TextFormField(
                  controller: _tagNameController,
                  decoration: const InputDecoration(
                      labelText: "Tag Name", hintText: "e.g. Groceries", border: OutlineInputBorder()),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a tag name';
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: pickColor,
                      child: const Text('Pick Color'),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      color: _selectedColor,
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: pickIcon,
                      child: const Text('Pick Icon'),
                    ),
                    if (_selectedIcon != null) Icon(_selectedIcon!.data, color: _selectedColor),
                  ],
                ),
                ElevatedButton(
                  onPressed: editTag,
                  child: const Text("Update Tag"),
                ),
              ],
            ),
          ),
        ));
  }
}
