enum TransactionType {
  contribution,
  withdrawal,
  loanDisbursement,
  loanRepayment,
  fee,
  dividend,
  penalty;

  String get displayName {
    switch (this) {
      case TransactionType.contribution:
        return 'Contribution';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.loanDisbursement:
        return 'Loan Disbursement';
      case TransactionType.loanRepayment:
        return 'Loan Repayment';
      case TransactionType.fee:
        return 'Fee';
      case TransactionType.dividend:
        return 'Dividend';
      case TransactionType.penalty:
        return 'Penalty';
    }
  }

  bool get isIncome {
    return this == TransactionType.contribution ||
        this == TransactionType.loanRepayment ||
        this == TransactionType.fee;
  }

  static TransactionType fromString(String value) {
    switch (value) {
      case 'contribution':
        return TransactionType.contribution;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'loan_disbursement':
        return TransactionType.loanDisbursement;
      case 'loan_repayment':
        return TransactionType.loanRepayment;
      case 'fee':
        return TransactionType.fee;
      case 'dividend':
        return TransactionType.dividend;
      case 'penalty':
        return TransactionType.penalty;
      default:
        throw ArgumentError('Unknown transaction type: $value');
    }
  }

  String toDbString() {
    switch (this) {
      case TransactionType.contribution:
        return 'contribution';
      case TransactionType.withdrawal:
        return 'withdrawal';
      case TransactionType.loanDisbursement:
        return 'loan_disbursement';
      case TransactionType.loanRepayment:
        return 'loan_repayment';
      case TransactionType.fee:
        return 'fee';
      case TransactionType.dividend:
        return 'dividend';
      case TransactionType.penalty:
        return 'penalty';
    }
  }
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled;

  static TransactionStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }
}

class TransactionModel {
  final String id;
  final String groupId;
  final String userId;
  final TransactionType type;
  final double amount;
  final double? balanceBefore;
  final double? balanceAfter;
  final String? description;
  final String? referenceId;
  final TransactionStatus status;
  final DateTime transactionDate;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.type,
    required this.amount,
    this.balanceBefore,
    this.balanceAfter,
    this.description,
    this.referenceId,
    this.status = TransactionStatus.completed,
    required this.transactionDate,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      balanceBefore: json['balance_before'] != null
          ? (json['balance_before'] as num).toDouble()
          : null,
      balanceAfter: json['balance_after'] != null
          ? (json['balance_after'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      referenceId: json['reference_id'] as String?,
      status: TransactionStatus.fromString(json['status'] as String),
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'type': type.toDbString(),
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'description': description,
      'reference_id': referenceId,
      'status': status.name,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? groupId,
    String? userId,
    TransactionType? type,
    double? amount,
    double? balanceBefore,
    double? balanceAfter,
    String? description,
    String? referenceId,
    TransactionStatus? status,
    DateTime? transactionDate,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      status: status ?? this.status,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
