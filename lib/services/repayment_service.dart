import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_repayment_model.dart';
import '../models/loan_model.dart';
import 'supabase_service.dart';

class RepaymentService {
  final SupabaseClient _client = SupabaseService.client;

  // Make a loan repayment
  Future<LoanRepaymentModel> makeRepayment({
    required String loanId,
    required double amount,
    required double principalAmount,
    required double interestAmount,
    required PaymentMethod paymentMethod,
    String? paymentReference,
    String? notes,
    required String createdBy,
  }) async {
    try {
      final response = await _client.from('loan_repayments').insert({
        'loan_id': loanId,
        'amount': amount,
        'principal_amount': principalAmount,
        'interest_amount': interestAmount,
        'payment_method': paymentMethod.value,
        'payment_reference': paymentReference,
        'notes': notes,
        'created_by': createdBy,
      }).select().single();

      // Check if loan is fully repaid and update status
      final loan = await _client
          .from('loans')
          .select()
          .eq('id', loanId)
          .single();

      final loanAmount = (loan['amount'] as num).toDouble();
      final totalRepaid = await getTotalRepaid(loanId: loanId);

      if (totalRepaid >= loanAmount) {
        await _client
            .from('loans')
            .update({
              'status': 'repaid',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', loanId);
      }

      return LoanRepaymentModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get all repayments for a loan
  Future<List<LoanRepaymentModel>> getLoanRepayments({
    required String loanId,
  }) async {
    try {
      final response = await _client
          .from('loan_repayments')
          .select()
          .eq('loan_id', loanId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LoanRepaymentModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get total amount repaid for a loan
  Future<double> getTotalRepaid({required String loanId}) async {
    try {
      final repayments = await getLoanRepayments(loanId: loanId);
      double total = 0.0;
      for (var repayment in repayments) {
        total += repayment.principalAmount;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // Get remaining balance for a loan
  Future<double> getRemainingBalance({
    required String loanId,
    required double loanAmount,
  }) async {
    try {
      final totalRepaid = await getTotalRepaid(loanId: loanId);
      return loanAmount - totalRepaid;
    } catch (e) {
      return loanAmount;
    }
  }

  // Calculate repayment schedule
  Future<List<Map<String, dynamic>>> calculateRepaymentSchedule({
    required double loanAmount,
    required double interestRate,
    required int durationMonths,
    required InterestType interestType,
  }) async {
    List<Map<String, dynamic>> schedule = [];
    double remainingPrincipal = loanAmount;

    if (interestType == InterestType.flat) {
      // Flat rate: Same interest throughout
      final totalInterest = loanAmount * (interestRate / 100);
      final monthlyPayment = (loanAmount + totalInterest) / durationMonths;
      final monthlyPrincipal = loanAmount / durationMonths;
      final monthlyInterest = totalInterest / durationMonths;

      for (int i = 1; i <= durationMonths; i++) {
        schedule.add({
          'month': i,
          'payment': monthlyPayment,
          'principal': monthlyPrincipal,
          'interest': monthlyInterest,
          'balance': loanAmount - (monthlyPrincipal * i),
        });
      }
    } else {
      // Declining balance: Interest on remaining balance
      for (int i = 1; i <= durationMonths; i++) {
        final monthlyInterest = remainingPrincipal * (interestRate / 100);
        final monthlyPrincipal = loanAmount / durationMonths;
        final monthlyPayment = monthlyPrincipal + monthlyInterest;

        schedule.add({
          'month': i,
          'payment': monthlyPayment,
          'principal': monthlyPrincipal,
          'interest': monthlyInterest,
          'balance': remainingPrincipal - monthlyPrincipal,
        });

        remainingPrincipal -= monthlyPrincipal;
      }
    }

    return schedule;
  }

  // Disburse loan (change status from approved to active)
  Future<bool> disburseLoan({
    required String loanId,
    required String disbursedBy,
  }) async {
    try {
      await _client.from('loans').update({
        'status': 'active',
        'disbursed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', loanId);

      return true;
    } catch (e) {
      return false;
    }
  }
}
