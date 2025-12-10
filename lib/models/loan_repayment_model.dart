class LoanRepaymentModel {
  final String id;
  final String loanId;
  final double amount;
  final double principalAmount;
  final double interestAmount;
  final PaymentMethod paymentMethod;
  final String? paymentReference;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;

  LoanRepaymentModel({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.principalAmount,
    required this.interestAmount,
    required this.paymentMethod,
    this.paymentReference,
    this.notes,
    required this.createdBy,
    required this.createdAt,
  });

  factory LoanRepaymentModel.fromJson(Map<String, dynamic> json) {
    return LoanRepaymentModel(
      id: json['id'] as String,
      loanId: json['loan_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      principalAmount: (json['principal_amount'] as num).toDouble(),
      interestAmount: (json['interest_amount'] as num).toDouble(),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String),
      paymentReference: json['payment_reference'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'amount': amount,
      'principal_amount': principalAmount,
      'interest_amount': interestAmount,
      'payment_method': paymentMethod.value,
      'payment_reference': paymentReference,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum PaymentMethod {
  cash,
  mobileMoney,
  bankTransfer;

  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'mobile_money':
        return PaymentMethod.mobileMoney;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.cash;
    }
  }
}
