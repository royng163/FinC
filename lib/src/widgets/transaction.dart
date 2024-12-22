class Transaction {
  const Transaction(
      this.id, this.name, this.account, this.amount, this.currency);

  final int id;
  final String name;
  final String account;
  final double amount;
  final String currency;
}
