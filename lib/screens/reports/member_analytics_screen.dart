import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/analytics_provider.dart';
import '../../providers/group_provider.dart';

class MemberAnalyticsScreen extends StatefulWidget {
  final String memberId;
  const MemberAnalyticsScreen({super.key, required this.memberId});

  @override
  State<MemberAnalyticsScreen> createState() => _MemberAnalyticsScreenState();
}

class _MemberAnalyticsScreenState extends State<MemberAnalyticsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final analytics = context.read<AnalyticsProvider>();
    final groupProvider = context.read<GroupProvider>();
    final gid = groupProvider.selectedGroup?.id;
    if (gid != null && analytics.memberAnalytics == null && !analytics.isLoadingMember) {
      analytics.loadMemberAnalytics(memberId: widget.memberId, groupId: gid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(
          'Member Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: analytics.isLoadingMember
            ? Center(child: CircularProgressIndicator(color: Colors.orange.shade600))
            : analytics.errorMessage != null
                ? Center(child: Text('Error: ${analytics.errorMessage}'))
                : _buildMember(analytics),
      ),
    );
  }

  Widget _buildMember(AnalyticsProvider analytics) {
    final m = analytics.memberAnalytics;
    if (m == null) return const Center(child: Text('No data'));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.memberName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Total Contributions: \$${m.totalContributions.toStringAsFixed(2)}'),
          Text('Outstanding Balance: \$${m.outstandingBalance.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          const Text('Contribution History:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...m.contributionHistory.map((c) => ListTile(
                title: Text('\$${c.amount.toStringAsFixed(2)}'),
                subtitle: Text(c.date.toIso8601String()),
              )),
          const SizedBox(height: 12),
          const Text('Loan History:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...m.loanHistory.map((l) => ListTile(
                title: Text('\$${l.amount.toStringAsFixed(2)}'),
                subtitle: Text('Status: ${l.status}'),
                trailing: Text('Balance: \$${l.balance.toStringAsFixed(2)}'),
              )),
        ],
      ),
    );
  }
}
