class FinancialReportModel {
  final String groupId;
  final DateTime reportDate;
  final double totalContributions;
  final double totalLoans;
  final double totalRepayments;
  final double totalExpenses;
  final double netIncome;
  final double outstandingLoans;
  final double cashBalance;
  final List<MonthlyData> contributionTrends;
  final List<MemberContribution> topContributors;
  final LoanPortfolio loanPortfolio;

  FinancialReportModel({
    required this.groupId,
    required this.reportDate,
    required this.totalContributions,
    required this.totalLoans,
    required this.totalRepayments,
    required this.totalExpenses,
    required this.netIncome,
    required this.outstandingLoans,
    required this.cashBalance,
    required this.contributionTrends,
    required this.topContributors,
    required this.loanPortfolio,
  });

  factory FinancialReportModel.fromJson(Map<String, dynamic> json) {
    return FinancialReportModel(
      groupId: json['group_id'] as String,
      reportDate: DateTime.parse(json['report_date'] as String),
      totalContributions: (json['total_contributions'] as num).toDouble(),
      totalLoans: (json['total_loans'] as num).toDouble(),
      totalRepayments: (json['total_repayments'] as num).toDouble(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      netIncome: (json['net_income'] as num).toDouble(),
      outstandingLoans: (json['outstanding_loans'] as num).toDouble(),
      cashBalance: (json['cash_balance'] as num).toDouble(),
      contributionTrends: (json['contribution_trends'] as List?)
              ?.map((e) => MonthlyData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topContributors: (json['top_contributors'] as List?)
              ?.map((e) => MemberContribution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      loanPortfolio: LoanPortfolio.fromJson(
        json['loan_portfolio'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'report_date': reportDate.toIso8601String(),
      'total_contributions': totalContributions,
      'total_loans': totalLoans,
      'total_repayments': totalRepayments,
      'total_expenses': totalExpenses,
      'net_income': netIncome,
      'outstanding_loans': outstandingLoans,
      'cash_balance': cashBalance,
      'contribution_trends': contributionTrends.map((e) => e.toJson()).toList(),
      'top_contributors': topContributors.map((e) => e.toJson()).toList(),
      'loan_portfolio': loanPortfolio.toJson(),
    };
  }
}

class MonthlyData {
  final String month;
  final double amount;
  final DateTime date;

  MonthlyData({
    required this.month,
    required this.amount,
    required this.date,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(
      month: json['month'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }
}

class MemberContribution {
  final String memberId;
  final String memberName;
  final double totalAmount;
  final int contributionCount;

  MemberContribution({
    required this.memberId,
    required this.memberName,
    required this.totalAmount,
    required this.contributionCount,
  });

  factory MemberContribution.fromJson(Map<String, dynamic> json) {
    return MemberContribution(
      memberId: json['member_id'] as String,
      memberName: json['member_name'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      contributionCount: json['contribution_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'member_name': memberName,
      'total_amount': totalAmount,
      'contribution_count': contributionCount,
    };
  }
}

class LoanPortfolio {
  final int totalLoans;
  final int activeLoans;
  final int completedLoans;
  final int defaultedLoans;
  final double averageLoanSize;
  final double repaymentRate;

  LoanPortfolio({
    required this.totalLoans,
    required this.activeLoans,
    required this.completedLoans,
    required this.defaultedLoans,
    required this.averageLoanSize,
    required this.repaymentRate,
  });

  factory LoanPortfolio.fromJson(Map<String, dynamic> json) {
    return LoanPortfolio(
      totalLoans: json['total_loans'] as int,
      activeLoans: json['active_loans'] as int,
      completedLoans: json['completed_loans'] as int,
      defaultedLoans: json['defaulted_loans'] as int,
      averageLoanSize: (json['average_loan_size'] as num).toDouble(),
      repaymentRate: (json['repayment_rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_loans': totalLoans,
      'active_loans': activeLoans,
      'completed_loans': completedLoans,
      'defaulted_loans': defaultedLoans,
      'average_loan_size': averageLoanSize,
      'repayment_rate': repaymentRate,
    };
  }
}
