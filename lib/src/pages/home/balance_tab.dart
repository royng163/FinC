import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finc/src/helpers/authentication_service.dart';
import 'package:finc/src/helpers/balance_service.dart';
import 'package:finc/src/helpers/hive_service.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../components/app_routes.dart';
import '../../helpers/settings_service.dart';
import '../../models/transaction_model.dart';

class BalanceTab extends StatefulWidget {
  final SettingsService settingsService;
  final Function(BalanceTabState) registerState;

  const BalanceTab({super.key, required this.settingsService, required this.registerState});

  @override
  BalanceTabState createState() => BalanceTabState();
}

class BalanceTabState extends State<BalanceTab> {
  final BalanceService balanceService = BalanceService();
  final HiveService _hiveService = HiveService();
  final AuthenticationService authService = AuthenticationService();
  final ScrollController scrollController = ScrollController();
  final int pageSize = 10;
  late User user;
  double totalBalance = 0.0;
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  List<AccountModel> accounts = [];
  List<TransactionModel> transactions = [];
  Map<String, TagModel> tags = {};
  bool isLoading = false;
  bool hasMore = true;
  DocumentSnapshot? lastDocument;

  @override
  void initState() {
    super.initState();
    widget.registerState(this);
    user = authService.getCurrentUser();
    fetchTotalBalance();
    fetchMonthlyTransactions();
    fetchAccounts();
    fetchTags();
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        fetchTransactions();
      }
    });
  }

  Future<void> fetchTotalBalance() async {
    try {
      double balance = await balanceService.getTotalBalance(widget.settingsService.baseCurrency);

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
      final result = await balanceService.getMonthlyStats(widget.settingsService.baseCurrency);
      setState(() {
        totalIncome = result['income']!;
        totalExpense = result['expense']!;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch transactions: $e')),
      );
    }
  }

  Future<void> fetchAccounts() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<AccountModel> fetchedAccounts = await _hiveService.getAccounts();
      setState(() {
        accounts = fetchedAccounts;
        isLoading = false;
        if (fetchedAccounts.isNotEmpty) {
          fetchTransactions();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch accounts: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTransactions() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Calculate starting and ending indices for pagination
      int startIndex = transactions.length;
      int endIndex = startIndex + pageSize;

      List<TransactionModel> allTransactions = await _hiveService.getTransactions();

      // Check if there are more transactions to load
      if (startIndex >= allTransactions.length) {
        setState(() {
          hasMore = false;
        });
        return;
      }

      // Apply pagination
      endIndex = endIndex > allTransactions.length ? allTransactions.length : endIndex;
      List<TransactionModel> fetchedTransactions = allTransactions.sublist(startIndex, endIndex);

      setState(() {
        transactions.addAll(fetchedTransactions);
        // Set hasMore to false if we've loaded all transactions
        if (endIndex >= allTransactions.length) {
          hasMore = false;
        }
      });
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
      List<TagModel> fetchedTags = await _hiveService.getTags();

      setState(() {
        tags = {for (var tag in fetchedTags) tag.tagId: tag};
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch tags: $e')),
      );
    }
  }

  Future<void> refreshData() async {
    fetchTotalBalance();
    fetchMonthlyTransactions();
    transactions.clear();
    lastDocument = null;
    hasMore = true;
    fetchTransactions();
  }

  String getTransactionName(TransactionModel transaction) {
    // Display corresponding transaction name for transfer transactions
    if (transaction.transactionType == TransactionType.transfer) {
      return '${accounts.firstWhere((account) => account.accountId == transaction.accountId).accountName} to ${accounts.firstWhere((account) => account.accountId == transaction.transactionName).accountName}';
    }
    // Simply return the transaction name for other transaction types
    return transaction.transactionName;
  }

  String getDisplayAmount(TransactionModel transaction) {
    String symbol;
    switch (transaction.transactionType) {
      case TransactionType.expense:
        symbol = '-';
        break;
      case TransactionType.transfer:
        symbol = '⇄';
        break;
      default:
        symbol = '';
    }
    // Display the amount in the transaction currency
    return '$symbol${transaction.amount} ${transaction.currency}';
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group transactions by date
    Map<String, List<TransactionModel>> groupedTransactions = {};
    for (var transaction in transactions) {
      String date = DateFormat('yyyy-MM-dd').format(transaction.transactionTime.toDate());
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    // Create a list that includes both date headers and transactions
    List<dynamic> items = [];
    groupedTransactions.forEach((date, transactions) {
      items.add(date); // Add date header
      items.addAll(transactions); // Add transactions for that date
    });

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: Hive.box<TransactionModel>('transactions').listenable(),
        builder: (BuildContext context, Box<TransactionModel> box, Widget? child) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<AccountModel>('accounts').listenable(),
            builder: (BuildContext context, Box<AccountModel> box, Widget? child) {
              return ValueListenableBuilder(
                valueListenable: Hive.box<TagModel>('tags').listenable(),
                builder: (BuildContext context, Box<TagModel> box, Widget? child) {
                  return Column(
                    children: [
                      Card(
                        color: Theme.of(context).cardColor,
                        surfaceTintColor: Theme.of(context).primaryColor,
                        margin: const EdgeInsets.all(8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      const Row(
                        children: [
                          Text("Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: items.length + (hasMore ? 1 : 0),
                          itemBuilder: (BuildContext context, int index) {
                            if (index == items.length) {
                              return isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : const SizedBox.shrink();
                            }

                            final item = items[index];
                            if (item is String) {
                              // Date header
                              return Container(
                                  color: Theme.of(context).splashColor,
                                  child: Text(item, style: const TextStyle(fontSize: 16)));
                            } else if (item is TransactionModel) {
                              final transaction = item;
                              final transactionTags = transaction.tags.map((tagId) => tags[tagId]).toList();
                              // Retrieve account information using accountId
                              final account = accounts.firstWhere(
                                  (account) => account.accountId == transaction.accountId,
                                  orElse: () =>
                                      throw StateError('No account found for accountId: ${transaction.accountId}'));
                              final accountTag = TagModel(
                                tagId: "",
                                userId: "",
                                tagName: account.accountName,
                                tagType: TagType.methods,
                                icon: account.icon,
                                color: account.color,
                              );
                              // Prepend the new tag object to the transactionTags list
                              transactionTags.insert(0, accountTag);
                              return ListTile(
                                title: Text(getTransactionName(transaction), style: TextStyle(fontSize: 16)),
                                subtitle: Wrap(
                                  children: transactionTags
                                      .map((tag) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 1.0),
                                            margin: const EdgeInsets.only(top: 4.0, right: 4.0),
                                            decoration: BoxDecoration(
                                              color: Color(tag!.color).withAlpha(100),
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  deserializeIcon(tag.icon)?.data,
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
                                  getDisplayAmount(transaction),
                                  style: const TextStyle(fontSize: 18),
                                ),
                                onTap: () async {
                                  await context.push(
                                    AppRoutes.editTransaction,
                                    extra: transaction,
                                  );
                                },
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
