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
  
  // Borrower information
  final String? borrowerId;
  final String? borrowerName;
  final String? borrowerPhone;
  final String? borrowerAvatarUrl;
  
  // Loan information
  final double? loanAmount;
  final String? loanPurpose;
  final int? loanDurationMonths;
  final double? loanInterestRate;
  final String? loanInterestType;
  final double? totalRepayable;
  final double? monthlyPayment;
  
  // Borrower track record
  final int? borrowerTotalLoans;
  final int? borrowerCompletedLoans;
  final double? borrowerCurrentSavings;
  final DateTime? borrowerMemberSince;
  final double? borrowerAttendanceRate;

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
    this.borrowerId,
    this.borrowerName,
    this.borrowerPhone,
    this.borrowerAvatarUrl,
    this.loanAmount,
    this.loanPurpose,
    this.loanDurationMonths,
    this.loanInterestRate,
    this.loanInterestType,
    this.totalRepayable,
    this.monthlyPayment,
    this.borrowerTotalLoans,
    this.borrowerCompletedLoans,
    this.borrowerCurrentSavings,
    this.borrowerMemberSince,
    this.borrowerAttendanceRate,
  });

  factory LoanGuarantorModel.fromJson(Map<String, dynamic> json) {
    // Calculate monthly payment if loan details exist
    double? monthlyPayment;
    if (json['loan_total_repayable'] != null && 
        json['loan_duration_months'] != null &&
        json['loan_duration_months'] > 0) {
      monthlyPayment = (json['loan_total_repayable'] as num).toDouble() / 
                      (json['loan_duration_months'] as int);
    }

    return LoanGuarantorModel(
      id: json['id'] as String,
      loanId: json['loan_id'] as String,
      guarantorId: json['guarantor_id'] as String,
      guarantorName: json['guarantor_name'] as String? ?? 'Unknown',
      guaranteedAmount: json['guaranteed_amount'] != null 
          ? (json['guaranteed_amount'] as num).toDouble()
          : 0.0,
      status: GuarantorStatus.fromString(json['status'] as String),
      // Use requested_at if available, otherwise fall back to created_at
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'] as String)
          : DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      responseMessage: json['response_message'] as String?,
      
      // Borrower info
      borrowerId: json['borrower_id'] as String?,
      borrowerName: json['borrower_name'] as String?,
      borrowerPhone: json['borrower_phone'] as String?,
      borrowerAvatarUrl: json['borrower_avatar_url'] as String?,
      
      // Loan info
      loanAmount: json['loan_amount'] != null 
          ? (json['loan_amount'] as num).toDouble() 
          : null,
      loanPurpose: json['loan_purpose'] as String?,
      loanDurationMonths: json['loan_duration_months'] as int?,
      loanInterestRate: json['loan_interest_rate'] != null
          ? (json['loan_interest_rate'] as num).toDouble()
          : null,
      loanInterestType: json['loan_interest_type'] as String?,
      totalRepayable: json['loan_total_repayable'] != null
          ? (json['loan_total_repayable'] as num).toDouble()
          : null,
      monthlyPayment: monthlyPayment,
      
      // Borrower track record
      borrowerTotalLoans: json['borrower_total_loans'] as int?,
      borrowerCompletedLoans: json['borrower_completed_loans'] as int?,
      borrowerCurrentSavings: json['borrower_current_savings'] != null
          ? (json['borrower_current_savings'] as num).toDouble()
          : null,
      borrowerMemberSince: json['borrower_member_since'] != null
          ? DateTime.parse(json['borrower_member_since'] as String)
          : null,
      borrowerAttendanceRate: json['borrower_attendance_rate'] != null
          ? (json['borrower_attendance_rate'] as num).toDouble()
          : null,
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
      'borrower_id': borrowerId,
      'borrower_name': borrowerName,
      'loan_amount': loanAmount,
      'loan_purpose': loanPurpose,
      'loan_duration_months': loanDurationMonths,
    };
  }

  bool get isPending => status == GuarantorStatus.pending;
  bool get isApproved => status == GuarantorStatus.approved;
  bool get isRejected => status == GuarantorStatus.rejected;
  
  // Helper getters
  String get borrowerDisplayName => borrowerName ?? 'Unknown Borrower';
  String get loanPurposeDisplay => loanPurpose ?? 'Not specified';
  double get yourLiability => guaranteedAmount;
  
  String get borrowerInitials {
    if (borrowerName == null || borrowerName!.isEmpty) return '?';
    final names = borrowerName!.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return borrowerName![0].toUpperCase();
  }
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
