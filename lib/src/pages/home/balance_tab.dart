import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_converter_pro/currency_converter_pro.dart';
import 'package:finc/src/helpers/balance_service.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/settings_controller.dart';
import '../../models/transaction_model.dart';
import 'edit_transaction_view.dart';

class BalanceTab extends StatefulWidget {
  final SettingsController settingsController;

  const BalanceTab({super.key, required this.settingsController});

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
  late BalanceService balanceService;

  @override
  void initState() {
    super.initState();
    balanceService = BalanceService();
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
      double balance = await balanceService
          .getTotalBalance(widget.settingsController.baseCurrency);

      setState(() {
        totalBalance = balance;
      });
    } catch (e) {
      if (!mounted) return;
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

      for (var doc in transactionsSnapshot.docs) {
        final transaction = TransactionModel.fromDocument(doc);
        final transactionDate = transaction.transactionTime.toDate();

        if (transactionDate.isAfter(currentMonth)) {
          if (transaction.transactionType == TransactionType.income) {
            income += transaction.amount;
          } else if (transaction.transactionType == TransactionType.expense) {
            expense += transaction.amount;
          }
        }
      }

      setState(() {
        totalIncome = income;
        totalExpense = expense;
      });
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
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
      for (var doc in tagsSnapshot.docs) {
        final tag = TagModel.fromDocument(doc);
        fetchedTags[tag.tagId] = tag;
      }

      setState(() {
        tags = fetchedTags;
      });
    } catch (e) {
      if (!mounted) return;
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
        Card(
          color: Theme.of(context).cardColor,
          surfaceTintColor: Theme.of(context).primaryColor,
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
                          style: const TextStyle(fontSize: 20),
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
                          style: const TextStyle(fontSize: 20),
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
                context.push('/add-account');
              },
              child: const Text('Add Account'),
            ),
            ElevatedButton(
              onPressed: () {
                context.push('/add-tag');
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
                title: Text(transaction.transactionName,
                    style: TextStyle(fontSize: 16)),
                subtitle: Wrap(
                  children: transactionTags
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3.0, vertical: 1.0),
                            margin: const EdgeInsets.only(top: 4.0, right: 4.0),
                            decoration: BoxDecoration(
                              color: Color(tag!.color).withAlpha(100),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  IconData(tag.icon,
                                      fontFamily: 'MaterialIcons'),
                                  size: 14,
                                  color: Color(tag.color),
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  tag.tagName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
                trailing: Text(
                  '${transaction.amount} ${transaction.currency}',
                  style: const TextStyle(fontSize: 18),
                ),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTransactionView(
                        transaction: transaction,
                      ),
                    ),
                  );
                  if (result == true) {
                    fetchTotalBalance();
                    fetchMonthlyTransactions();
                    fetchTransactions();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
