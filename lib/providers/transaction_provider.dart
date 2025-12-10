import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, double> _summary = {
    'income': 0,
    'expense': 0,
    'balance': 0,
  };

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, double> get summary => _summary;
  double get balance => _summary['balance'] ?? 0;
  double get income => _summary['income'] ?? 0;
  double get expense => _summary['expense'] ?? 0;

  Future<void> loadUserTransactions({
    required String userId,
    int? limit,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _transactionService.getUserTransactions(
        userId: userId,
        limit: limit,
      );
      await loadTransactionSummary(userId: userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTransactionSummary({
    required String userId,
    String? groupId,
  }) async {
    try {
      _summary = await _transactionService.getTransactionSummary(
        userId: userId,
        groupId: groupId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transaction summary: $e');
    }
  }

  Future<bool> createTransaction({
    required String groupId,
    required String userId,
    required TransactionType type,
    required double amount,
    String? description,
    String? referenceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transaction = await _transactionService.createTransaction(
        groupId: groupId,
        userId: userId,
        type: type,
        amount: amount,
        description: description,
        referenceId: referenceId,
      );

      _transactions.insert(0, transaction);
      await loadTransactionSummary(userId: userId, groupId: groupId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadGroupTransactions({
    required String groupId,
    int? limit,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _transactionService.getGroupTransactions(
        groupId: groupId,
        limit: limit,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterByType({
    required String userId,
    required TransactionType type,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _transactionService.getTransactionsByType(
        userId: userId,
        type: type,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _transactionService.getTransactionsByDateRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearTransactions() {
    _transactions = [];
    _summary = {'income': 0, 'expense': 0, 'balance': 0};
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
