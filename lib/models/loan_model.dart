enum LoanStatus {
  pending,
  approved,
  rejected,
  disbursed,
  active,
  completed,
  defaulted;

  String get displayName {
    switch (this) {
      case LoanStatus.pending:
        return 'Pending Approval';
      case LoanStatus.approved:
        return 'Approved';
      case LoanStatus.rejected:
        return 'Rejected';
      case LoanStatus.disbursed:
        return 'Disbursed';
      case LoanStatus.active:
        return 'Active';
      case LoanStatus.completed:
        return 'Completed';
      case LoanStatus.defaulted:
        return 'Defaulted';
    }
  }

  static LoanStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return LoanStatus.pending;
      case 'approved':
        return LoanStatus.approved;
      case 'rejected':
        return LoanStatus.rejected;
      case 'disbursed':
        return LoanStatus.disbursed;
      case 'active':
        return LoanStatus.active;
      case 'completed':
        return LoanStatus.completed;
      case 'defaulted':
        return LoanStatus.defaulted;
      default:
        return LoanStatus.pending;
    }
  }
}

enum InterestType {
  flat,
  decliningBalance;

  String get displayName {
    switch (this) {
      case InterestType.flat:
        return 'Flat Rate';
      case InterestType.decliningBalance:
        return 'Declining Balance';
    }
  }

  static InterestType fromString(String value) {
    return value == 'declining_balance'
        ? InterestType.decliningBalance
        : InterestType.flat;
  }

  String toDbString() {
    return this == InterestType.decliningBalance
        ? 'declining_balance'
        : 'flat';
  }
}

class LoanModel {
  final String id;
  final String groupId;
  final String borrowerId;
  final double amount;
  final double interestRate;
  final InterestType interestType;
  final int durationMonths;
  final String purpose;
  final LoanStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? disbursedAt;
  final DateTime? dueDate;
  final double? totalRepayable;
  final double amountRepaid;
  final double? balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanModel({
    required this.id,
    required this.groupId,
    required this.borrowerId,
    required this.amount,
    required this.interestRate,
    this.interestType = InterestType.flat,
    required this.durationMonths,
    required this.purpose,
    this.status = LoanStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.disbursedAt,
    this.dueDate,
    this.totalRepayable,
    this.amountRepaid = 0.0,
    this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      borrowerId: json['borrower_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      interestRate: (json['interest_rate'] as num).toDouble(),
      interestType: InterestType.fromString(json['interest_type'] as String),
      durationMonths: json['duration_months'] as int,
      purpose: json['purpose'] as String,
      status: LoanStatus.fromString(json['status'] as String),
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      disbursedAt: json['disbursed_at'] != null
          ? DateTime.parse(json['disbursed_at'] as String)
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      totalRepayable: json['total_repayable'] != null
          ? (json['total_repayable'] as num).toDouble()
          : null,
      amountRepaid: (json['amount_repaid'] as num?)?.toDouble() ?? 0.0,
      balance: json['balance'] != null
          ? (json['balance'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'borrower_id': borrowerId,
      'amount': amount,
      'interest_rate': interestRate,
      'interest_type': interestType.toDbString(),
      'duration_months': durationMonths,
      'purpose': purpose,
      'status': status.name,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'disbursed_at': disbursedAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'total_repayable': totalRepayable,
      'amount_repaid': amountRepaid,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double calculateTotalRepayable() {
    if (interestType == InterestType.flat) {
      final interest = (amount * interestRate / 100) * durationMonths;
      return amount + interest;
    } else {
      // Declining balance - simplified calculation
      // For accurate declining balance, use proper amortization schedule
      final monthlyRate = interestRate / 100 / 12;
      final totalInterest = amount * monthlyRate * durationMonths;
      return amount + totalInterest;
    }
  }

  double get remainingBalance => (totalRepayable ?? calculateTotalRepayable()) - amountRepaid;

  double get progressPercentage {
    final total = totalRepayable ?? calculateTotalRepayable();
    if (total == 0) return 0;
    return (amountRepaid / total * 100).clamp(0, 100);
  }

  LoanModel copyWith({
    String? id,
    String? groupId,
    String? borrowerId,
    double? amount,
    double? interestRate,
    InterestType? interestType,
    int? durationMonths,
    String? purpose,
    LoanStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? disbursedAt,
    DateTime? dueDate,
    double? totalRepayable,
    double? amountRepaid,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      borrowerId: borrowerId ?? this.borrowerId,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      interestType: interestType ?? this.interestType,
      durationMonths: durationMonths ?? this.durationMonths,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      dueDate: dueDate ?? this.dueDate,
      totalRepayable: totalRepayable ?? this.totalRepayable,
      amountRepaid: amountRepaid ?? this.amountRepaid,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
