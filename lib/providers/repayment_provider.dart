import 'package:flutter/material.dart';
import '../models/loan_repayment_model.dart';
import '../models/loan_model.dart';
import '../services/repayment_service.dart';

class RepaymentProvider with ChangeNotifier {
  final RepaymentService _repaymentService = RepaymentService();

  List<LoanRepaymentModel> _repayments = [];
  List<Map<String, dynamic>> _repaymentSchedule = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _totalRepaid = 0.0;
  double _remainingBalance = 0.0;

  List<LoanRepaymentModel> get repayments => _repayments;
  List<Map<String, dynamic>> get repaymentSchedule => _repaymentSchedule;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get totalRepaid => _totalRepaid;
  double get remainingBalance => _remainingBalance;

  // Load repayments for a loan
  Future<void> loadLoanRepayments({required String loanId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _repayments = await _repaymentService.getLoanRepayments(loanId: loanId);
      _totalRepaid = await _repaymentService.getTotalRepaid(loanId: loanId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate remaining balance
  Future<void> calculateRemainingBalance({
    required String loanId,
    required double loanAmount,
  }) async {
    try {
      _remainingBalance = await _repaymentService.getRemainingBalance(
        loanId: loanId,
        loanAmount: loanAmount,
      );
      notifyListeners();
    } catch (e) {
      _remainingBalance = loanAmount;
    }
  }

  // Make a repayment
  Future<bool> makeRepayment({
    required String loanId,
    required double amount,
    required double principalAmount,
    required double interestAmount,
    required PaymentMethod paymentMethod,
    String? paymentReference,
    String? notes,
    required String createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final repayment = await _repaymentService.makeRepayment(
        loanId: loanId,
        amount: amount,
        principalAmount: principalAmount,
        interestAmount: interestAmount,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        notes: notes,
        createdBy: createdBy,
      );

      _repayments.insert(0, repayment);
      _totalRepaid += principalAmount;
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

  // Calculate repayment schedule
  Future<void> calculateRepaymentSchedule({
    required double loanAmount,
    required double interestRate,
    required int durationMonths,
    required InterestType interestType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _repaymentSchedule = await _repaymentService.calculateRepaymentSchedule(
        loanAmount: loanAmount,
        interestRate: interestRate,
        durationMonths: durationMonths,
        interestType: interestType,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Disburse loan
  Future<bool> disburseLoan({
    required String loanId,
    required String disbursedBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repaymentService.disburseLoan(
        loanId: loanId,
        disbursedBy: disbursedBy,
      );
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _repayments = [];
    _repaymentSchedule = [];
    _isLoading = false;
    _errorMessage = null;
    _totalRepaid = 0.0;
    _remainingBalance = 0.0;
    notifyListeners();
  }
}
