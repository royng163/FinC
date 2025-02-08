import 'package:adaptive_navigation/adaptive_navigation.dart';
import 'package:finc/src/helpers/authentication_service.dart';
import 'package:finc/src/helpers/balance_service.dart';
import 'package:finc/src/helpers/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../components/app_routes.dart';
import '../../helpers/settings_service.dart';
import '../../models/tag_model.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';

class AccountsPage extends StatefulWidget {
  final SettingsService settingsService;

  const AccountsPage({super.key, required this.settingsService});

  @override
  AccountsPageState createState() => AccountsPageState();
}

class AccountsPageState extends State<AccountsPage> {
  final BalanceService balanceService = BalanceService();
  final FirestoreService firestoreService = FirestoreService();
  final AuthenticationService authService = AuthenticationService();
  late User user;
  List<AccountModel> accounts = [];
  List<TransactionModel> transactions = [];
  Map<String, TagModel> tags = {};
  bool isLoadingAccounts = true;
  bool isLoadingTransactions = false;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    user = authService.getCurrentUser();
    fetchAccounts();
    fetchTags();
  }

  Future<void> fetchAccounts() async {
    setState(() {
      isLoadingAccounts = true;
    });

    try {
      accounts = await firestoreService.getAccounts(user.uid);

      setState(() {
        if (accounts.isNotEmpty) {
          fetchTransactions(accounts[0].accountId);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch accounts: $e')),
      );
    } finally {
      setState(() {
        isLoadingAccounts = false;
      });
    }
  }

  Future<void> fetchTags() async {
    try {
      List<TagModel> fetchedTags = await firestoreService.getTags(user.uid);

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

  Future<void> fetchTransactions(String accountId) async {
    setState(() {
      isLoadingTransactions = true;
    });

    try {
      transactions = await firestoreService.getAccountTransactions(user.uid, accountId);

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch transactions: $e')),
      );
    } finally {
      setState(() {
        isLoadingTransactions = false;
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
      if (transaction.accountId == accounts[selectedIndex].accountId) {
        // Transfer to the destination account with Id stored in transactionName
        return 'To ${accounts.firstWhere((account) => account.accountId == transaction.transactionName).accountName}';
      } else {
        // Transfer from another account
        return 'From ${accounts.firstWhere((account) => account.accountId == transaction.accountId).accountName}';
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
        if (transaction.accountId == accounts[selectedIndex].accountId) {
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
      body: isLoadingAccounts
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: PageView.builder(
                    itemCount: accounts.length,
                    controller: PageController(viewportFraction: 0.8),
                    onPageChanged: (index) {
                      setState(() {
                        selectedIndex = index;
                        fetchTransactions(accounts[index].accountId);
                      });
                    },
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final Color backgroundColor = Color(account.color);
                      final Color textColor = getTextColor(backgroundColor);
                      return FutureBuilder<double>(
                        future: balanceService.getAccountBalance(account.balances, widget.settingsService.baseCurrency),
                        builder: (context, snapshot) {
                          double accountBalance = snapshot.data ?? 0.0;
                          return GestureDetector(
                            onTap: () async {
                              final result = await context.push(
                                AppRoutes.editAccount,
                                extra: account,
                              );
                              if (result == true) {
                                fetchAccounts();
                              }
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
                isLoadingTransactions
                    ? const Center(child: CircularProgressIndicator())
                    : Expanded(
                        child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            final transactionTags = transaction.tags.map((tagId) => tags[tagId]).toList();
                            return ListTile(
                              title: Text(getTransactionName(transaction)),
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
                              onTap: () async {
                                final result = await context.push(
                                  AppRoutes.editTransaction,
                                  extra: transaction,
                                );
                                if (result == true) {
                                  fetchTransactions(accounts[selectedIndex].accountId);
                                } else if (result == 'deleted') {
                                  fetchAccounts();
                                }
                              },
                            );
                          },
                        ),
                      ),
              ],
            ),
    );
  }
}
