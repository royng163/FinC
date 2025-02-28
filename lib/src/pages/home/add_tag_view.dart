import 'package:finc/src/helpers/authentication_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import '../../helpers/hive_service.dart';
import '../../models/tag_model.dart';
import '../../helpers/firestore_service.dart';

class AddTagView extends StatefulWidget {
  const AddTagView({super.key});

  @override
  AddTagViewState createState() => AddTagViewState();
}

class AddTagViewState extends State<AddTagView> {
  final FirestoreService _firestoreService = FirestoreService();
  final HiveService _hiveService = HiveService();
  final AuthenticationService _authService = AuthenticationService();
  final TextEditingController _tagNameController = TextEditingController();
  late User _user;
  Color _selectedColor = Colors.grey;
  IconPickerIcon? _selectedIcon;
  TagType _selectedTagType = TagType.categories;

  @override
  void initState() {
    super.initState();
    _user = _authService.getCurrentUser();
  }

  @override
  void dispose() {
    _tagNameController.dispose();
    super.dispose();
  }

  void addCategory() async {
    try {
      final TagModel category = TagModel(
        tagId: _firestoreService.firestore.collection('Categories').doc().id,
        userId: _user.uid,
        tagName: _tagNameController.text,
        tagType: _selectedTagType,
        icon: serializeIcon(_selectedIcon!) ?? {},
        // ignore: deprecated_member_use
        color: _selectedColor.value,
      );

      await _hiveService.setTag(category);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category Added Successfully')),
      );

      // Clear the form
      _tagNameController.clear();
      setState(() {
        _selectedTagType = TagType.categories;
        _selectedColor = Colors.grey;
      });

      Navigator.pop(context, true);
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add category: $e')),
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
          title: const Text('New Tag'),
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
                      return 'Please enter a category name';
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
                  onPressed: addCategory,
                  child: const Text("Add Category"),
                ),
              ],
            ),
          ),
        ));
  }
}
