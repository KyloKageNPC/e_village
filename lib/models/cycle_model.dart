/// Cycle status enum
enum CycleStatus {
  active,
  closed,
  archived;

  String get displayName {
    switch (this) {
      case CycleStatus.active:
        return 'Active';
      case CycleStatus.closed:
        return 'Closed';
      case CycleStatus.archived:
        return 'Archived';
    }
  }

  static CycleStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return CycleStatus.active;
      case 'closed':
        return CycleStatus.closed;
      case 'archived':
        return CycleStatus.archived;
      default:
        return CycleStatus.active;
    }
  }
}

/// Represents a lending cycle for a village banking group
class CycleModel {
  final String id;
  final String groupId;
  final int cycleNumber;
  final String name;
  final DateTime startDate;
  final DateTime expectedEndDate;
  final DateTime? actualEndDate;
  final CycleStatus status;
  
  // Financial summary
  final double totalContributions;
  final double totalLoansDisbursed;
  final double totalInterestEarned;
  final double totalPenaltiesCollected;
  final double totalExpenses;
  final double netProfit;
  
  // Opening/closing balances
  final double openingFundBalance;
  final double closingFundBalance;
  
  // Cycle settings
  final double? contributionAmount;
  final double maxLoanMultiplier;
  final double defaultInterestRate;
  final double latePaymentPenalty;
  
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CycleModel({
    required this.id,
    required this.groupId,
    required this.cycleNumber,
    required this.name,
    required this.startDate,
    required this.expectedEndDate,
    this.actualEndDate,
    required this.status,
    this.totalContributions = 0,
    this.totalLoansDisbursed = 0,
    this.totalInterestEarned = 0,
    this.totalPenaltiesCollected = 0,
    this.totalExpenses = 0,
    this.netProfit = 0,
    this.openingFundBalance = 0,
    this.closingFundBalance = 0,
    this.contributionAmount,
    this.maxLoanMultiplier = 3.0,
    this.defaultInterestRate = 10.0,
    this.latePaymentPenalty = 5.0,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate days remaining in the cycle
  int get daysRemaining {
    final endDate = actualEndDate ?? expectedEndDate;
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Calculate cycle progress percentage
  double get progressPercentage {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;
    
    final endDate = actualEndDate ?? expectedEndDate;
    if (now.isAfter(endDate)) return 100;
    
    final totalDays = endDate.difference(startDate).inDays;
    if (totalDays == 0) return 100;
    
    final elapsedDays = now.difference(startDate).inDays;
    return (elapsedDays / totalDays * 100).clamp(0, 100);
  }

  /// Calculate total fund available
  double get totalFundAvailable {
    return openingFundBalance + totalContributions + totalInterestEarned + 
           totalPenaltiesCollected - totalLoansDisbursed - totalExpenses;
  }

  /// Check if the cycle is currently active
  bool get isActive => status == CycleStatus.active;

  /// Check if the cycle is overdue (past expected end date but still active)
  bool get isOverdue {
    return isActive && DateTime.now().isAfter(expectedEndDate);
  }

  /// Create from JSON (Supabase response)
  factory CycleModel.fromJson(Map<String, dynamic> json) {
    return CycleModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      cycleNumber: json['cycle_number'] as int,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      expectedEndDate: DateTime.parse(json['expected_end_date'] as String),
      actualEndDate: json['actual_end_date'] != null 
          ? DateTime.parse(json['actual_end_date'] as String)
          : null,
      status: CycleStatus.fromString(json['status'] as String? ?? 'active'),
      totalContributions: (json['total_contributions'] as num?)?.toDouble() ?? 0,
      totalLoansDisbursed: (json['total_loans_disbursed'] as num?)?.toDouble() ?? 0,
      totalInterestEarned: (json['total_interest_earned'] as num?)?.toDouble() ?? 0,
      totalPenaltiesCollected: (json['total_penalties_collected'] as num?)?.toDouble() ?? 0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0,
      openingFundBalance: (json['opening_fund_balance'] as num?)?.toDouble() ?? 0,
      closingFundBalance: (json['closing_fund_balance'] as num?)?.toDouble() ?? 0,
      contributionAmount: (json['contribution_amount'] as num?)?.toDouble(),
      maxLoanMultiplier: (json['max_loan_multiplier'] as num?)?.toDouble() ?? 3.0,
      defaultInterestRate: (json['default_interest_rate'] as num?)?.toDouble() ?? 10.0,
      latePaymentPenalty: (json['late_payment_penalty'] as num?)?.toDouble() ?? 5.0,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase insert
  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'cycle_number': cycleNumber,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'expected_end_date': expectedEndDate.toIso8601String().split('T')[0],
      'actual_end_date': actualEndDate?.toIso8601String().split('T')[0],
      'status': status.name,
      'total_contributions': totalContributions,
      'total_loans_disbursed': totalLoansDisbursed,
      'total_interest_earned': totalInterestEarned,
      'total_penalties_collected': totalPenaltiesCollected,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
      'opening_fund_balance': openingFundBalance,
      'closing_fund_balance': closingFundBalance,
      'contribution_amount': contributionAmount,
      'max_loan_multiplier': maxLoanMultiplier,
      'default_interest_rate': defaultInterestRate,
      'late_payment_penalty': latePaymentPenalty,
      'notes': notes,
      'created_by': createdBy,
    };
  }

  /// Create a copy with updated fields
  CycleModel copyWith({
    String? id,
    String? groupId,
    int? cycleNumber,
    String? name,
    DateTime? startDate,
    DateTime? expectedEndDate,
    DateTime? actualEndDate,
    CycleStatus? status,
    double? totalContributions,
    double? totalLoansDisbursed,
    double? totalInterestEarned,
    double? totalPenaltiesCollected,
    double? totalExpenses,
    double? netProfit,
    double? openingFundBalance,
    double? closingFundBalance,
    double? contributionAmount,
    double? maxLoanMultiplier,
    double? defaultInterestRate,
    double? latePaymentPenalty,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CycleModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      status: status ?? this.status,
      totalContributions: totalContributions ?? this.totalContributions,
      totalLoansDisbursed: totalLoansDisbursed ?? this.totalLoansDisbursed,
      totalInterestEarned: totalInterestEarned ?? this.totalInterestEarned,
      totalPenaltiesCollected: totalPenaltiesCollected ?? this.totalPenaltiesCollected,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      openingFundBalance: openingFundBalance ?? this.openingFundBalance,
      closingFundBalance: closingFundBalance ?? this.closingFundBalance,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      maxLoanMultiplier: maxLoanMultiplier ?? this.maxLoanMultiplier,
      defaultInterestRate: defaultInterestRate ?? this.defaultInterestRate,
      latePaymentPenalty: latePaymentPenalty ?? this.latePaymentPenalty,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Profit distribution status
enum DistributionStatus {
  pending,
  distributed,
  carriedForward;

  static DistributionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return DistributionStatus.pending;
      case 'distributed':
        return DistributionStatus.distributed;
      case 'carried_forward':
        return DistributionStatus.carriedForward;
      default:
        return DistributionStatus.pending;
    }
  }
}

/// Represents a member's profit distribution for a cycle
class CycleProfitDistribution {
  final String id;
  final String cycleId;
  final String memberId;
  final double totalContributions;
  final double contributionPercentage;
  final double profitShare;
  final double amountDistributed;
  final DateTime? distributionDate;
  final String? distributionMethod;
  final String? transactionReference;
  final DistributionStatus status;
  final String? notes;
  final DateTime createdAt;
  
  // Joined member info
  final String? memberName;

  CycleProfitDistribution({
    required this.id,
    required this.cycleId,
    required this.memberId,
    required this.totalContributions,
    required this.contributionPercentage,
    required this.profitShare,
    this.amountDistributed = 0,
    this.distributionDate,
    this.distributionMethod,
    this.transactionReference,
    required this.status,
    this.notes,
    required this.createdAt,
    this.memberName,
  });

  factory CycleProfitDistribution.fromJson(Map<String, dynamic> json) {
    return CycleProfitDistribution(
      id: json['id'] as String,
      cycleId: json['cycle_id'] as String,
      memberId: json['member_id'] as String,
      totalContributions: (json['total_contributions'] as num).toDouble(),
      contributionPercentage: (json['contribution_percentage'] as num).toDouble(),
      profitShare: (json['profit_share'] as num).toDouble(),
      amountDistributed: (json['amount_distributed'] as num?)?.toDouble() ?? 0,
      distributionDate: json['distribution_date'] != null 
          ? DateTime.parse(json['distribution_date'] as String)
          : null,
      distributionMethod: json['distribution_method'] as String?,
      transactionReference: json['transaction_reference'] as String?,
      status: DistributionStatus.fromString(json['status'] as String? ?? 'pending'),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      memberName: json['profiles']?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cycle_id': cycleId,
      'member_id': memberId,
      'total_contributions': totalContributions,
      'contribution_percentage': contributionPercentage,
      'profit_share': profitShare,
      'amount_distributed': amountDistributed,
      'distribution_date': distributionDate?.toIso8601String(),
      'distribution_method': distributionMethod,
      'transaction_reference': transactionReference,
      'status': status.name,
      'notes': notes,
    };
  }
}

/// Represents an expense in a cycle
class CycleExpense {
  final String id;
  final String cycleId;
  final String groupId;
  final String expenseType;
  final String description;
  final double amount;
  final DateTime expenseDate;
  final String? receiptUrl;
  final String? recordedBy;
  final String? approvedBy;
  final String status;
  final DateTime createdAt;

  CycleExpense({
    required this.id,
    required this.cycleId,
    required this.groupId,
    required this.expenseType,
    required this.description,
    required this.amount,
    required this.expenseDate,
    this.receiptUrl,
    this.recordedBy,
    this.approvedBy,
    this.status = 'pending',
    required this.createdAt,
  });

  factory CycleExpense.fromJson(Map<String, dynamic> json) {
    return CycleExpense(
      id: json['id'] as String,
      cycleId: json['cycle_id'] as String,
      groupId: json['group_id'] as String,
      expenseType: json['expense_type'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expense_date'] as String),
      receiptUrl: json['receipt_url'] as String?,
      recordedBy: json['recorded_by'] as String?,
      approvedBy: json['approved_by'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cycle_id': cycleId,
      'group_id': groupId,
      'expense_type': expenseType,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'receipt_url': receiptUrl,
      'recorded_by': recordedBy,
      'approved_by': approvedBy,
      'status': status,
    };
  }
}

/// Financial summary for a cycle
class CycleSummary {
  final double totalContributions;
  final double totalLoansDisbursed;
  final double totalInterestEarned;
  final double totalPenalties;
  final double totalExpenses;
  final double netProfit;
  final int totalMembers;
  final int activeLoans;
  final double outstandingLoans;

  CycleSummary({
    this.totalContributions = 0,
    this.totalLoansDisbursed = 0,
    this.totalInterestEarned = 0,
    this.totalPenalties = 0,
    this.totalExpenses = 0,
    this.netProfit = 0,
    this.totalMembers = 0,
    this.activeLoans = 0,
    this.outstandingLoans = 0,
  });

  factory CycleSummary.fromJson(Map<String, dynamic> json) {
    return CycleSummary(
      totalContributions: (json['total_contributions'] as num?)?.toDouble() ?? 0,
      totalLoansDisbursed: (json['total_loans_disbursed'] as num?)?.toDouble() ?? 0,
      totalInterestEarned: (json['total_interest_earned'] as num?)?.toDouble() ?? 0,
      totalPenalties: (json['total_penalties'] as num?)?.toDouble() ?? 0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0,
      totalMembers: (json['total_members'] as num?)?.toInt() ?? 0,
      activeLoans: (json['active_loans'] as num?)?.toInt() ?? 0,
      outstandingLoans: (json['outstanding_loans'] as num?)?.toDouble() ?? 0,
    );
  }
}
