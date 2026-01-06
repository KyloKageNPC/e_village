import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/loan_guarantor_model.dart';
import '../providers/guarantor_provider.dart';
import '../services/guarantor_service.dart';

class GuarantorRequestDetailScreen extends StatefulWidget {
  final LoanGuarantorModel request;

  const GuarantorRequestDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<GuarantorRequestDetailScreen> createState() =>
      _GuarantorRequestDetailScreenState();
}

class _GuarantorRequestDetailScreenState
    extends State<GuarantorRequestDetailScreen> {
  final GuarantorService _guarantorService = GuarantorService();
  List<LoanGuarantorModel> _otherGuarantors = [];
  bool _loadingOthers = true;

  @override
  void initState() {
    super.initState();
    _loadOtherGuarantors();
  }

  Future<void> _loadOtherGuarantors() async {
    try {
      final others = await _guarantorService.getOtherGuarantors(
        loanId: widget.request.loanId,
        currentGuarantorId: widget.request.guarantorId,
      );
      setState(() {
        _otherGuarantors = others;
        _loadingOthers = false;
      });
    } catch (e) {
      setState(() => _loadingOthers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');
    final request = widget.request;

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text(
          'Guarantee Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with borrower info
            _buildBorrowerHeader(request),
            const SizedBox(height: 16),

            // Loan information
            _buildLoanInformation(request, currencyFormat),
            const SizedBox(height: 16),

            // Your liability
            _buildYourLiability(request, currencyFormat),
            const SizedBox(height: 16),

            // Borrower track record
            _buildBorrowerTrackRecord(request, currencyFormat, dateFormat),
            const SizedBox(height: 16),

            // Other guarantors
            _buildOtherGuarantors(),
            const SizedBox(height: 16),

            // Action buttons
            if (request.isPending) _buildActionButtons(request),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowerHeader(LoanGuarantorModel request) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        ),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: request.borrowerAvatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      request.borrowerAvatarUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildInitialsAvatar(request);
                      },
                    ),
                  )
                : _buildInitialsAvatar(request),
          ),
          const SizedBox(height: 16),
          Text(
            request.borrowerDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (request.borrowerPhone != null) ...[
            const SizedBox(height: 4),
            Text(
              request.borrowerPhone!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Requesting Guarantee',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(LoanGuarantorModel request) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.orange.shade300,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          request.borrowerInitials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoanInformation(
    LoanGuarantorModel request,
    NumberFormat currencyFormat,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Loan Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildInfoRow('Amount', currencyFormat.format(request.loanAmount ?? 0)),
          const SizedBox(height: 12),
          _buildInfoRow('Purpose', request.loanPurposeDisplay),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Duration',
            '${request.loanDurationMonths ?? 0} months',
          ),
          if (request.monthlyPayment != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Monthly Payment',
              currencyFormat.format(request.monthlyPayment),
            ),
          ],
          if (request.totalRepayable != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Total Repayable',
              currencyFormat.format(request.totalRepayable),
              highlight: true,
            ),
          ],
          if (request.loanInterestRate != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Interest Rate',
              '${request.loanInterestRate}%',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYourLiability(
    LoanGuarantorModel request,
    NumberFormat currencyFormat,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Your Liability',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'If the borrower defaults, you will be responsible for:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              currencyFormat.format(request.yourLiability),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This amount will be deducted from your savings account',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade800,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowerTrackRecord(
    LoanGuarantorModel request,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Borrower Track Record',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrackRecordStat(
                'Total Loans',
                '${request.borrowerTotalLoans ?? 0}',
                Icons.receipt_long,
                Colors.blue,
              ),
              _buildTrackRecordStat(
                'Completed',
                '${request.borrowerCompletedLoans ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildTrackRecordStat(
                'Success Rate',
                _calculateSuccessRate(request),
                Icons.trending_up,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          if (request.borrowerCurrentSavings != null)
            _buildInfoRow(
              'Current Savings',
              currencyFormat.format(request.borrowerCurrentSavings),
            ),
          if (request.borrowerMemberSince != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Member Since',
              dateFormat.format(request.borrowerMemberSince!),
            ),
          ],
          if (request.borrowerAttendanceRate != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Attendance Rate',
              '${(request.borrowerAttendanceRate! * 100).toStringAsFixed(0)}%',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackRecordStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  String _calculateSuccessRate(LoanGuarantorModel request) {
    if (request.borrowerTotalLoans == null || request.borrowerTotalLoans == 0) {
      return 'N/A';
    }
    final rate =
        (request.borrowerCompletedLoans! / request.borrowerTotalLoans!) * 100;
    return '${rate.toStringAsFixed(0)}%';
  }

  Widget _buildOtherGuarantors() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.purple.shade600, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Other Guarantors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          if (_loadingOthers)
            const Center(child: CircularProgressIndicator())
          else if (_otherGuarantors.isEmpty)
            const Center(
              child: Text(
                'You are the only guarantor for this loan',
                style: TextStyle(
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            for (var guarantor in _otherGuarantors)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getStatusColor(guarantor.status),
                      child: Text(
                        guarantor.guarantorName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guarantor.guarantorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Guarantees: \$${guarantor.guaranteedAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(guarantor.status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        guarantor.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(guarantor.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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

  Color _getStatusColor(GuarantorStatus status) {
    switch (status) {
      case GuarantorStatus.approved:
        return Colors.green;
      case GuarantorStatus.rejected:
        return Colors.red;
      case GuarantorStatus.pending:
        return Colors.orange;
    }
  }

  Widget _buildActionButtons(LoanGuarantorModel request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleReject(request),
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleApprove(request),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: highlight ? Colors.orange.shade700 : Colors.black,
          ),
        ),
      ],
    );
  }

  void _handleApprove(LoanGuarantorModel request) {
    _showResponseDialog(
      context: context,
      title: 'Approve Guarantee Request',
      message:
          'Are you sure you want to guarantee ${request.borrowerDisplayName}\'s loan of \$${request.loanAmount?.toStringAsFixed(2)}?',
      isApproval: true,
      onConfirm: (message) async {
        try {
          final provider = context.read<GuarantorProvider>();
          await provider.approveRequest(guarantorId: request.id, message: message);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Guarantee request approved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error approving request: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  void _handleReject(LoanGuarantorModel request) {
    _showResponseDialog(
      context: context,
      title: 'Reject Guarantee Request',
      message:
          'Are you sure you want to reject ${request.borrowerDisplayName}\'s guarantee request?',
      isApproval: false,
      onConfirm: (message) async {
        try {
          final provider = context.read<GuarantorProvider>();
          await provider.rejectRequest(guarantorId: request.id, message: message);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Guarantee request rejected'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error rejecting request: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  void _showResponseDialog({
    required BuildContext context,
    required String title,
    required String message,
    required bool isApproval,
    required Function(String?) onConfirm,
  }) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Optional Message',
                hintText: 'Add a message (optional)',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(
                  isApproval ? Icons.check_circle : Icons.info,
                  color: isApproval ? Colors.green : Colors.orange,
                ),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm(messageController.text.trim().isNotEmpty
                  ? messageController.text.trim()
                  : null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApproval ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}
