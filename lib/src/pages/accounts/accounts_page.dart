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
          // Track if data changed
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
            // get account id
            final accountId = _accounts[_selectedIndex].accountId;

            // Check if transaction count changed (additions/deletions)
            if (_hiveService.getAccountTransactionsCount(accountId) != _transactions.length || dataChanged) {
              _transactions = _hiveService.getAccountTransactions(accountId);
            }
          }

          // Rest of UI remains unchanged
          return _isLoadingAccounts
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: PageView.builder(
                        itemCount: _accounts.length,
                        controller: PageController(viewportFraction: 0.8),
                        onPageChanged: (index) {
                          setState(() {
                            _selectedIndex = index;
                            fetchTransactions(_accounts[index].accountId);
                          });
                        },
                        itemBuilder: (context, index) {
                          final account = _accounts[index];
                          final Color backgroundColor = Color(account.color);
                          final Color textColor = getTextColor(backgroundColor);
                          return FutureBuilder<double>(
                            future: _balanceService.getAccountBalance(
                                account.balances, widget.settingsService.baseCurrency),
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
                                  margin: const EdgeInsets.all(8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          account.accountName,
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Balance: \$${accountBalance.toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 16, color: textColor),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Account Type: ${account.accountType.toString().split('.').last}',
                                          style: TextStyle(fontSize: 16, color: textColor),
                                        ),
                                        if (kDebugMode) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Account ID: ${account.accountId}',
                                            style: TextStyle(fontSize: 12, color: textColor),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoadingTransactions
                        ? const Center(child: CircularProgressIndicator())
                        : Expanded(
                            child: ListView.builder(
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _transactions[index];
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
                                return ListTile(
                                  title: Text(getTransactionName(transaction)),
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
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        DateFormat.yMMMd().format(transaction.transactionTime.toDate()),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        getDisplayAmount(transaction),
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    context.push(
                                      AppRoutes.editTransaction,
                                      extra: transaction,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ],
                );
        },
      ),
    );
  }
}
