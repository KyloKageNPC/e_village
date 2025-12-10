import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/savings_account.dart';
import '../models/transaction_model.dart';
import 'supabase_service.dart';

class SavingsService {
  final SupabaseClient _client = SupabaseService.client;

  // Get or create savings account for a user in a group
  Future<SavingsAccount> getOrCreateSavingsAccount({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Try to get existing account
      final response = await _client
          .from('savings_accounts')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return SavingsAccount.fromJson(response);
      }

      // Create new account if it doesn't exist
      final newAccount = await _client
          .from('savings_accounts')
          .insert({
            'group_id': groupId,
            'user_id': userId,
            'balance': 0.0,
            'total_contributions': 0.0,
            'total_withdrawals': 0.0,
          })
          .select()
          .single();

      return SavingsAccount.fromJson(newAccount);
    } catch (e) {
      rethrow;
    }
  }

  // Make a contribution
  Future<SavingsAccount> makeContribution({
    required String groupId,
    required String userId,
    required double amount,
    String? description,
  }) async {
    try {
      // Get current savings account
      final account = await getOrCreateSavingsAccount(
        groupId: groupId,
        userId: userId,
      );

      // Create transaction record
      await _client.from('transactions').insert({
        'group_id': groupId,
        'user_id': userId,
        'type': 'contribution',
        'amount': amount,
        'description': description ?? 'Regular contribution',
        'status': 'completed',
      });

      // Update savings account
      final updatedAccount = await _client
          .from('savings_accounts')
          .update({
            'balance': account.balance + amount,
            'total_contributions': account.totalContributions + amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', account.id)
          .select()
          .single();

      return SavingsAccount.fromJson(updatedAccount);
    } catch (e) {
      rethrow;
    }
  }

  // Make a withdrawal
  Future<SavingsAccount> makeWithdrawal({
    required String groupId,
    required String userId,
    required double amount,
    String? description,
  }) async {
    try {
      // Get current savings account
      final account = await getOrCreateSavingsAccount(
        groupId: groupId,
        userId: userId,
      );

      // Check if sufficient balance
      if (account.balance < amount) {
        throw Exception('Insufficient balance for withdrawal');
      }

      // Create transaction record
      await _client.from('transactions').insert({
        'group_id': groupId,
        'user_id': userId,
        'type': 'withdrawal',
        'amount': amount,
        'description': description ?? 'Savings withdrawal',
        'status': 'completed',
      });

      // Update savings account
      final updatedAccount = await _client
          .from('savings_accounts')
          .update({
            'balance': account.balance - amount,
            'total_withdrawals': account.totalWithdrawals + amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', account.id)
          .select()
          .single();

      return SavingsAccount.fromJson(updatedAccount);
    } catch (e) {
      rethrow;
    }
  }

  // Get savings account by ID
  Future<SavingsAccount> getSavingsAccount(String accountId) async {
    try {
      final response = await _client
          .from('savings_accounts')
          .select()
          .eq('id', accountId)
          .single();

      return SavingsAccount.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get all group savings accounts (for treasurers)
  Future<List<SavingsAccount>> getGroupSavingsAccounts({
    required String groupId,
  }) async {
    try {
      final response = await _client
          .from('savings_accounts')
          .select()
          .eq('group_id', groupId)
          .order('balance', ascending: false);

      return (response as List)
          .map((json) => SavingsAccount.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get group total savings
  Future<double> getGroupTotalSavings({required String groupId}) async {
    try {
      final accounts = await getGroupSavingsAccounts(groupId: groupId);
      double total = 0.0;
      for (var account in accounts) {
        total += account.balance;
      }
      return total;
    } catch (e) {
      rethrow;
    }
  }

  // Get contribution history for a user
  Future<List<TransactionModel>> getContributionHistory({
    required String userId,
    String? groupId,
    int? limit,
  }) async {
    try {
      dynamic query = _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .inFilter('type', ['contribution'])
          .order('created_at', ascending: false);

      if (groupId != null) {
        query = query.eq('group_id', groupId);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
