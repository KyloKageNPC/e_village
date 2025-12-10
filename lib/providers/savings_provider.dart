import 'package:flutter/foundation.dart';
import '../models/savings_account.dart';
import '../models/transaction_model.dart';
import '../services/savings_service.dart';

class SavingsProvider with ChangeNotifier {
  final SavingsService _savingsService = SavingsService();

  SavingsAccount? _currentSavingsAccount;
  List<SavingsAccount> _groupSavingsAccounts = [];
  List<TransactionModel> _contributionHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  SavingsAccount? get currentSavingsAccount => _currentSavingsAccount;
  List<SavingsAccount> get groupSavingsAccounts => _groupSavingsAccounts;
  List<TransactionModel> get contributionHistory => _contributionHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get currentBalance => _currentSavingsAccount?.balance ?? 0.0;
  double get totalContributions => _currentSavingsAccount?.totalContributions ?? 0.0;
  double get totalWithdrawals => _currentSavingsAccount?.totalWithdrawals ?? 0.0;

  // Load user's savings account for a specific group
  Future<void> loadSavingsAccount({
    required String groupId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSavingsAccount = await _savingsService.getOrCreateSavingsAccount(
        groupId: groupId,
        userId: userId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Make a contribution
  Future<bool> makeContribution({
    required String groupId,
    required String userId,
    required double amount,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSavingsAccount = await _savingsService.makeContribution(
        groupId: groupId,
        userId: userId,
        amount: amount,
        description: description,
      );
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

  // Make a withdrawal
  Future<bool> makeWithdrawal({
    required String groupId,
    required String userId,
    required double amount,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSavingsAccount = await _savingsService.makeWithdrawal(
        groupId: groupId,
        userId: userId,
        amount: amount,
        description: description,
      );
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

  // Load all group savings accounts (for treasurers)
  Future<void> loadGroupSavingsAccounts({required String groupId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groupSavingsAccounts = await _savingsService.getGroupSavingsAccounts(
        groupId: groupId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load contribution history
  Future<void> loadContributionHistory({
    required String userId,
    String? groupId,
    int? limit,
  }) async {
    try {
      _contributionHistory = await _savingsService.getContributionHistory(
        userId: userId,
        groupId: groupId,
        limit: limit,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading contribution history: $e');
    }
  }

  // Get group total savings
  Future<double> getGroupTotalSavings({required String groupId}) async {
    try {
      return await _savingsService.getGroupTotalSavings(groupId: groupId);
    } catch (e) {
      debugPrint('Error getting group total savings: $e');
      return 0.0;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSavingsAccount() {
    _currentSavingsAccount = null;
    _contributionHistory = [];
    notifyListeners();
  }
}
