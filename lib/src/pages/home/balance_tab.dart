import 'package:flutter/material.dart';

import '../../widgets/transaction.dart';
import 'transaction_details_view.dart';

class BalanceTab extends StatelessWidget {
  const BalanceTab({
    super.key,
    this.transactions = const [
      Transaction(1, "Lunch", "Alipay", -24.9, "HKD"),
      Transaction(
        2,
        "Dinner",
        "Gold Card",
        -233.54,
        "HKD",
      ),
      Transaction(3, "Hotel", "MMP Card", -2300.75, "JPY"),
      Transaction(4, "TSFS", "HSBC", 5600, "HKD"),
    ],
  });

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card.filled(
          margin: const EdgeInsets.all(8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${transactions.map((t) => t.amount).reduce((a, b) => a + b).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24),
                    ),
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
                        Text(
                          '${transactions.where((t) => t.amount > 0).map((t) => t.amount).reduce((a, b) => a + b).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Expense',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${transactions.where((t) => t.amount < 0).map((t) => t.amount).reduce((a, b) => a + b).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Row(
          children: [
            Text("Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                leading: const Icon(Icons.money),
                title: Text(transactions[index].name),
                subtitle: Text(transactions[index].account),
                trailing: Text(
                    '${transactions[index].amount} ${transactions[index].currency}',
                    style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TransactionDetailsView()));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
