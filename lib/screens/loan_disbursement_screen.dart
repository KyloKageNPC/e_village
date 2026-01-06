import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/loan_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/payment_provider.dart';
import '../config/pawapay_config.dart';
import '../widgets/mmo_selector.dart';
import '../models/loan_model.dart';
import '../models/pawapay_models.dart';

/// Screen for treasurers to disburse approved loans via mobile money
class LoanDisbursementScreen extends StatefulWidget {
  final LoanModel loan;

  const LoanDisbursementScreen({
    super.key,
    required this.loan,
  });

  @override
  State<LoanDisbursementScreen> createState() => _LoanDisbursementScreenState();
}

class _LoanDisbursementScreenState extends State<LoanDisbursementScreen> {
  final _phoneController = TextEditingController();
  
  String? _selectedProvider;
  String? _phoneError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadBorrowerDetails();
  }

  Future<void> _loadBorrowerDetails() async {
    // Try to get borrower's phone number from their profile
    // For now, we'll let the treasurer enter it
    // In a real app, you'd fetch this from the borrower's profile
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_phoneController.text.isEmpty) {
      setState(() => _phoneError = 'Please enter borrower\'s phone number');
      return false;
    }
    if (!PawapayConfig.isValidZambianPhone(_phoneController.text)) {
      setState(() => _phoneError = 'Invalid Zambian phone number');
      return false;
    }
    if (_selectedProvider == null) {
      _showMessage('Please select a mobile money provider', isError: true);
      return false;
    }
    setState(() => _phoneError = null);
    return true;
  }

  Future<void> _disburseLoan() async {
    if (!_validateForm()) return;

    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final loanProvider = context.read<LoanProvider>();

    if (authProvider.currentUser == null || groupProvider.selectedGroup == null) {
      _showMessage('Session error. Please try again.', isError: true);
      return;
    }

    // Confirm disbursement
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    try {
      // Initiate mobile money payout to borrower
      final transaction = await paymentProvider.disburseLoan(
        userId: widget.loan.borrowerId,
        groupId: groupProvider.selectedGroup!.id,
        loanId: widget.loan.id,
        amount: widget.loan.amount,
        phoneNumber: _phoneController.text,
        provider: _selectedProvider!,
      );

      if (transaction != null) {
        // Show processing dialog
        if (mounted) {
          _showProcessingDialog(transaction, loanProvider);
        }
      } else {
        setState(() => _isSubmitting = false);
        _showMessage(paymentProvider.error ?? 'Disbursement failed', isError: true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showMessage('Error: ${e.toString()}', isError: true);
    }
  }

  Future<bool> _showConfirmationDialog() async {
    final currencyFormat = NumberFormat.currency(symbol: 'K ', decimalDigits: 2);
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirm Disbursement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to disburse:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currencyFormat.format(widget.loan.amount),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('To: ${_phoneController.text}'),
                  Text('Provider: ${_getProviderName(_selectedProvider)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone. The money will be sent immediately to the borrower\'s mobile wallet.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Send'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showProcessingDialog(MobileMoneyTransaction transaction, LoanProvider loanProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DisbursementProcessingDialog(
        transaction: transaction,
        loan: widget.loan,
        onComplete: (success) async {
          Navigator.of(dialogContext).pop();
          setState(() => _isSubmitting = false);

          if (success) {
            // Update loan status to disbursed
            await loanProvider.disburseLoan(
              loanId: widget.loan.id,
            );

            _showMessage('Loan disbursed successfully!');
            
            // Pop back to previous screen
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          } else {
            _showMessage('Disbursement failed. Please try again.', isError: true);
          }
        },
        onCancel: () {
          Navigator.of(dialogContext).pop();
          setState(() => _isSubmitting = false);
          context.read<PaymentProvider>().resetFlow();
        },
      ),
    );
  }

  String _getProviderName(String? code) {
    switch (code) {
      case 'MTN_MOMO_ZMB':
        return 'MTN Mobile Money';
      case 'AIRTEL_ZMB':
        return 'Airtel Money';
      case 'ZAMTEL_ZMB':
        return 'Zamtel Kwacha';
      default:
        return code ?? 'Unknown';
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'K ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text(
          'Disburse Loan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.payments, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Loan Amount to Disburse',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(widget.loan.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Purpose: ${widget.loan.purpose}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Loan Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loan Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Interest Rate', '${widget.loan.interestRate}%'),
                  _buildDetailRow('Duration', '${widget.loan.durationMonths} months'),
                  _buildDetailRow(
                    'Total Repayable',
                    currencyFormat.format(
                      widget.loan.amount * (1 + widget.loan.interestRate / 100),
                    ),
                  ),
                  _buildDetailRow(
                    'Approved On',
                    widget.loan.approvedAt != null
                        ? dateFormat.format(widget.loan.approvedAt!)
                        : 'N/A',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recipient Details Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Send to Borrower',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Provider Selection
                  MmoSelector(
                    selectedProvider: _selectedProvider,
                    onProviderSelected: (provider) {
                      setState(() => _selectedProvider = provider);
                    },
                    enabled: !_isSubmitting,
                  ),

                  const SizedBox(height: 16),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Borrower\'s Phone Number',
                      hintText: '097XXXXXXX',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      errorText: _phoneError,
                    ),
                    onChanged: (value) {
                      final detected = PawapayConfig.detectProviderFromPhone(value);
                      if (detected != null) {
                        setState(() => _selectedProvider = detected);
                      }
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Warning Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please verify the phone number belongs to the borrower before disbursing. Money sent cannot be reversed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Disburse Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _disburseLoan,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSubmitting ? 'Processing...' : 'Disburse Loan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.green.shade300,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sandbox Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'SANDBOX MODE: No real money will be transferred. This is for testing purposes only.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
      ),
    );
  }
}

/// Dialog showing disbursement processing status
class _DisbursementProcessingDialog extends StatelessWidget {
  final MobileMoneyTransaction transaction;
  final LoanModel loan;
  final Function(bool success) onComplete;
  final VoidCallback onCancel;

  const _DisbursementProcessingDialog({
    required this.transaction,
    required this.loan,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, _) {
        final flowState = paymentProvider.flowState;
        final currentTx = paymentProvider.currentTransaction;

        // Auto-handle completion
        if (flowState == PaymentFlowState.completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onComplete(true);
          });
        } else if (flowState == PaymentFlowState.failed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onComplete(false);
          });
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _buildStatusIcon(flowState),
              const SizedBox(height: 20),
              Text(
                _getStatusTitle(flowState),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStatusMessage(flowState, currentTx),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (flowState == PaymentFlowState.processing ||
                  flowState == PaymentFlowState.awaitingConfirmation) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  backgroundColor: Colors.green.shade100,
                  valueColor: AlwaysStoppedAnimation(Colors.green.shade600),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(PaymentFlowState state) {
    switch (state) {
      case PaymentFlowState.processing:
      case PaymentFlowState.awaitingConfirmation:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.green),
              ),
            ),
          ),
        );
      case PaymentFlowState.completed:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        );
      case PaymentFlowState.failed:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error, color: Colors.red, size: 50),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _getStatusTitle(PaymentFlowState state) {
    switch (state) {
      case PaymentFlowState.processing:
        return 'Processing Disbursement';
      case PaymentFlowState.awaitingConfirmation:
        return 'Sending Loan...';
      case PaymentFlowState.completed:
        return 'Loan Disbursed!';
      case PaymentFlowState.failed:
        return 'Disbursement Failed';
      default:
        return 'Processing...';
    }
  }

  String _getStatusMessage(PaymentFlowState state, MobileMoneyTransaction? tx) {
    switch (state) {
      case PaymentFlowState.processing:
        return 'Initiating loan transfer...';
      case PaymentFlowState.awaitingConfirmation:
        return 'Sending K${loan.amount.toStringAsFixed(2)} to borrower\'s mobile wallet...';
      case PaymentFlowState.completed:
        return 'The loan has been successfully sent to the borrower!';
      case PaymentFlowState.failed:
        return 'The transfer could not be completed. Please try again.';
      default:
        return 'Please wait...';
    }
  }
}
