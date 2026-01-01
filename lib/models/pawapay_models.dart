/// PawaPay API Models
/// 
/// Data models for PawaPay Mobile Money API requests and responses
library;

// ============================================
// DEPOSIT MODELS (Collect money)
// ============================================

enum DepositStatus {
  accepted,    // Request accepted, waiting for customer
  processing,  // Customer initiated, processing
  completed,   // Payment successful
  failed,      // Payment failed
  rejected,    // Request rejected
  cancelled,   // Cancelled by customer/system
  unknown,     // Unknown status
}

class DepositResponse {
  final String depositId;
  final DepositStatus status;
  final String localStatus; // Our internal status tracking
  final String? errorMessage;
  final String? failureCode;
  final String? providerTransactionId;
  final String? customerMessage;
  final DateTime? completedAt;
  final double? amount;
  final String? currency;

  DepositResponse({
    required this.depositId,
    required this.status,
    required this.localStatus,
    this.errorMessage,
    this.failureCode,
    this.providerTransactionId,
    this.customerMessage,
    this.completedAt,
    this.amount,
    this.currency,
  });

  factory DepositResponse.fromJson(Map<String, dynamic> json) {
    return DepositResponse(
      depositId: json['depositId'] ?? '',
      status: _parseDepositStatus(json['status']),
      localStatus: json['localStatus'] ?? _mapToLocalStatus(json['status']),
      errorMessage: json['errorMessage'] ?? json['failureReason']?['failureMessage'],
      failureCode: json['failureCode'] ?? json['failureReason']?['failureCode'],
      providerTransactionId: json['providerTransactionId'],
      customerMessage: json['customerMessage'],
      completedAt: json['completedAt'] != null 
          ? DateTime.tryParse(json['completedAt']) 
          : null,
      amount: json['amount'] != null 
          ? double.tryParse(json['amount'].toString()) 
          : null,
      currency: json['currency'],
    );
  }

  bool get isTerminal => 
      status == DepositStatus.completed || 
      status == DepositStatus.failed ||
      status == DepositStatus.rejected ||
      status == DepositStatus.cancelled;

  bool get isSuccessful => status == DepositStatus.completed;

  bool get isPending => 
      status == DepositStatus.accepted || 
      status == DepositStatus.processing;

  String get displayStatus {
    switch (status) {
      case DepositStatus.accepted:
        return 'Waiting for approval';
      case DepositStatus.processing:
        return 'Processing payment';
      case DepositStatus.completed:
        return 'Payment successful';
      case DepositStatus.failed:
        return 'Payment failed';
      case DepositStatus.rejected:
        return 'Payment rejected';
      case DepositStatus.cancelled:
        return 'Payment cancelled';
      case DepositStatus.unknown:
        return 'Unknown status';
    }
  }

  static DepositStatus _parseDepositStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACCEPTED':
        return DepositStatus.accepted;
      case 'PROCESSING':
        return DepositStatus.processing;
      case 'COMPLETED':
        return DepositStatus.completed;
      case 'FAILED':
        return DepositStatus.failed;
      case 'REJECTED':
        return DepositStatus.rejected;
      case 'CANCELLED':
        return DepositStatus.cancelled;
      default:
        return DepositStatus.unknown;
    }
  }

  static String _mapToLocalStatus(String? apiStatus) {
    switch (apiStatus?.toUpperCase()) {
      case 'ACCEPTED':
      case 'PROCESSING':
        return 'pending';
      case 'COMPLETED':
        return 'completed';
      case 'FAILED':
      case 'REJECTED':
      case 'CANCELLED':
        return 'failed';
      default:
        return 'pending';
    }
  }
}

// ============================================
// PAYOUT MODELS (Send money)
// ============================================

enum PayoutStatus {
  accepted,   // Request accepted
  enqueued,   // Queued for processing
  processing, // Being processed
  completed,  // Payout successful
  failed,     // Payout failed
  rejected,   // Request rejected
  unknown,    // Unknown status
}

class PayoutResponse {
  final String payoutId;
  final PayoutStatus status;
  final String localStatus;
  final String? errorMessage;
  final String? failureCode;
  final String? providerTransactionId;
  final DateTime? completedAt;
  final double? amount;
  final String? currency;

  PayoutResponse({
    required this.payoutId,
    required this.status,
    required this.localStatus,
    this.errorMessage,
    this.failureCode,
    this.providerTransactionId,
    this.completedAt,
    this.amount,
    this.currency,
  });

  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    return PayoutResponse(
      payoutId: json['payoutId'] ?? '',
      status: _parsePayoutStatus(json['status']),
      localStatus: json['localStatus'] ?? _mapToLocalStatus(json['status']),
      errorMessage: json['errorMessage'] ?? json['failureReason']?['failureMessage'],
      failureCode: json['failureCode'] ?? json['failureReason']?['failureCode'],
      providerTransactionId: json['providerTransactionId'],
      completedAt: json['completedAt'] != null 
          ? DateTime.tryParse(json['completedAt']) 
          : null,
      amount: json['amount'] != null 
          ? double.tryParse(json['amount'].toString()) 
          : null,
      currency: json['currency'],
    );
  }

  bool get isTerminal => 
      status == PayoutStatus.completed || 
      status == PayoutStatus.failed ||
      status == PayoutStatus.rejected;

  bool get isSuccessful => status == PayoutStatus.completed;

  bool get isPending => 
      status == PayoutStatus.accepted || 
      status == PayoutStatus.enqueued ||
      status == PayoutStatus.processing;

  String get displayStatus {
    switch (status) {
      case PayoutStatus.accepted:
        return 'Request accepted';
      case PayoutStatus.enqueued:
        return 'Queued for processing';
      case PayoutStatus.processing:
        return 'Processing payout';
      case PayoutStatus.completed:
        return 'Payout successful';
      case PayoutStatus.failed:
        return 'Payout failed';
      case PayoutStatus.rejected:
        return 'Payout rejected';
      case PayoutStatus.unknown:
        return 'Unknown status';
    }
  }

  static PayoutStatus _parsePayoutStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACCEPTED':
        return PayoutStatus.accepted;
      case 'ENQUEUED':
        return PayoutStatus.enqueued;
      case 'PROCESSING':
        return PayoutStatus.processing;
      case 'COMPLETED':
        return PayoutStatus.completed;
      case 'FAILED':
        return PayoutStatus.failed;
      case 'REJECTED':
        return PayoutStatus.rejected;
      default:
        return PayoutStatus.unknown;
    }
  }

  static String _mapToLocalStatus(String? apiStatus) {
    switch (apiStatus?.toUpperCase()) {
      case 'ACCEPTED':
      case 'ENQUEUED':
      case 'PROCESSING':
        return 'pending';
      case 'COMPLETED':
        return 'completed';
      case 'FAILED':
      case 'REJECTED':
        return 'failed';
      default:
        return 'pending';
    }
  }
}

// ============================================
// UTILITY MODELS
// ============================================

class PredictProviderResponse {
  final String? provider;
  final bool isValid;
  final String? errorMessage;

  PredictProviderResponse({
    this.provider,
    required this.isValid,
    this.errorMessage,
  });

  factory PredictProviderResponse.fromJson(Map<String, dynamic> json) {
    return PredictProviderResponse(
      provider: json['provider'],
      isValid: json['provider'] != null,
    );
  }
}

class ActiveConfigResponse {
  final List<ProviderConfig> providers;

  ActiveConfigResponse({required this.providers});

  factory ActiveConfigResponse.fromJson(Map<String, dynamic> json) {
    final providersList = json['providers'] as List? ?? [];
    return ActiveConfigResponse(
      providers: providersList
          .map((p) => ProviderConfig.fromJson(p))
          .toList(),
    );
  }
}

class ProviderConfig {
  final String provider;
  final String country;
  final String currency;
  final double minDeposit;
  final double maxDeposit;
  final double minPayout;
  final double maxPayout;
  final bool depositsEnabled;
  final bool payoutsEnabled;

  ProviderConfig({
    required this.provider,
    required this.country,
    required this.currency,
    required this.minDeposit,
    required this.maxDeposit,
    required this.minPayout,
    required this.maxPayout,
    required this.depositsEnabled,
    required this.payoutsEnabled,
  });

  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    return ProviderConfig(
      provider: json['provider'] ?? '',
      country: json['country'] ?? '',
      currency: json['currency'] ?? '',
      minDeposit: (json['depositConfiguration']?['minAmount'] ?? 1).toDouble(),
      maxDeposit: (json['depositConfiguration']?['maxAmount'] ?? 50000).toDouble(),
      minPayout: (json['payoutConfiguration']?['minAmount'] ?? 1).toDouble(),
      maxPayout: (json['payoutConfiguration']?['maxAmount'] ?? 50000).toDouble(),
      depositsEnabled: json['depositConfiguration']?['enabled'] ?? false,
      payoutsEnabled: json['payoutConfiguration']?['enabled'] ?? false,
    );
  }
}

// ============================================
// MOBILE MONEY TRANSACTION MODEL (Local DB)
// ============================================

enum MobileMoneyOperationType {
  deposit,   // Collecting money (contributions, repayments)
  payout,    // Sending money (disbursements, withdrawals)
}

enum MobileMoneyTransactionStatus {
  pending,
  processing,
  completed,
  failed,
}

class MobileMoneyTransaction {
  final String id;
  final String pawapayId; // depositId or payoutId
  final MobileMoneyOperationType operationType;
  final String userId;
  final String? groupId;
  final double amount;
  final String currency;
  final String phoneNumber;
  final String mmoProvider;
  final MobileMoneyTransactionStatus status;
  final String? pawapayStatus;
  final String? failureCode;
  final String? failureMessage;
  final String? referenceType; // contribution, repayment, disbursement, withdrawal
  final String? referenceId;
  final String? providerTransactionId;
  final DateTime createdAt;
  final DateTime? completedAt;

  MobileMoneyTransaction({
    required this.id,
    required this.pawapayId,
    required this.operationType,
    required this.userId,
    this.groupId,
    required this.amount,
    this.currency = 'ZMW',
    required this.phoneNumber,
    required this.mmoProvider,
    required this.status,
    this.pawapayStatus,
    this.failureCode,
    this.failureMessage,
    this.referenceType,
    this.referenceId,
    this.providerTransactionId,
    required this.createdAt,
    this.completedAt,
  });

  factory MobileMoneyTransaction.fromJson(Map<String, dynamic> json) {
    return MobileMoneyTransaction(
      id: json['id'],
      pawapayId: json['pawapay_id'],
      operationType: json['operation_type'] == 'deposit' 
          ? MobileMoneyOperationType.deposit 
          : MobileMoneyOperationType.payout,
      userId: json['user_id'],
      groupId: json['group_id'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'ZMW',
      phoneNumber: json['phone_number'],
      mmoProvider: json['mmo_provider'],
      status: _parseStatus(json['status']),
      pawapayStatus: json['pawapay_status'],
      failureCode: json['failure_code'],
      failureMessage: json['failure_message'],
      referenceType: json['reference_type'],
      referenceId: json['reference_id'],
      providerTransactionId: json['provider_transaction_id'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pawapay_id': pawapayId,
      'operation_type': operationType == MobileMoneyOperationType.deposit 
          ? 'deposit' 
          : 'payout',
      'user_id': userId,
      'group_id': groupId,
      'amount': amount,
      'currency': currency,
      'phone_number': phoneNumber,
      'mmo_provider': mmoProvider,
      'status': status.name,
      'pawapay_status': pawapayStatus,
      'failure_code': failureCode,
      'failure_message': failureMessage,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'provider_transaction_id': providerTransactionId,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  static MobileMoneyTransactionStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return MobileMoneyTransactionStatus.pending;
      case 'processing':
        return MobileMoneyTransactionStatus.processing;
      case 'completed':
        return MobileMoneyTransactionStatus.completed;
      case 'failed':
        return MobileMoneyTransactionStatus.failed;
      default:
        return MobileMoneyTransactionStatus.pending;
    }
  }

  MobileMoneyTransaction copyWith({
    String? id,
    String? pawapayId,
    MobileMoneyOperationType? operationType,
    String? userId,
    String? groupId,
    double? amount,
    String? currency,
    String? phoneNumber,
    String? mmoProvider,
    MobileMoneyTransactionStatus? status,
    String? pawapayStatus,
    String? failureCode,
    String? failureMessage,
    String? referenceType,
    String? referenceId,
    String? providerTransactionId,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return MobileMoneyTransaction(
      id: id ?? this.id,
      pawapayId: pawapayId ?? this.pawapayId,
      operationType: operationType ?? this.operationType,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mmoProvider: mmoProvider ?? this.mmoProvider,
      status: status ?? this.status,
      pawapayStatus: pawapayStatus ?? this.pawapayStatus,
      failureCode: failureCode ?? this.failureCode,
      failureMessage: failureMessage ?? this.failureMessage,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      providerTransactionId: providerTransactionId ?? this.providerTransactionId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  String get displayProvider {
    switch (mmoProvider) {
      case 'MTN_MOMO_ZMB':
        return 'MTN Mobile Money';
      case 'AIRTEL_ZMB':
        return 'Airtel Money';
      case 'ZAMTEL_ZMB':
        return 'Zamtel Kwacha';
      default:
        return mmoProvider;
    }
  }

  String get displayStatus {
    switch (status) {
      case MobileMoneyTransactionStatus.pending:
        return 'Pending';
      case MobileMoneyTransactionStatus.processing:
        return 'Processing';
      case MobileMoneyTransactionStatus.completed:
        return 'Completed';
      case MobileMoneyTransactionStatus.failed:
        return 'Failed';
    }
  }
}
