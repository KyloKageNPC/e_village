import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/savings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/payment_provider.dart';
import '../config/pawapay_config.dart';
import '../widgets/mmo_selector.dart';
import '../models/pawapay_models.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isSubmitting = false;
  String? _selectedProvider;
  String? _phoneError;

  // Quick withdrawal amounts (in ZMW)
  final List<double> _quickAmounts = [100, 200, 500, 1000, 2000, 5000];
  double? _selectedAmount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final savingsProvider = context.read<SavingsProvider>();

    if (authProvider.currentUser != null && groupProvider.selectedGroup != null) {
      await savingsProvider.loadSavingsAccount(
        groupId: groupProvider.selectedGroup!.id,
        userId: authProvider.currentUser!.id,
      );
    }

    // Pre-fill phone from profile
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
      _selectedAmount = amount;
      _amountController.text = amount.toString();
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

  Future<void> _submitWithdrawal() async {
    if (!_validateForm()) return;

    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final savingsProvider = context.read<SavingsProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    if (authProvider.currentUser == null || groupProvider.selectedGroup == null) {
      _showMessage('Session error. Please try again.', isError: true);
      return;
    }

    final amount = double.parse(_amountController.text);

    // Check if user has sufficient balance
    if (amount > savingsProvider.currentBalance) {
      _showMessage(
        'Insufficient balance. Available: K${savingsProvider.currentBalance.toStringAsFixed(2)}',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Initiate mobile money payout
      final transaction = await paymentProvider.processWithdrawal(
        userId: authProvider.currentUser!.id,
        groupId: groupProvider.selectedGroup!.id,
        amount: amount,
        phoneNumber: _phoneController.text,
        provider: _selectedProvider!,
      );

      if (transaction != null) {
        // Show processing dialog
        if (mounted) {
          _showProcessingDialog(transaction);
        }
      } else {
        setState(() => _isSubmitting = false);
        _showMessage(paymentProvider.error ?? 'Withdrawal failed', isError: true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showMessage('Error: ${e.toString()}', isError: true);
    }
  }

  void _showProcessingDialog(MobileMoneyTransaction transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WithdrawalProcessingDialog(
        transaction: transaction,
        onComplete: (success) async {
          Navigator.of(context).pop();
          setState(() => _isSubmitting = false);

          if (success) {
            // Deduct from savings
            final authProvider = context.read<AuthProvider>();
            final groupProvider = context.read<GroupProvider>();
            final savingsProvider = context.read<SavingsProvider>();

            await savingsProvider.makeWithdrawal(
              groupId: groupProvider.selectedGroup!.id,
              userId: authProvider.currentUser!.id,
              amount: double.parse(_amountController.text),
              description: 'Mobile money withdrawal',
            );

            _showMessage('Withdrawal successful! Money sent to your mobile wallet.');
            _amountController.clear();
            _selectedAmount = null;
            await _loadData(); // Refresh balance
          } else {
            _showMessage('Withdrawal failed. Please try again.', isError: true);
          }
        },
        onCancel: () {
          Navigator.of(context).pop();
          setState(() => _isSubmitting = false);
          context.read<PaymentProvider>().resetFlow();
        },
      ),
    );
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
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text(
          'Withdraw Savings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<SavingsProvider>(
        builder: (context, savingsProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.purple.shade700],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(savingsProvider.currentBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
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
                      final isSelected = _selectedAmount == amount;
                      final isDisabled = amount > savingsProvider.currentBalance;
                      return GestureDetector(
                        onTap: isDisabled ? null : () => _selectQuickAmount(amount),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDisabled
                                ? Colors.grey.shade200
                                : isSelected
                                    ? Colors.purple.shade600
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDisabled
                                  ? Colors.grey.shade300
                                  : isSelected
                                      ? Colors.purple.shade600
                                      : Colors.purple.shade200,
                            ),
                          ),
                          child: Text(
                            'K ${amount.toInt()}',
                            style: TextStyle(
                              color: isDisabled
                                  ? Colors.grey
                                  : isSelected
                                      ? Colors.white
                                      : Colors.purple.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Custom Amount Input
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (ZMW)',
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
                      if (amount > savingsProvider.currentBalance) {
                        return 'Insufficient balance';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedAmount = double.tryParse(value);
                      });
                    },
                  ),

                  const SizedBox(height: 24),

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
                            Icon(Icons.phone_android, color: Colors.purple),
                            SizedBox(width: 8),
                            Text(
                              'Send to Mobile Money',
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
                            labelText: 'Phone Number',
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
                            'Funds will be sent directly to your mobile money wallet. Transaction may take a few minutes.',
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
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitWithdrawal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.purple.shade300,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Withdraw to Mobile Money',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
        },
      ),
    );
  }
}

/// Dialog showing withdrawal processing status
class _WithdrawalProcessingDialog extends StatelessWidget {
  final MobileMoneyTransaction transaction;
  final Function(bool success) onComplete;
  final VoidCallback onCancel;

  const _WithdrawalProcessingDialog({
    required this.transaction,
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
              
              // Status Icon
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
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              if (flowState == PaymentFlowState.processing ||
                  flowState == PaymentFlowState.awaitingConfirmation) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  backgroundColor: Colors.purple.shade100,
                  valueColor: AlwaysStoppedAnimation(Colors.purple.shade600),
                ),
              ],

              const SizedBox(height: 24),

              if (flowState == PaymentFlowState.processing ||
                  flowState == PaymentFlowState.awaitingConfirmation)
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
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
            color: Colors.purple.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.purple),
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
        return 'Processing Withdrawal';
      case PaymentFlowState.awaitingConfirmation:
        return 'Sending Money...';
      case PaymentFlowState.completed:
        return 'Withdrawal Successful!';
      case PaymentFlowState.failed:
        return 'Withdrawal Failed';
      default:
        return 'Processing...';
    }
  }

  String _getStatusMessage(PaymentFlowState state, MobileMoneyTransaction? tx) {
    switch (state) {
      case PaymentFlowState.processing:
        return 'Initiating transfer to your mobile money account...';
      case PaymentFlowState.awaitingConfirmation:
        return 'Transferring K${tx?.amount.toStringAsFixed(2) ?? ''} to ${tx?.phoneNumber ?? ''}';
      case PaymentFlowState.completed:
        return 'Money has been sent to your mobile wallet!';
      case PaymentFlowState.failed:
        return 'The transfer could not be completed. Please try again.';
      default:
        return 'Please wait...';
    }
  }
}
