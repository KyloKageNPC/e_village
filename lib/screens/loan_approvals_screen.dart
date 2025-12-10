import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/loan_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../models/loan_model.dart';

class LoanApprovalsScreen extends StatefulWidget {
  const LoanApprovalsScreen({super.key});

  @override
  State<LoanApprovalsScreen> createState() => _LoanApprovalsScreenState();
}

class _LoanApprovalsScreenState extends State<LoanApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingLoans();
    });
  }

  Future<void> _loadPendingLoans() async {
    final groupProvider = context.read<GroupProvider>();
    final loanProvider = context.read<LoanProvider>();

    if (groupProvider.selectedGroup != null) {
      await loanProvider.loadGroupLoans(
        groupId: groupProvider.selectedGroup!.id,
        status: LoanStatus.pending,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();

    // Check if user has permission to approve loans
    if (!groupProvider.canApproveLoans) {
      return Scaffold(
        backgroundColor: Colors.orange.shade100,
        appBar: AppBar(
          title: Text(
            'Loan Approvals',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange.shade600,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.red.shade400,
              ),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Only Treasurers and Chairpersons can approve loans',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      appBar: AppBar(
        title: Text(
          'Loan Approvals',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Consumer<LoanProvider>(
        builder: (context, loanProvider, _) {
          if (loanProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.orange.shade600,
              ),
            );
          }

          if (loanProvider.loans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'All Caught Up!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No pending loan requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: loanProvider.loans.length,
            itemBuilder: (context, index) {
              final loan = loanProvider.loans[index];
              return _buildLoanRequestCard(loan);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoanRequestCard(LoanModel loan) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade500],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Loan Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dateFormat.format(loan.createdAt),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Loan Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      currencyFormat.format(loan.amount),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Purpose
                _buildInfoRow('Purpose', loan.purpose),
                SizedBox(height: 12),

                // Interest Details
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        'Interest Rate',
                        '${loan.interestRate}%',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoRow(
                        'Duration',
                        '${loan.durationMonths} months',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Interest Type
                _buildInfoRow(
                  'Interest Type',
                  loan.interestType.displayName,
                ),
                SizedBox(height: 12),

                // Total Repayment
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Repayment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        currencyFormat.format(loan.amount + (loan.amount * loan.interestRate / 100)),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectLoan(loan.id),
                        icon: Icon(Icons.close, size: 18),
                        label: Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade600),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveLoan(loan.id),
                        icon: Icon(Icons.check, size: 18),
                        label: Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Future<void> _approveLoan(String loanId) async {
    final authProvider = context.read<AuthProvider>();
    final loanProvider = context.read<LoanProvider>();

    if (authProvider.currentUser == null) return;

    final success = await loanProvider.approveLoan(
      loanId: loanId,
      approverId: authProvider.currentUser!.id,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loan approved successfully!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      await _loadPendingLoans();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve loan'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _rejectLoan(String loanId) async {
    final loanProvider = context.read<LoanProvider>();

    final success = await loanProvider.rejectLoan(loanId: loanId);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loan rejected'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      await _loadPendingLoans();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject loan'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }
}
