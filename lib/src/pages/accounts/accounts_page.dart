// ignore_for_file: deprecated_member_use

import 'package:adaptive_navigation/adaptive_navigation.dart';
import 'package:finc/src/components/app_routes.dart';
import 'package:finc/src/helpers/balance_service.dart';
import 'package:finc/src/helpers/hive_service.dart';
import 'package:finc/src/helpers/settings_service.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:finc/src/models/transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class AccountsPage extends StatefulWidget {
  final SettingsService settingsService;

  const AccountsPage({super.key, required this.settingsService});

  @override
  AccountsPageState createState() => AccountsPageState();
}

class AccountsPageState extends State<AccountsPage> {
  final BalanceService _balanceService = BalanceService();
  final HiveService _hiveService = HiveService();
  List<AccountModel> _accounts = [];
  List<TransactionModel> _transactions = [];
  List<TagModel> _tags = [];
  bool _isLoadingAccounts = true;
  bool _isLoadingTransactions = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoadingAccounts = true;
    });

    try {
      // Load accounts and tags (quick operations)
      _accounts = _hiveService.getAccounts();
      _tags = _hiveService.getTags();

      // Load transactions for the first account if available
      if (_accounts.isNotEmpty) {
        setState(() {
          _isLoadingTransactions = true;
        });

        _transactions = _hiveService.getAccountTransactions(_accounts[_selectedIndex].accountId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
          _isLoadingTransactions = false;
        });
      }
    }
  }

  Future<void> fetchTransactions(String accountId) async {
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      _transactions = _hiveService.getAccountTransactions(accountId);

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch transactions: $e')),
      );
    } finally {
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  Color getTextColor(Color backgroundColor) {
    // Calculate the luminance of the background color
    double luminance = backgroundColor.computeLuminance();
    // Return black for light backgrounds and white for dark backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  String getTransactionName(TransactionModel transaction) {
    // Display corresponding transaction name for transfer transactions
    if (transaction.transactionType == TransactionType.transfer) {
      if (transaction.accountId == _accounts[_selectedIndex].accountId) {
        // Transfer to the destination account with Id stored in transactionName
        return 'To ${_accounts.firstWhere((account) => account.accountId == transaction.transactionName).accountName}';
      } else {
        // Transfer from another account
        return 'From ${_accounts.firstWhere((account) => account.accountId == transaction.accountId).accountName}';
      }
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
        if (transaction.accountId == _accounts[_selectedIndex].accountId) {
          symbol = '-';
        } else {
          symbol = '';
        }
        break;
      default:
        symbol = '';
    }
    // Display the amount in the transaction currency
    return '$symbol${transaction.amount} ${transaction.currency}';
  }

  String formatAccountType(AccountType type) {
    // Convert the enum value to string and remove the enum type prefix
    final rawName = type.toString().split('.').last;

    // Insert spaces before capital letters and capitalize the first letter
    final formattedName = rawName
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (Match m) => '${m[1]} ${m[2]}')
        .replaceFirstMapped(RegExp(r'^[a-z]'), (Match m) => m[0]!.toUpperCase());

    return formattedName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdaptiveAppBar(
        title: const Text('FinC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          Hive.box<TransactionModel>('transactions').listenable(),
          Hive.box<AccountModel>('accounts').listenable(),
          Hive.box<TagModel>('tags').listenable(),
        ]),
        builder: (context, _) {
          _processDataChanges();

          return _isLoadingAccounts
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildAccountCards(),
                    _buildTransactionHeader(),
                    _buildTransactionContent(),
                  ],
                );
        },
      ),
    );
  }

// Process data changes when Hive boxes update
  void _processDataChanges() {
    bool dataChanged = false;

    // Get fresh data when boxes change
    final currentAccounts = _hiveService.getAccounts();
    if (_accounts.length != currentAccounts.length || !listEquals(_accounts, currentAccounts)) {
      _accounts = currentAccounts;
      dataChanged = true;
    }

    // Update tags when they change
    final fetchedTags = _hiveService.getTags();
    if (!listEquals(_tags, fetchedTags)) {
      _tags = fetchedTags;
      dataChanged = true;
    }

    // Make sure selectedIndex is valid when accounts change
    if (_accounts.isEmpty) {
      _selectedIndex = 0;
      _transactions = [];
    } else {
      // Ensure selected index is within bounds
      _selectedIndex = _selectedIndex >= _accounts.length ? 0 : _selectedIndex;
      final accountId = _accounts[_selectedIndex].accountId;

      // Check if transaction count changed (additions/deletions)
      if (_hiveService.getAccountTransactionsCount(accountId) != _transactions.length || dataChanged) {
        _transactions = _hiveService.getAccountTransactions(accountId);
      }
    }
  }

// Account cards section
  Widget _buildAccountCards() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: PageView.builder(
        itemCount: _accounts.length,
        controller: PageController(viewportFraction: 0.85),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
            fetchTransactions(_accounts[index].accountId);
          });
        },
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8), // Additional padding for each card
            child: _buildAccountCard(index),
          );
        },
      ),
    );
  }

// Individual account card
  Widget _buildAccountCard(int index) {
    final account = _accounts[index];
    final Color backgroundColor = Color(account.color);
    final Color textColor = getTextColor(backgroundColor);

    return FutureBuilder<double>(
      future: _balanceService.getAccountBalance(account.balances, widget.settingsService.baseCurrency),
      builder: (context, snapshot) {
        double accountBalance = snapshot.data ?? 0.0;
        return GestureDetector(
          onTap: () {
            context.push(
              AppRoutes.editAccount,
              extra: account,
            );
          },
          child: Card(
            color: backgroundColor,
            elevation: 4,
            shadowColor: backgroundColor.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAccountCardHeader(account, textColor),
                  const SizedBox(height: 8),
                  _buildAccountCardBody(account, textColor, accountBalance),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Account card header with name and icon
  Widget _buildAccountCardHeader(AccountModel account, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            account.accountName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(
          deserializeIcon(account.icon)?.data,
          color: textColor.withOpacity(0.8),
          size: 24,
        ),
      ],
    );
  }

// Account card body with balance and type
  Widget _buildAccountCardBody(AccountModel account, Color textColor, double accountBalance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${accountBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        _buildAccountTypeBadge(account, textColor),
      ],
    );
  }

// Account type badge/chip
  Widget _buildAccountTypeBadge(AccountModel account, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        formatAccountType(account.accountType),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

// Transactions header
  Widget _buildTransactionHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1.0,
          ),
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
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
              color: colorScheme.primary,
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

// Transaction content area (shows loading, empty state, or transactions list)
  Widget _buildTransactionContent() {
    return _isLoadingTransactions
        ? const Expanded(child: Center(child: CircularProgressIndicator()))
        : Expanded(
            child: _transactions.isEmpty ? _buildEmptyTransactionsState() : _buildTransactionsList(),
          );
  }

// Empty state for no transactions
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
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transactions for this account will appear here',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// Transaction list
  Widget _buildTransactionsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

// Individual transaction item
  Widget _buildTransactionItem(TransactionModel transaction) {
    final transactionTags = _tags.where((tag) => transaction.tags.contains(tag.tagId)).toList();

    return InkWell(
      onTap: () {
        context.push(
          AppRoutes.editTransaction,
          extra: transaction,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                  if (transactionTags.isNotEmpty) _buildTransactionTags(transactionTags),
                ],
              ),
            ),
            _buildTransactionAmount(transaction),
          ],
        ),
      ),
    );
  }

// Transaction tags horizontal list
  Widget _buildTransactionTags(List<TagModel> tags) {
    return SizedBox(
      height: 24,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, tagIndex) {
          final tag = tags[tagIndex];
          return _buildTagChip(tag);
        },
      ),
    );
  }

// Individual tag chip
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

// Transaction amount and date display
  Widget _buildTransactionAmount(TransactionModel transaction) {
    return Column(
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
        const SizedBox(height: 4),
        Text(
          DateFormat.yMMMd().format(transaction.transactionTime.toDate()),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
