import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_database.dart';
import '../services/savings_service.dart';
import '../services/loan_service.dart';
import '../services/chat_service.dart';
import '../models/chat_message_model.dart';
import 'dart:async';

class OfflineProvider with ChangeNotifier {
  final OfflineDatabase _offlineDb = OfflineDatabase();
  final Connectivity _connectivity = Connectivity();
  final SavingsService _savingsService = SavingsService();
  final LoanService _loanService = LoanService();
  final ChatService _chatService = ChatService();

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingOperationsCount = 0;
  StreamSubscription? _connectivitySubscription;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingOperationsCount => _pendingOperationsCount;
  bool get hasPendingOperations => _pendingOperationsCount > 0;

  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });

    // Load pending operations count
    await _updatePendingCount();

    debugPrint('✅ Offline provider initialized (Online: $_isOnline)');
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateOnlineStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
      notifyListeners();
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    _updateOnlineStatus(results);

    // Auto-sync when back online
    if (_isOnline && hasPendingOperations) {
      syncPendingOperations();
    }
  }

  void _updateOnlineStatus(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);

    if (wasOffline && _isOnline) {
      debugPrint('✅ Connection restored');
    } else if (!wasOffline && !_isOnline) {
      debugPrint('⚠️ Connection lost - switching to offline mode');
    }

    notifyListeners();
  }

  Future<void> _updatePendingCount() async {
    _pendingOperationsCount = await _offlineDb.getPendingOperationsCount();
    notifyListeners();
  }

  // ==================== CACHE OPERATIONS ====================

  Future<void> cacheTransaction(Map<String, dynamic> transaction) async {
    try {
      await _offlineDb.cacheTransaction(transaction);
      debugPrint('Transaction cached offline');
    } catch (e) {
      debugPrint('Error caching transaction: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedTransactions({
    required String userId,
    int limit = 50,
  }) async {
    try {
      return await _offlineDb.getCachedTransactions(
        userId: userId,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting cached transactions: $e');
      return [];
    }
  }

  Future<void> cacheLoan(Map<String, dynamic> loan) async {
    try {
      await _offlineDb.cacheLoan(loan);
      debugPrint('Loan cached offline');
    } catch (e) {
      debugPrint('Error caching loan: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedLoans({
    required String borrowerId,
  }) async {
    try {
      return await _offlineDb.getCachedLoans(borrowerId: borrowerId);
    } catch (e) {
      debugPrint('Error getting cached loans: $e');
      return [];
    }
  }

  Future<void> cacheSavingsAccount(Map<String, dynamic> savings) async {
    try {
      await _offlineDb.cacheSavingsAccount(savings);
      debugPrint('Savings account cached offline');
    } catch (e) {
      debugPrint('Error caching savings: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedSavingsAccount({
    required String userId,
    required String groupId,
  }) async {
    try {
      return await _offlineDb.getCachedSavingsAccount(
        userId: userId,
        groupId: groupId,
      );
    } catch (e) {
      debugPrint('Error getting cached savings: $e');
      return null;
    }
  }

  Future<void> cacheMessage(Map<String, dynamic> message) async {
    try {
      await _offlineDb.cacheMessage(message);
      debugPrint('Message cached offline');
    } catch (e) {
      debugPrint('Error caching message: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedMessages({
    required String groupId,
    int limit = 100,
  }) async {
    try {
      return await _offlineDb.getCachedMessages(
        groupId: groupId,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting cached messages: $e');
      return [];
    }
  }

  // ==================== PENDING OPERATIONS ====================

  Future<void> addPendingContribution({
    required String groupId,
    required String userId,
    required double amount,
    String? description,
  }) async {
    await _offlineDb.addPendingOperation(
      operationType: 'contribution',
      data: {
        'group_id': groupId,
        'user_id': userId,
        'amount': amount,
        'description': description,
      },
    );
    await _updatePendingCount();
    debugPrint('Contribution queued for sync');
  }

  Future<void> addPendingLoanRequest({
    required String groupId,
    required String borrowerId,
    required double amount,
    required double interestRate,
    required int durationMonths,
    required String purpose,
  }) async {
    await _offlineDb.addPendingOperation(
      operationType: 'loan_request',
      data: {
        'group_id': groupId,
        'borrower_id': borrowerId,
        'amount': amount,
        'interest_rate': interestRate,
        'duration_months': durationMonths,
        'purpose': purpose,
      },
    );
    await _updatePendingCount();
    debugPrint('Loan request queued for sync');
  }

  Future<void> addPendingMessage({
    required String groupId,
    required String senderId,
    required String content,
    required String messageType,
  }) async {
    await _offlineDb.addPendingOperation(
      operationType: 'message',
      data: {
        'group_id': groupId,
        'sender_id': senderId,
        'content': content,
        'message_type': messageType,
      },
    );
    await _updatePendingCount();
    debugPrint('Message queued for sync');
  }

  // ==================== SYNC ====================

  Future<bool> syncPendingOperations() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress');
      return false;
    }

    if (!_isOnline) {
      debugPrint('Cannot sync while offline');
      return false;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final operations = await _offlineDb.getPendingOperations();
      debugPrint('Syncing ${operations.length} pending operations...');

      int successCount = 0;
      int failureCount = 0;

      for (final operation in operations) {
        try {
          final success = await _syncOperation(operation);
          if (success) {
            await _offlineDb.removePendingOperation(operation['id']);
            successCount++;
          } else {
            await _offlineDb.incrementRetryCount(operation['id']);
            failureCount++;
          }
        } catch (e) {
          debugPrint('Error syncing operation ${operation['id']}: $e');
          await _offlineDb.incrementRetryCount(operation['id']);
          failureCount++;
        }
      }

      await _updatePendingCount();
      _isSyncing = false;
      notifyListeners();

      debugPrint('Sync complete: $successCount successful, $failureCount failed');
      return failureCount == 0;
    } catch (e) {
      debugPrint('Error during sync: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _syncOperation(Map<String, dynamic> operation) async {
    try {
      final data = operation['data'];

      switch (operation['operation_type']) {
        case 'contribution':
          debugPrint('Syncing contribution: $data');
          await _savingsService.makeContribution(
            groupId: data['group_id'],
            userId: data['user_id'],
            amount: data['amount'].toDouble(),
            description: data['description'],
          );
          return true;

        case 'loan_request':
          debugPrint('Syncing loan request: $data');
          await _loanService.createLoanRequest(
            groupId: data['group_id'],
            borrowerId: data['borrower_id'],
            amount: data['amount'].toDouble(),
            interestRate: data['interest_rate'].toDouble(),
            durationMonths: data['duration_months'],
            purpose: data['purpose'],
          );
          return true;

        case 'message':
          debugPrint('Syncing message: $data');
          await _chatService.sendMessage(
            groupId: data['group_id'],
            senderId: data['sender_id'],
            senderName: data['sender_name'] ?? 'Unknown',
            message: data['content'],
            type: MessageType.text,
          );
          return true;

        default:
          debugPrint('Unknown operation type: ${operation['operation_type']}');
          return false;
      }
    } catch (e) {
      debugPrint('Error syncing operation: $e');
      return false;
    }
  }

  // ==================== UTILITY ====================

  Future<void> clearAllCache() async {
    await _offlineDb.clearAllCache();
    await _updatePendingCount();
    debugPrint('All cache cleared');
  }

  Future<void> clearPendingOperations() async {
    await _offlineDb.clearPendingOperations();
    await _updatePendingCount();
    debugPrint('All pending operations cleared');
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
