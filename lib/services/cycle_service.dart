import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cycle_model.dart';

/// Service for managing village banking cycles
class CycleService {
  final _supabase = Supabase.instance.client;

  // ============================================
  // CYCLE CRUD OPERATIONS
  // ============================================

  /// Get all cycles for a group
  Future<List<CycleModel>> getCycles(String groupId) async {
    try {
      final response = await _supabase
          .from('cycles')
          .select()
          .eq('group_id', groupId)
          .order('cycle_number', ascending: false);

      return (response as List)
          .map((json) => CycleModel.fromJson(json))
          .toList();
    } catch (e) {
      throw CycleException('Failed to load cycles: $e');
    }
  }

  /// Get the active cycle for a group
  Future<CycleModel?> getActiveCycle(String groupId) async {
    try {
      final response = await _supabase
          .from('cycles')
          .select()
          .eq('group_id', groupId)
          .eq('status', 'active')
          .maybeSingle();

      if (response == null) return null;
      return CycleModel.fromJson(response);
    } catch (e) {
      throw CycleException('Failed to load active cycle: $e');
    }
  }

  /// Get a specific cycle by ID
  Future<CycleModel?> getCycleById(String cycleId) async {
    try {
      final response = await _supabase
          .from('cycles')
          .select()
          .eq('id', cycleId)
          .maybeSingle();

      if (response == null) return null;
      return CycleModel.fromJson(response);
    } catch (e) {
      throw CycleException('Failed to load cycle: $e');
    }
  }

  /// Get the next cycle number for a group
  Future<int> getNextCycleNumber(String groupId) async {
    try {
      final response = await _supabase
          .from('cycles')
          .select('cycle_number')
          .eq('group_id', groupId)
          .order('cycle_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return 1;
      return (response['cycle_number'] as int) + 1;
    } catch (e) {
      return 1;
    }
  }

  /// Create a new cycle
  Future<CycleModel> createCycle({
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
    try {
      // Check if there's an active cycle
      final activeCycle = await getActiveCycle(groupId);
      if (activeCycle != null) {
        throw CycleException('There is already an active cycle. Please close it first.');
      }

      // Get next cycle number
      final cycleNumber = await getNextCycleNumber(groupId);

      final cycleData = {
        'group_id': groupId,
        'cycle_number': cycleNumber,
        'name': name,
        'start_date': startDate.toIso8601String().split('T')[0],
        'expected_end_date': expectedEndDate.toIso8601String().split('T')[0],
        'status': 'active',
        'contribution_amount': contributionAmount,
        'max_loan_multiplier': maxLoanMultiplier,
        'default_interest_rate': defaultInterestRate,
        'late_payment_penalty': latePaymentPenalty,
        'opening_fund_balance': openingBalance,
        'notes': notes,
        'created_by': createdBy,
      };

      final response = await _supabase
          .from('cycles')
          .insert(cycleData)
          .select()
          .single();

      return CycleModel.fromJson(response);
    } catch (e) {
      if (e is CycleException) rethrow;
      throw CycleException('Failed to create cycle: $e');
    }
  }

  /// Update cycle settings
  Future<CycleModel> updateCycle({
    required String cycleId,
    String? name,
    DateTime? expectedEndDate,
    double? contributionAmount,
    double? maxLoanMultiplier,
    double? defaultInterestRate,
    double? latePaymentPenalty,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (expectedEndDate != null) {
        updateData['expected_end_date'] = expectedEndDate.toIso8601String().split('T')[0];
      }
      if (contributionAmount != null) updateData['contribution_amount'] = contributionAmount;
      if (maxLoanMultiplier != null) updateData['max_loan_multiplier'] = maxLoanMultiplier;
      if (defaultInterestRate != null) updateData['default_interest_rate'] = defaultInterestRate;
      if (latePaymentPenalty != null) updateData['late_payment_penalty'] = latePaymentPenalty;
      if (notes != null) updateData['notes'] = notes;

      final response = await _supabase
          .from('cycles')
          .update(updateData)
          .eq('id', cycleId)
          .select()
          .single();

      return CycleModel.fromJson(response);
    } catch (e) {
      throw CycleException('Failed to update cycle: $e');
    }
  }

  /// Close a cycle
  Future<CycleModel> closeCycle({
    required String cycleId,
    required double closingBalance,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('cycles')
          .update({
            'status': 'closed',
            'actual_end_date': DateTime.now().toIso8601String().split('T')[0],
            'closing_fund_balance': closingBalance,
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cycleId)
          .select()
          .single();

      return CycleModel.fromJson(response);
    } catch (e) {
      throw CycleException('Failed to close cycle: $e');
    }
  }

  /// Archive a closed cycle
  Future<void> archiveCycle(String cycleId) async {
    try {
      await _supabase
          .from('cycles')
          .update({
            'status': 'archived',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cycleId)
          .eq('status', 'closed');
    } catch (e) {
      throw CycleException('Failed to archive cycle: $e');
    }
  }

  // ============================================
  // FINANCIAL CALCULATIONS
  // ============================================

  /// Calculate cycle summary from transactions
  Future<CycleSummary> calculateCycleSummary(
    String groupId, 
    DateTime startDate, 
    DateTime endDate,
  ) async {
    try {
      // Get total contributions
      final contributionsResponse = await _supabase
          .from('contribution_accounts')
          .select('amount')
          .eq('group_id', groupId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final totalContributions = (contributionsResponse as List)
          .fold<double>(0, (sum, c) => sum + (c['amount'] as num).toDouble());

      // Get loan statistics
      final loansResponse = await _supabase
          .from('loans')
          .select('amount, status')
          .eq('group_id', groupId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .inFilter('status', ['disbursed', 'active', 'completed']);

      final loans = loansResponse as List;
      final totalLoansDisbursed = loans.fold<double>(
        0, (sum, l) => sum + (l['amount'] as num).toDouble()
      );
      final activeLoans = loans.where((l) => l['status'] == 'active').length;

      // Get interest earned from repayments
      final repaymentsResponse = await _supabase
          .from('loan_repayments')
          .select('interest_amount, loan_id, loans!inner(group_id)')
          .eq('loans.group_id', groupId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final totalInterestEarned = (repaymentsResponse as List)
          .fold<double>(0, (sum, r) => sum + ((r['interest_amount'] as num?)?.toDouble() ?? 0));

      // Get expenses
      final expensesResponse = await _supabase
          .from('cycle_expenses')
          .select('amount')
          .eq('group_id', groupId)
          .eq('status', 'approved')
          .gte('expense_date', startDate.toIso8601String().split('T')[0])
          .lte('expense_date', endDate.toIso8601String().split('T')[0]);

      final totalExpenses = (expensesResponse as List)
          .fold<double>(0, (sum, e) => sum + (e['amount'] as num).toDouble());

      // Get member count
      final membersResponse = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('status', 'active');

      final totalMembers = (membersResponse as List).length;

      // Calculate outstanding loans
      final outstandingResponse = await _supabase
          .from('loans')
          .select('amount, amount_repaid')
          .eq('group_id', groupId)
          .eq('status', 'active');

      final outstandingLoans = (outstandingResponse as List).fold<double>(
        0, 
        (sum, l) => sum + ((l['amount'] as num).toDouble() - ((l['amount_repaid'] as num?)?.toDouble() ?? 0))
      );

      final netProfit = totalInterestEarned - totalExpenses;

      return CycleSummary(
        totalContributions: totalContributions,
        totalLoansDisbursed: totalLoansDisbursed,
        totalInterestEarned: totalInterestEarned,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
        totalMembers: totalMembers,
        activeLoans: activeLoans,
        outstandingLoans: outstandingLoans,
      );
    } catch (e) {
      throw CycleException('Failed to calculate cycle summary: $e');
    }
  }

  /// Update cycle financials (call periodically to keep totals up to date)
  Future<void> updateCycleFinancials(String cycleId) async {
    try {
      final cycle = await getCycleById(cycleId);
      if (cycle == null) throw CycleException('Cycle not found');

      final summary = await calculateCycleSummary(
        cycle.groupId,
        cycle.startDate,
        cycle.actualEndDate ?? cycle.expectedEndDate,
      );

      await _supabase.from('cycles').update({
        'total_contributions': summary.totalContributions,
        'total_loans_disbursed': summary.totalLoansDisbursed,
        'total_interest_earned': summary.totalInterestEarned,
        'total_expenses': summary.totalExpenses,
        'net_profit': summary.netProfit,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', cycleId);
    } catch (e) {
      if (e is CycleException) rethrow;
      throw CycleException('Failed to update cycle financials: $e');
    }
  }

  // ============================================
  // PROFIT DISTRIBUTION
  // ============================================

  /// Calculate profit distribution for all members
  Future<List<CycleProfitDistribution>> calculateProfitDistribution(
    String cycleId,
  ) async {
    try {
      final cycle = await getCycleById(cycleId);
      if (cycle == null) throw CycleException('Cycle not found');

      // Get all member contributions for this cycle period
      final contributionsResponse = await _supabase
          .from('contribution_accounts')
          .select('user_id, amount')
          .eq('group_id', cycle.groupId)
          .gte('created_at', cycle.startDate.toIso8601String())
          .lte('created_at', (cycle.actualEndDate ?? cycle.expectedEndDate).toIso8601String());

      // Calculate total contributions per member
      final memberContributions = <String, double>{};
      for (final c in contributionsResponse as List) {
        final userId = c['user_id'] as String;
        final amount = (c['amount'] as num).toDouble();
        memberContributions[userId] = (memberContributions[userId] ?? 0) + amount;
      }

      // Calculate total pool
      final totalPool = memberContributions.values.fold<double>(0, (a, b) => a + b);
      if (totalPool == 0) return [];

      // Calculate each member's share
      final distributions = <CycleProfitDistribution>[];
      final profitToDistribute = cycle.netProfit;

      for (final entry in memberContributions.entries) {
        final percentage = (entry.value / totalPool) * 100;
        final profitShare = (percentage / 100) * profitToDistribute;

        distributions.add(CycleProfitDistribution(
          id: '', // Will be set by database
          cycleId: cycleId,
          memberId: entry.key,
          totalContributions: entry.value,
          contributionPercentage: percentage,
          profitShare: profitShare,
          status: DistributionStatus.pending,
          createdAt: DateTime.now(),
        ));
      }

      return distributions;
    } catch (e) {
      if (e is CycleException) rethrow;
      throw CycleException('Failed to calculate profit distribution: $e');
    }
  }

  /// Save profit distribution records
  Future<void> saveProfitDistributions(
    List<CycleProfitDistribution> distributions,
  ) async {
    try {
      // Delete existing pending distributions for this cycle
      if (distributions.isNotEmpty) {
        await _supabase
            .from('cycle_profit_distributions')
            .delete()
            .eq('cycle_id', distributions.first.cycleId)
            .eq('status', 'pending');
      }

      // Insert new distributions
      await _supabase
          .from('cycle_profit_distributions')
          .insert(distributions.map((d) => d.toJson()).toList());
    } catch (e) {
      throw CycleException('Failed to save profit distributions: $e');
    }
  }

  /// Get profit distributions for a cycle
  Future<List<CycleProfitDistribution>> getProfitDistributions(
    String cycleId,
  ) async {
    try {
      final response = await _supabase
          .from('cycle_profit_distributions')
          .select('*, profiles(full_name)')
          .eq('cycle_id', cycleId)
          .order('profit_share', ascending: false);

      return (response as List)
          .map((json) => CycleProfitDistribution.fromJson(json))
          .toList();
    } catch (e) {
      throw CycleException('Failed to load profit distributions: $e');
    }
  }

  /// Mark a distribution as distributed
  Future<void> markDistributed({
    required String distributionId,
    required String method,
    String? transactionReference,
  }) async {
    try {
      await _supabase
          .from('cycle_profit_distributions')
          .update({
            'status': 'distributed',
            'distribution_date': DateTime.now().toIso8601String(),
            'distribution_method': method,
            'transaction_reference': transactionReference,
            'amount_distributed': await _supabase
                .from('cycle_profit_distributions')
                .select('profit_share')
                .eq('id', distributionId)
                .single()
                .then((r) => r['profit_share']),
          })
          .eq('id', distributionId);
    } catch (e) {
      throw CycleException('Failed to mark distribution: $e');
    }
  }

  // ============================================
  // EXPENSES
  // ============================================

  /// Add an expense to a cycle
  Future<CycleExpense> addExpense({
    required String cycleId,
    required String groupId,
    required String expenseType,
    required String description,
    required double amount,
    required DateTime expenseDate,
    String? receiptUrl,
    required String recordedBy,
  }) async {
    try {
      final response = await _supabase
          .from('cycle_expenses')
          .insert({
            'cycle_id': cycleId,
            'group_id': groupId,
            'expense_type': expenseType,
            'description': description,
            'amount': amount,
            'expense_date': expenseDate.toIso8601String().split('T')[0],
            'receipt_url': receiptUrl,
            'recorded_by': recordedBy,
            'status': 'pending',
          })
          .select()
          .single();

      return CycleExpense.fromJson(response);
    } catch (e) {
      throw CycleException('Failed to add expense: $e');
    }
  }

  /// Get expenses for a cycle
  Future<List<CycleExpense>> getCycleExpenses(String cycleId) async {
    try {
      final response = await _supabase
          .from('cycle_expenses')
          .select()
          .eq('cycle_id', cycleId)
          .order('expense_date', ascending: false);

      return (response as List)
          .map((json) => CycleExpense.fromJson(json))
          .toList();
    } catch (e) {
      throw CycleException('Failed to load expenses: $e');
    }
  }

  /// Approve an expense
  Future<void> approveExpense(String expenseId, String approvedBy) async {
    try {
      await _supabase
          .from('cycle_expenses')
          .update({
            'status': 'approved',
            'approved_by': approvedBy,
          })
          .eq('id', expenseId);
    } catch (e) {
      throw CycleException('Failed to approve expense: $e');
    }
  }

  /// Reject an expense
  Future<void> rejectExpense(String expenseId) async {
    try {
      await _supabase
          .from('cycle_expenses')
          .update({'status': 'rejected'})
          .eq('id', expenseId);
    } catch (e) {
      throw CycleException('Failed to reject expense: $e');
    }
  }
}

/// Exception class for cycle operations
class CycleException implements Exception {
  final String message;
  CycleException(this.message);

  @override
  String toString() => message;
}
