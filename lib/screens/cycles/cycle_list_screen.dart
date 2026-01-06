import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/cycle_model.dart';
import '../../providers/cycle_provider.dart';
import '../../providers/group_provider.dart';
import 'create_cycle_screen.dart';
import 'cycle_details_screen.dart';

/// Screen showing all cycles for a group
class CycleListScreen extends StatefulWidget {
  const CycleListScreen({super.key});

  @override
  State<CycleListScreen> createState() => _CycleListScreenState();
}

class _CycleListScreenState extends State<CycleListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCycles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCycles() async {
    final groupProvider = context.read<GroupProvider>();
    final cycleProvider = context.read<CycleProvider>();

    if (groupProvider.selectedGroup != null) {
      await cycleProvider.loadCycles(groupProvider.selectedGroup!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Cycle Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.play_circle_outline)),
            Tab(text: 'Closed', icon: Icon(Icons.check_circle_outline)),
            Tab(text: 'Archived', icon: Icon(Icons.archive_outlined)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCycles,
          ),
        ],
      ),
      body: Consumer<CycleProvider>(
        builder: (context, cycleProvider, _) {
          if (cycleProvider.isLoading && cycleProvider.cycles.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            );
          }

          if (cycleProvider.error != null && cycleProvider.cycles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    cycleProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCycles,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildActiveTab(cycleProvider),
              _buildCycleList(cycleProvider.closedCycles, 'No closed cycles'),
              _buildCycleList(cycleProvider.archivedCycles, 'No archived cycles'),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<GroupProvider>(
        builder: (context, groupProvider, _) {
          if (!groupProvider.canApproveLoans) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _createNewCycle(context),
            backgroundColor: Colors.indigo,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'New Cycle',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTab(CycleProvider cycleProvider) {
    if (cycleProvider.activeCycle == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.loop,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Cycle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new cycle to begin tracking\ncontributions and loans',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Consumer<GroupProvider>(
              builder: (context, groupProvider, _) {
                if (!groupProvider.canApproveLoans) {
                  return const SizedBox.shrink();
                }
                return ElevatedButton.icon(
                  onPressed: () => _createNewCycle(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Start New Cycle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveCycleCard(cycleProvider.activeCycle!),
          const SizedBox(height: 24),
          if (cycleProvider.currentSummary != null) ...[
            _buildSummaryCard(cycleProvider.currentSummary!),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveCycleCard(CycleModel cycle) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewCycleDetails(cycle),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Cycle ${cycle.cycleNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (cycle.isOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'OVERDUE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  cycle.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${dateFormat.format(cycle.startDate)} - ${dateFormat.format(cycle.expectedEndDate)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: cycle.progressPercentage / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${cycle.progressPercentage.toStringAsFixed(0)}% complete',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${cycle.daysRemaining} days remaining',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(CycleSummary summary) {
    final currencyFormat = NumberFormat.currency(symbol: 'K ', decimalDigits: 2);

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
          const Text(
            'Cycle Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Total Contributions',
            currencyFormat.format(summary.totalContributions),
            Icons.savings,
            Colors.blue,
          ),
          _buildSummaryRow(
            'Loans Disbursed',
            currencyFormat.format(summary.totalLoansDisbursed),
            Icons.account_balance,
            Colors.orange,
          ),
          _buildSummaryRow(
            'Interest Earned',
            currencyFormat.format(summary.totalInterestEarned),
            Icons.trending_up,
            Colors.green,
          ),
          _buildSummaryRow(
            'Expenses',
            currencyFormat.format(summary.totalExpenses),
            Icons.receipt_long,
            Colors.red,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Net Profit',
            currencyFormat.format(summary.netProfit),
            Icons.account_balance_wallet,
            summary.netProfit >= 0 ? Colors.green : Colors.red,
            isTotal: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                '${summary.totalMembers}',
                'Members',
                Icons.people,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                '${summary.activeLoans}',
                'Active Loans',
                Icons.credit_card,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                currencyFormat.format(summary.outstandingLoans),
                'Outstanding',
                Icons.pending,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? color : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleList(List<CycleModel> cycles, String emptyMessage) {
    if (cycles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cycles.length,
      itemBuilder: (context, index) => _buildCycleCard(cycles[index]),
    );
  }

  Widget _buildCycleCard(CycleModel cycle) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'K ', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewCycleDetails(cycle),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cycle.status == CycleStatus.closed
                            ? Colors.green.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Cycle ${cycle.cycleNumber}',
                        style: TextStyle(
                          color: cycle.status == CycleStatus.closed
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Icon(
                      cycle.status == CycleStatus.closed
                          ? Icons.check_circle
                          : Icons.archive,
                      color: cycle.status == CycleStatus.closed
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  cycle.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFormat.format(cycle.startDate)} - ${dateFormat.format(cycle.actualEndDate ?? cycle.expectedEndDate)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Profit:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      currencyFormat.format(cycle.netProfit),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cycle.netProfit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createNewCycle(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCycleScreen()),
    );
  }

  void _viewCycleDetails(CycleModel cycle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CycleDetailsScreen(cycle: cycle),
      ),
    );
  }
}
