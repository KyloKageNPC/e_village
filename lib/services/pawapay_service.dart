import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/pawapay_config.dart';
import '../models/pawapay_models.dart';

/// PawaPay API Service
/// 
/// Handles all communication with the PawaPay Mobile Money API
/// Supports deposits (collect money) and payouts (send money)
class PawapayService {
  static final PawapayService _instance = PawapayService._internal();
  factory PawapayService() => _instance;
  PawapayService._internal();

  final _uuid = const Uuid();

  // ============================================
  // DEPOSITS (Collect money from customer)
  // ============================================

  /// Initiate a deposit request (customer pays to your account)
  /// 
  /// Returns [DepositResponse] with status and depositId
  /// Customer will receive USSD prompt to enter PIN
  Future<DepositResponse> initiateDeposit({
    required double amount,
    required String phoneNumber,
    required String provider,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    final depositId = _uuid.v4();
    final normalizedPhone = PawapayConfig.normalizePhoneNumber(phoneNumber);

    // Metadata is optional - PawaPay expects array of objects with unique fieldName
    // Format: [{"fieldName": "myField1", "fieldValue": "value1"}, ...]
    // Each fieldName must be unique across all metadata entries
    // Currently not used in the deposit request, but kept for future use
    // ignore: unused_local_variable
    List<Map<String, String>>? pawapayMetadata;
    if (metadata != null && metadata.isNotEmpty) {
      pawapayMetadata = metadata.entries
          .map((e) => {
                e.key: e.value.toString(),  // Simple key-value pairs
              })
          .toList();
    }

    // PawaPay v2 API format from docs - minimal required fields only
    final requestBody = {
      'depositId': depositId,
      'amount': amount.toStringAsFixed(0),  // No decimals for ZMW
      'currency': PawapayConfig.currency,
      'payer': {
        'type': 'MMO',
        'accountDetails': {
          'phoneNumber': normalizedPhone,
          'provider': provider,
        },
      },
      // Skip metadata for now - will add back once payment works
    };

    // Debug logging
    debugPrint('🚀 PawaPay Deposit Request:');
    debugPrint('   Endpoint: ${PawapayConfig.depositsEndpoint}');
    debugPrint('   Deposit ID: $depositId');
    debugPrint('   Amount: ${amount.toStringAsFixed(0)} ${PawapayConfig.currency}');
    debugPrint('   Phone: $normalizedPhone');
    debugPrint('   Provider: $provider');
    debugPrint('   Request Body: ${jsonEncode(requestBody)}');

    try {
      final response = await http
          .post(
            Uri.parse(PawapayConfig.depositsEndpoint),
            headers: PawapayConfig.headers,
            body: jsonEncode(requestBody),
          )
          .timeout(PawapayConfig.requestTimeout);

      debugPrint('📥 PawaPay Response:');
      debugPrint('   Status Code: ${response.statusCode}');
      debugPrint('   Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Deposit request accepted');
        return DepositResponse.fromJson({
          ...responseData,
          'depositId': depositId,
          'localStatus': 'pending',
        });
      } else {
        debugPrint('❌ Deposit request rejected');
        // Extract error from failureReason object
        final failureReason = responseData['failureReason'];
        final errorMessage = failureReason?['failureMessage'] ?? responseData['message'] ?? 'Request failed';
        final errorCode = failureReason?['failureCode'] ?? responseData['errorCode'];
        debugPrint('   Error: $errorMessage');
        debugPrint('   Error Code: $errorCode');
        return DepositResponse(
          depositId: depositId,
          status: DepositStatus.rejected,
          localStatus: 'failed',
          errorMessage: errorMessage,
          failureCode: errorCode,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Network error during deposit request:');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      return DepositResponse(
        depositId: depositId,
        status: DepositStatus.rejected,
        localStatus: 'error',
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Check the status of a deposit
  Future<DepositResponse> getDepositStatus(String depositId) async {
    try {
      debugPrint('🔍 Checking deposit status: $depositId');
      
      final response = await http
          .get(
            Uri.parse(PawapayConfig.depositStatusEndpoint(depositId)),
            headers: PawapayConfig.headers,
          )
          .timeout(PawapayConfig.requestTimeout);

      debugPrint('📥 Status Response: ${response.statusCode}');
      debugPrint('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // PawaPay returns: {"data": {...deposit...}, "status": "FOUND"}
        // or for array: [{"data": {...}, "status": "FOUND"}]
        Map<String, dynamic> depositData;
        
        if (responseData is List && responseData.isNotEmpty) {
          // Array response - get first item's data
          final firstItem = responseData.first;
          depositData = firstItem['data'] ?? firstItem;
        } else if (responseData is Map && responseData.containsKey('data')) {
          // Wrapped response - extract from data field
          depositData = responseData['data'];
        } else {
          // Direct deposit data
          depositData = responseData;
        }
        
        debugPrint('   Parsed deposit status: ${depositData['status']}');
        return DepositResponse.fromJson(depositData);
      } else {
        return DepositResponse(
          depositId: depositId,
          status: DepositStatus.rejected,
          localStatus: 'error',
          errorMessage: 'Failed to get status',
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking deposit status: $e');
      return DepositResponse(
        depositId: depositId,
        status: DepositStatus.rejected,
        localStatus: 'error',
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Poll for deposit completion with timeout
  /// 
  /// Continuously checks status until completed, failed, or timeout
  Stream<DepositResponse> pollDepositStatus(String depositId) async* {
    int attempts = 0;

    while (attempts < PawapayConfig.maxPollAttempts) {
      await Future.delayed(PawapayConfig.pollInterval);
      attempts++;

      debugPrint('🔄 Poll attempt $attempts/${PawapayConfig.maxPollAttempts}');
      
      final status = await getDepositStatus(depositId);
      yield status;

      // Stop polling if terminal state reached
      if (status.isTerminal) {
        debugPrint('🏁 Terminal state reached: ${status.status}');
        break;
      }
    }

    // If we exit the loop without terminal state, yield timeout
    if (attempts >= PawapayConfig.maxPollAttempts) {
      debugPrint('⏱️ Polling timeout after $attempts attempts');
      yield DepositResponse(
        depositId: depositId,
        status: DepositStatus.rejected,
        localStatus: 'timeout',
        errorMessage: 'Payment timeout - please check your transaction history',
      );
    }
  }

  // ============================================
  // PAYOUTS (Send money to customer)
  // ============================================

  /// Initiate a payout (send money to customer's wallet)
  /// 
  /// Used for loan disbursements, withdrawals, refunds
  Future<PayoutResponse> initiatePayout({
    required double amount,
    required String phoneNumber,
    required String provider,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    final payoutId = _uuid.v4();
    final normalizedPhone = PawapayConfig.normalizePhoneNumber(phoneNumber);

    // Convert metadata to PawaPay's required array format
    List<Map<String, String>>? pawapayMetadata;
    if (metadata != null && metadata.isNotEmpty) {
      pawapayMetadata = metadata.entries
          .map((e) => {
                'fieldName': e.key,
                'fieldValue': e.value.toString(),
              })
          .toList();
    }

    // PawaPay v2 API format for payouts
    final requestBody = {
      'payoutId': payoutId,
      'amount': amount.toStringAsFixed(0),  // No decimals for ZMW
      'currency': PawapayConfig.currency,
      'recipient': {
        'type': 'MMO',
        'accountDetails': {
          'phoneNumber': normalizedPhone,
          'provider': provider,
        },
      },
      if (pawapayMetadata != null) 'metadata': pawapayMetadata,
    };

    debugPrint('🚀 PawaPay Payout Request:');
    debugPrint('   Endpoint: ${PawapayConfig.payoutsEndpoint}');
    debugPrint('   Payout ID: $payoutId');
    debugPrint('   Amount: ${amount.toStringAsFixed(0)} ${PawapayConfig.currency}');
    debugPrint('   Phone: $normalizedPhone');
    debugPrint('   Provider: $provider');

    try {
      final response = await http
          .post(
            Uri.parse(PawapayConfig.payoutsEndpoint),
            headers: PawapayConfig.headers,
            body: jsonEncode(requestBody),
          )
          .timeout(PawapayConfig.requestTimeout);

      debugPrint('📥 Payout Response: ${response.statusCode}');
      debugPrint('   Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Payout request accepted');
        return PayoutResponse.fromJson({
          ...responseData,
          'payoutId': payoutId,
          'localStatus': 'pending',
        });
      } else {
        debugPrint('❌ Payout request rejected');
        // Extract error from failureReason object
        final failureReason = responseData['failureReason'];
        final errorMessage = failureReason?['failureMessage'] ?? responseData['message'] ?? 'Request failed';
        final errorCode = failureReason?['failureCode'] ?? responseData['errorCode'];
        debugPrint('   Error: $errorMessage');
        debugPrint('   Error Code: $errorCode');
        return PayoutResponse(
          payoutId: payoutId,
          status: PayoutStatus.rejected,
          localStatus: 'failed',
          errorMessage: errorMessage,
          failureCode: errorCode,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Network error during payout: $e');
      debugPrint('   Stack: $stackTrace');
      return PayoutResponse(
        payoutId: payoutId,
        status: PayoutStatus.rejected,
        localStatus: 'error',
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Check the status of a payout
  Future<PayoutResponse> getPayoutStatus(String payoutId) async {
    try {
      final response = await http
          .get(
            Uri.parse(PawapayConfig.payoutStatusEndpoint(payoutId)),
            headers: PawapayConfig.headers,
          )
          .timeout(PawapayConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payoutData = data is List ? data.first : data;
        return PayoutResponse.fromJson(payoutData);
      } else {
        return PayoutResponse(
          payoutId: payoutId,
          status: PayoutStatus.rejected,
          localStatus: 'error',
          errorMessage: 'Failed to get status',
        );
      }
    } catch (e) {
      return PayoutResponse(
        payoutId: payoutId,
        status: PayoutStatus.rejected,
        localStatus: 'error',
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Poll for payout completion
  Stream<PayoutResponse> pollPayoutStatus(String payoutId) async* {
    int attempts = 0;

    while (attempts < PawapayConfig.maxPollAttempts) {
      await Future.delayed(PawapayConfig.pollInterval);
      attempts++;

      final status = await getPayoutStatus(payoutId);
      yield status;

      if (status.isTerminal) {
        break;
      }
    }

    if (attempts >= PawapayConfig.maxPollAttempts) {
      yield PayoutResponse(
        payoutId: payoutId,
        status: PayoutStatus.rejected,
        localStatus: 'timeout',
        errorMessage: 'Payout timeout - please check transaction status',
      );
    }
  }

  // ============================================
  // TOOLKIT / UTILITY ENDPOINTS
  // ============================================

  /// Predict MMO provider from phone number
  /// 
  /// Validates phone and returns likely provider
  Future<PredictProviderResponse> predictProvider(String phoneNumber) async {
    final normalizedPhone = PawapayConfig.normalizePhoneNumber(phoneNumber);

    try {
      final response = await http
          .post(
            Uri.parse(PawapayConfig.predictProviderEndpoint),
            headers: PawapayConfig.headers,
            body: jsonEncode({
              'phoneNumber': normalizedPhone,
              'country': PawapayConfig.countryCode,
            }),
          )
          .timeout(PawapayConfig.requestTimeout);

      if (response.statusCode == 200) {
        return PredictProviderResponse.fromJson(jsonDecode(response.body));
      } else {
        // Fallback to local detection
        final detectedProvider =
            PawapayConfig.detectProviderFromPhone(normalizedPhone);
        return PredictProviderResponse(
          provider: detectedProvider,
          isValid: detectedProvider != null,
        );
      }
    } catch (e) {
      // Fallback to local detection on error
      final detectedProvider =
          PawapayConfig.detectProviderFromPhone(normalizedPhone);
      return PredictProviderResponse(
        provider: detectedProvider,
        isValid: detectedProvider != null,
      );
    }
  }

  /// Get active configuration (available providers, limits, etc.)
  Future<ActiveConfigResponse?> getActiveConfig() async {
    try {
      final response = await http
          .get(
            Uri.parse(PawapayConfig.activeConfigEndpoint),
            headers: PawapayConfig.headers,
          )
          .timeout(PawapayConfig.requestTimeout);

      if (response.statusCode == 200) {
        return ActiveConfigResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check provider availability
  Future<Map<String, bool>> checkAvailability() async {
    try {
      final response = await http
          .get(
            Uri.parse(PawapayConfig.availabilityEndpoint),
            headers: PawapayConfig.headers,
          )
          .timeout(PawapayConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return {
          for (var item in data)
            item['provider'] as String: item['available'] == true
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Format amount for display
  String formatAmount(double amount) {
    return 'K ${amount.toStringAsFixed(2)}';
  }

  /// Get user-friendly error message
  String getErrorMessage(String? failureCode) {
    switch (failureCode) {
      case 'INSUFFICIENT_BALANCE':
        return 'Insufficient balance in your mobile money account';
      case 'INVALID_PHONE_NUMBER':
        return 'Invalid phone number. Please check and try again';
      case 'ACCOUNT_NOT_FOUND':
        return 'Mobile money account not found for this number';
      case 'TRANSACTION_LIMIT_EXCEEDED':
        return 'Transaction limit exceeded. Try a smaller amount';
      case 'PROVIDER_UNAVAILABLE':
        return 'Service temporarily unavailable. Please try again later';
      case 'TIMEOUT':
        return 'Transaction timed out. Please check your mobile money app';
      case 'CANCELLED':
        return 'Transaction was cancelled';
      case 'DUPLICATE_TRANSACTION':
        return 'Duplicate transaction detected';
      default:
        return 'Transaction failed. Please try again';
    }
  }
}
