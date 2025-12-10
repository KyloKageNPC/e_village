import 'package:flutter/material.dart';

class MyTransactions extends StatelessWidget {
  final String transactionName;
  final String money;
  final String expenseOrIncome;
  const MyTransactions({
    required this.transactionName, 
    required this.money, 
    required this.expenseOrIncome, 
    super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        title: Text(transactionName),
        subtitle: Text(expenseOrIncome),
        trailing: Text(money),
      ),
    );
  }
}