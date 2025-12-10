import 'package:flutter/foundation.dart';
import '../models/loan_model.dart';
import '../services/loan_service.dart';

class LoanProvider with ChangeNotifier {
  final LoanService _loanService = LoanService();

  List<LoanModel> _loans = [];
  List<LoanModel> _pendingLoans = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _statistics = {};

  List<LoanModel> get loans => _loans;
  List<LoanModel> get pendingLoans => _pendingLoans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get statistics => _statistics;

  Future<bool> createLoanRequest({
    required String groupId,
    required String borrowerId,
    required double amount,
    required double interestRate,
    required int durationMonths,
    required String purpose,
    InterestType interestType = InterestType.flat,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loan = await _loanService.createLoanRequest(
        groupId: groupId,
        borrowerId: borrowerId,
        amount: amount,
        interestRate: interestRate,
        durationMonths: durationMonths,
        purpose: purpose,
        interestType: interestType,
      );

      _loans.insert(0, loan);
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

  Future<void> loadBorrowerLoans({required String borrowerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _loans = await _loanService.getBorrowerLoans(borrowerId: borrowerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupLoans({
    required String groupId,
    LoanStatus? status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _loans = await _loanService.getGroupLoans(
        groupId: groupId,
        status: status,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingLoans({required String groupId}) async {
    try {
      _pendingLoans = await _loanService.getPendingLoans(groupId: groupId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading pending loans: $e');
    }
  }

  Future<bool> approveLoan({
    required String loanId,
    required String approverId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loan = await _loanService.approveLoan(
        loanId: loanId,
        approverId: approverId,
      );

      _updateLoanInList(loan);
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

  Future<bool> rejectLoan({required String loanId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loan = await _loanService.rejectLoan(loanId: loanId);
      _updateLoanInList(loan);
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

  Future<bool> disburseLoan({required String loanId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loan = await _loanService.disburseLoan(loanId: loanId);
      _updateLoanInList(loan);
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

  Future<bool> recordRepayment({
    required String loanId,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loan = await _loanService.recordRepayment(
        loanId: loanId,
        amount: amount,
      );
      _updateLoanInList(loan);
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

  Future<void> loadLoanStatistics({required String groupId}) async {
    try {
      _statistics = await _loanService.getLoanStatistics(groupId: groupId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading loan statistics: $e');
    }
  }

  void _updateLoanInList(LoanModel loan) {
    final index = _loans.indexWhere((l) => l.id == loan.id);
    if (index != -1) {
      _loans[index] = loan;
    }

    final pendingIndex = _pendingLoans.indexWhere((l) => l.id == loan.id);
    if (pendingIndex != -1) {
      _pendingLoans.removeAt(pendingIndex);
    }
  }

  void clearLoans() {
    _loans = [];
    _pendingLoans = [];
    _statistics = {};
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
