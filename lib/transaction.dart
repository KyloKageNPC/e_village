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
    final isIncome = expenseOrIncome.toLowerCase() == 'income';
    final color = isIncome ? Colors.green.shade600 : Colors.red.shade600;
    final icon = isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          transactionName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            expenseOrIncome,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Text(
          money,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
