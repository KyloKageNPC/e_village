import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/loan_provider.dart';
import '../providers/group_provider.dart';
import '../models/loan_model.dart';
import 'loan_disbursement_screen.dart';

/// Screen showing approved loans that need to be disbursed
class PendingDisbursementsScreen extends StatefulWidget {
  const PendingDisbursementsScreen({super.key});

  @override
  State<PendingDisbursementsScreen> createState() => _PendingDisbursementsScreenState();
}

class _PendingDisbursementsScreenState extends State<PendingDisbursementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApprovedLoans();
    });
  }

  Future<void> _loadApprovedLoans() async {
    final groupProvider = context.read<GroupProvider>();
    final loanProvider = context.read<LoanProvider>();

    if (groupProvider.selectedGroup != null) {
      await loanProvider.loadGroupLoans(
        groupId: groupProvider.selectedGroup!.id,
        status: LoanStatus.approved,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();

    // Check if user has permission to disburse loans
    if (!groupProvider.canApproveLoans) {
      return Scaffold(
        backgroundColor: Colors.green.shade50,
        appBar: AppBar(
          title: const Text(
            'Pending Disbursements',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green.shade600,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.red.shade400),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only Treasurers can disburse loans',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text(
          'Pending Disbursements',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApprovedLoans,
          ),
        ],
      ),
      body: Consumer<LoanProvider>(
        builder: (context, loanProvider, _) {
          if (loanProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final approvedLoans = loanProvider.loans
              .where((loan) => loan.status == LoanStatus.approved)
              .toList();

          if (approvedLoans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All Caught Up!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No loans pending disbursement',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadApprovedLoans,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: approvedLoans.length,
              itemBuilder: (context, index) {
                return _buildLoanCard(approvedLoans[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoanCard(LoanModel loan) {
    final currencyFormat = NumberFormat.currency(symbol: 'K ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'APPROVED',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        currencyFormat.format(loan.amount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Approved On',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      loan.approvedAt != null
                          ? dateFormat.format(loan.approvedAt!)
                          : 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('Purpose', loan.purpose),
                const SizedBox(height: 8),
                _buildDetailRow('Interest Rate', '${loan.interestRate}%'),
                const SizedBox(height: 8),
                _buildDetailRow('Duration', '${loan.durationMonths} months'),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Total Repayable',
                  currencyFormat.format(
                    loan.amount * (1 + loan.interestRate / 100),
                  ),
                ),
                const SizedBox(height: 16),

                // Disburse Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoanDisbursementScreen(loan: loan),
                      ),
                    ).then((result) {
                      if (result == true) {
                        _loadApprovedLoans();
                      }
                    }),
                    icon: const Icon(Icons.send),
                    label: const Text('Disburse via Mobile Money'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
