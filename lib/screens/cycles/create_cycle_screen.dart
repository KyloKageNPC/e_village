import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cycle_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';

/// Screen for creating a new cycle
class CreateCycleScreen extends StatefulWidget {
  const CreateCycleScreen({super.key});

  @override
  State<CreateCycleScreen> createState() => _CreateCycleScreenState();
}

class _CreateCycleScreenState extends State<CreateCycleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contributionController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _interestRateController = TextEditingController(text: '10');
  final _loanMultiplierController = TextEditingController(text: '3');
  final _penaltyController = TextEditingController(text: '5');
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 180)); // 6 months
  int _durationMonths = 6;

  @override
  void initState() {
    super.initState();
    _setDefaultName();
  }

  void _setDefaultName() {
    final year = DateTime.now().year;
    final cycleProvider = context.read<CycleProvider>();
    final nextNumber = cycleProvider.cycles.length + 1;
    _nameController.text = 'Cycle $nextNumber - $year';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contributionController.dispose();
    _openingBalanceController.dispose();
    _interestRateController.dispose();
    _loanMultiplierController.dispose();
    _penaltyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateEndDate() {
    setState(() {
      _endDate = DateTime(_startDate.year, _startDate.month + _durationMonths, _startDate.day);
    });
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.indigo),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _updateEndDate();
      });
    }
  }

  Future<void> _createCycle() async {
    if (!_formKey.currentState!.validate()) return;

    final groupProvider = context.read<GroupProvider>();
    final cycleProvider = context.read<CycleProvider>();
    final authProvider = context.read<AuthProvider>();

    if (groupProvider.selectedGroup == null || authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group first')),
      );
      return;
    }

    final success = await cycleProvider.createCycle(
      groupId: groupProvider.selectedGroup!.id,
      name: _nameController.text.trim(),
      startDate: _startDate,
      expectedEndDate: _endDate,
      contributionAmount: _contributionController.text.isNotEmpty
          ? double.tryParse(_contributionController.text)
          : null,
      maxLoanMultiplier: double.tryParse(_loanMultiplierController.text) ?? 3.0,
      defaultInterestRate: double.tryParse(_interestRateController.text) ?? 10.0,
      latePaymentPenalty: double.tryParse(_penaltyController.text) ?? 5.0,
      openingBalance: double.tryParse(_openingBalanceController.text) ?? 0,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdBy: authProvider.currentUser!.id,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cycle created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cycleProvider.error ?? 'Failed to create cycle'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Start New Cycle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<CycleProvider>(
        builder: (context, cycleProvider, _) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cycle Info Card
                _buildCard(
                  title: 'Cycle Information',
                  icon: Icons.info_outline,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        'Cycle Name',
                        'e.g., Cycle 1 - 2024',
                        Icons.label,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a cycle name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            'Start Date',
                            dateFormat.format(_startDate),
                            _selectStartDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDurationDropdown(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: Colors.indigo.shade600),
                          const SizedBox(width: 12),
                          Text(
                            'End Date: ${dateFormat.format(_endDate)}',
                            style: TextStyle(
                              color: Colors.indigo.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Financial Settings Card
                _buildCard(
                  title: 'Financial Settings',
                  icon: Icons.account_balance_wallet,
                  children: [
                    TextFormField(
                      controller: _contributionController,
                      decoration: _inputDecoration(
                        'Recommended Contribution (Optional)',
                        'e.g., 500',
                        Icons.savings,
                        prefix: 'K ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _openingBalanceController,
                      decoration: _inputDecoration(
                        'Opening Balance (from previous cycle)',
                        'e.g., 10000',
                        Icons.account_balance,
                        prefix: 'K ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _interestRateController,
                            decoration: _inputDecoration(
                              'Interest Rate',
                              '10',
                              Icons.percent,
                              suffix: '% monthly',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final rate = double.tryParse(value);
                                if (rate == null || rate < 0 || rate > 100) {
                                  return 'Invalid rate';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _loanMultiplierController,
                            decoration: _inputDecoration(
                              'Max Loan Multiplier',
                              '3',
                              Icons.close,
                              suffix: 'x savings',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final mult = double.tryParse(value);
                                if (mult == null || mult < 1 || mult > 10) {
                                  return 'Invalid (1-10)';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _penaltyController,
                      decoration: _inputDecoration(
                        'Late Payment Penalty',
                        '5',
                        Icons.warning_amber,
                        suffix: '%',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Notes Card
                _buildCard(
                  title: 'Notes',
                  icon: Icons.note,
                  children: [
                    TextFormField(
                      controller: _notesController,
                      decoration: _inputDecoration(
                        'Additional Notes (Optional)',
                        'Any special rules or notes for this cycle...',
                        Icons.edit_note,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Create Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: cycleProvider.isLoading ? null : _createCycle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: cycleProvider.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Start Cycle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    String hint,
    IconData icon, {
    String? prefix,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      prefixText: prefix,
      suffixText: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.indigo.shade600, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildDateField(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _durationMonths,
          isExpanded: true,
          items: [3, 6, 9, 12]
              .map((months) => DropdownMenuItem(
                    value: months,
                    child: Text('$months months'),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _durationMonths = value;
                _updateEndDate();
              });
            }
          },
        ),
      ),
    );
  }
}
