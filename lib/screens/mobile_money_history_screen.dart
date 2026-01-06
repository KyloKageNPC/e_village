import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';
import '../models/pawapay_models.dart';

/// Screen showing user's mobile money transaction history
class MobileMoneyHistoryScreen extends StatefulWidget {
  const MobileMoneyHistoryScreen({super.key});

  @override
  State<MobileMoneyHistoryScreen> createState() => _MobileMoneyHistoryScreenState();
}

class _MobileMoneyHistoryScreenState extends State<MobileMoneyHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final authProvider = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    if (authProvider.currentUser != null) {
      await paymentProvider.loadTransactionHistory(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Mobile Money History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, _) {
          if (paymentProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          if (paymentProvider.transactionHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Transactions Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your mobile money transactions will appear here',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paymentProvider.transactionHistory.length,
              itemBuilder: (context, index) {
                final transaction = paymentProvider.transactionHistory[index];
                return _buildTransactionCard(transaction);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(MobileMoneyTransaction transaction) {
    final currencyFormat = NumberFormat.currency(symbol: 'K ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy h:mm a');

    final isDeposit = transaction.operationType == MobileMoneyOperationType.deposit;
    final isPayout = transaction.operationType == MobileMoneyOperationType.payout;

    // Determine icon and colors based on type and status
    IconData icon;
    Color iconBgColor;
    Color iconColor;
    String typeLabel;

    switch (transaction.referenceType) {
      case 'contribution':
        icon = Icons.savings;
        iconBgColor = Colors.blue.shade100;
        iconColor = Colors.blue.shade700;
        typeLabel = 'Contribution';
        break;
      case 'repayment':
        icon = Icons.payment;
        iconBgColor = Colors.orange.shade100;
        iconColor = Colors.orange.shade700;
        typeLabel = 'Loan Repayment';
        break;
      case 'disbursement':
        icon = Icons.account_balance;
        iconBgColor = Colors.green.shade100;
        iconColor = Colors.green.shade700;
        typeLabel = 'Loan Disbursement';
        break;
      case 'withdrawal':
        icon = Icons.money_off;
        iconBgColor = Colors.purple.shade100;
        iconColor = Colors.purple.shade700;
        typeLabel = 'Withdrawal';
        break;
      default:
        icon = isDeposit ? Icons.arrow_downward : Icons.arrow_upward;
        iconBgColor = Colors.grey.shade100;
        iconColor = Colors.grey.shade700;
        typeLabel = isDeposit ? 'Deposit' : 'Payout';
    }

    // Status badge color
    Color statusColor;
    String statusText = transaction.status.name.toUpperCase();
    switch (transaction.status) {
      case MobileMoneyTransactionStatus.completed:
        statusColor = Colors.green;
        statusText = 'COMPLETED';
        break;
      case MobileMoneyTransactionStatus.pending:
        statusColor = Colors.orange;
        statusText = 'PENDING';
        break;
      case MobileMoneyTransactionStatus.failed:
        statusColor = Colors.red;
        statusText = 'FAILED';
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),

              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          typeLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${isPayout ? '-' : '+'}${currencyFormat.format(transaction.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isPayout ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          transaction.phoneNumber,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(transaction.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(MobileMoneyTransaction transaction) {
    final currencyFormat = NumberFormat.currency(symbol: 'K ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy h:mm:ss a');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Text(
                'Transaction Details',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Amount
            Center(
              child: Text(
                currencyFormat.format(transaction.amount),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: transaction.operationType == MobileMoneyOperationType.payout
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildDetailItem('Type', transaction.referenceType?.toUpperCase() ?? 'N/A'),
            _buildDetailItem('Phone Number', transaction.phoneNumber),
            _buildDetailItem('Provider', _getProviderName(transaction.mmoProvider)),
            _buildDetailItem('Status', transaction.status.name.toUpperCase()),
            _buildDetailItem('Created', dateFormat.format(transaction.createdAt)),
            if (transaction.completedAt != null)
              _buildDetailItem('Completed', dateFormat.format(transaction.completedAt!)),
            if (transaction.providerTransactionId != null)
              _buildDetailItem('Provider Ref', transaction.providerTransactionId!),
            if (transaction.failureMessage != null)
              _buildDetailItem('Error', transaction.failureMessage!, isError: true),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isError ? Colors.red : Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getProviderName(String code) {
    switch (code) {
      case 'MTN_MOMO_ZMB':
        return 'MTN Mobile Money';
      case 'AIRTEL_ZMB':
        return 'Airtel Money';
      case 'ZAMTEL_ZMB':
        return 'Zamtel Kwacha';
      default:
        return code;
    }
  }
}
