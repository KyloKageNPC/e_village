import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/financial_report_model.dart';
import '../models/member_analytics_model.dart';
import '../models/group_performance_model.dart';
import 'supabase_service.dart';

class AnalyticsService {
  final SupabaseClient _client = SupabaseService.client;

  // =============================================
  // FINANCIAL REPORT METHODS
  // =============================================

  Future<FinancialReportModel> getFinancialReport({
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(Duration(days: 365));
      final end = endDate ?? DateTime.now();

      // Fetch all transactions for the period
      final transactionsResp = await _client
          .from('transactions')
          .select()
          .eq('group_id', groupId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      final transactionsList = (transactionsResp as List<dynamic>).cast<Map<String, dynamic>>();

      // Fetch loans for the period
      final loansResp = await _client
          .from('loans')
          .select()
          .eq('group_id', groupId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      final loansList = (loansResp as List<dynamic>).cast<Map<String, dynamic>>();

      // Calculate metrics
      double totalContributions = 0;
      double totalExpenses = 0;
      for (var tx in transactionsList) {
        final amount = (tx['amount'] as num).toDouble();
        if (tx['type'] == 'contribution' || tx['type'] == 'deposit') {
          totalContributions += amount;
        } else if (tx['type'] == 'expense' || tx['type'] == 'withdrawal') {
          totalExpenses += amount;
        }
      }

      double totalLoans = 0;
      double totalRepayments = 0;
      double outstandingLoans = 0;
      int activeLoans = 0;
      int completedLoans = 0;
      int defaultedLoans = 0;

      for (var loan in loansList) {
        final amount = (loan['amount'] as num).toDouble();
        final repaid = (loan['repaid_amount'] as num?)?.toDouble() ?? 0;
        final status = loan['status'] as String;

        totalLoans += amount;
        totalRepayments += repaid;

        if (status == 'active') {
          activeLoans++;
          outstandingLoans += (amount - repaid);
        } else if (status == 'completed') {
          completedLoans++;
        } else if (status == 'defaulted') {
          defaultedLoans++;
          outstandingLoans += (amount - repaid);
        }
      }

      final netIncome = totalContributions + totalRepayments - totalLoans - totalExpenses;
      final cashBalance = netIncome + outstandingLoans;

      // Get contribution trends (monthly)
      final contributionTrends = await _getMonthlyContributions(groupId, start, end);

      // Get top contributors
      final topContributors = await _getTopContributors(groupId, start, end);

      // Create loan portfolio
      final loanPortfolio = LoanPortfolio(
        totalLoans: loansList.length,
        activeLoans: activeLoans,
        completedLoans: completedLoans,
        defaultedLoans: defaultedLoans,
        averageLoanSize: loansList.isNotEmpty ? totalLoans / loansList.length : 0,
        repaymentRate: totalLoans > 0 ? (totalRepayments / totalLoans) * 100 : 0,
      );

      return FinancialReportModel(
        groupId: groupId,
        reportDate: DateTime.now(),
        totalContributions: totalContributions,
        totalLoans: totalLoans,
        totalRepayments: totalRepayments,
        totalExpenses: totalExpenses,
        netIncome: netIncome,
        outstandingLoans: outstandingLoans,
        cashBalance: cashBalance,
        contributionTrends: contributionTrends,
        topContributors: topContributors,
        loanPortfolio: loanPortfolio,
      );
    } catch (e, st) {
      developer.log('❌ Error fetching financial report: $e', error: e, stackTrace: st, name: 'AnalyticsService');
      rethrow;
    }
  }

  Future<List<MonthlyData>> _getMonthlyContributions(
    String groupId,
    DateTime start,
    DateTime end,
  ) async {
    try {
        final transactionsResponse = await _client
          .from('transactions')
          .select()
          .eq('group_id', groupId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: true);

        // Cast once and filter types locally (server-side 'in' helper not available on this SDK version)
        final transactionsList = (transactionsResponse as List<dynamic>).cast<Map<String, dynamic>>();
        final transactions = transactionsList.where((tx) => tx['type'] == 'contribution' || tx['type'] == 'deposit').toList();

      // Group by month
      final Map<String, double> monthlyTotals = {};
      final Map<String, DateTime> monthDates = {};

      for (var tx in transactions) {
        final date = DateTime.parse(tx['created_at'] as String);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        final amount = (tx['amount'] as num).toDouble();

        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
        monthDates[monthKey] = date;
      }

      return monthlyTotals.entries.map((entry) {
        return MonthlyData(
          month: entry.key,
          amount: entry.value,
          date: monthDates[entry.key]!,
        );
      }).toList();
    } catch (e, st) {
      developer.log('❌ Error fetching monthly contributions: $e', error: e, stackTrace: st, name: 'AnalyticsService');
      return [];
    }
  }

  Future<List<MemberContribution>> _getTopContributors(
    String groupId,
    DateTime start,
    DateTime end,
  ) async {
    try {
        final transactionsResponse = await _client
          .from('transactions')
          .select('user_id, amount, profiles(full_name)')
          .eq('group_id', groupId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

        final transactionsList = (transactionsResponse as List<dynamic>).cast<Map<String, dynamic>>();
        final transactions = transactionsList.where((tx) => tx['type'] == 'contribution' || tx['type'] == 'deposit').toList();

      // Group by member
      final Map<String, Map<String, dynamic>> memberTotals = {};

      for (var tx in transactions) {
        final userId = tx['user_id'] as String;
        final amount = (tx['amount'] as num).toDouble();
        final profile = tx['profiles'] as Map<String, dynamic>?;
        final name = profile?['full_name'] as String? ?? 'Unknown';

        if (!memberTotals.containsKey(userId)) {
          memberTotals[userId] = {
            'name': name,
            'total': 0.0,
            'count': 0,
          };
        }

        memberTotals[userId]!['total'] = (memberTotals[userId]!['total'] as double) + amount;
        memberTotals[userId]!['count'] = (memberTotals[userId]!['count'] as int) + 1;
      }

      // Convert to list and sort by total
      final contributors = memberTotals.entries.map((entry) {
        return MemberContribution(
          memberId: entry.key,
          memberName: entry.value['name'] as String,
          totalAmount: entry.value['total'] as double,
          contributionCount: entry.value['count'] as int,
        );
      }).toList();

      contributors.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      return contributors.take(10).toList();
    } catch (e, st) {
      developer.log('❌ Error fetching top contributors: $e', error: e, stackTrace: st, name: 'AnalyticsService');
      return [];
    }
  }

  // =============================================
  // MEMBER ANALYTICS METHODS
  // =============================================

  Future<MemberAnalyticsModel> getMemberAnalytics({
    required String memberId,
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(Duration(days: 365));
      final end = endDate ?? DateTime.now();

      // Fetch member profile
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', memberId)
          .single();

      // Fetch transactions
      final transactions = await _client
          .from('transactions')
          .select()
          .eq('user_id', memberId)
          .eq('group_id', groupId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false);

      // Fetch loans
      final loans = await _client
          .from('loans')
          .select()
          .eq('borrower_id', memberId)
          .eq('group_id', groupId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      // Fetch meeting attendance
      final attendanceRecords = await _client
          .from('meeting_attendance')
          .select('meeting_id, status')
          .eq('user_id', memberId);

      final meetings = await _client
          .from('meetings')
          .select('id')
          .eq('group_id', groupId)
          .gte('meeting_date', start.toIso8601String())
          .lte('meeting_date', end.toIso8601String());

      // Calculate metrics
      double totalContributions = 0;
      for (var tx in transactions as List) {
        if (tx['type'] == 'contribution' || tx['type'] == 'deposit') {
          totalContributions += (tx['amount'] as num).toDouble();
        }
      }

      double totalLoans = 0;
      double totalRepayments = 0;
      double outstandingBalance = 0;

      for (var loan in loans as List) {
        final amount = (loan['amount'] as num).toDouble();
        final repaid = (loan['repaid_amount'] as num?)?.toDouble() ?? 0;
        totalLoans += amount;
        totalRepayments += repaid;
        if (loan['status'] == 'active' || loan['status'] == 'defaulted') {
          outstandingBalance += (amount - repaid);
        }
      }

      final meetingsAttended = (attendanceRecords as List)
          .where((a) => a['status'] == 'present')
          .length;
      final totalMeetings = (meetings as List).length;
      final attendanceRate = totalMeetings > 0
          ? (meetingsAttended / totalMeetings) * 100
          : 0.0;

      // Calculate participation score (0-100)
      double participationScore = 0;
      participationScore += attendanceRate * 0.4; // 40% weight
      participationScore += (totalContributions > 0 ? 30 : 0); // 30% weight
      participationScore += ((loans as List).isNotEmpty ? 15 : 0); // 15% weight
      participationScore += (outstandingBalance == 0 ? 15 : 0); // 15% weight

      // Build contribution history
      final contributionHistory = (transactions as List).map((tx) {
        return ContributionHistory(
          id: tx['id'] as String,
          amount: (tx['amount'] as num).toDouble(),
          date: DateTime.parse(tx['created_at'] as String),
          type: tx['type'] as String,
        );
      }).toList();

      // Build loan history
      final loanHistory = (loans as List).map((loan) {
        return LoanHistory(
          id: loan['id'] as String,
          amount: (loan['amount'] as num).toDouble(),
          repaidAmount: (loan['repaid_amount'] as num?)?.toDouble() ?? 0,
          balance: (loan['amount'] as num).toDouble() - ((loan['repaid_amount'] as num?)?.toDouble() ?? 0),
          disbursedDate: DateTime.parse(loan['created_at'] as String),
          dueDate: loan['due_date'] != null
              ? DateTime.parse(loan['due_date'] as String)
              : null,
          status: loan['status'] as String,
        );
      }).toList();

      return MemberAnalyticsModel(
        memberId: memberId,
        memberName: profile['full_name'] as String? ?? 'Unknown',
        totalContributions: totalContributions,
        totalLoans: totalLoans,
        totalRepayments: totalRepayments,
        outstandingBalance: outstandingBalance,
        meetingsAttended: meetingsAttended,
        totalMeetings: totalMeetings,
        attendanceRate: attendanceRate,
        participationScore: participationScore,
        contributionHistory: contributionHistory,
        loanHistory: loanHistory,
      );
    } catch (e, st) {
      developer.log('❌ Error fetching member analytics: $e', error: e, stackTrace: st, name: 'AnalyticsService');
      rethrow;
    }
  }

  // =============================================
  // GROUP PERFORMANCE METHODS
  // =============================================

  Future<GroupPerformanceModel> getGroupPerformance({
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(Duration(days: 365));
      final end = endDate ?? DateTime.now();

      // Fetch group details
      final group = await _client
          .from('village_groups')
          .select()
          .eq('id', groupId)
          .single();

      // Fetch all members
      final members = await _client
          .from('group_members')
          .select('user_id, role, profiles(full_name)')
          .eq('group_id', groupId);

      final totalMembers = (members as List).length;

      // Calculate active vs inactive members
      final transactions = await _client
          .from('transactions')
          .select('user_id')
          .eq('group_id', groupId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      final activeUserIds = (transactions as List)
          .map((tx) => tx['user_id'] as String)
          .toSet();
      final activeMembers = activeUserIds.length;
      final inactiveMembers = totalMembers - activeMembers;

      // Get loan default rate
      final loans = await _client
          .from('loans')
          .select('status')
          .eq('group_id', groupId);

      final totalLoans = (loans as List).length;
      final defaultedLoans = (loans as List)
          .where((loan) => loan['status'] == 'defaulted')
          .length;
      final loanDefaultRate = totalLoans > 0
          ? (defaultedLoans / totalLoans) * 100
          : 0.0;

      // Get average attendance rate
      final meetings = await _client
          .from('meetings')
          .select('id')
          .eq('group_id', groupId)
          .gte('meeting_date', start.toIso8601String())
          .lte('meeting_date', end.toIso8601String());

      double averageAttendanceRate = 0;
      if ((meetings as List).isNotEmpty) {
        final attendanceRecords = await _client
          .from('meeting_attendance')
          .select('meeting_id, status')
          .inFilter('meeting_id', (meetings as List).map((m) => m['id']).toList());

        final totalAttendance = (attendanceRecords as List)
            .where((a) => a['status'] == 'present')
            .length;
        averageAttendanceRate = (totalAttendance / ((meetings as List).length * totalMembers)) * 100;
      }

      // Calculate group health score (0-100)
      double healthScore = 0;
      healthScore += (100 - loanDefaultRate) * 0.3; // 30% weight
      healthScore += averageAttendanceRate * 0.3; // 30% weight
      healthScore += (activeMembers / totalMembers) * 100 * 0.2; // 20% weight
      healthScore += (totalLoans > 0 ? 20 : 0); // 20% weight

      // Get contributions over time
      final contributionsOverTime = await _getGroupMonthlyContributions(groupId, start, end);

      // Get attendance trends
      final attendanceTrends = await _getAttendanceTrends(groupId, start, end);

      // Calculate member activity levels
      final memberActivity = await _getMemberActivity(groupId, start, end);

      return GroupPerformanceModel(
        groupId: groupId,
        groupName: group['name'] as String,
        totalMembers: totalMembers,
        activeMembers: activeMembers,
        inactiveMembers: inactiveMembers,
        groupHealthScore: healthScore,
        loanDefaultRate: loanDefaultRate,
        averageAttendanceRate: averageAttendanceRate,
        contributionsOverTime: contributionsOverTime,
        attendanceTrends: attendanceTrends,
        memberActivity: memberActivity,
      );
    } catch (e, st) {
      developer.log('❌ Error fetching group performance: $e', error: e, stackTrace: st, name: 'AnalyticsService');
      rethrow;
    }
  }

  Future<List<MonthlyContribution>> _getGroupMonthlyContributions(
    String groupId,
    DateTime start,
    DateTime end,
  ) async {
    try {
        final transactionsResponse = await _client
          .from('transactions')
          .select()
          .eq('group_id', groupId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: true);

        final transactionsList = (transactionsResponse as List<dynamic>).cast<Map<String, dynamic>>();
        final transactions = transactionsList.where((tx) => tx['type'] == 'contribution' || tx['type'] == 'deposit').toList();

      // Group by month
      final Map<String, Map<String, dynamic>> monthlyData = {};

      for (var tx in transactions) {
        final date = DateTime.parse(tx['created_at'] as String);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        final amount = (tx['amount'] as num).toDouble();
        final userId = tx['user_id'] as String;

        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {
            'amount': 0.0,
            'users': <String>{},
            'date': date,
          };
        }

        monthlyData[monthKey]!['amount'] = (monthlyData[monthKey]!['amount'] as double) + amount;
        (monthlyData[monthKey]!['users'] as Set<String>).add(userId);
      }

      return monthlyData.entries.map((entry) {
        return MonthlyContribution(
          month: entry.key,
          amount: entry.value['amount'] as double,
          contributorCount: (entry.value['users'] as Set<String>).length,
          date: entry.value['date'] as DateTime,
        );
      }).toList();
    } catch (e, st) {
      developer.log('❌ Error fetching group monthly contributions: $e', error: e, stackTrace: st, name: 'AnalyticsService');
      return [];
    }
  }

  Future<List<AttendanceTrend>> _getAttendanceTrends(
    String groupId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final meetings = await _client
          .from('meetings')
          .select('id, meeting_date')
          .eq('group_id', groupId)
          .gte('meeting_date', start.toIso8601String())
          .lte('meeting_date', end.toIso8601String())
          .order('meeting_date', ascending: true);

      final members = await _client
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);

      final totalMembers = (members as List).length;

      final List<AttendanceTrend> trends = [];

      for (var meeting in meetings as List) {
        final meetingId = meeting['id'] as String;
        final meetingDate = meeting['meeting_date'] as String;

        final attendance = await _client
            .from('meeting_attendance')
            .select('status')
            .eq('meeting_id', meetingId);

        final attendees = (attendance as List)
            .where((a) => a['status'] == 'present')
            .length;

        final rate = totalMembers > 0 ? (attendees / totalMembers) * 100 : 0.0;

        trends.add(AttendanceTrend(
          meetingDate: meetingDate,
          attendees: attendees,
          totalMembers: totalMembers,
          rate: rate,
        ));
      }

      return trends;
    } catch (e, st) {
      developer.log('❌ Error fetching attendance trends: $e', error: e, stackTrace: st, name: 'AnalyticsService');
      return [];
    }
  }

  Future<MemberActivity> _getMemberActivity(
    String groupId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final members = await _client
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);

      int highlyActive = 0;
      int moderatelyActive = 0;
      int lowActivity = 0;
      int inactive = 0;

      for (var member in members as List) {
        final userId = member['user_id'] as String;

        // Get transaction count
        final transactions = await _client
            .from('transactions')
            .select('id')
            .eq('user_id', userId)
            .eq('group_id', groupId)
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String());

        final txCount = (transactions as List).length;

        if (txCount >= 10) {
          highlyActive++;
        } else if (txCount >= 5) {
          moderatelyActive++;
        } else if (txCount >= 1) {
          lowActivity++;
        } else {
          inactive++;
        }
      }

      return MemberActivity(
        highlyActive: highlyActive,
        moderatelyActive: moderatelyActive,
        lowActivity: lowActivity,
        inactive: inactive,
      );
    } catch (e, st) {
      developer.log('❌ Error fetching member activity: $e', error: e, stackTrace: st, name: 'AnalyticsService');
      return MemberActivity(
        highlyActive: 0,
        moderatelyActive: 0,
        lowActivity: 0,
        inactive: 0,
      );
    }
  }
}
