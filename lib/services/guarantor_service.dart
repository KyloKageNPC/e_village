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
      // Step 1: Get basic guarantor requests
      // Note: Use created_at for ordering as requested_at might not exist in older schemas
      dynamic query = _client
          .from('loan_guarantors')
          .select()
          .eq('guarantor_id', userId)
          .order('created_at', ascending: false);

      if (status != null) {
        query = query.eq('status', status.value);
      }

      final response = await query;
      final guarantorRequests = response as List;
      
      // If no requests found, return empty list
      if (guarantorRequests.isEmpty) {
        return [];
      }
      
      // Step 2: Fetch complete details for each request
      List<LoanGuarantorModel> enrichedRequests = [];
      
      for (var item in guarantorRequests) {
        final loanId = item['loan_id'];
        
        // Fetch loan details
        final loanData = await _client
            .from('loans')
            .select('borrower_id, amount, purpose, duration_months, interest_rate, interest_type, total_repayable, group_id')
            .eq('id', loanId)
            .maybeSingle();
        
        if (loanData == null) continue; // Skip if loan not found
        
        final borrowerId = loanData['borrower_id'];
        
        // Fetch borrower profile
        final borrowerProfile = await _client
            .from('profiles')
            .select('full_name, phone_number, avatar_url, created_at')
            .eq('id', borrowerId)
            .maybeSingle();
        
        // Fetch borrower's loan history
        final borrowerLoans = await _client
            .from('loans')
            .select('status')
            .eq('borrower_id', borrowerId);
        
        final totalLoans = (borrowerLoans as List).length;
        final completedLoans = borrowerLoans
            .where((l) => l['status'] == 'completed')
            .length;
        
        // Fetch borrower's current savings
        final savingsData = await _client
            .from('savings_accounts')
            .select('balance')
            .eq('user_id', borrowerId)
            .eq('group_id', loanData['group_id'])
            .maybeSingle();
        
        // Fetch attendance rate (if meetings table exists)
        double? attendanceRate;
        try {
          final attendanceData = await _client
              .rpc('get_member_attendance_rate', params: {
                'user_id': borrowerId,
                'group_id': loanData['group_id'],
              });
          attendanceRate = (attendanceData as num?)?.toDouble();
        } catch (e) {
          // Attendance RPC might not exist yet, default to null
          attendanceRate = null;
        }
        
        // Combine all data
        final enrichedData = <String, dynamic>{
          ...item,
          'borrower_id': borrowerId,
          'borrower_name': borrowerProfile?['full_name'],
          'borrower_phone': borrowerProfile?['phone_number'],
          'borrower_avatar_url': borrowerProfile?['avatar_url'],
          'borrower_member_since': borrowerProfile?['created_at'],
          'loan_amount': loanData['amount'],
          'loan_purpose': loanData['purpose'],
          'loan_duration_months': loanData['duration_months'],
          'loan_interest_rate': loanData['interest_rate'],
          'loan_interest_type': loanData['interest_type'],
          'loan_total_repayable': loanData['total_repayable'],
          'borrower_total_loans': totalLoans,
          'borrower_completed_loans': completedLoans,
          'borrower_current_savings': savingsData?['balance'],
          'borrower_attendance_rate': attendanceRate,
        };
        
        enrichedRequests.add(LoanGuarantorModel.fromJson(enrichedData));
      }
      
      return enrichedRequests;
    } catch (e) {
      // Error fetching guarantor requests
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

  // Get other guarantors for a specific loan (excluding current user)
  Future<List<LoanGuarantorModel>> getOtherGuarantors({
    required String loanId,
    required String currentGuarantorId,
  }) async {
    try {
      final response = await _client
          .from('loan_guarantors')
          .select()
          .eq('loan_id', loanId)
          .neq('guarantor_id', currentGuarantorId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => LoanGuarantorModel.fromJson(json))
          .toList();
    } catch (e) {
      // Error fetching other guarantors
      return [];
    }
  }
}
