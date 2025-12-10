class LoanGuarantorModel {
  final String id;
  final String loanId;
  final String guarantorId;
  final String guarantorName;
  final double guaranteedAmount;
  final GuarantorStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final String? responseMessage;

  LoanGuarantorModel({
    required this.id,
    required this.loanId,
    required this.guarantorId,
    required this.guarantorName,
    required this.guaranteedAmount,
    required this.status,
    required this.requestedAt,
    this.respondedAt,
    this.responseMessage,
  });

  factory LoanGuarantorModel.fromJson(Map<String, dynamic> json) {
    return LoanGuarantorModel(
      id: json['id'] as String,
      loanId: json['loan_id'] as String,
      guarantorId: json['guarantor_id'] as String,
      guarantorName: json['guarantor_name'] as String? ?? 'Unknown',
      guaranteedAmount: (json['guaranteed_amount'] as num).toDouble(),
      status: GuarantorStatus.fromString(json['status'] as String),
      requestedAt: DateTime.parse(json['requested_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      responseMessage: json['response_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'guarantor_id': guarantorId,
      'guarantor_name': guarantorName,
      'guaranteed_amount': guaranteedAmount,
      'status': status.value,
      'requested_at': requestedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'response_message': responseMessage,
    };
  }

  bool get isPending => status == GuarantorStatus.pending;
  bool get isApproved => status == GuarantorStatus.approved;
  bool get isRejected => status == GuarantorStatus.rejected;
}

enum GuarantorStatus {
  pending,
  approved,
  rejected;

  String get value {
    switch (this) {
      case GuarantorStatus.pending:
        return 'pending';
      case GuarantorStatus.approved:
        return 'approved';
      case GuarantorStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
      case GuarantorStatus.pending:
        return 'Pending';
      case GuarantorStatus.approved:
        return 'Approved';
      case GuarantorStatus.rejected:
        return 'Rejected';
    }
  }

  static GuarantorStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return GuarantorStatus.pending;
      case 'approved':
        return GuarantorStatus.approved;
      case 'rejected':
        return GuarantorStatus.rejected;
      default:
        return GuarantorStatus.pending;
    }
  }
}
