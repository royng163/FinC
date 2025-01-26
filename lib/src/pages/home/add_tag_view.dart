import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import '../../models/tag_model.dart';
import '../../helpers/firestore_service.dart';

class AddTagView extends StatefulWidget {
  const AddTagView({super.key});

  @override
  AddTagViewState createState() => AddTagViewState();
}

class AddTagViewState extends State<AddTagView> {
  final TextEditingController tagNameController = TextEditingController();
  Color selectedColor = Colors.grey;
  IconPickerIcon? selectedIcon;
  TagType selectedTagType = TagType.categories;

  late FirestoreService firestore;

  @override
  void initState() {
    super.initState();
    firestore = FirestoreService();
  }

  @override
  void dispose() {
    tagNameController.dispose();
    super.dispose();
  }

  void addCategory() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      final String userId = user.uid;
      final String categoryId = firestore.db.collection('Categories').doc().id;

      final TagModel category = TagModel(
        tagId: categoryId,
        userId: userId,
        tagName: tagNameController.text,
        tagType: selectedTagType,
        icon: serializeIcon(selectedIcon!) ?? {},
        color: selectedColor.value,
      );

      await firestore.setTag(category);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category Added Successfully')),
      );

      // Clear the form
      tagNameController.clear();
      setState(() {
        selectedTagType = TagType.categories;
        selectedColor = Colors.grey;
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
              color: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
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
    selectedIcon = await showIconPicker(
      context,
      configuration: SinglePickerConfiguration(
        iconPackModes: [IconPack.fontAwesomeIcons],
      ),
    );
    if (selectedIcon != null) {
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
                      selected: selectedTagType == TagType.categories,
                      onSelected: (selected) {
                        setState(() {
                          selectedTagType = TagType.categories;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Method'),
                      selected: selectedTagType == TagType.methods,
                      onSelected: (selected) {
                        setState(() {
                          selectedTagType = TagType.methods;
                        });
                      },
                    ),
                  ],
                ),
                TextFormField(
                  controller: tagNameController,
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
                      color: selectedColor,
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: pickIcon,
                      child: const Text('Pick Icon'),
                    ),
                    if (selectedIcon != null) Icon(selectedIcon!.data, color: selectedColor),
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
