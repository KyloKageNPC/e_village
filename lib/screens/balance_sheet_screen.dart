import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/loan_model.dart';
import '../providers/group_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/loan_provider.dart';
import '../services/report_exporter.dart';

/// Balance Sheet Screen showing group's financial position
/// Assets = Liabilities + Equity
class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  bool _isLoading = true;
  DateTime _asOfDate = DateTime.now();

  // Balance sheet data
  double _cashOnHand = 0;
  double _loansReceivable = 0;
  double _interestReceivable = 0;
  double _totalAssets = 0;

  double _memberSavings = 0;
  double _pendingWithdrawals = 0;
  double _totalLiabilities = 0;

  double _retainedEarnings = 0;
  double _currentPeriodProfit = 0;
  double _totalEquity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBalanceSheetData();
    });
  }

  Future<void> _loadBalanceSheetData() async {
    setState(() => _isLoading = true);

    try {
      final groupProvider = context.read<GroupProvider>();
      final cycleProvider = context.read<CycleProvider>();
      final savingsProvider = context.read<SavingsProvider>();
      final loanProvider = context.read<LoanProvider>();

      if (groupProvider.selectedGroup == null) {
        setState(() => _isLoading = false);
        return;
      }

      final groupId = groupProvider.selectedGroup!.id;

      // Load data from providers
      await savingsProvider.loadGroupSavingsAccounts(groupId: groupId);
      await loanProvider.loadGroupLoans(groupId: groupId);

      // Calculate Assets
      // Total member savings from group savings accounts
      _memberSavings = savingsProvider.groupSavingsAccounts.fold(
        0.0,
        (sum, account) => sum + account.balance,
      );

      // Calculate outstanding loans and interest from disbursed loans
      final outstandingLoans = loanProvider.loans.where(
        (loan) => loan.status == LoanStatus.disbursed,
      ).toList();
      
      _loansReceivable = outstandingLoans.fold(
        0.0,
        (sum, loan) => sum + loan.remainingBalance,
      );
      
      // Interest receivable = Total repayable - Principal - Amount already paid
      _interestReceivable = outstandingLoans.fold(
        0.0,
        (sum, loan) {
          final totalRepayable = loan.totalRepayable ?? loan.amount;
          final interestPortion = totalRepayable - loan.amount;
          final interestPaid = loan.amountRepaid > loan.amount 
              ? loan.amountRepaid - loan.amount 
              : 0.0;
          return sum + (interestPortion - interestPaid).clamp(0, double.infinity);
        },
      );

      // Calculate from active cycle if available
      if (cycleProvider.activeCycle != null) {
        final cycle = cycleProvider.activeCycle!;
        _cashOnHand = cycle.totalFundAvailable;
        _currentPeriodProfit = cycle.netProfit;
      } else {
        _cashOnHand = _memberSavings - _loansReceivable;
      }

      _totalAssets = _cashOnHand + _loansReceivable + _interestReceivable;

      // Calculate Liabilities
      // Member savings are liabilities (owed back to members)
      _pendingWithdrawals = 0; // Could be tracked in future
      _totalLiabilities = _memberSavings + _pendingWithdrawals;

      // Calculate Equity
      // Retained earnings from previous cycles
      _retainedEarnings = _calculateRetainedEarnings(cycleProvider);
      _totalEquity = _retainedEarnings + _currentPeriodProfit;

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading balance sheet: $e');
      setState(() => _isLoading = false);
    }
  }

  double _calculateRetainedEarnings(CycleProvider cycleProvider) {
    // Sum up net profits from all closed cycles
    return cycleProvider.closedCycles.fold(
      0.0,
      (sum, cycle) => sum + cycle.netProfit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'K ', decimalDigits: 2);
    final dateFormat = DateFormat('MMMM dd, yyyy');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Balance Sheet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportBalanceSheet,
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBalanceSheetData,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            )
          : RefreshIndicator(
              onRefresh: _loadBalanceSheetData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with date
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.indigo.shade700,
                            Colors.indigo.shade500,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer<GroupProvider>(
                            builder: (context, gp, _) => Text(
                              gp.selectedGroup?.name ?? 'Village Group',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'As of ${dateFormat.format(_asOfDate)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Summary Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  'Total Assets',
                                  currencyFormat.format(_totalAssets),
                                  Icons.account_balance,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Total Equity',
                                  currencyFormat.format(_totalEquity),
                                  Icons.trending_up,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Assets Section
                          _buildSection(
                            'Assets',
                            Icons.account_balance_wallet,
                            Colors.blue,
                            [
                              _buildLineItem('Cash on Hand', _cashOnHand, currencyFormat),
                              _buildLineItem('Loans Receivable', _loansReceivable, currencyFormat),
                              _buildLineItem('Interest Receivable', _interestReceivable, currencyFormat),
                            ],
                            _totalAssets,
                            currencyFormat,
                          ),

                          const SizedBox(height: 16),

                          // Liabilities Section
                          _buildSection(
                            'Liabilities',
                            Icons.credit_card,
                            Colors.orange,
                            [
                              _buildLineItem('Member Savings (Due to Members)', _memberSavings, currencyFormat),
                              if (_pendingWithdrawals > 0)
                                _buildLineItem('Pending Withdrawals', _pendingWithdrawals, currencyFormat),
                            ],
                            _totalLiabilities,
                            currencyFormat,
                          ),

                          const SizedBox(height: 16),

                          // Equity Section
                          _buildSection(
                            'Equity',
                            Icons.pie_chart,
                            Colors.green,
                            [
                              _buildLineItem('Retained Earnings', _retainedEarnings, currencyFormat),
                              _buildLineItem('Current Period Profit', _currentPeriodProfit, currencyFormat),
                            ],
                            _totalEquity,
                            currencyFormat,
                          ),

                          const SizedBox(height: 24),

                          // Balance Check Card
                          _buildBalanceCheckCard(currencyFormat),

                          const SizedBox(height: 24),

                          // Key Ratios
                          _buildRatiosCard(),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> items,
    double total,
    NumberFormat currencyFormat,
  ) {
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
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: items,
            ),
          ),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total $title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  currencyFormat.format(total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(String label, double value, NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            currencyFormat.format(value),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCheckCard(NumberFormat currencyFormat) {
    final liabilitiesPlusEquity = _totalLiabilities + _totalEquity;
    final isBalanced = (_totalAssets - liabilitiesPlusEquity).abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isBalanced ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBalanced ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isBalanced ? Icons.check_circle : Icons.warning,
                color: isBalanced ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                isBalanced ? 'Balance Sheet Balanced' : 'Balance Sheet Imbalanced',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isBalanced ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Assets'),
              Text(
                currencyFormat.format(_totalAssets),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Liabilities + Equity'),
              Text(
                currencyFormat.format(liabilitiesPlusEquity),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (!isBalanced) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Difference'),
                Text(
                  currencyFormat.format(_totalAssets - liabilitiesPlusEquity),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatiosCard() {
    // Calculate key financial ratios
    final loanToSavingsRatio = _memberSavings > 0 
        ? (_loansReceivable / _memberSavings * 100) 
        : 0.0;
    final profitMargin = _totalAssets > 0 
        ? (_currentPeriodProfit / _totalAssets * 100) 
        : 0.0;

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
              Icon(Icons.analytics, color: Colors.indigo, size: 24),
              SizedBox(width: 12),
              Text(
                'Key Ratios',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRatioItem(
            'Loan to Savings Ratio',
            '${loanToSavingsRatio.toStringAsFixed(1)}%',
            loanToSavingsRatio <= 80 ? Colors.green : Colors.orange,
            'Recommended: Below 80%',
          ),
          const SizedBox(height: 12),
          _buildRatioItem(
            'Return on Assets',
            '${profitMargin.toStringAsFixed(1)}%',
            profitMargin >= 5 ? Colors.green : Colors.orange,
            'Healthy: Above 5%',
          ),
        ],
      ),
    );
  }

  Widget _buildRatioItem(String label, String value, Color color, String note) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                note,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOfDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _asOfDate) {
      setState(() {
        _asOfDate = picked;
      });
      _loadBalanceSheetData();
    }
  }

  Future<void> _exportBalanceSheet() async {
    final groupProvider = context.read<GroupProvider>();

    try {
      await ReportExporter.exportBalanceSheet(
        groupName: groupProvider.selectedGroup?.name ?? 'Village Group',
        asOfDate: _asOfDate,
        cashOnHand: _cashOnHand,
        loansReceivable: _loansReceivable,
        interestReceivable: _interestReceivable,
        totalAssets: _totalAssets,
        memberSavings: _memberSavings,
        pendingWithdrawals: _pendingWithdrawals,
        totalLiabilities: _totalLiabilities,
        retainedEarnings: _retainedEarnings,
        currentPeriodProfit: _currentPeriodProfit,
        totalEquity: _totalEquity,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }
}
