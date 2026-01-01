import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/pawapay_config.dart';
import '../models/pawapay_models.dart';
import '../services/pawapay_service.dart';

/// Payment Provider
/// 
/// Manages mobile money payment state and operations
/// Handles deposits (contributions, repayments) and payouts (disbursements, withdrawals)
class PaymentProvider extends ChangeNotifier {
  final _pawapayService = PawapayService();
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // State
  bool _isLoading = false;
  String? _error;
  MobileMoneyTransaction? _currentTransaction;
  List<MobileMoneyTransaction> _transactionHistory = [];
  StreamSubscription? _statusSubscription;

  // Payment flow state
  PaymentFlowState _flowState = PaymentFlowState.idle;
  String? _selectedProvider;
  String? _phoneNumber;
  double? _amount;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  MobileMoneyTransaction? get currentTransaction => _currentTransaction;
  List<MobileMoneyTransaction> get transactionHistory => _transactionHistory;
  PaymentFlowState get flowState => _flowState;
  String? get selectedProvider => _selectedProvider;
  String? get phoneNumber => _phoneNumber;
  double? get amount => _amount;

  // ============================================
  // PAYMENT FLOW MANAGEMENT
  // ============================================

  /// Start a new payment flow
  void startPaymentFlow({
    required double amount,
    String? phoneNumber,
    String? provider,
  }) {
    _amount = amount;
    _phoneNumber = phoneNumber;
    _selectedProvider = provider;
    _flowState = PaymentFlowState.enteringDetails;
    _error = null;
    notifyListeners();
  }

  /// Update selected provider
  void setProvider(String? provider) {
    _selectedProvider = provider;
    notifyListeners();
  }

  /// Update phone number
  void setPhoneNumber(String? phone) {
    _phoneNumber = phone;
    // Auto-detect provider from phone number
    if (phone != null && phone.length >= 6) {
      final detected = PawapayConfig.detectProviderFromPhone(phone);
      if (detected != null) {
        _selectedProvider = detected;
      }
    }
    notifyListeners();
  }

  /// Reset payment flow
  void resetFlow() {
    _flowState = PaymentFlowState.idle;
    _currentTransaction = null;
    _error = null;
    _selectedProvider = null;
    _phoneNumber = null;
    _amount = null;
    _statusSubscription?.cancel();
    notifyListeners();
  }

  // ============================================
  // DEPOSIT OPERATIONS (Collect money)
  // ============================================

  /// Make a contribution via mobile money
  /// 
  /// Creates a deposit request and tracks the transaction
  Future<MobileMoneyTransaction?> makeContribution({
    required String userId,
    required String groupId,
    required double amount,
    required String phoneNumber,
    required String provider,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    _flowState = PaymentFlowState.processing;
    notifyListeners();

    try {
      // 1. Initiate PawaPay deposit
      final depositResponse = await _pawapayService.initiateDeposit(
        amount: amount,
        phoneNumber: phoneNumber,
        provider: provider,
        description: description ?? 'Group contribution',
        metadata: {
          'type': 'contribution',
          'group_id': groupId,
          'user_id': userId,
        },
      );

      if (depositResponse.status == DepositStatus.rejected) {
        _error = depositResponse.errorMessage ?? 'Payment request rejected';
        _flowState = PaymentFlowState.failed;
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // 2. Create local transaction record
      final transaction = MobileMoneyTransaction(
        id: _uuid.v4(),
        pawapayId: depositResponse.depositId,
        operationType: MobileMoneyOperationType.deposit,
        userId: userId,
        groupId: groupId,
        amount: amount,
        phoneNumber: PawapayConfig.normalizePhoneNumber(phoneNumber),
        mmoProvider: provider,
        status: MobileMoneyTransactionStatus.pending,
        pawapayStatus: depositResponse.status.name.toUpperCase(),
        referenceType: 'contribution',
        createdAt: DateTime.now(),
      );

      // 3. Save to Supabase
      await _saveTransaction(transaction);
      _currentTransaction = transaction;
      _flowState = PaymentFlowState.awaitingConfirmation;
      notifyListeners();

      // 4. Start polling for status
      _pollDepositStatus(depositResponse.depositId, transaction);

      return transaction;
    } catch (e) {
      _error = 'Failed to initiate payment: ${e.toString()}';
      _flowState = PaymentFlowState.failed;
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Make a loan repayment via mobile money
  Future<MobileMoneyTransaction?> makeLoanRepayment({
    required String userId,
    required String groupId,
    required String loanId,
    required double amount,
    required String phoneNumber,
    required String provider,
  }) async {
    _isLoading = true;
    _error = null;
    _flowState = PaymentFlowState.processing;
    notifyListeners();

    try {
      final depositResponse = await _pawapayService.initiateDeposit(
        amount: amount,
        phoneNumber: phoneNumber,
        provider: provider,
        description: 'Loan repayment',
        metadata: {
          'type': 'repayment',
          'group_id': groupId,
          'user_id': userId,
          'loan_id': loanId,
        },
      );

      if (depositResponse.status == DepositStatus.rejected) {
        _error = depositResponse.errorMessage ?? 'Payment request rejected';
        _flowState = PaymentFlowState.failed;
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final transaction = MobileMoneyTransaction(
        id: _uuid.v4(),
        pawapayId: depositResponse.depositId,
        operationType: MobileMoneyOperationType.deposit,
        userId: userId,
        groupId: groupId,
        amount: amount,
        phoneNumber: PawapayConfig.normalizePhoneNumber(phoneNumber),
        mmoProvider: provider,
        status: MobileMoneyTransactionStatus.pending,
        pawapayStatus: depositResponse.status.name.toUpperCase(),
        referenceType: 'repayment',
        referenceId: loanId,
        createdAt: DateTime.now(),
      );

      await _saveTransaction(transaction);
      _currentTransaction = transaction;
      _flowState = PaymentFlowState.awaitingConfirmation;
      notifyListeners();

      _pollDepositStatus(depositResponse.depositId, transaction);

      return transaction;
    } catch (e) {
      _error = 'Failed to initiate repayment: ${e.toString()}';
      _flowState = PaymentFlowState.failed;
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ============================================
  // PAYOUT OPERATIONS (Send money)
  // ============================================

  /// Disburse a loan via mobile money
  Future<MobileMoneyTransaction?> disburseLoan({
    required String userId,
    required String groupId,
    required String loanId,
    required double amount,
    required String phoneNumber,
    required String provider,
  }) async {
    _isLoading = true;
    _error = null;
    _flowState = PaymentFlowState.processing;
    notifyListeners();

    try {
      final payoutResponse = await _pawapayService.initiatePayout(
        amount: amount,
        phoneNumber: phoneNumber,
        provider: provider,
        description: 'Loan disbursement',
        metadata: {
          'type': 'disbursement',
          'group_id': groupId,
          'user_id': userId,
          'loan_id': loanId,
        },
      );

      if (payoutResponse.status == PayoutStatus.rejected) {
        _error = payoutResponse.errorMessage ?? 'Payout request rejected';
        _flowState = PaymentFlowState.failed;
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final transaction = MobileMoneyTransaction(
        id: _uuid.v4(),
        pawapayId: payoutResponse.payoutId,
        operationType: MobileMoneyOperationType.payout,
        userId: userId,
        groupId: groupId,
        amount: amount,
        phoneNumber: PawapayConfig.normalizePhoneNumber(phoneNumber),
        mmoProvider: provider,
        status: MobileMoneyTransactionStatus.pending,
        pawapayStatus: payoutResponse.status.name.toUpperCase(),
        referenceType: 'disbursement',
        referenceId: loanId,
        createdAt: DateTime.now(),
      );

      await _saveTransaction(transaction);
      _currentTransaction = transaction;
      _flowState = PaymentFlowState.awaitingConfirmation;
      notifyListeners();

      _pollPayoutStatus(payoutResponse.payoutId, transaction);

      return transaction;
    } catch (e) {
      _error = 'Failed to initiate disbursement: ${e.toString()}';
      _flowState = PaymentFlowState.failed;
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Process a withdrawal to mobile money
  Future<MobileMoneyTransaction?> processWithdrawal({
    required String userId,
    required String groupId,
    required double amount,
    required String phoneNumber,
    required String provider,
  }) async {
    _isLoading = true;
    _error = null;
    _flowState = PaymentFlowState.processing;
    notifyListeners();

    try {
      final payoutResponse = await _pawapayService.initiatePayout(
        amount: amount,
        phoneNumber: phoneNumber,
        provider: provider,
        description: 'Savings withdrawal',
        metadata: {
          'type': 'withdrawal',
          'group_id': groupId,
          'user_id': userId,
        },
      );

      if (payoutResponse.status == PayoutStatus.rejected) {
        _error = payoutResponse.errorMessage ?? 'Withdrawal request rejected';
        _flowState = PaymentFlowState.failed;
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final transaction = MobileMoneyTransaction(
        id: _uuid.v4(),
        pawapayId: payoutResponse.payoutId,
        operationType: MobileMoneyOperationType.payout,
        userId: userId,
        groupId: groupId,
        amount: amount,
        phoneNumber: PawapayConfig.normalizePhoneNumber(phoneNumber),
        mmoProvider: provider,
        status: MobileMoneyTransactionStatus.pending,
        pawapayStatus: payoutResponse.status.name.toUpperCase(),
        referenceType: 'withdrawal',
        createdAt: DateTime.now(),
      );

      await _saveTransaction(transaction);
      _currentTransaction = transaction;
      _flowState = PaymentFlowState.awaitingConfirmation;
      notifyListeners();

      _pollPayoutStatus(payoutResponse.payoutId, transaction);

      return transaction;
    } catch (e) {
      _error = 'Failed to initiate withdrawal: ${e.toString()}';
      _flowState = PaymentFlowState.failed;
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ============================================
  // STATUS POLLING
  // ============================================

  void _pollDepositStatus(String depositId, MobileMoneyTransaction transaction) {
    _statusSubscription?.cancel();
    
    _statusSubscription = _pawapayService
        .pollDepositStatus(depositId)
        .listen((response) async {
      final updatedTransaction = transaction.copyWith(
        status: _mapDepositToTransactionStatus(response.status),
        pawapayStatus: response.status.name.toUpperCase(),
        failureCode: response.failureCode,
        failureMessage: response.errorMessage,
        providerTransactionId: response.providerTransactionId,
        completedAt: response.isTerminal ? DateTime.now() : null,
      );

      _currentTransaction = updatedTransaction;
      await _updateTransaction(updatedTransaction);

      if (response.isSuccessful) {
        _flowState = PaymentFlowState.completed;
        _isLoading = false;
      } else if (response.isTerminal) {
        _flowState = PaymentFlowState.failed;
        _error = response.errorMessage ?? 
            _pawapayService.getErrorMessage(response.failureCode);
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  void _pollPayoutStatus(String payoutId, MobileMoneyTransaction transaction) {
    _statusSubscription?.cancel();
    
    _statusSubscription = _pawapayService
        .pollPayoutStatus(payoutId)
        .listen((response) async {
      final updatedTransaction = transaction.copyWith(
        status: _mapPayoutToTransactionStatus(response.status),
        pawapayStatus: response.status.name.toUpperCase(),
        failureCode: response.failureCode,
        failureMessage: response.errorMessage,
        providerTransactionId: response.providerTransactionId,
        completedAt: response.isTerminal ? DateTime.now() : null,
      );

      _currentTransaction = updatedTransaction;
      await _updateTransaction(updatedTransaction);

      if (response.isSuccessful) {
        _flowState = PaymentFlowState.completed;
        _isLoading = false;
      } else if (response.isTerminal) {
        _flowState = PaymentFlowState.failed;
        _error = response.errorMessage ?? 
            _pawapayService.getErrorMessage(response.failureCode);
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  // ============================================
  // DATABASE OPERATIONS
  // ============================================

  Future<void> _saveTransaction(MobileMoneyTransaction transaction) async {
    try {
      await _supabase
          .from('mobile_money_transactions')
          .insert(transaction.toJson());
    } catch (e) {
      debugPrint('Error saving transaction: $e');
    }
  }

  Future<void> _updateTransaction(MobileMoneyTransaction transaction) async {
    try {
      await _supabase
          .from('mobile_money_transactions')
          .update({
            'status': transaction.status.name,
            'pawapay_status': transaction.pawapayStatus,
            'failure_code': transaction.failureCode,
            'failure_message': transaction.failureMessage,
            'provider_transaction_id': transaction.providerTransactionId,
            'completed_at': transaction.completedAt?.toIso8601String(),
          })
          .eq('pawapay_id', transaction.pawapayId);
    } catch (e) {
      debugPrint('Error updating transaction: $e');
    }
  }

  /// Load user's transaction history
  Future<void> loadTransactionHistory(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('mobile_money_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      _transactionHistory = (response as List)
          .map((json) => MobileMoneyTransaction.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transaction history: $e');
    }
  }

  /// Load group's transaction history
  Future<List<MobileMoneyTransaction>> loadGroupTransactions(
    String groupId, {
    int limit = 100,
  }) async {
    try {
      final response = await _supabase
          .from('mobile_money_transactions')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => MobileMoneyTransaction.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading group transactions: $e');
      return [];
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  MobileMoneyTransactionStatus _mapDepositToTransactionStatus(DepositStatus status) {
    switch (status) {
      case DepositStatus.accepted:
      case DepositStatus.processing:
        return MobileMoneyTransactionStatus.processing;
      case DepositStatus.completed:
        return MobileMoneyTransactionStatus.completed;
      case DepositStatus.failed:
      case DepositStatus.rejected:
      case DepositStatus.cancelled:
      case DepositStatus.unknown:
        return MobileMoneyTransactionStatus.failed;
    }
  }

  MobileMoneyTransactionStatus _mapPayoutToTransactionStatus(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.accepted:
      case PayoutStatus.enqueued:
      case PayoutStatus.processing:
        return MobileMoneyTransactionStatus.processing;
      case PayoutStatus.completed:
        return MobileMoneyTransactionStatus.completed;
      case PayoutStatus.failed:
      case PayoutStatus.rejected:
      case PayoutStatus.unknown:
        return MobileMoneyTransactionStatus.failed;
    }
  }

  /// Validate phone number
  bool isValidPhone(String phone) {
    return PawapayConfig.isValidZambianPhone(phone);
  }

  /// Get provider name for display
  String getProviderDisplayName(String providerCode) {
    for (final provider in PawapayConfig.zambianProviders) {
      if (provider.code == providerCode) {
        return provider.name;
      }
    }
    return providerCode;
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}

/// Payment flow states
enum PaymentFlowState {
  idle,                  // No payment in progress
  enteringDetails,       // User entering phone/provider
  processing,            // Initiating payment request
  awaitingConfirmation,  // Waiting for user to confirm on phone
  completed,             // Payment successful
  failed,                // Payment failed
}
