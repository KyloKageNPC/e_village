import 'package:flutter/material.dart';
import '../models/financial_report_model.dart';
import '../models/member_analytics_model.dart';
import '../models/group_performance_model.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  FinancialReportModel? _financialReport;
  MemberAnalyticsModel? _memberAnalytics;
  GroupPerformanceModel? _groupPerformance;

  bool _isLoadingFinancial = false;
  bool _isLoadingMember = false;
  bool _isLoadingGroup = false;

  String? _errorMessage;

  FinancialReportModel? get financialReport => _financialReport;
  MemberAnalyticsModel? get memberAnalytics => _memberAnalytics;
  GroupPerformanceModel? get groupPerformance => _groupPerformance;

  bool get isLoadingFinancial => _isLoadingFinancial;
  bool get isLoadingMember => _isLoadingMember;
  bool get isLoadingGroup => _isLoadingGroup;

  String? get errorMessage => _errorMessage;

  // =============================================
  // FINANCIAL REPORT METHODS
  // =============================================

  Future<void> loadFinancialReport({
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoadingFinancial = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _financialReport = await _analyticsService.getFinancialReport(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoadingFinancial = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingFinancial = false;
      notifyListeners();
    }
  }

  void clearFinancialReport() {
    _financialReport = null;
    notifyListeners();
  }

  // =============================================
  // MEMBER ANALYTICS METHODS
  // =============================================

  Future<void> loadMemberAnalytics({
    required String memberId,
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoadingMember = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _memberAnalytics = await _analyticsService.getMemberAnalytics(
        memberId: memberId,
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoadingMember = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingMember = false;
      notifyListeners();
    }
  }

  void clearMemberAnalytics() {
    _memberAnalytics = null;
    notifyListeners();
  }

  // =============================================
  // GROUP PERFORMANCE METHODS
  // =============================================

  Future<void> loadGroupPerformance({
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoadingGroup = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groupPerformance = await _analyticsService.getGroupPerformance(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoadingGroup = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingGroup = false;
      notifyListeners();
    }
  }

  void clearGroupPerformance() {
    _groupPerformance = null;
    notifyListeners();
  }

  // =============================================
  // GENERAL METHODS
  // =============================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearAll() {
    _financialReport = null;
    _memberAnalytics = null;
    _groupPerformance = null;
    _isLoadingFinancial = false;
    _isLoadingMember = false;
    _isLoadingGroup = false;
    _errorMessage = null;
    notifyListeners();
  }
}
