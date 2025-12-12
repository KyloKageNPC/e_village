class GroupPerformanceModel {
  final String groupId;
  final String groupName;
  final int totalMembers;
  final int activeMembers;
  final int inactiveMembers;
  final double groupHealthScore;
  final double loanDefaultRate;
  final double averageAttendanceRate;
  final List<MonthlyContribution> contributionsOverTime;
  final List<AttendanceTrend> attendanceTrends;
  final MemberActivity memberActivity;

  GroupPerformanceModel({
    required this.groupId,
    required this.groupName,
    required this.totalMembers,
    required this.activeMembers,
    required this.inactiveMembers,
    required this.groupHealthScore,
    required this.loanDefaultRate,
    required this.averageAttendanceRate,
    required this.contributionsOverTime,
    required this.attendanceTrends,
    required this.memberActivity,
  });

  factory GroupPerformanceModel.fromJson(Map<String, dynamic> json) {
    return GroupPerformanceModel(
      groupId: json['group_id'] as String,
      groupName: json['group_name'] as String,
      totalMembers: json['total_members'] as int,
      activeMembers: json['active_members'] as int,
      inactiveMembers: json['inactive_members'] as int,
      groupHealthScore: (json['group_health_score'] as num).toDouble(),
      loanDefaultRate: (json['loan_default_rate'] as num).toDouble(),
      averageAttendanceRate: (json['average_attendance_rate'] as num).toDouble(),
      contributionsOverTime: (json['contributions_over_time'] as List?)
              ?.map((e) => MonthlyContribution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attendanceTrends: (json['attendance_trends'] as List?)
              ?.map((e) => AttendanceTrend.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      memberActivity: MemberActivity.fromJson(
        json['member_activity'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'group_name': groupName,
      'total_members': totalMembers,
      'active_members': activeMembers,
      'inactive_members': inactiveMembers,
      'group_health_score': groupHealthScore,
      'loan_default_rate': loanDefaultRate,
      'average_attendance_rate': averageAttendanceRate,
      'contributions_over_time': contributionsOverTime.map((e) => e.toJson()).toList(),
      'attendance_trends': attendanceTrends.map((e) => e.toJson()).toList(),
      'member_activity': memberActivity.toJson(),
    };
  }

  String get healthScoreLabel {
    if (groupHealthScore >= 80) return 'Excellent';
    if (groupHealthScore >= 60) return 'Good';
    if (groupHealthScore >= 40) return 'Fair';
    return 'Needs Attention';
  }

  double get memberActivityRate {
    if (totalMembers == 0) return 0;
    return (activeMembers / totalMembers) * 100;
  }
}

class MonthlyContribution {
  final String month;
  final double amount;
  final int contributorCount;
  final DateTime date;

  MonthlyContribution({
    required this.month,
    required this.amount,
    required this.contributorCount,
    required this.date,
  });

  factory MonthlyContribution.fromJson(Map<String, dynamic> json) {
    return MonthlyContribution(
      month: json['month'] as String,
      amount: (json['amount'] as num).toDouble(),
      contributorCount: json['contributor_count'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'amount': amount,
      'contributor_count': contributorCount,
      'date': date.toIso8601String(),
    };
  }
}

class AttendanceTrend {
  final String meetingDate;
  final int attendees;
  final int totalMembers;
  final double rate;

  AttendanceTrend({
    required this.meetingDate,
    required this.attendees,
    required this.totalMembers,
    required this.rate,
  });

  factory AttendanceTrend.fromJson(Map<String, dynamic> json) {
    return AttendanceTrend(
      meetingDate: json['meeting_date'] as String,
      attendees: json['attendees'] as int,
      totalMembers: json['total_members'] as int,
      rate: (json['rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meeting_date': meetingDate,
      'attendees': attendees,
      'total_members': totalMembers,
      'rate': rate,
    };
  }
}

class MemberActivity {
  final int highlyActive;
  final int moderatelyActive;
  final int lowActivity;
  final int inactive;

  MemberActivity({
    required this.highlyActive,
    required this.moderatelyActive,
    required this.lowActivity,
    required this.inactive,
  });

  factory MemberActivity.fromJson(Map<String, dynamic> json) {
    return MemberActivity(
      highlyActive: json['highly_active'] as int,
      moderatelyActive: json['moderately_active'] as int,
      lowActivity: json['low_activity'] as int,
      inactive: json['inactive'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highly_active': highlyActive,
      'moderately_active': moderatelyActive,
      'low_activity': lowActivity,
      'inactive': inactive,
    };
  }
}
