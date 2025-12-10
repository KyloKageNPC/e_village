import 'package:e_village/bottombutton.dart';
import 'package:e_village/components/popup.dart';
import 'package:e_village/top_caed.dart';
import 'package:e_village/transaction.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      body: Column(
        children: [
          TopNueCard(
            balance: '\$ 20',
            income: '\$ 1000',
            expense: '\$ 500',
          ),
          SizedBox(height: 10,),
          Expanded(child: SingleChildScrollView(
            child: Column(
              children: [
              MyTransactions(
              transactionName: 'Ball', 
              money: '50', 
              expenseOrIncome: 'Expense'),
            
            SizedBox(height: 5,),
            MyTransactions(
              transactionName: 'Ball', 
              money: '50', 
              expenseOrIncome: 'Expense'),
            
            SizedBox(height: 10,),
            MyTransactions(
              transactionName: 'Ball', 
              money: '50', 
              expenseOrIncome: 'Expense'),
            
            SizedBox(height: 10,),
            MyTransactions(
              transactionName: 'Ball', 
              money: '50', 
              expenseOrIncome: 'Expense'),
            
            SizedBox(height: 10,),
            MyTransactions(
              transactionName: 'Ball', 
              money: '50', 
              expenseOrIncome: 'Expense'),
            
            SizedBox(height: 10,),
            MyTransactions(
              transactionName: 'Ball', 
              money: '50', 
              expenseOrIncome: 'Expense'),
            
            SizedBox(height: 10,),
            MyTransactions(
              transactionName: 'Ball', 
              money: '50', 
              expenseOrIncome: 'Expense'),

            SizedBox(height: 10,),
            MyTransactions(
              transactionName: 'Ball', 
              money: '50', 
              expenseOrIncome: 'Expense'),
              ],
            ),
          )),
          
 

          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: MyBottomButton(
                  color: Colors.orange.shade600, 
                  size: Size(60, 50), 
                  icon: Icon(Icons.upload)
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: (){
                  showDialog(
                    context: context,
                    builder: (context) => const PopupMenu(),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: MyBottomButton(
                    color: Colors.orange.shade600, 
                    size: Size(70, 80), 
                    icon: Icon(Icons.add)
                  ),
                ),
              ),

              Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 30.0),
                child: MyBottomButton(
                  color: Colors.orange.shade600, 
                  size: Size(60, 50), 
                  icon: Icon(Icons.settings)
                ),
              )

            ],
          ),
          SizedBox(height: 20,)
        ],

        
      ),
      
      
    );
  }
}