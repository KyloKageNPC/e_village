class MemberAnalyticsModel {
  final String memberId;
  final String memberName;
  final double totalContributions;
  final double totalLoans;
  final double totalRepayments;
  final double outstandingBalance;
  final int meetingsAttended;
  final int totalMeetings;
  final double attendanceRate;
  final double participationScore;
  final List<ContributionHistory> contributionHistory;
  final List<LoanHistory> loanHistory;

  MemberAnalyticsModel({
    required this.memberId,
    required this.memberName,
    required this.totalContributions,
    required this.totalLoans,
    required this.totalRepayments,
    required this.outstandingBalance,
    required this.meetingsAttended,
    required this.totalMeetings,
    required this.attendanceRate,
    required this.participationScore,
    required this.contributionHistory,
    required this.loanHistory,
  });

  factory MemberAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return MemberAnalyticsModel(
      memberId: json['member_id'] as String,
      memberName: json['member_name'] as String,
      totalContributions: (json['total_contributions'] as num).toDouble(),
      totalLoans: (json['total_loans'] as num).toDouble(),
      totalRepayments: (json['total_repayments'] as num).toDouble(),
      outstandingBalance: (json['outstanding_balance'] as num).toDouble(),
      meetingsAttended: json['meetings_attended'] as int,
      totalMeetings: json['total_meetings'] as int,
      attendanceRate: (json['attendance_rate'] as num).toDouble(),
      participationScore: (json['participation_score'] as num).toDouble(),
      contributionHistory: (json['contribution_history'] as List?)
              ?.map((e) => ContributionHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      loanHistory: (json['loan_history'] as List?)
              ?.map((e) => LoanHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'member_name': memberName,
      'total_contributions': totalContributions,
      'total_loans': totalLoans,
      'total_repayments': totalRepayments,
      'outstanding_balance': outstandingBalance,
      'meetings_attended': meetingsAttended,
      'total_meetings': totalMeetings,
      'attendance_rate': attendanceRate,
      'participation_score': participationScore,
      'contribution_history': contributionHistory.map((e) => e.toJson()).toList(),
      'loan_history': loanHistory.map((e) => e.toJson()).toList(),
    };
  }
}

class ContributionHistory {
  final String id;
  final double amount;
  final DateTime date;
  final String type;

  ContributionHistory({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
  });

  factory ContributionHistory.fromJson(Map<String, dynamic> json) {
    return ContributionHistory(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
    };
  }
}

class LoanHistory {
  final String id;
  final double amount;
  final double repaidAmount;
  final double balance;
  final DateTime disbursedDate;
  final DateTime? dueDate;
  final String status;

  LoanHistory({
    required this.id,
    required this.amount,
    required this.repaidAmount,
    required this.balance,
    required this.disbursedDate,
    this.dueDate,
    required this.status,
  });

  factory LoanHistory.fromJson(Map<String, dynamic> json) {
    return LoanHistory(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      repaidAmount: (json['repaid_amount'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      disbursedDate: DateTime.parse(json['disbursed_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'repaid_amount': repaidAmount,
      'balance': balance,
      'disbursed_date': disbursedDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status,
    };
  }
}
