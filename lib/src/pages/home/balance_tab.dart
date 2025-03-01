import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finc/src/helpers/authentication_service.dart';
import 'package:finc/src/helpers/balance_service.dart';
import 'package:finc/src/helpers/hive_service.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  final BalanceService _balanceService = BalanceService();
  final HiveService _hiveService = HiveService();
  final AuthenticationService _authService = AuthenticationService();
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 10;
  late User _user;
  double? _totalBalance;
  double? _totalIncome;
  double? _totalExpense;
  List<AccountModel> _accounts = [];
  List<TransactionModel> _transactions = [];
  List<TagModel> _tags = [];
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    widget.registerState(this);
    _user = _authService.getCurrentUser();
    fetchData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        fetchTransactions();
      }
    });
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _transactions = []; // Clear transactions to ensure fresh load
      _hasMore = true; // Reset pagination
    });

    try {
      // Load accounts and tags first (quick operation)
      _accounts = _hiveService.getAccounts();
      _tags = _hiveService.getTags();

      // Load transactions separately
      fetchTransactions();

      // Load balance calculations
      final baseCurrency = widget.settingsService.baseCurrency;
      final balance = await _balanceService.getTotalBalance(baseCurrency);
      final monthlyStats = await _balanceService.getMonthlyStats(baseCurrency);

      if (mounted) {
        setState(() {
          _totalBalance = balance;
          _totalIncome = monthlyStats['income'] ?? 0.0;
          _totalExpense = monthlyStats['expense'] ?? 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
        setState(() {
          _totalBalance = 0;
          _totalIncome = 0;
          _totalExpense = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> fetchTransactions() async {
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate starting index for pagination
      int startIndex = _transactions.length;

      // Get only the transactions needed for the current page
      List<TransactionModel> fetchedTransactions = _hiveService.getPaginatedTransactions(startIndex, _pageSize);

      setState(() {
        _transactions.addAll(fetchedTransactions);
        // Update hasMore based on whether we've loaded all transactions
        _hasMore = startIndex + fetchedTransactions.length < _hiveService.getTransactionsCount();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch transactions: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getTransactionName(TransactionModel transaction) {
    // Display corresponding transaction name for transfer transactions
    if (transaction.transactionType == TransactionType.transfer) {
      return '${_accounts.firstWhere((account) => account.accountId == transaction.accountId).accountName} to ${_accounts.firstWhere((account) => account.accountId == transaction.transactionName).accountName}';
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

  void _refreshStats() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Calculate new balances asynchronously
        final baseCurrency = widget.settingsService.baseCurrency;
        _balanceService.getTotalBalance(baseCurrency).then((balance) {
          if (mounted) {
            setState(() {
              _totalBalance = balance;
            });
          }
        });

        _balanceService.getMonthlyStats(baseCurrency).then((monthlyStats) {
          if (mounted) {
            setState(() {
              _totalIncome = monthlyStats['income'] ?? 0.0;
              _totalExpense = monthlyStats['expense'] ?? 0.0;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            Hive.box<TransactionModel>('transactions').listenable(),
            Hive.box<AccountModel>('accounts').listenable(),
            Hive.box<TagModel>('tags').listenable(),
          ]),
          builder: (context, child) {
            // A flag to track if we need to refresh the UI
            bool dataChanged = false;

            // Check if accounts changed
            final currentAccounts = _hiveService.getAccounts();
            if (_accounts.length != currentAccounts.length || !listEquals(_accounts, currentAccounts)) {
              _accounts = currentAccounts;
              dataChanged = true;
            }

            // Check if tags changed
            final currentTags = _hiveService.getTags();
            if (_tags.length != currentTags.length || !listEquals(_tags, currentTags)) {
              _tags = currentTags;
              dataChanged = true;
            }

            // Check if transactions changed - compare counts to avoid full comparison
            int transactionCount = _hiveService.getTransactionsCount();

            // Only refresh transactions if data has actually changed
            if (dataChanged ||
                _transactions.isEmpty ||
                transactionCount != _hiveService.getLastKnownTransactionCount()) {
              // Store the current count for future comparison
              _hiveService.setLastKnownTransactionCount(transactionCount);

              // Reset to first page if needed
              if (_transactions.isEmpty || transactionCount < _transactions.length) {
                _transactions = _hiveService.getPaginatedTransactions(0, _pageSize);
              } else {
                // Otherwise refresh the current page
                _transactions = _hiveService.getPaginatedTransactions(0, _transactions.length);
              }
              _hasMore = _transactions.length < transactionCount;

              // Queue balance update only when data changes
              // This significantly reduces unnecessary calculations
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _refreshStats();
              });
            }

            // Group transactions by date
            Map<String, List<TransactionModel>> groupedTransactions = {};
            for (var transaction in _transactions) {
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
                            _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _totalBalance?.toStringAsFixed(2) ?? '0.00',
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
                                _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        _totalIncome?.toStringAsFixed(2) ?? '0.00',
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
                                _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        _totalExpense?.toStringAsFixed(2) ?? '0.00',
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
                    controller: _scrollController,
                    itemCount: items.length + (_hasMore ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == items.length) {
                        return _isLoading ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink();
                      }

                      final item = items[index];
                      if (item is String) {
                        // Date header
                        return Container(
                            color: Theme.of(context).splashColor,
                            child: Text(item, style: const TextStyle(fontSize: 16)));
                      } else if (item is TransactionModel) {
                        final transaction = item;
                        // Safer way to get tags with error handling
                        final List<TagModel> transactionTags = [];
                        try {
                          for (var tagId in transaction.tags) {
                            try {
                              final tag = _tags.firstWhere((tag) => tag.tagId == tagId,
                                  orElse: () => TagModel(
                                      tagId: tagId,
                                      userId: "",
                                      tagName: "Unknown Tag",
                                      tagType: TagType.categories,
                                      icon: {},
                                      // ignore: deprecated_member_use
                                      color: Colors.grey.value));
                              transactionTags.add(tag);
                            } catch (e) {
                              throw ("Error finding tag $tagId: $e");
                              // Skip this tag
                            }
                          }
                        } catch (e) {
                          throw ("Error processing tags: $e");
                        }
                        // Retrieve account information using accountId
                        final account = _accounts.firstWhere(
                          (account) => account.accountId == transaction.accountId,
                          orElse: () => AccountModel(
                            accountId: transaction.accountId,
                            userId: _user.uid,
                            accountName: "Unknown Account",
                            accountType: AccountType.bank,
                            balances: {},
                            icon: {},
                            // ignore: deprecated_member_use
                            color: Colors.grey.value,
                            createdAt: Timestamp.now(),
                          ),
                        );
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
                                        color: Color(tag.color).withAlpha(100),
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
                          onTap: () {
                            context.push(
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
        ),
      ),
    );
  }
}
