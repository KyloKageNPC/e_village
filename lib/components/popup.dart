import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/loan_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../models/loan_model.dart';

class PopupMenu extends StatefulWidget {
  const PopupMenu({super.key});

  @override
  State<PopupMenu> createState() => _PopupMenuState();
}

class _PopupMenuState extends State<PopupMenu> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _interestRateController = TextEditingController(text: '10');
  final _durationController = TextEditingController(text: '6');

  InterestType _selectedInterestType = InterestType.flat;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _interestRateController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submitLoanRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final loanProvider = context.read<LoanProvider>();
    final groupProvider = context.read<GroupProvider>();

    if (authProvider.currentUser == null) {
      _showMessage('Please log in to request a loan', isError: true);
      return;
    }

    if (groupProvider.selectedGroup == null) {
      _showMessage('Please select a village group first', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await loanProvider.createLoanRequest(
      groupId: groupProvider.selectedGroup!.id,
      borrowerId: authProvider.currentUser!.id,
      amount: double.parse(_amountController.text),
      interestRate: double.parse(_interestRateController.text),
      durationMonths: int.parse(_durationController.text),
      purpose: _purposeController.text,
      interestType: _selectedInterestType,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      _showMessage('Loan request submitted successfully!', isError: false);
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      _showMessage(
        loanProvider.errorMessage ?? 'Failed to submit loan request',
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.shade600,
                    Colors.orange.shade500,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loan Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Fill in the details below',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Loan Amount'),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          hint: 'Enter amount',
                          prefix: Text('\$ ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
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
                      SizedBox(height: 16),
                      _buildLabel('Purpose'),
                      TextFormField(
                        controller: _purposeController,
                        maxLines: 2,
                        decoration: _inputDecoration(hint: 'Reason for loan'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the purpose';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Interest Rate (%)'),
                                TextFormField(
                                  controller: _interestRateController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(hint: '10'),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Duration (Months)'),
                                TextFormField(
                                  controller: _durationController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(hint: '6'),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildLabel('Interest Type'),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                        ),
                        child: RadioGroup<InterestType>(
                          groupValue: _selectedInterestType,
                          onChanged: (InterestType? value) {
                            if (value != null) {
                              setState(() => _selectedInterestType = value);
                            }
                          },
                          child: Column(
                            children: [
                              ListTile(
                                title: Text('Flat Rate'),
                                subtitle: Text('Same interest throughout', style: TextStyle(fontSize: 12)),
                                leading: Radio<InterestType>(
                                  value: InterestType.flat,
                                  activeColor: Colors.orange.shade600,
                                ),
                              ),
                              ListTile(
                                title: Text('Declining Balance'),
                                subtitle: Text('Interest on remaining balance', style: TextStyle(fontSize: 12)),
                                leading: Radio<InterestType>(
                                  value: InterestType.decliningBalance,
                                  activeColor: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitLoanRequest,
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
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Submit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
