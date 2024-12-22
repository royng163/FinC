import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  DateTimeRange? selectedDateRange;

  final List<Account> accounts = [
    Account(name: 'Checking', balance: 5000, income: 3000, expense: 2000),
    Account(name: 'Savings', balance: 10000, income: 5000, expense: 0),
    Account(name: 'Investment', balance: 15000, income: 7000, expense: 3000),
  ];

  final List<Transaction> transactions = [
    Transaction(
        title: 'Salary',
        amount: 3000,
        date: DateTime.now().subtract(const Duration(days: 1))),
    Transaction(
        title: 'Groceries',
        amount: -150,
        date: DateTime.now().subtract(const Duration(days: 2))),
    // Add more transactions here
  ];

  final CarouselController controller = CarouselController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
        // Filter transactions based on selectedDateRange
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: CarouselView.weighted(
              controller: controller,
              itemSnapping: true,
              flexWeights: const [1, 8, 1],
              children: accounts.map((Account account) {
                return Card.filled(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  margin: const EdgeInsets.all(8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Total Balance',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${account.balance}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Income',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('${account.income}'),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'Expense',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('${account.expense}'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDateRange == null
                    ? 'Select Date Range'
                    : '${DateFormat.yMd().format(selectedDateRange!.start)} - ${DateFormat.yMd().format(selectedDateRange!.end)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: _pickDateRange,
                child: const Text('Pick Date'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                return ListTile(
                  leading: Icon(
                    txn.amount >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    color: txn.amount >= 0 ? Colors.green : Colors.red,
                  ),
                  title: Text(txn.title),
                  subtitle: Text(DateFormat.yMMMd().format(txn.date)),
                  trailing: Text('\$${txn.amount}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Account {
  final String name;
  final double balance;
  final double income;
  final double expense;

  Account({
    required this.name,
    required this.balance,
    required this.income,
    required this.expense,
  });
}

class Transaction {
  final String title;
  final double amount;
  final DateTime date;

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
  });
}
