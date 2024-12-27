import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import '../../models/category_model.dart';
import '../../helpers/firestore_service.dart';

class AddCategoryView extends StatefulWidget {
  const AddCategoryView({super.key});

  @override
  AddCategoryViewState createState() => AddCategoryViewState();
}

class AddCategoryViewState extends State<AddCategoryView> {
  final TextEditingController categoryNameController = TextEditingController();
  Color selectedColor = Colors.grey;
  IconData selectedIcon = Icons.category;
  String selectedTransactionType = 'Expense';

  late FirestoreService firestore;

  @override
  void initState() {
    super.initState();
    firestore = FirestoreService();
  }

  @override
  void dispose() {
    categoryNameController.dispose();
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

      final CategoryModel category = CategoryModel(
        categoryId: categoryId,
        userId: userId,
        categoryName: categoryNameController.text,
        transactionType: selectedTransactionType,
        icon: selectedIcon.codePoint,
        color: selectedColor.value,
      );

      await firestore.createCategory(category);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category Added Successfully')),
      );

      // Clear the form
      categoryNameController.clear();
      setState(() {
        selectedTransactionType = 'Expense';
        selectedColor = Colors.grey;
        selectedIcon = Icons.category;
      });

      // Optionally, navigate back or perform other actions
      // Navigator.pop(context);
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
    IconPickerIcon? icon = await showIconPicker(
      context,
      configuration: SinglePickerConfiguration(
        iconPackModes: [IconPack.material],
      ),
    );
    if (icon != null) {
      setState(() {
        selectedIcon = icon.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('New Category'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Form(
            child: Column(
              spacing: 8,
              children: [
                TextFormField(
                  controller: categoryNameController,
                  decoration: const InputDecoration(
                      labelText: "Category Name",
                      hintText: "e.g. Groceries",
                      border: OutlineInputBorder()),
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
                    Icon(selectedIcon, color: selectedColor),
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: selectedTransactionType,
                  decoration: const InputDecoration(
                    labelText: "Transaction Type",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Income',
                      child: Text('Income'),
                    ),
                    DropdownMenuItem(
                      value: 'Expense',
                      child: Text('Expense'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedTransactionType = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a transaction type';
                    }
                    return null;
                  },
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
