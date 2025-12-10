import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/savings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
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
  bool _isSubmitting = false;

  // Pre-set amount options
  final List<double> _quickAmounts = [10, 20, 50, 100, 200, 500];
  double? _selectedAmount;

  @override
  void initState() {
    super.initState();
    _loadSavingsAccount();
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

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final savingsProvider = context.read<SavingsProvider>();

    if (authProvider.currentUser == null) {
      _showMessage('Please log in to make a contribution', isError: true);
      return;
    }

    if (groupProvider.selectedGroup == null) {
      _showMessage('Please select a village group first', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await savingsProvider.makeContribution(
      groupId: groupProvider.selectedGroup!.id,
      userId: authProvider.currentUser!.id,
      amount: double.parse(_amountController.text),
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      _showMessage('Contribution successful!', isError: false);
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      _showMessage(
        savingsProvider.errorMessage ?? 'Failed to make contribution',
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
        title: Text(
          'Make Contribution',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContributionHistoryScreen(),
                ),
              );
            },
            icon: Icon(Icons.history, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Balance Card
            Consumer<SavingsProvider>(
              builder: (context, savingsProvider, _) {
                return Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(20),
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
                        offset: Offset(0, 4),
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
                      SizedBox(height: 8),
                      Text(
                        '\$${savingsProvider.currentBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
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
                              SizedBox(height: 4),
                              Text(
                                '\$${savingsProvider.totalContributions.toStringAsFixed(2)}',
                                style: TextStyle(
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
                              SizedBox(height: 4),
                              Text(
                                '\$${savingsProvider.totalWithdrawals.toStringAsFixed(2)}',
                                style: TextStyle(
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
            ),

            // Contribution Form
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Amounts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickAmounts.map((amount) {
                        final isSelected = _selectedAmount == amount;
                        return GestureDetector(
                          onTap: () => _selectQuickAmount(amount),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orange.shade600
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orange.shade600
                                    : Colors.black.withValues(alpha: 0.1),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '\$$amount',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24),
                    _buildLabel('Contribution Amount'),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        hint: 'Enter custom amount',
                        prefix: Text(
                          '\$ ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedAmount = null;
                        });
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
                    SizedBox(height: 20),
                    _buildLabel('Description (Optional)'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        hint: 'e.g., Weekly contribution, Extra savings',
                      ),
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitContribution,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Make Contribution',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
