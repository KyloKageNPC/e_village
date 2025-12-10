import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_guarantor_model.dart';
import 'supabase_service.dart';

class GuarantorService {
  final SupabaseClient _client = SupabaseService.client;

  // Add guarantors to a loan
  Future<List<LoanGuarantorModel>> addGuarantors({
    required String loanId,
    required List<Map<String, dynamic>> guarantors,
  }) async {
    try {
      final guarantorData = guarantors.map((g) {
        return {
          'loan_id': loanId,
          'guarantor_id': g['guarantor_id'],
          'guarantor_name': g['guarantor_name'],
          'guaranteed_amount': g['guaranteed_amount'],
          'status': 'pending',
        };
      }).toList();

      final response = await _client
          .from('loan_guarantors')
          .insert(guarantorData)
          .select();

      return (response as List)
          .map((json) => LoanGuarantorModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get guarantors for a loan
  Future<List<LoanGuarantorModel>> getLoanGuarantors({
    required String loanId,
  }) async {
    try {
      final response = await _client
          .from('loan_guarantors')
          .select()
          .eq('loan_id', loanId)
          .order('requested_at', ascending: true);

      return (response as List)
          .map((json) => LoanGuarantorModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get guarantor requests for a user (loans they need to guarantee)
  Future<List<LoanGuarantorModel>> getGuarantorRequests({
    required String userId,
    GuarantorStatus? status,
  }) async {
    try {
      dynamic query = _client
          .from('loan_guarantors')
          .select()
          .eq('guarantor_id', userId)
          .order('requested_at', ascending: false);

      if (status != null) {
        query = query.eq('status', status.value);
      }

      final response = await query;

      return (response as List)
          .map((json) => LoanGuarantorModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get pending guarantor requests count
  Future<int> getPendingRequestsCount({required String userId}) async {
    try {
      final response = await _client
          .from('loan_guarantors')
          .select()
          .eq('guarantor_id', userId)
          .eq('status', 'pending');

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Approve guarantor request
  Future<LoanGuarantorModel> approveGuarantorRequest({
    required String guarantorId,
    String? message,
  }) async {
    try {
      final response = await _client
          .from('loan_guarantors')
          .update({
            'status': 'approved',
            'responded_at': DateTime.now().toIso8601String(),
            'response_message': message,
          })
          .eq('id', guarantorId)
          .select()
          .single();

      return LoanGuarantorModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Reject guarantor request
  Future<LoanGuarantorModel> rejectGuarantorRequest({
    required String guarantorId,
    String? message,
  }) async {
    try {
      final response = await _client
          .from('loan_guarantors')
          .update({
            'status': 'rejected',
            'responded_at': DateTime.now().toIso8601String(),
            'response_message': message,
          })
          .eq('id', guarantorId)
          .select()
          .single();

      return LoanGuarantorModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Check if all guarantors have approved
  Future<bool> areAllGuarantorsApproved({required String loanId}) async {
    try {
      final guarantors = await getLoanGuarantors(loanId: loanId);

      if (guarantors.isEmpty) return false;

      return guarantors.every((g) => g.status == GuarantorStatus.approved);
    } catch (e) {
      return false;
    }
  }

  // Check if any guarantor has rejected
  Future<bool> hasAnyGuarantorRejected({required String loanId}) async {
    try {
      final guarantors = await getLoanGuarantors(loanId: loanId);
      return guarantors.any((g) => g.status == GuarantorStatus.rejected);
    } catch (e) {
      return false;
    }
  }

  // Get total guaranteed amount for a loan
  Future<double> getTotalGuaranteedAmount({required String loanId}) async {
    try {
      final guarantors = await getLoanGuarantors(loanId: loanId);
      double total = 0.0;
      for (var guarantor in guarantors.where((g) => g.isApproved)) {
        total += guarantor.guaranteedAmount;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }
}
