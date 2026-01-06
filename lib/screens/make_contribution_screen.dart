import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/savings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/payment_provider.dart';
import '../config/pawapay_config.dart';
import '../widgets/mmo_selector.dart';
import '../services/group_alert_service.dart';
import 'contribution_history_screen.dart';

class MakeContributionScreen extends StatefulWidget {
  const MakeContributionScreen({super.key});

  @override
  State<MakeContributionScreen> createState() => _MakeContributionScreenState();
}

class _MakeContributionScreenState extends State<MakeContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _useMobileMoney = true; // Default to mobile money
  String? _selectedProvider;
  String? _phoneError;

  // Pre-set amount options (in ZMW)
  final List<double> _quickAmounts = [50, 100, 200, 500, 1000, 2000];
  double? _selectedAmount;

  @override
  void initState() {
    super.initState();
    _loadSavingsAccount();
    _loadUserMobileMoneyDetails();
  }

  Future<void> _loadSavingsAccount() async {
    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final savingsProvider = context.read<SavingsProvider>();

    if (authProvider.currentUser != null && groupProvider.selectedGroup != null) {
      await savingsProvider.loadSavingsAccount(
        groupId: groupProvider.selectedGroup!.id,
        userId: authProvider.currentUser!.id,
      );
    }
  }

  Future<void> _loadUserMobileMoneyDetails() async {
    // Pre-fill phone number from user profile if available
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userProfile?.phoneNumber != null) {
      _phoneController.text = authProvider.userProfile!.phoneNumber!;
      // Auto-detect provider
      final detected = PawapayConfig.detectProviderFromPhone(_phoneController.text);
      if (detected != null) {
        setState(() {
          _selectedProvider = detected;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  void _onProviderSelected(String? provider) {
    setState(() {
      _selectedProvider = provider;
    });
  }

  void _onPhoneChanged(String? detected) {
    if (detected != null) {
      setState(() {
        _selectedProvider = detected;
      });
    }
  }

  bool _validateMobileMoneyDetails() {
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

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();

    if (authProvider.currentUser == null) {
      _showMessage('Please log in to make a contribution', isError: true);
      return;
    }

    if (groupProvider.selectedGroup == null) {
      _showMessage('Please select a village group first', isError: true);
      return;
    }

    final amount = double.parse(_amountController.text);

    if (_useMobileMoney) {
      if (!_validateMobileMoneyDetails()) {
        return;
      }
      await _submitMobileMoneyContribution(
        userId: authProvider.currentUser!.id,
        groupId: groupProvider.selectedGroup!.id,
        amount: amount,
      );
    } else {
      await _submitDirectContribution(
        userId: authProvider.currentUser!.id,
        groupId: groupProvider.selectedGroup!.id,
        amount: amount,
      );
    }
  }

  Future<void> _submitMobileMoneyContribution({
    required String userId,
    required String groupId,
    required double amount,
  }) async {
    setState(() => _isSubmitting = true);

    final paymentProvider = context.read<PaymentProvider>();

    final transaction = await paymentProvider.makeContribution(
      userId: userId,
      groupId: groupId,
      amount: amount,
      phoneNumber: _phoneController.text,
      provider: _selectedProvider!,
      description: _descriptionController.text.isEmpty
          ? 'Group contribution'
          : _descriptionController.text,
    );

    if (transaction != null) {
      // Show payment status dialog
      if (mounted) {
        await _showPaymentStatusDialog();
      }
    } else {
      setState(() => _isSubmitting = false);
      _showMessage(
        paymentProvider.error ?? 'Failed to initiate payment',
        isError: true,
      );
    }
  }

  Future<void> _showPaymentStatusDialog() async {
    // Capture provider before async gap
    final paymentProvider = context.read<PaymentProvider>();
    final savingsProvider = context.read<SavingsProvider>();
    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final groupAlertService = GroupAlertService();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PaymentStatusDialog(),
    );

    // Check final status and update UI
    setState(() => _isSubmitting = false);

    if (paymentProvider.flowState == PaymentFlowState.completed) {
      // IMPORTANT: Record the contribution in the transactions table
      // This updates the savings balance and creates transaction history
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount > 0 && 
          authProvider.currentUser != null && 
          groupProvider.selectedGroup != null) {
        await savingsProvider.makeContribution(
          groupId: groupProvider.selectedGroup!.id,
          userId: authProvider.currentUser!.id,
          amount: amount,
          description: _descriptionController.text.isEmpty
              ? 'Mobile money contribution'
              : _descriptionController.text,
        );
        
        // Send alert to group chat for transparency
        await groupAlertService.sendContributionAlert(
          groupId: groupProvider.selectedGroup!.id,
          memberName: authProvider.userProfile?.fullName ?? 'A member',
          amount: amount,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
        );
      }
      
      // Reload savings account to show updated balance
      await _loadSavingsAccount();
      _showMessage('Contribution successful!', isError: false);
      
      // Reset form
      _amountController.clear();
      _descriptionController.clear();
      setState(() => _selectedAmount = null);
      
      // Navigate back after delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else if (paymentProvider.flowState == PaymentFlowState.failed) {
      _showMessage(
        paymentProvider.error ?? 'Payment failed',
        isError: true,
      );
    }

    // Reset payment flow
    paymentProvider.resetFlow();
  }

  Future<void> _submitDirectContribution({
    required String userId,
    required String groupId,
    required double amount,
  }) async {
    setState(() => _isSubmitting = true);

    final savingsProvider = context.read<SavingsProvider>();
    final authProvider = context.read<AuthProvider>();
    final groupAlertService = GroupAlertService();

    final success = await savingsProvider.makeContribution(
      groupId: groupId,
      userId: userId,
      amount: amount,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      // Send alert to group chat for transparency
      await groupAlertService.sendContributionAlert(
        groupId: groupId,
        memberName: authProvider.userProfile?.fullName ?? 'A member',
        amount: amount,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );
      
      _showMessage('Contribution recorded!', isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      _showMessage(
        savingsProvider.errorMessage ?? 'Failed to record contribution',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      appBar: AppBar(
        title: const Text(
          'Make Contribution',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContributionHistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Balance Card
            _buildBalanceCard(),

            // Contribution Form
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Method Toggle
                    _buildPaymentMethodToggle(),
                    const SizedBox(height: 20),

                    // Quick Amounts
                    const Text(
                      'Quick Amounts (ZMW)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickAmounts(),
                    const SizedBox(height: 24),

                    // Amount Input
                    _buildLabel('Contribution Amount'),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        hint: 'Enter custom amount',
                        prefix: const Text(
                          'K ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _selectedAmount = null);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Mobile Money Details (if enabled)
                    if (_useMobileMoney) ...[
                      _buildMobileMoneySection(),
                      const SizedBox(height: 20),
                    ],

                    // Description
                    _buildLabel('Description (Optional)'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        hint: 'e.g., Weekly contribution, Extra savings',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Consumer<SavingsProvider>(
      builder: (context, savingsProvider, _) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade600,
                Colors.green.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Current Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'K ${savingsProvider.currentBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Total Contributions',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'K ${savingsProvider.totalContributions.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Column(
                    children: [
                      Text(
                        'Withdrawals',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'K ${savingsProvider.totalWithdrawals.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useMobileMoney = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _useMobileMoney
                      ? Colors.orange.shade600
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_android,
                      color: _useMobileMoney ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mobile Money',
                      style: TextStyle(
                        color: _useMobileMoney ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useMobileMoney = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_useMobileMoney
                      ? Colors.orange.shade600
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.money,
                      color: !_useMobileMoney ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Record Cash',
                      style: TextStyle(
                        color: !_useMobileMoney ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _quickAmounts.map((amount) {
        final isSelected = _selectedAmount == amount;
        return GestureDetector(
          onTap: () => _selectQuickAmount(amount),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange.shade600 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.orange.shade600
                    : Colors.black.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: Text(
              'K$amount',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileMoneySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text(
                'Mobile Money Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // MMO Provider Selector
          MmoSelector(
            selectedProvider: _selectedProvider,
            onProviderSelected: _onProviderSelected,
            enabled: !_isSubmitting,
          ),
          const SizedBox(height: 16),

          // Phone Number Input
          MobileMoneyPhoneInput(
            controller: _phoneController,
            selectedProvider: _selectedProvider,
            onProviderDetected: _onPhoneChanged,
            errorText: _phoneError,
            enabled: !_isSubmitting,
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, 
                    color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You will receive a prompt on your phone to confirm the payment.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitContribution,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _useMobileMoney ? 'Pay with Mobile Money' : 'Record Contribution',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefix: prefix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

/// Payment Status Dialog
/// 
/// Shows real-time payment status while waiting for confirmation
class _PaymentStatusDialog extends StatelessWidget {
  const _PaymentStatusDialog();

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, _) {
        final flowState = paymentProvider.flowState;
        final isProcessing = flowState == PaymentFlowState.processing ||
            flowState == PaymentFlowState.awaitingConfirmation;
        final isComplete = flowState == PaymentFlowState.completed;
        final isFailed = flowState == PaymentFlowState.failed;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              
              // Status Icon/Animation
              if (isProcessing)
                Column(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation(
                          Colors.orange.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      flowState == PaymentFlowState.awaitingConfirmation
                          ? 'Check Your Phone'
                          : 'Processing...',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      flowState == PaymentFlowState.awaitingConfirmation
                          ? 'Enter your PIN on your phone to confirm the payment'
                          : 'Please wait while we process your payment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                )
              else if (isComplete)
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 60,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your contribution has been recorded',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                )
              else if (isFailed)
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error,
                        size: 60,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Payment Failed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      paymentProvider.error ?? 'Please try again',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Close button (only when terminal state)
              if (isComplete || isFailed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isComplete
                          ? Colors.green.shade600
                          : Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isComplete ? 'Done' : 'Close'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
