import 'package:flutter/material.dart';
import '../models/loan_guarantor_model.dart';
import '../services/guarantor_service.dart';

class GuarantorProvider with ChangeNotifier {
  final GuarantorService _guarantorService = GuarantorService();

  List<LoanGuarantorModel> _guarantorRequests = [];
  List<LoanGuarantorModel> _loanGuarantors = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _pendingRequestsCount = 0;

  List<LoanGuarantorModel> get guarantorRequests => _guarantorRequests;
  List<LoanGuarantorModel> get loanGuarantors => _loanGuarantors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get pendingRequestsCount => _pendingRequestsCount;

  // Get pending guarantor requests
  List<LoanGuarantorModel> get pendingRequests {
    return _guarantorRequests
        .where((g) => g.status == GuarantorStatus.pending)
        .toList();
  }

  // Add guarantors to a loan
  Future<bool> addGuarantors({
    required String loanId,
    required List<Map<String, dynamic>> guarantors,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _guarantorService.addGuarantors(
        loanId: loanId,
        guarantors: guarantors,
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

  // Load guarantor requests for current user
  Future<void> loadGuarantorRequests({
    required String userId,
    GuarantorStatus? status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _guarantorRequests = await _guarantorService.getGuarantorRequests(
        userId: userId,
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

  // Load guarantors for a specific loan
  Future<void> loadLoanGuarantors({required String loanId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _loanGuarantors = await _guarantorService.getLoanGuarantors(
        loanId: loanId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load pending requests count
  Future<void> loadPendingRequestsCount({required String userId}) async {
    try {
      _pendingRequestsCount = await _guarantorService.getPendingRequestsCount(
        userId: userId,
      );
      notifyListeners();
    } catch (e) {
      _pendingRequestsCount = 0;
    }
  }

  // Approve guarantor request
  Future<bool> approveRequest({
    required String guarantorId,
    String? message,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedGuarantor = await _guarantorService.approveGuarantorRequest(
        guarantorId: guarantorId,
        message: message,
      );

      // Update in local list
      final index = _guarantorRequests.indexWhere((g) => g.id == guarantorId);
      if (index != -1) {
        _guarantorRequests[index] = updatedGuarantor;
      }

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

  // Reject guarantor request
  Future<bool> rejectRequest({
    required String guarantorId,
    String? message,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedGuarantor = await _guarantorService.rejectGuarantorRequest(
        guarantorId: guarantorId,
        message: message,
      );

      // Update in local list
      final index = _guarantorRequests.indexWhere((g) => g.id == guarantorId);
      if (index != -1) {
        _guarantorRequests[index] = updatedGuarantor;
      }

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

  // Check if all guarantors approved for a loan
  Future<bool> checkAllGuarantorsApproved({required String loanId}) async {
    return await _guarantorService.areAllGuarantorsApproved(loanId: loanId);
  }

  // Check if any guarantor rejected for a loan
  Future<bool> checkAnyGuarantorRejected({required String loanId}) async {
    return await _guarantorService.hasAnyGuarantorRejected(loanId: loanId);
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _guarantorRequests = [];
    _loanGuarantors = [];
    _isLoading = false;
    _errorMessage = null;
    _pendingRequestsCount = 0;
    notifyListeners();
  }
}
