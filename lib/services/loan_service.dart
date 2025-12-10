import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import 'supabase_service.dart';

class LoanService {
  final SupabaseClient _client = SupabaseService.client;

  // Create loan request
  Future<LoanModel> createLoanRequest({
    required String groupId,
    required String borrowerId,
    required double amount,
    required double interestRate,
    required int durationMonths,
    required String purpose,
    InterestType interestType = InterestType.flat,
  }) async {
    try {
      final response = await _client.from('loans').insert({
        'group_id': groupId,
        'borrower_id': borrowerId,
        'amount': amount,
        'interest_rate': interestRate,
        'interest_type': interestType.toDbString(),
        'duration_months': durationMonths,
        'purpose': purpose,
        'status': 'pending',
      }).select().single();

      return LoanModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get all loans for a borrower
  Future<List<LoanModel>> getBorrowerLoans({
    required String borrowerId,
  }) async {
    try {
      final response = await _client
          .from('loans')
          .select()
          .eq('borrower_id', borrowerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LoanModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get all loans for a group
  Future<List<LoanModel>> getGroupLoans({
    required String groupId,
    LoanStatus? status,
  }) async {
    try {
      var query = _client
          .from('loans')
          .select()
          .eq('group_id', groupId);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => LoanModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get pending loan requests
  Future<List<LoanModel>> getPendingLoans({
    required String groupId,
  }) async {
    try {
      final response = await _client
          .from('loans')
          .select()
          .eq('group_id', groupId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LoanModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Approve loan
  Future<LoanModel> approveLoan({
    required String loanId,
    required String approverId,
  }) async {
    try {
      final loan = await getLoanById(loanId);
      final totalRepayable = loan.calculateTotalRepayable();

      final response = await _client
          .from('loans')
          .update({
            'status': 'approved',
            'approved_by': approverId,
            'approved_at': DateTime.now().toIso8601String(),
            'total_repayable': totalRepayable,
            'balance': totalRepayable,
          })
          .eq('id', loanId)
          .select()
          .single();

      return LoanModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Reject loan
  Future<LoanModel> rejectLoan({
    required String loanId,
  }) async {
    try {
      final response = await _client
          .from('loans')
          .update({'status': 'rejected'})
          .eq('id', loanId)
          .select()
          .single();

      return LoanModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Disburse loan
  Future<LoanModel> disburseLoan({
    required String loanId,
  }) async {
    try {
      final dueDate = DateTime.now().add(
        Duration(days: 30), // Simplified - add duration_months * 30 days
      );

      final response = await _client
          .from('loans')
          .update({
            'status': 'active',
            'disbursed_at': DateTime.now().toIso8601String(),
            'due_date': dueDate.toIso8601String(),
          })
          .eq('id', loanId)
          .select()
          .single();

      return LoanModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Record loan repayment
  Future<LoanModel> recordRepayment({
    required String loanId,
    required double amount,
  }) async {
    try {
      final loan = await getLoanById(loanId);
      final newAmountRepaid = loan.amountRepaid + amount;
      final newBalance = (loan.balance ?? loan.calculateTotalRepayable()) - amount;

      String newStatus = loan.status.name;
      if (newBalance <= 0) {
        newStatus = 'completed';
      }

      final response = await _client
          .from('loans')
          .update({
            'amount_repaid': newAmountRepaid,
            'balance': newBalance,
            'status': newStatus,
          })
          .eq('id', loanId)
          .select()
          .single();

      return LoanModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get single loan by ID
  Future<LoanModel> getLoanById(String loanId) async {
    try {
      final response = await _client
          .from('loans')
          .select()
          .eq('id', loanId)
          .single();

      return LoanModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get active loans (disbursed or active status)
  Future<List<LoanModel>> getActiveLoans({
    required String borrowerId,
  }) async {
    try {
      final response = await _client
          .from('loans')
          .select()
          .eq('borrower_id', borrowerId)
          .inFilter('status', ['active', 'disbursed'])
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LoanModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get loan statistics
  Future<Map<String, dynamic>> getLoanStatistics({
    required String groupId,
  }) async {
    try {
      final loans = await getGroupLoans(groupId: groupId);

      double totalDisbursed = 0;
      double totalRepaid = 0;
      double totalOutstanding = 0;
      int activeLoansCount = 0;
      int completedLoansCount = 0;

      for (var loan in loans) {
        if (loan.status == LoanStatus.active ||
            loan.status == LoanStatus.disbursed ||
            loan.status == LoanStatus.completed) {
          totalDisbursed += loan.amount;
          totalRepaid += loan.amountRepaid;

          if (loan.status == LoanStatus.active || loan.status == LoanStatus.disbursed) {
            totalOutstanding += loan.remainingBalance;
            activeLoansCount++;
          } else if (loan.status == LoanStatus.completed) {
            completedLoansCount++;
          }
        }
      }

      return {
        'total_disbursed': totalDisbursed,
        'total_repaid': totalRepaid,
        'total_outstanding': totalOutstanding,
        'active_loans_count': activeLoansCount,
        'completed_loans_count': completedLoansCount,
        'total_loans': loans.length,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Stream loans in real-time
  Stream<List<LoanModel>> streamGroupLoans({
    required String groupId,
  }) {
    return _client
        .from('loans')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => LoanModel.fromJson(json)).toList());
  }
}
