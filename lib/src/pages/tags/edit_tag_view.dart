import 'package:finc/src/helpers/authentication_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import '../../models/tag_model.dart';
import '../../helpers/firestore_service.dart';

class EditTagView extends StatefulWidget {
  final TagModel tag;

  const EditTagView({super.key, required this.tag});

  @override
  EditTagViewState createState() => EditTagViewState();
}

class EditTagViewState extends State<EditTagView> {
  final FirestoreService firestoreService = FirestoreService();
  final AuthenticationService authService = AuthenticationService();
  final TextEditingController tagNameController = TextEditingController();
  late User user;
  late Color selectedColor;
  late IconPickerIcon? selectedIcon;
  late TagType selectedTagType;

  @override
  void initState() {
    super.initState();
    user = authService.getCurrentUser();
    tagNameController.text = widget.tag.tagName;
    selectedColor = Color(widget.tag.color);
    selectedIcon = deserializeIcon(widget.tag.icon);
    selectedTagType = widget.tag.tagType;
  }

  @override
  void dispose() {
    tagNameController.dispose();
    super.dispose();
  }

  Future<void> editTag() async {
    try {
      final TagModel updatedTag = TagModel(
        tagId: widget.tag.tagId,
        userId: user.uid,
        tagName: tagNameController.text,
        tagType: selectedTagType,
        icon: serializeIcon(selectedIcon!) ?? {},
        color: selectedColor.value,
      );

      await firestoreService.setTag(updatedTag);

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
                  onPressed: editTag,
                  child: const Text("Update Tag"),
                ),
              ],
            ),
          ),
        ));
  }
}
