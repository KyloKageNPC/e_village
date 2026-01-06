import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../utils/routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.orange.shade50,
        child: Column(
          children: [
            // Header
            Consumer2<AuthProvider, GroupProvider>(
              builder: (context, authProvider, groupProvider, _) {
                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.shade600,
                        Colors.orange.shade400,
                      ],
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      authProvider.userProfile?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ),
                  accountName: Text(
                    authProvider.userProfile?.fullName ?? 'User',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  accountEmail: Text(
                    groupProvider.selectedGroup?.name ?? 'No group selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                );
              },
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home,
                    title: 'Home',
                    route: AppRoutes.home,
                  ),
                  Divider(height: 1),
                  _buildSectionTitle('Finances'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.savings,
                    title: 'Make Contribution',
                    route: AppRoutes.makeContribution,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.history,
                    title: 'Contribution History',
                    route: AppRoutes.contributionHistory,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: 'My Loans',
                    route: AppRoutes.myLoans,
                  ),
                  Divider(height: 1),
                  _buildSectionTitle('Mobile Money'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.money_off,
                    title: 'Withdraw Savings',
                    route: AppRoutes.withdrawal,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.history,
                    title: 'Transaction History',
                    route: AppRoutes.mobileMoneyHistory,
                  ),
                  Consumer<GroupProvider>(
                    builder: (context, groupProvider, _) {
                      if (!groupProvider.canApproveLoans) {
                        return SizedBox.shrink();
                      }
                      return _buildDrawerItem(
                        context,
                        icon: Icons.send,
                        title: 'Disburse Loans',
                        route: AppRoutes.pendingDisbursements,
                      );
                    },
                  ),
                  Divider(height: 1),
                  _buildSectionTitle('Analytics'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.account_balance,
                    title: 'Balance Sheet',
                    route: AppRoutes.balanceSheet,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.analytics,
                    title: 'Financial Reports',
                    route: AppRoutes.financialReport,
                  ),
                  // 'My Analytics' needs to pass the current user's id as an argument
                  Builder(
                    builder: (ctx) {
                      final auth = Provider.of<AuthProvider>(ctx, listen: false);
                      final memberId = auth.userProfile?.id;
                      return ListTile(
                        leading: Icon(Icons.person),
                        title: Text('My Analytics'),
                        onTap: () {
                          Navigator.pop(ctx);
                          if (memberId != null && memberId.isNotEmpty) {
                            Navigator.pushNamed(ctx, AppRoutes.memberAnalytics, arguments: memberId);
                          } else {
                            Navigator.pushNamed(ctx, AppRoutes.memberAnalytics);
                          }
                        },
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.bar_chart,
                    title: 'Group Performance',
                    route: AppRoutes.groupPerformance,
                  ),
                  Divider(height: 1),
                  _buildSectionTitle('Group'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.groups,
                    title: 'Switch Group',
                    route: AppRoutes.groupSelection,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.chat,
                    title: 'Group Chat',
                    route: AppRoutes.groupChat,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.event,
                    title: 'Meetings',
                    route: AppRoutes.meetings,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.loop,
                    title: 'Cycles',
                    route: AppRoutes.cycles,
                  ),
                  Divider(height: 1),
                  _buildSectionTitle('Approvals'),
                  Consumer<GroupProvider>(
                    builder: (context, groupProvider, _) {
                      if (!groupProvider.canApproveLoans) {
                        return SizedBox.shrink();
                      }
                      return _buildDrawerItem(
                        context,
                        icon: Icons.approval,
                        title: 'Loan Approvals',
                        route: AppRoutes.loanApprovals,
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.verified_user,
                    title: 'Guarantor Requests',
                    route: AppRoutes.guarantorRequests,
                  ),
                ],
              ),
            ),

            Divider(height: 1),
            _buildSectionTitle('Account'),
            _buildDrawerItem(
              context,
              icon: Icons.settings,
              title: 'Profile & Settings',
              route: AppRoutes.profileSettings,
            ),

            // Logout Button
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red.shade600),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && context.mounted) {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                }
              },
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black.withValues(alpha: 0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isCurrentRoute = ModalRoute.of(context)?.settings.name == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isCurrentRoute ? Colors.orange.shade600 : Colors.black.withValues(alpha: 0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isCurrentRoute ? Colors.orange.shade600 : Colors.black.withValues(alpha: 0.9),
          fontWeight: isCurrentRoute ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isCurrentRoute,
      selectedTileColor: Colors.orange.shade100,
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isCurrentRoute) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
