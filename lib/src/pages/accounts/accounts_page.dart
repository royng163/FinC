import 'package:adaptive_navigation/adaptive_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finc/src/helpers/balance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../components/app_routes.dart';
import '../../components/settings_controller.dart';
import 'edit_account_view.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';

class AccountsPage extends StatefulWidget {
  final SettingsController settingsController;

  const AccountsPage({super.key, required this.settingsController});

  @override
  AccountsPageState createState() => AccountsPageState();
}

class AccountsPageState extends State<AccountsPage> {
  List<AccountModel> accounts = [];
  List<TransactionModel> transactions = [];
  bool isLoadingAccounts = true;
  bool isLoadingTransactions = false;
  int selectedIndex = 0;
  late BalanceService balanceService;

  @override
  void initState() {
    super.initState();
    balanceService = BalanceService();
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    setState(() {
      isLoadingAccounts = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final accountsSnapshot = await FirebaseFirestore.instance
          .collection('Accounts')
          .where('userId', isEqualTo: user?.uid)
          .get();

      List<AccountModel> fetchedAccounts = accountsSnapshot.docs.map((doc) {
        return AccountModel.fromDocument(doc);
      }).toList();

      setState(() {
        accounts = fetchedAccounts;
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

  Future<void> fetchTransactions(String accountId) async {
    setState(() {
      isLoadingTransactions = true;
    });

    try {
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('Transactions')
          .where('accountId', isEqualTo: accountId)
          .get();

      List<TransactionModel> fetchedTransactions =
          transactionsSnapshot.docs.map((doc) {
        return TransactionModel.fromDocument(doc);
      }).toList();

      setState(() {
        transactions = fetchedTransactions;
      });
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
                        future: balanceService.getAccountBalance(
                            account.balances,
                            widget.settingsController.baseCurrency),
                        builder: (context, snapshot) {
                          double accountBalance = snapshot.data ?? 0.0;
                          return GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditAccountView(
                                    account: account,
                                  ),
                                ),
                              );
                              if (result == true) {
                                fetchAccounts();
                              }
                            },
                            child: Card(
                              color: backgroundColor,
                              margin: const EdgeInsets.all(8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      account.accountName,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textColor),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Balance: \$${accountBalance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 16, color: textColor),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Account Type: ${account.accountType.toString().split('.').last}',
                                      style: TextStyle(
                                          fontSize: 16, color: textColor),
                                    ),
                                    if (kDebugMode) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Account ID: ${account.accountId}',
                                        style: TextStyle(
                                            fontSize: 12, color: textColor),
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
                            return ListTile(
                              title: Text(transaction.transactionName),
                              subtitle: Text(DateFormat.yMMMd().format(
                                  transaction.transactionTime.toDate())),
                              trailing: Text(
                                '\$${transaction.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
    );
  }
}
