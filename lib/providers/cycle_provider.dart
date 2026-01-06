import 'package:flutter/foundation.dart';
import '../models/cycle_model.dart';
import '../services/cycle_service.dart';

/// Provider for managing cycle state
class CycleProvider extends ChangeNotifier {
  final CycleService _cycleService = CycleService();

  // State
  bool _isLoading = false;
  String? _error;
  List<CycleModel> _cycles = [];
  CycleModel? _activeCycle;
  CycleModel? _selectedCycle;
  CycleSummary? _currentSummary;
  List<CycleProfitDistribution> _distributions = [];
  List<CycleExpense> _expenses = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CycleModel> get cycles => _cycles;
  CycleModel? get activeCycle => _activeCycle;
  CycleModel? get selectedCycle => _selectedCycle;
  CycleSummary? get currentSummary => _currentSummary;
  List<CycleProfitDistribution> get distributions => _distributions;
  List<CycleExpense> get expenses => _expenses;

  // Computed getters
  bool get hasActiveCycle => _activeCycle != null;
  List<CycleModel> get closedCycles => _cycles.where((c) => c.status == CycleStatus.closed).toList();
  List<CycleModel> get archivedCycles => _cycles.where((c) => c.status == CycleStatus.archived).toList();

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error
  void _setError(String? message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  // ============================================
  // CYCLE OPERATIONS
  // ============================================

  /// Load all cycles for a group
  Future<void> loadCycles(String groupId) async {
    _setLoading(true);
    _error = null;

    try {
      _cycles = await _cycleService.getCycles(groupId);
      _activeCycle = _cycles.firstWhere(
        (c) => c.status == CycleStatus.active,
        orElse: () => _cycles.isNotEmpty ? _cycles.first : _cycles.first,
      );
      
      // Load summary for active cycle
      if (_activeCycle != null) {
        await loadCycleSummary(_activeCycle!.id);
      }
      
      _isLoading = false;
      notifyListeners();
    } on CycleException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to load cycles: $e');
    }
  }

  /// Load only the active cycle for a group
  Future<void> loadActiveCycle(String groupId) async {
    _setLoading(true);
    _error = null;

    try {
      _activeCycle = await _cycleService.getActiveCycle(groupId);
      _isLoading = false;
      notifyListeners();
    } on CycleException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to load active cycle: $e');
    }
  }

  /// Select a cycle for detailed view
  Future<void> selectCycle(String cycleId) async {
    _setLoading(true);
    _error = null;

    try {
      _selectedCycle = await _cycleService.getCycleById(cycleId);
      if (_selectedCycle != null) {
        await loadCycleSummary(cycleId);
        await loadDistributions(cycleId);
        await loadExpenses(cycleId);
      }
      _isLoading = false;
      notifyListeners();
    } on CycleException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to select cycle: $e');
    }
  }

  /// Create a new cycle
  Future<bool> createCycle({
    required String groupId,
    required String name,
    required DateTime startDate,
    required DateTime expectedEndDate,
    double? contributionAmount,
    double maxLoanMultiplier = 3.0,
    double defaultInterestRate = 10.0,
    double latePaymentPenalty = 5.0,
    double openingBalance = 0,
    String? notes,
    required String createdBy,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final newCycle = await _cycleService.createCycle(
        groupId: groupId,
        name: name,
        startDate: startDate,
        expectedEndDate: expectedEndDate,
        contributionAmount: contributionAmount,
        maxLoanMultiplier: maxLoanMultiplier,
        defaultInterestRate: defaultInterestRate,
        latePaymentPenalty: latePaymentPenalty,
        openingBalance: openingBalance,
        notes: notes,
        createdBy: createdBy,
      );

      _cycles.insert(0, newCycle);
      _activeCycle = newCycle;
      _isLoading = false;
      notifyListeners();
      return true;
    } on CycleException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to create cycle: $e');
      return false;
    }
  }

  /// Update cycle settings
  Future<bool> updateCycle({
    required String cycleId,
    String? name,
    DateTime? expectedEndDate,
    double? contributionAmount,
    double? maxLoanMultiplier,
    double? defaultInterestRate,
    double? latePaymentPenalty,
    String? notes,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final updated = await _cycleService.updateCycle(
        cycleId: cycleId,
        name: name,
        expectedEndDate: expectedEndDate,
        contributionAmount: contributionAmount,
        maxLoanMultiplier: maxLoanMultiplier,
        defaultInterestRate: defaultInterestRate,
        latePaymentPenalty: latePaymentPenalty,
        notes: notes,
      );

      // Update in local list
      final index = _cycles.indexWhere((c) => c.id == cycleId);
      if (index != -1) {
        _cycles[index] = updated;
      }

      if (_activeCycle?.id == cycleId) {
        _activeCycle = updated;
      }

      if (_selectedCycle?.id == cycleId) {
        _selectedCycle = updated;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on CycleException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to update cycle: $e');
      return false;
    }
  }

  /// Archive a closed cycle
  Future<bool> archiveCycle(String cycleId) async {
    _setLoading(true);
    _error = null;

    try {
      await _cycleService.archiveCycle(cycleId);

      // Update in local list
      final index = _cycles.indexWhere((c) => c.id == cycleId);
      if (index != -1) {
        _cycles[index] = _cycles[index].copyWith(status: CycleStatus.archived);
      }

      if (_selectedCycle?.id == cycleId) {
        _selectedCycle = _selectedCycle!.copyWith(status: CycleStatus.archived);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on CycleException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to archive cycle: $e');
      return false;
    }
  }

  // ============================================
  // FINANCIAL OPERATIONS
  // ============================================

  /// Load cycle summary
  Future<void> loadCycleSummary(String cycleId) async {
    try {
      final cycle = _cycles.firstWhere(
        (c) => c.id == cycleId,
        orElse: () => throw CycleException('Cycle not found'),
      );

      _currentSummary = await _cycleService.calculateCycleSummary(
        cycle.groupId,
        cycle.startDate,
        cycle.actualEndDate ?? cycle.expectedEndDate,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cycle summary: $e');
    }
  }

  /// Refresh cycle financials
  Future<void> refreshCycleFinancials(String cycleId) async {
    try {
      await _cycleService.updateCycleFinancials(cycleId);
      
      // Reload the cycle
      final updated = await _cycleService.getCycleById(cycleId);
      if (updated != null) {
        final index = _cycles.indexWhere((c) => c.id == cycleId);
        if (index != -1) {
          _cycles[index] = updated;
        }
        if (_activeCycle?.id == cycleId) {
          _activeCycle = updated;
        }
        if (_selectedCycle?.id == cycleId) {
          _selectedCycle = updated;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing cycle financials: $e');
    }
  }

  // ============================================
  // PROFIT DISTRIBUTION
  // ============================================

  /// Calculate profit distribution
  Future<List<CycleProfitDistribution>> calculateDistributions(
    String cycleId,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      _distributions = await _cycleService.calculateProfitDistribution(cycleId);
      _isLoading = false;
      notifyListeners();
      return _distributions;
    } on CycleException catch (e) {
      _setError(e.message);
      return [];
    } catch (e) {
      _setError('Failed to calculate distributions: $e');
      return [];
    }
  }

  /// Save profit distributions
  Future<bool> saveDistributions(List<CycleProfitDistribution> distributions) async {
    _setLoading(true);
    _error = null;

    try {
      await _cycleService.saveProfitDistributions(distributions);
      _distributions = distributions;
      _isLoading = false;
      notifyListeners();
      return true;
    } on CycleException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to save distributions: $e');
      return false;
    }
  }

  /// Load existing distributions
  Future<void> loadDistributions(String cycleId) async {
    try {
      _distributions = await _cycleService.getProfitDistributions(cycleId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading distributions: $e');
    }
  }

  /// Mark a distribution as distributed
  Future<bool> markDistributed({
    required String distributionId,
    required String method,
    String? transactionReference,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _cycleService.markDistributed(
        distributionId: distributionId,
        method: method,
        transactionReference: transactionReference,
      );

      // Update local state
      final index = _distributions.indexWhere((d) => d.id == distributionId);
      if (index != -1) {
        // Reload distributions to get updated data
        if (_selectedCycle != null) {
          await loadDistributions(_selectedCycle!.id);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on CycleException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to mark distribution: $e');
      return false;
    }
  }

  // ============================================
  // EXPENSES
  // ============================================

  /// Load expenses for a cycle
  Future<void> loadExpenses(String cycleId) async {
    try {
      _expenses = await _cycleService.getCycleExpenses(cycleId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }
  }

  /// Add an expense
  Future<bool> addExpense({
    required String cycleId,
    required String groupId,
    required String expenseType,
    required String description,
    required double amount,
    required DateTime expenseDate,
    String? receiptUrl,
    required String recordedBy,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final expense = await _cycleService.addExpense(
        cycleId: cycleId,
        groupId: groupId,
        expenseType: expenseType,
        description: description,
        amount: amount,
        expenseDate: expenseDate,
        receiptUrl: receiptUrl,
        recordedBy: recordedBy,
      );

      _expenses.insert(0, expense);
      _isLoading = false;
      notifyListeners();
      return true;
    } on CycleException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to add expense: $e');
      return false;
    }
  }

  /// Approve an expense
  Future<bool> approveExpense(String expenseId, String approvedBy) async {
    _setLoading(true);
    _error = null;

    try {
      await _cycleService.approveExpense(expenseId, approvedBy);

      // Update local state
      final index = _expenses.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        // Reload expenses
        if (_selectedCycle != null) {
          await loadExpenses(_selectedCycle!.id);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on CycleException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to approve expense: $e');
      return false;
    }
  }

  /// Reject an expense
  Future<bool> rejectExpense(String expenseId) async {
    _setLoading(true);
    _error = null;

    try {
      await _cycleService.rejectExpense(expenseId);

      // Reload expenses
      if (_selectedCycle != null) {
        await loadExpenses(_selectedCycle!.id);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on CycleException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to reject expense: $e');
      return false;
    }
  }

  /// Clear selection
  void clearSelection() {
    _selectedCycle = null;
    _currentSummary = null;
    _distributions = [];
    _expenses = [];
    notifyListeners();
  }

  /// Get a cycle by ID
  Future<CycleModel?> getCycleById(String cycleId) async {
    try {
      return await _cycleService.getCycleById(cycleId);
    } catch (e) {
      debugPrint('Error getting cycle by id: $e');
      return null;
    }
  }

  /// Distribute profits for a cycle
  Future<bool> distributeProfits(String cycleId) async {
    _setLoading(true);
    _error = null;

    try {
      // First calculate the distributions
      _distributions = await _cycleService.calculateProfitDistribution(cycleId);
      
      if (_distributions.isEmpty) {
        _setError('No contributions found to distribute');
        return false;
      }

      // Save the distributions
      await _cycleService.saveProfitDistributions(_distributions);
      
      // Mark them as distributed
      for (final dist in _distributions) {
        await _cycleService.markDistributed(
          distributionId: dist.id,
          method: 'system',
        );
      }

      // Refresh cycle data
      final updated = await _cycleService.getCycleById(cycleId);
      if (updated != null) {
        final index = _cycles.indexWhere((c) => c.id == cycleId);
        if (index != -1) {
          _cycles[index] = updated;
        }
        if (_activeCycle?.id == cycleId) {
          _activeCycle = updated;
        }
        if (_selectedCycle?.id == cycleId) {
          _selectedCycle = updated;
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on CycleException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to distribute profits: $e');
      return false;
    }
  }

  /// Close cycle with optional profit distribution
  Future<bool> closeCycle(
    String cycleId, {
    bool distributeProfits = false,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Get current cycle data
      final cycle = _cycles.firstWhere(
        (c) => c.id == cycleId,
        orElse: () => throw CycleException('Cycle not found'),
      );

      // Calculate closing balance
      final closingBalance = cycle.totalFundAvailable;

      // If distributing profits, do that first
      if (distributeProfits) {
        final distributed = await this.distributeProfits(cycleId);
        if (!distributed) {
          // Continue even if distribution fails - just log it
          debugPrint('Warning: Profit distribution failed');
        }
      }

      // Close the cycle
      final closed = await _cycleService.closeCycle(
        cycleId: cycleId,
        closingBalance: closingBalance,
        notes: distributeProfits ? 'Closed with profit distribution' : null,
      );

      // Update in local list
      final index = _cycles.indexWhere((c) => c.id == cycleId);
      if (index != -1) {
        _cycles[index] = closed;
      }

      if (_activeCycle?.id == cycleId) {
        _activeCycle = null;
      }

      if (_selectedCycle?.id == cycleId) {
        _selectedCycle = closed;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on CycleException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to close cycle: $e');
      return false;
    }
  }
}
