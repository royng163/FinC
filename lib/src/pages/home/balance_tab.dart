// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finc/src/components/app_routes.dart';
import 'package:finc/src/helpers/authentication_service.dart';
import 'package:finc/src/helpers/balance_service.dart';
import 'package:finc/src/helpers/hive_service.dart';
import 'package:finc/src/helpers/settings_service.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:finc/src/models/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

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
            _processDataChanges();

            return Column(
              children: [
                _buildBalanceSummaryCard(),
                _buildTransactionsHeader(),
                _buildTransactionsList(),
              ],
            );
          },
        ),
      ),
    );
  }

// Process data changes and update state
  void _processDataChanges() {
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
    int currentTransactionCount = _hiveService.getTransactionsCount();
    if (dataChanged || _transactions.isEmpty || _transactions.length != currentTransactionCount) {
      // Reset to first page if needed
      if (_transactions.isEmpty || currentTransactionCount < _transactions.length) {
        _transactions = _hiveService.getPaginatedTransactions(0, _pageSize);
      } else {
        // Otherwise refresh the current page
        _transactions = _hiveService.getPaginatedTransactions(0, currentTransactionCount);
      }
      _hasMore = _transactions.length < currentTransactionCount;

      // Queue balance update only when data changes
      // This significantly reduces unnecessary calculations
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshStats();
      });
    }
  }

// Balance summary card at the top
  Widget _buildBalanceSummaryCard() {
    return Card(
      color: Theme.of(context).cardColor,
      surfaceTintColor: Theme.of(context).primaryColor,
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTotalBalanceSection(),
            const SizedBox(height: 16),
            _buildIncomeExpenseRow(),
          ],
        ),
      ),
    );
  }

// Total balance display
  Widget _buildTotalBalanceSection() {
    return Column(
      children: [
        const Text(
          'Total Balance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _totalBalance?.toStringAsFixed(2) ?? '0.00',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
      ],
    );
  }

// Income and expense summary row
  Widget _buildIncomeExpenseRow() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _buildFinancialMetric(
            label: 'Income',
            value: _totalIncome,
            color: Colors.green,
          ),
        ),
        Container(
          height: 40,
          width: 1,
          color: colorScheme.outlineVariant,
        ),
        Expanded(
          child: _buildFinancialMetric(
            label: 'Expense',
            value: _totalExpense,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

// Helper for financial metrics (income/expense)
  Widget _buildFinancialMetric({
    required String label,
    required double? value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                value?.toStringAsFixed(2) ?? '0.00',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
      ],
    );
  }

// Transactions section header
  Widget _buildTransactionsHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1.0,
          ),
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TRANSACTIONS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              // Add filter action
            },
            icon: const Icon(Icons.filter_list, size: 18),
            label: const Text('Filter'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

// The transactions list with grouped items
  Widget _buildTransactionsList() {
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

    return Expanded(
      child: items.isEmpty
          ? _buildEmptyTransactionsState()
          : ListView.builder(
              controller: _scrollController,
              itemCount: items.length + (_hasMore ? 1 : 0),
              itemBuilder: (BuildContext context, int index) {
                if (index == items.length) {
                  return _isLoading ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink();
                }

                final item = items[index];
                if (item is String) {
                  return _buildDateHeader(item);
                } else if (item is TransactionModel) {
                  return _buildTransactionItem(item);
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }

// Empty state for transactions
  Widget _buildEmptyTransactionsState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add new transactions to track your finances',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

// Date header in the transactions list
  Widget _buildDateHeader(String date) {
    final formattedDate = DateFormat.yMMMMd().format(DateTime.parse(date));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Text(
        formattedDate,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

// Individual transaction item
  Widget _buildTransactionItem(TransactionModel transaction) {
    // Get tags for this transaction
    List<TagModel> transactionTags = _getTransactionTags(transaction);

    // Get account information
    final account = _getAccountForTransaction(transaction);

    // Create account tag and add to beginning of tags list
    final accountTag = TagModel(
      tagId: "",
      userId: "",
      tagName: account.accountName,
      tagType: TagType.methods,
      icon: account.icon,
      color: account.color,
    );
    transactionTags.insert(0, accountTag);

    return InkWell(
      onTap: () async {
        await context.push(
          AppRoutes.editTransaction,
          extra: transaction,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTransactionName(transaction),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (transactionTags.isNotEmpty)
                    SizedBox(
                      height: 24,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: transactionTags.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemBuilder: (context, tagIndex) {
                          final tag = transactionTags[tagIndex];
                          return _buildTagChip(tag);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  getDisplayAmount(transaction),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: transaction.transactionType == TransactionType.expense
                        ? Colors.red
                        : transaction.transactionType == TransactionType.income
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Helper method to get transaction tags
  List<TagModel> _getTransactionTags(TransactionModel transaction) {
    final List<TagModel> transactionTags = [];
    try {
      for (var tagId in transaction.tags) {
        try {
          final tag = _tags.firstWhere(
            (tag) => tag.tagId == tagId,
            orElse: () => TagModel(
              tagId: tagId,
              userId: "",
              tagName: "Unknown Tag",
              tagType: TagType.categories,
              icon: {},
              color: Colors.grey.value,
            ),
          );
          transactionTags.add(tag);
        } catch (e) {
          // Skip this tag
        }
      }
    } catch (e) {
      // Handle error
    }
    return transactionTags;
  }

// Helper method to get account for a transaction
  AccountModel _getAccountForTransaction(TransactionModel transaction) {
    return _accounts.firstWhere(
      (account) => account.accountId == transaction.accountId,
      orElse: () => AccountModel(
        accountId: transaction.accountId,
        userId: _user.uid,
        accountName: "Unknown Account",
        accountType: AccountType.bank,
        balances: {},
        icon: {},
        color: Colors.grey.value,
        createdAt: Timestamp.now(),
      ),
    );
  }

// Builds a tag chip
  Widget _buildTagChip(TagModel tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(tag.color).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            deserializeIcon(tag.icon)?.data,
            size: 12,
            color: Color(tag.color),
          ),
          const SizedBox(width: 4),
          Text(
            tag.tagName,
            style: TextStyle(
              fontSize: 12,
              color: Color(tag.color),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
