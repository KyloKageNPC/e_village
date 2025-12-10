import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/savings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../models/transaction_model.dart';

class ContributionHistoryScreen extends StatefulWidget {
  const ContributionHistoryScreen({super.key});

  @override
  State<ContributionHistoryScreen> createState() => _ContributionHistoryScreenState();
}

class _ContributionHistoryScreenState extends State<ContributionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final savingsProvider = context.read<SavingsProvider>();

    if (authProvider.currentUser != null) {
      await savingsProvider.loadContributionHistory(
        userId: authProvider.currentUser!.id,
        groupId: groupProvider.selectedGroup?.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      appBar: AppBar(
        title: Text(
          'Contribution History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Consumer<SavingsProvider>(
        builder: (context, savingsProvider, _) {
          if (savingsProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.orange.shade600,
              ),
            );
          }

          if (savingsProvider.contributionHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.orange.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Contributions Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your contribution history will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.shade600,
                      Colors.orange.shade400,
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
                      'Total Contributions',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '\$${savingsProvider.totalContributions.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${savingsProvider.contributionHistory.length} contributions made',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // History List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: savingsProvider.contributionHistory.length,
                  itemBuilder: (context, index) {
                    final contribution = savingsProvider.contributionHistory[index];
                    return _buildContributionCard(contribution);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContributionCard(TransactionModel contribution) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.savings,
                color: Colors.green.shade600,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contribution.description ?? 'Contribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    dateFormat.format(contribution.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    timeFormat.format(contribution.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${contribution.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 4),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    contribution.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
