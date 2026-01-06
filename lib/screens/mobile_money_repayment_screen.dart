import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/repayment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/payment_provider.dart';
import '../config/pawapay_config.dart';
import '../widgets/mmo_selector.dart';
import '../models/loan_model.dart';
import '../models/loan_repayment_model.dart';
import '../models/pawapay_models.dart';

/// Screen for making loan repayments via mobile money
class MobileMoneyRepaymentScreen extends StatefulWidget {
  final LoanModel loan;
  final double remainingBalance;

  const MobileMoneyRepaymentScreen({
    super.key,
    required this.loan,
    required this.remainingBalance,
  });

  @override
  State<MobileMoneyRepaymentScreen> createState() => _MobileMoneyRepaymentScreenState();
}

class _MobileMoneyRepaymentScreenState extends State<MobileMoneyRepaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _selectedProvider;
  String? _phoneError;
  bool _isSubmitting = false;

  // Quick repayment amounts
  late List<double> _quickAmounts;

  @override
  void initState() {
    super.initState();
    _initQuickAmounts();
    _loadUserPhone();
  }

  void _initQuickAmounts() {
    final remaining = widget.remainingBalance;
    final monthlyPayment = remaining / widget.loan.durationMonths;
    
    _quickAmounts = [
      monthlyPayment.roundToDouble(),
      (monthlyPayment * 2).roundToDouble(),
      (remaining / 2).roundToDouble(),
      remaining,
    ].where((amount) => amount > 0 && amount <= remaining).toSet().toList()
      ..sort();
  }

  void _loadUserPhone() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userProfile?.phoneNumber != null) {
      _phoneController.text = authProvider.userProfile!.phoneNumber!;
      final detected = PawapayConfig.detectProviderFromPhone(_phoneController.text);
      if (detected != null) {
        setState(() => _selectedProvider = detected);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;

    if (_phoneController.text.isEmpty) {
      setState(() => _phoneError = 'Please enter phone number');
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

  Future<void> _submitRepayment() async {
    if (!_validateForm()) return;

    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    if (authProvider.currentUser == null || groupProvider.selectedGroup == null) {
      _showMessage('Session error. Please try again.', isError: true);
      return;
    }

    final amount = double.parse(_amountController.text);

    if (amount > widget.remainingBalance) {
      _showMessage(
        'Amount exceeds remaining balance of K${widget.remainingBalance.toStringAsFixed(2)}',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Initiate mobile money deposit (user pays to group)
      final transaction = await paymentProvider.makeLoanRepayment(
        userId: authProvider.currentUser!.id,
        groupId: groupProvider.selectedGroup!.id,
        loanId: widget.loan.id,
        amount: amount,
        phoneNumber: _phoneController.text,
        provider: _selectedProvider!,
      );

      if (transaction != null) {
        // Show processing dialog
        if (mounted) {
          _showProcessingDialog(transaction, amount);
        }
      } else {
        setState(() => _isSubmitting = false);
        _showMessage(paymentProvider.error ?? 'Payment failed', isError: true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showMessage('Error: ${e.toString()}', isError: true);
    }
  }

  void _showProcessingDialog(MobileMoneyTransaction transaction, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RepaymentProcessingDialog(
        transaction: transaction,
        amount: amount,
        onComplete: (success) async {
          Navigator.of(dialogContext).pop();
          setState(() => _isSubmitting = false);

          if (success) {
            // Record the repayment in the database
            final authProvider = context.read<AuthProvider>();
            final repaymentProvider = context.read<RepaymentProvider>();

            // Calculate principal/interest split (simplified)
            final interestPortion = amount * (widget.loan.interestRate / 100) / 12;
            final principalPortion = amount - interestPortion;

            await repaymentProvider.makeRepayment(
              loanId: widget.loan.id,
              amount: amount,
              principalAmount: principalPortion > 0 ? principalPortion : amount,
              interestAmount: interestPortion > 0 ? interestPortion : 0,
              paymentMethod: PaymentMethod.mobileMoney,
              notes: 'Mobile money payment via ${_getProviderName(_selectedProvider)}',
              createdBy: authProvider.currentUser!.id,
            );

            _showMessage('Repayment successful!');
            
            // Pop back to loan details
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          } else {
            _showMessage('Payment failed. Please try again.', isError: true);
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

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text(
          'Loan Repayment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loan Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade700],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Remaining Balance',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              currencyFormat.format(widget.remainingBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Original Loan',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                          ),
                          Text(
                            currencyFormat.format(widget.loan.amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Amount Selection
              const Text(
                'Quick Select Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickAmounts.map((amount) {
                  final isFullPayment = amount == widget.remainingBalance;
                  return GestureDetector(
                    onTap: () => _selectQuickAmount(amount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isFullPayment
                            ? Colors.green.shade100
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFullPayment
                              ? Colors.green.shade400
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'K ${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isFullPayment
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isFullPayment)
                            Text(
                              'Pay off',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Custom Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Repayment Amount (ZMW)',
                  prefixText: 'K ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > widget.remainingBalance) {
                    return 'Amount exceeds remaining balance';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Mobile Money Section
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
                        Icon(Icons.phone_android, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Pay via Mobile Money',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                        labelText: 'Your Phone Number',
                        hintText: '097XXXXXXX',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        errorText: _phoneError,
                        helperText: 'You will receive a payment prompt on this number',
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

              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will receive a USSD prompt to confirm payment. Enter your mobile money PIN to complete.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitRepayment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.payment),
                  label: Text(
                    _isSubmitting ? 'Processing...' : 'Pay Now',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.orange.shade300,
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
                        'SANDBOX MODE: No real money will be deducted. This is for testing purposes only.',
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
      ),
    );
  }
}

/// Dialog showing repayment processing status
class _RepaymentProcessingDialog extends StatelessWidget {
  final MobileMoneyTransaction transaction;
  final double amount;
  final Function(bool success) onComplete;
  final VoidCallback onCancel;

  const _RepaymentProcessingDialog({
    required this.transaction,
    required this.amount,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, _) {
        final flowState = paymentProvider.flowState;

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
                _getStatusMessage(flowState),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (flowState == PaymentFlowState.processing ||
                  flowState == PaymentFlowState.awaitingConfirmation) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  backgroundColor: Colors.orange.shade100,
                  valueColor: AlwaysStoppedAnimation(Colors.orange.shade600),
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
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.orange),
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
        return 'Processing Payment';
      case PaymentFlowState.awaitingConfirmation:
        return 'Waiting for Confirmation';
      case PaymentFlowState.completed:
        return 'Payment Successful!';
      case PaymentFlowState.failed:
        return 'Payment Failed';
      default:
        return 'Processing...';
    }
  }

  String _getStatusMessage(PaymentFlowState state) {
    switch (state) {
      case PaymentFlowState.processing:
        return 'Initiating payment request...';
      case PaymentFlowState.awaitingConfirmation:
        return 'Please check your phone and enter your PIN to confirm the payment of K${amount.toStringAsFixed(2)}';
      case PaymentFlowState.completed:
        return 'Your repayment of K${amount.toStringAsFixed(2)} has been received!';
      case PaymentFlowState.failed:
        return 'The payment could not be processed. Please try again.';
      default:
        return 'Please wait...';
    }
  }
}
