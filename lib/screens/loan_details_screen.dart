import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/repayment_provider.dart';
import '../providers/auth_provider.dart';
import '../models/loan_model.dart';
import '../models/loan_repayment_model.dart';
import 'mobile_money_repayment_screen.dart';

class LoanDetailsScreen extends StatefulWidget {
  final LoanModel loan;

  const LoanDetailsScreen({super.key, required this.loan});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final repaymentProvider = context.read<RepaymentProvider>();
    await repaymentProvider.loadLoanRepayments(loanId: widget.loan.id);
    await repaymentProvider.calculateRemainingBalance(
      loanId: widget.loan.id,
      loanAmount: widget.loan.amount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      appBar: AppBar(
        title: Text(
          'Loan Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Consumer<RepaymentProvider>(
        builder: (context, repaymentProvider, _) {
          if (repaymentProvider.isLoading && repaymentProvider.repayments.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.orange.shade600,
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Loan Summary Card
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Loan Amount',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        currencyFormat.format(widget.loan.amount),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoColumn(
                            'Repaid',
                            currencyFormat.format(repaymentProvider.totalRepaid),
                            Colors.green.shade300,
                          ),
                          _buildInfoColumn(
                            'Remaining',
                            currencyFormat.format(repaymentProvider.remainingBalance),
                            Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Loan Details
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildDetailRow('Purpose', widget.loan.purpose),
                      SizedBox(height: 12),
                      _buildDetailRow('Interest Rate', '${widget.loan.interestRate}%'),
                      SizedBox(height: 12),
                      _buildDetailRow('Duration', '${widget.loan.durationMonths} months'),
                      SizedBox(height: 12),
                      _buildDetailRow('Interest Type', widget.loan.interestType.displayName),
                      SizedBox(height: 12),
                      _buildDetailRow('Status', widget.loan.status.displayName),
                      SizedBox(height: 12),
                      _buildDetailRow('Request Date', dateFormat.format(widget.loan.createdAt)),
                      if (widget.loan.approvedAt != null) ...[
                        SizedBox(height: 12),
                        _buildDetailRow('Approved Date', dateFormat.format(widget.loan.approvedAt!)),
                      ],
                      if (widget.loan.disbursedAt != null) ...[
                        SizedBox(height: 12),
                        _buildDetailRow('Disbursed Date', dateFormat.format(widget.loan.disbursedAt!)),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Make Repayment Buttons (only if loan is active/disbursed)
                if ((widget.loan.status == LoanStatus.active || 
                     widget.loan.status == LoanStatus.disbursed) && 
                    repaymentProvider.remainingBalance > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        // Mobile Money Payment Button
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MobileMoneyRepaymentScreen(
                                loan: widget.loan,
                                remainingBalance: repaymentProvider.remainingBalance,
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _loadData(); // Refresh data if payment was made
                            }
                          }),
                          icon: Icon(Icons.phone_android),
                          label: Text('Pay via Mobile Money'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                        SizedBox(height: 12),
                        // Cash Payment Button
                        OutlinedButton.icon(
                          onPressed: () => _showRepaymentDialog(),
                          icon: Icon(Icons.payments_outlined),
                          label: Text('Record Cash Payment'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                            side: BorderSide(color: Colors.green.shade600),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 16),

                // Repayment History
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repayment History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      if (repaymentProvider.repayments.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No repayments made yet',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        )
                      else
                        ...repaymentProvider.repayments.map((repayment) {
                          return _buildRepaymentItem(repayment);
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildRepaymentItem(LoanRepaymentModel repayment) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy h:mm a');

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(repayment.amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  repayment.paymentMethod.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Principal: ${currencyFormat.format(repayment.principalAmount)}',
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
              ),
              SizedBox(width: 12),
              Text(
                'Interest: ${currencyFormat.format(repayment.interestAmount)}',
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            dateFormat.format(repayment.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.5)),
          ),
          if (repayment.notes != null) ...[
            SizedBox(height: 4),
            Text(
              repayment.notes!,
              style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }

  void _showRepaymentDialog() {
    final amountController = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.cash;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Make Repayment',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.orange.shade50,
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: selectedMethod,
                  decoration: InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.orange.shade50,
                  ),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedMethod = value);
                    }
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.orange.shade50,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter amount')),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter valid amount')),
                  );
                  return;
                }

                Navigator.pop(context);
                await _makeRepayment(amount, selectedMethod, notesController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeRepayment(
    double amount,
    PaymentMethod method,
    String notes,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final repaymentProvider = context.read<RepaymentProvider>();

    if (authProvider.currentUser == null) return;

    // Simple split: 80% principal, 20% interest (can be improved)
    final principalAmount = amount * 0.8;
    final interestAmount = amount * 0.2;

    final success = await repaymentProvider.makeRepayment(
      loanId: widget.loan.id,
      amount: amount,
      principalAmount: principalAmount,
      interestAmount: interestAmount,
      paymentMethod: method,
      notes: notes.isEmpty ? null : notes,
      createdBy: authProvider.currentUser!.id,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Repayment recorded successfully!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record repayment'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }
}
