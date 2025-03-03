// import 'package:finc/src/models/account_model.dart';
// import 'package:finc/src/models/transaction_model.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class RebateCalculatorView extends StatefulWidget {
//   const RebateCalculatorView({super.key});

//   @override
//   RebateCalculatorViewState createState() => RebateCalculatorViewState();
// }

// class RebateCalculatorViewState extends State<RebateCalculatorView> {
//   List<TransactionModel> transactions = [];
//   List<String> selectedTags = [];
//   bool isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     fetchTransactions();
//   }

//   Future<void> fetchTransactions() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final User? user = FirebaseAuth.instance.currentUser;
//       final transactionsSnapshot =
//           await FirebaseFirestore.instance.collection('Transactions').where('userId', isEqualTo: user?.uid).get();

//       List<TransactionModel> fetchedTransactions = transactionsSnapshot.docs.map((doc) {
//         return TransactionModel.fromDocument(doc);
//       }).toList();

//       setState(() {
//         transactions = fetchedTransactions;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to fetch transactions: $e')),
//       );
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   List<TransactionModel> filterTransactionsByTags(List<TransactionModel> transactions, List<String> tags) {
//     return transactions.where((transaction) {
//       return tags.every((tag) => transaction.tags.contains(tag));
//     }).toList();
//   }

//   double calculateRebate(List<TransactionModel> transactions, AccountModel account) {
//     double totalRebate = 0.0;

//     for (var transaction in transactions) {
//       double rebate = 0.0;

//       if (account.rebateConfig != null) {
//         for (var tag in transaction.tags) {
//           if (account.rebateConfig!.containsKey(tag)) {
//             rebate = account.rebateConfig![tag]!;
//             break;
//           }
//         }
//       }

//       totalRebate += transaction.amount * rebate;
//     }

//     return totalRebate;
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<TransactionModel> filteredTransactions = filterTransactionsByTags(transactions, selectedTags);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Filter Transactions'),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Wrap(
//               spacing: 8.0,
//               children: [
//                 FilterChip(
//                   label: const Text('Dining'),
//                   selected: selectedTags.contains('dining'),
//                   onSelected: (bool selected) {
//                     setState(() {
//                       if (selected) {
//                         selectedTags.add('dining');
//                       } else {
//                         selectedTags.removeWhere((String tag) => tag == 'dining');
//                       }
//                     });
//                   },
//                 ),
//                 FilterChip(
//                   label: const Text('Entertainment'),
//                   selected: selectedTags.contains('entertainment'),
//                   onSelected: (bool selected) {
//                     setState(() {
//                       if (selected) {
//                         selectedTags.add('entertainment');
//                       } else {
//                         selectedTags.removeWhere((String tag) => tag == 'entertainment');
//                       }
//                     });
//                   },
//                 ),
//                 FilterChip(
//                   label: const Text('Alipay'),
//                   selected: selectedTags.contains('alipay'),
//                   onSelected: (bool selected) {
//                     setState(() {
//                       if (selected) {
//                         selectedTags.add('alipay');
//                       } else {
//                         selectedTags.removeWhere((String tag) => tag == 'alipay');
//                       }
//                     });
//                   },
//                 ),
//                 FilterChip(
//                   label: const Text('Google Pay'),
//                   selected: selectedTags.contains('google_pay'),
//                   onSelected: (bool selected) {
//                     setState(() {
//                       if (selected) {
//                         selectedTags.add('google_pay');
//                       } else {
//                         selectedTags.removeWhere((String tag) => tag == 'google_pay');
//                       }
//                     });
//                   },
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : ListView.builder(
//                     itemCount: filteredTransactions.length,
//                     itemBuilder: (BuildContext context, int index) {
//                       final transaction = filteredTransactions[index];
//                       return ListTile(
//                         title: Text(transaction.transactionName),
//                         subtitle: Text(transaction.tags.join(', ')),
//                         trailing: Text('${transaction.amount} ${transaction.currency}'),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
