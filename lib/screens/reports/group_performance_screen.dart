import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/analytics_provider.dart';
import '../../providers/group_provider.dart';

class GroupPerformanceScreen extends StatefulWidget {
  const GroupPerformanceScreen({super.key});

  @override
  State<GroupPerformanceScreen> createState() => _GroupPerformanceScreenState();
}

class _GroupPerformanceScreenState extends State<GroupPerformanceScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final analytics = context.read<AnalyticsProvider>();
    final groupProvider = context.read<GroupProvider>();
    final gid = groupProvider.selectedGroup?.id;
    if (gid != null && analytics.groupPerformance == null && !analytics.isLoadingGroup) {
      analytics.loadGroupPerformance(groupId: gid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(
          'Group Performance',
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
        child: analytics.isLoadingGroup
            ? Center(child: CircularProgressIndicator(color: Colors.orange.shade600))
            : analytics.errorMessage != null
                ? Center(child: Text('Error: ${analytics.errorMessage}'))
                : _buildGroup(analytics),
      ),
    );
  }

  Widget _buildGroup(AnalyticsProvider analytics) {
    final g = analytics.groupPerformance;
    if (g == null) return const Center(child: Text('No data'));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(g.groupName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Members: ${g.totalMembers}'),
          Text('Active: ${g.activeMembers}  Inactive: ${g.inactiveMembers}'),
          const SizedBox(height: 12),
          Text('Loan Default Rate: ${g.loanDefaultRate.toStringAsFixed(2)}%'),
          const SizedBox(height: 12),
          const Text('Contributions Over Time:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...g.contributionsOverTime.map((c) => ListTile(
                title: Text(c.month),
                trailing: Text('\$${c.amount.toStringAsFixed(2)}'),
              )),
          const SizedBox(height: 12),
          const Text('Attendance Trends:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...g.attendanceTrends.map((a) => ListTile(
                title: Text(a.meetingDate),
                subtitle: Text('Rate: ${a.rate.toStringAsFixed(2)}%'),
              )),
        ],
      ),
    );
  }
}
