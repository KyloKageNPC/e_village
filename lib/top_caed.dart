import 'package:flutter/material.dart';

class TopNueCard extends StatelessWidget {
  final String balance;
  final String income;
  final String expense;

  TopNueCard({required this.balance, required this.income, required this.expense, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.orange.shade300,
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                offset: Offset(4.0, 4.0),
                blurRadius: 15.0,
                spreadRadius: 1.0,
              ),
              BoxShadow(
                color: Colors.white,
                offset: Offset(-4.0, -4.0),
                blurRadius: 15.0,
                spreadRadius: 1.0,
              )
            ]
          ),
          //color: Colors.grey.shade400,
          child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16,),
              Text('B A L A N C E',
              style: TextStyle(
                color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold
              ),),
      
              Text(
                balance,
              style: TextStyle(
                color: Colors.purple, fontSize: 40
              ),),
      
              

              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 1, 1, 1),
                    child: Container(
                      decoration: 
                      BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.green),
                      child: Icon(
                        size: 30,
                        Icons.arrow_upward_rounded, color: Colors.white,)),
                  ),
                  Text('  Income',
                  style: TextStyle(
                    color: Colors.black, fontSize: 16
                  ),),

                  Spacer(),

                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Container(
                      decoration: 
                      BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.red),
                      child: Icon(
                        size: 30,
                        Icons.arrow_downward_rounded, color: Colors.white,)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text('  Expense',
                    style: TextStyle(
                      color: Colors.black, fontSize: 16, fontFamily: 'Arial', fontWeight: FontWeight.bold
                    ),),
                  ),
                ],
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text(
                      income,
                      style: TextStyle(
                        fontSize: 20
                      ) ),
                  ),

                  Spacer(),

                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Text(
                      expense,
                      style: TextStyle(
                        fontSize: 20
                      ) ),
                  )
                ],
              )
              
            ],
          ),
          ),
        ),
      ),
    );
  }
}