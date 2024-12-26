import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BalanceTab extends StatelessWidget {
  const BalanceTab({
    super.key,
  });

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
                    // Text(
                    //   transactions
                    //       .map((t) => t.amount)
                    //       .reduce((a, b) => a + b)
                    //       .toStringAsFixed(2),
                    //   style: const TextStyle(fontSize: 24),
                    // ),
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
                        // Text(
                        //   transactions
                        //       .where((t) => t.amount > 0)
                        //       .map((t) => t.amount)
                        //       .reduce((a, b) => a + b)
                        //       .toStringAsFixed(2),
                        // ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Expense',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // Text(
                        //   transactions
                        //       .where((t) => t.amount < 0)
                        //       .map((t) => t.amount)
                        //       .reduce((a, b) => a + b)
                        //       .toStringAsFixed(2),
                        // ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () {
                context.go('/home/add-account');
              },
              child: const Text('Add Account'),
            ),
            ElevatedButton(
              onPressed: () {
                // Add your onPressed code here for adding a new category
              },
              child: const Text('Add Category'),
            ),
          ],
        ),
        const Row(
          children: [
            Text("Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        // Expanded(
        //   child: ListView.builder(
        //     itemCount: transactions.length,
        //     itemBuilder: (BuildContext context, int index) {
        //       return ListTile(
        //         leading: const Icon(Icons.money),
        //         title: Text(transactions[index].name),
        //         subtitle: Text(transactions[index].account),
        //         trailing: Text(
        //             '${transactions[index].amount} ${transactions[index].currency}',
        //             style: TextStyle(fontSize: 18)),
        //         onTap: () {
        //           Navigator.push(
        //               context,
        //               MaterialPageRoute(
        //                   builder: (context) => TransactionDetailsView()));
        //         },
        //       );
        //     },
        //   ),
        // ),
      ],
    );
  }
}
