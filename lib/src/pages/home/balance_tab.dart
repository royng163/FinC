import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:finc/src/pages/home/edit_transaction_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/transaction_model.dart';

class BalanceTab extends StatefulWidget {
  const BalanceTab({super.key});

  @override
  BalanceTabState createState() => BalanceTabState();
}

class BalanceTabState extends State<BalanceTab> {
  double totalBalance = 0.0;
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  List<AccountModel> accounts = [];
  List<TransactionModel> transactions = [];
  Map<String, TagModel> tags = {};
  bool isLoading = false;
  bool hasMore = true;
  DocumentSnapshot? lastDocument;
  final int pageSize = 10;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchTotalBalance();
    fetchMonthlyTransactions();
    fetchTransactions();
    fetchTags();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        fetchTransactions();
      }
    });
  }

  Future<void> fetchTotalBalance() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final accountsSnapshot = await FirebaseFirestore.instance
          .collection('Accounts')
          .where('userId', isEqualTo: user?.uid)
          .get();

      double balance = 0.0;
      List<AccountModel> fetchedAccounts = accountsSnapshot.docs.map((doc) {
        final account = AccountModel.fromDocument(doc);
        balance += account.balance;
        return account;
      }).toList();

      setState(() {
        totalBalance = balance;
        accounts = fetchedAccounts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch total balance: $e')),
      );
    }
  }

  Future<void> fetchMonthlyTransactions() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('Transactions')
          .where('userId', isEqualTo: user?.uid)
          .get();

      double income = 0.0;
      double expense = 0.0;
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);

      transactionsSnapshot.docs.forEach((doc) {
        final transaction = TransactionModel.fromDocument(doc);
        final transactionDate = transaction.transactionTime.toDate();

        if (transactionDate.isAfter(currentMonth)) {
          if (transaction.amount > 0) {
            income += transaction.amount;
          } else {
            expense += transaction.amount;
          }
        }
      });

      setState(() {
        totalIncome = income;
        totalExpense = expense;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch transactions: $e')),
      );
    }
  }

  Future<void> fetchTransactions() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      Query query = FirebaseFirestore.instance
          .collection('Transactions')
          .where('userId', isEqualTo: user?.uid)
          .orderBy('transactionTime', descending: true)
          .limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final transactionsSnapshot = await query.get();

      if (transactionsSnapshot.docs.isEmpty) {
        setState(() {
          hasMore = false;
        });
      } else {
        lastDocument = transactionsSnapshot.docs.last;
        List<TransactionModel> fetchedTransactions =
            transactionsSnapshot.docs.map((doc) {
          return TransactionModel.fromDocument(doc);
        }).toList();

        setState(() {
          transactions.addAll(fetchedTransactions);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch transactions: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTags() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final tagsSnapshot = await FirebaseFirestore.instance
          .collection('Tags')
          .where('userId', isEqualTo: user?.uid)
          .get();

      Map<String, TagModel> fetchedTags = {};
      tagsSnapshot.docs.forEach((doc) {
        final tag = TagModel.fromDocument(doc);
        fetchedTags[tag.tagId] = tag;
      });

      setState(() {
        tags = fetchedTags;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch tags: $e')),
      );
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

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
                      totalBalance.toStringAsFixed(2),
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
                          totalIncome.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 18),
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
                          totalExpense.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 18),
                        ),
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
                context.go('/home/add-tag');
              },
              child: const Text('Add Tag'),
            ),
          ],
        ),
        const Row(
          children: [
            Text("Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: transactions.length + (hasMore ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              if (index == transactions.length) {
                return isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.shrink();
              }
              final transaction = transactions[index];
              final transactionTags = transaction.tags
                  .map((tagId) => tags[tagId])
                  .where((tag) => tag != null)
                  .toList();
              return ListTile(
                title: Text(transaction.transactionName),
                subtitle: Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: transactionTags
                      .map((tag) => Chip(
                            label: Text(tag!.tagName),
                            avatar: Icon(
                              IconData(tag.icon, fontFamily: 'MaterialIcons'),
                              size: 16,
                              color: Color(tag.color),
                            ),
                            backgroundColor: Color(tag.color).withOpacity(0.2),
                          ))
                      .toList(),
                ),
                trailing: Text(
                  '${transaction.amount} ${transaction.currency}',
                  style: const TextStyle(fontSize: 18),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditTransactionView(transaction: transaction),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
