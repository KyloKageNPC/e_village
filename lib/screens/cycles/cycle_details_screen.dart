import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/cycle_model.dart';
import '../../providers/cycle_provider.dart';
import '../../providers/group_provider.dart';
import 'close_cycle_screen.dart';

/// Screen showing details of a specific cycle
class CycleDetailsScreen extends StatefulWidget {
  final CycleModel cycle;

  const CycleDetailsScreen({
    super.key,
    required this.cycle,
  });

  @override
  State<CycleDetailsScreen> createState() => _CycleDetailsScreenState();
}

class _CycleDetailsScreenState extends State<CycleDetailsScreen> {
  late CycleModel _cycle;

  @override
  void initState() {
    super.initState();
    _cycle = widget.cycle;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCycleDetails();
    });
  }

  Future<void> _loadCycleDetails() async {
    final cycleProvider = context.read<CycleProvider>();
    final updatedCycle = await cycleProvider.getCycleById(_cycle.id);
    if (updatedCycle != null && mounted) {
      setState(() {
        _cycle = updatedCycle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'K ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    final isActive = _cycle.status == CycleStatus.active;
    final canManage = _canManageCycle();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _getStatusColor(_cycle.status),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _cycle.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getStatusColor(_cycle.status),
                      _getStatusColor(_cycle.status).withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        _getStatusIcon(_cycle.status),
                        size: 60,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _cycle.status.displayName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (isActive && canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) => _handleMenuAction(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'close',
                      child: ListTile(
                        leading: Icon(Icons.stop_circle, color: Colors.orange),
                        title: Text('Close Cycle'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'distribute',
                      child: ListTile(
                        leading: Icon(Icons.account_balance_wallet, color: Colors.green),
                        title: Text('Distribute Profits'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  _buildSummaryCards(currencyFormat),

                  const SizedBox(height: 24),

                  // Duration Info
                  _buildDurationCard(dateFormat),

                  const SizedBox(height: 24),

                  // Financial Summary
                  _buildFinancialSummaryCard(currencyFormat),

                  const SizedBox(height: 24),

                  // Progress Card
                  _buildProgressCard(),

                  const SizedBox(height: 24),

                  // Cycle Settings Card
                  _buildSettingsCard(currencyFormat),

                  if (_cycle.notes != null && _cycle.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildNotesCard(),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isActive && canManage
          ? FloatingActionButton.extended(
              onPressed: () => _closeCycle(),
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.stop_circle, color: Colors.white),
              label: const Text(
                'Close Cycle',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildSummaryCards(NumberFormat currencyFormat) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Contributions',
            currencyFormat.format(_cycle.totalContributions),
            Icons.savings,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Loans Disbursed',
            currencyFormat.format(_cycle.totalLoansDisbursed),
            Icons.account_balance,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard(DateFormat dateFormat) {
    final durationDays = _cycle.actualEndDate != null
        ? _cycle.actualEndDate!.difference(_cycle.startDate).inDays
        : DateTime.now().difference(_cycle.startDate).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.indigo, size: 20),
              SizedBox(width: 8),
              Text(
                'Cycle Duration',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(_cycle.startDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _cycle.actualEndDate != null ? 'End Date' : 'Expected End',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cycle.actualEndDate != null
                          ? dateFormat.format(_cycle.actualEndDate!)
                          : dateFormat.format(_cycle.expectedEndDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timelapse, color: Colors.indigo, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$durationDays days',
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_cycle.isActive && _cycle.daysRemaining > 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_bottom, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${_cycle.daysRemaining} days left',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_cycle.isOverdue) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Financial Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFinancialRow('Opening Balance', currencyFormat.format(_cycle.openingFundBalance), Colors.grey),
          const SizedBox(height: 8),
          _buildFinancialRow('Total Contributions', currencyFormat.format(_cycle.totalContributions), Colors.blue),
          const SizedBox(height: 8),
          _buildFinancialRow('Interest Earned', currencyFormat.format(_cycle.totalInterestEarned), Colors.green),
          const SizedBox(height: 8),
          _buildFinancialRow('Penalties Collected', currencyFormat.format(_cycle.totalPenaltiesCollected), Colors.orange),
          const SizedBox(height: 8),
          _buildFinancialRow('Loans Disbursed', currencyFormat.format(_cycle.totalLoansDisbursed), Colors.red),
          const SizedBox(height: 8),
          _buildFinancialRow('Expenses', currencyFormat.format(_cycle.totalExpenses), Colors.red),
          const Divider(height: 24),
          _buildFinancialRow('Net Profit', currencyFormat.format(_cycle.netProfit), Colors.purple, isBold: true),
          const SizedBox(height: 8),
          _buildFinancialRow('Fund Available', currencyFormat.format(_cycle.totalFundAvailable), Colors.indigo, isBold: true),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.teal, size: 20),
              SizedBox(width: 8),
              Text(
                'Cycle Progress',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                '${_cycle.progressPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _cycle.progressPercentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _cycle.isOverdue ? Colors.red : Colors.teal,
            ),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            _cycle.isActive
                ? (_cycle.isOverdue
                    ? 'This cycle is overdue. Consider closing it.'
                    : '${_cycle.daysRemaining} days remaining')
                : 'Cycle completed',
            style: TextStyle(
              color: _cycle.isOverdue ? Colors.red : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, color: Colors.blueGrey, size: 20),
              SizedBox(width: 8),
              Text(
                'Cycle Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Contribution Amount',
            _cycle.contributionAmount != null
                ? currencyFormat.format(_cycle.contributionAmount)
                : 'Variable',
          ),
          _buildSettingItem(
            'Max Loan Multiplier',
            '${_cycle.maxLoanMultiplier}x savings',
          ),
          _buildSettingItem(
            'Interest Rate',
            '${_cycle.defaultInterestRate}%',
          ),
          _buildSettingItem(
            'Late Payment Penalty',
            '${_cycle.latePaymentPenalty}%',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _cycle.notes!,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CycleStatus status) {
    switch (status) {
      case CycleStatus.active:
        return Colors.indigo.shade600;
      case CycleStatus.closed:
        return Colors.orange.shade600;
      case CycleStatus.archived:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(CycleStatus status) {
    switch (status) {
      case CycleStatus.active:
        return Icons.play_circle;
      case CycleStatus.closed:
        return Icons.check_circle;
      case CycleStatus.archived:
        return Icons.archive;
    }
  }

  bool _canManageCycle() {
    final groupProvider = context.read<GroupProvider>();

    if (groupProvider.selectedGroup == null) {
      return false;
    }

    // Check if user can manage group (admin or treasurer)
    return groupProvider.canManageGroup || groupProvider.isTreasurer;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'close':
        _closeCycle();
        break;
      case 'distribute':
        _distributeProfit();
        break;
    }
  }

  void _closeCycle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CloseCycleScreen(cycle: _cycle),
      ),
    );
  }

  void _distributeProfit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Distribute Profits'),
        content: const Text(
          'This will calculate and distribute profits to all members based on their contribution shares. This action cannot be undone.\n\nDo you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Distribute'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final cycleProvider = context.read<CycleProvider>();
      final success = await cycleProvider.distributeProfits(_cycle.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Profits distributed successfully!'
                  : cycleProvider.error ?? 'Failed to distribute profits',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _loadCycleDetails();
        }
      }
    }
  }
}
