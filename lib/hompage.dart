import 'package:e_village/bottombutton.dart';
import 'package:e_village/components/popup.dart';
import 'package:e_village/top_caed.dart';
import 'package:e_village/transaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/group_provider.dart';
import 'providers/savings_provider.dart';
import 'screens/group/group_selection_screen.dart';
import 'screens/make_contribution_screen.dart';
import 'screens/loan_approvals_screen.dart';
import 'screens/meetings_list_screen.dart';
import 'screens/group/group_chat_screen.dart';
import 'screens/guarantor_requests_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/offline_indicator.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final groupProvider = context.read<GroupProvider>();
    final savingsProvider = context.read<SavingsProvider>();

    if (authProvider.currentUser != null) {
      // Restore group selection if there was a previously selected group
      if (groupProvider.selectedGroup == null && groupProvider.savedGroupId != null) {
        await groupProvider.restoreGroupSelection(authProvider.currentUser!.id);
      }

      await transactionProvider.loadUserTransactions(
        userId: authProvider.currentUser!.id,
        limit: 50,
      );

      // Load savings account if group is selected
      if (groupProvider.selectedGroup != null) {
        await savingsProvider.loadSavingsAccount(
          groupId: groupProvider.selectedGroup!.id,
          userId: authProvider.currentUser!.id,
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'E-Village Banking',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.orange.shade600,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              OfflineIndicator(),
            Consumer<TransactionProvider>(
              builder: (context, transProvider, _) {
                return TopNueCard(
                  balance: '\$${transProvider.balance.toStringAsFixed(2)}',
                  income: '\$${transProvider.income.toStringAsFixed(2)}',
                  expense: '\$${transProvider.expense.toStringAsFixed(2)}',
                );
              },
            ),
            SizedBox(height: 10),
            Consumer<GroupProvider>(
              builder: (context, groupProvider, _) {
                if (groupProvider.selectedGroup == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupSelectionScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade600,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade900),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap to select a village group',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.orange.shade900),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.orange.shade500],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.groups, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                groupProvider.selectedGroup!.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${groupProvider.groupMembers.length} members',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupSelectionScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.swap_horiz,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return Consumer<GroupProvider>(
                        builder: (context, groupProvider, _) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GuarantorRequestsScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_user,
                                        size: 14,
                                        color: Colors.purple.shade700,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Guarantor',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (groupProvider.canApproveLoans)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoanApprovalsScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.approval,
                                          size: 14,
                                          color: Colors.red.shade700,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Approvals',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (groupProvider.selectedGroup != null) ...[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MeetingsListScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.event,
                                          size: 14,
                                          color: Colors.blue.shade700,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Meetings',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GroupChatScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.chat,
                                          size: 14,
                                          color: Colors.green.shade700,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Chat',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 400,
              child: Consumer<TransactionProvider>(
                builder: (context, transProvider, _) {
                  if (transProvider.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.orange.shade600,
                      ),
                    );
                  }

                  if (transProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error loading transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              transProvider.errorMessage!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Retry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }

                  if (transProvider.transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Colors.orange.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start by creating your first transaction',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    itemCount: transProvider.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transProvider.transactions[index];
                      return MyTransactions(
                        transactionName: transaction.description ??
                            transaction.type.toString().split('.').last,
                        money: '\$${transaction.amount.toStringAsFixed(2)}',
                        expenseOrIncome: transaction.type.toString().contains('contribution') ||
                            transaction.type.toString().contains('disbursement') ||
                            transaction.type.toString().contains('repayment')
                            ? 'Income'
                            : 'Expense',
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MakeContributionScreen(),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: MyBottomButton(
                      color: Colors.green.shade600,
                      size: Size(60, 50),
                      icon: Icon(Icons.savings),
                    ),
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const PopupMenu(),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: MyBottomButton(
                      color: Colors.orange.shade600,
                      size: Size(70, 80),
                      icon: Icon(Icons.add),
                    ),
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupSelectionScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 30.0),
                    child: MyBottomButton(
                      color: Colors.orange.shade600,
                      size: Size(60, 50),
                      icon: Icon(Icons.groups),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
        ),
      ),
    );
  }
}