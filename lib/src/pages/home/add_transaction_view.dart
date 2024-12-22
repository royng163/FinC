import 'package:flutter/material.dart';

class AddTransactionView extends StatefulWidget {
  const AddTransactionView({super.key});

  @override
  AddTransactionViewState createState() => AddTransactionViewState();
}

class AddTransactionViewState extends State<AddTransactionView> {
  int selectedType = 0;
  final List<String> type = [
    "Expense",
    "Income",
    "Investment",
    "Transfer",
    "Adjustment"
  ];

  String selectedAccount = "";
  final List<String> accounts = ["Cash", "Alipay", "HSBC", "MMP Card"];

  String selectedCategory = "";
  final List<String> categories = [
    "Food",
    "Transport",
    "Entertainment",
    "Shopping",
    "Health",
  ];

  final TextEditingController dateTimeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('New Transaction'),
        ),
        body: Form(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 8,
              children: [
                Row(
                  children: [
                    Text("Transaction Type"),
                  ],
                ),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return Row(
                      spacing: 8,
                      children: type
                          .map((t) => ChoiceChip(
                                label: Text(t),
                                selected: selectedType == type.indexOf(t),
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedType =
                                        selected ? type.indexOf(t) : -1;
                                  });
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
                Row(
                  children: [
                    Text("Account"),
                  ],
                ),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return Row(
                      spacing: 8,
                      children: accounts
                          .map((a) => ChoiceChip(
                                label: Text(a),
                                selected: selectedAccount == a,
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedAccount = selected ? a : "";
                                  });
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
                Row(
                  children: [
                    Text("Category"),
                  ],
                ),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return Row(
                      spacing: 8,
                      children: categories
                          .map((c) => ChoiceChip(
                                label: Text(c),
                                selected: selectedCategory == c,
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedCategory = selected ? c : "";
                                  });
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
                Row(
                  children: [
                    Text("Details"),
                  ],
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      hintText: "Transaction Name",
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.text,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      hintText: "Amount", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      hintText: "Description", border: OutlineInputBorder()),
                  keyboardType: TextInputType.text,
                ),
                Row(
                  children: [
                    Text("Date & Time"),
                  ],
                ),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      spacing: 8,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(
                              text: "${DateTime.now().toLocal()}".split(' ')[0],
                            ),
                            decoration: const InputDecoration(
                                hintText: "Select Date",
                                border: OutlineInputBorder()),
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );

                              if (pickedDate != null) {
                                setState(() {
                                  dateTimeController.text =
                                      "${pickedDate.toLocal()}".split(' ')[0];
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(
                                text: TimeOfDay.now().format(context)),
                            decoration: const InputDecoration(
                                hintText: "Select Time",
                                border: OutlineInputBorder()),
                            readOnly: true,
                            onTap: () async {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );

                              if (pickedTime != null) {
                                setState(() {
                                  dateTimeController.text =
                                      "${dateTimeController.text} ${pickedTime.format(context)}";
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save the transaction
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
          ),
        ));
  }
}
