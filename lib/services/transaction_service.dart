import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import 'supabase_service.dart';

class TransactionService {
  final SupabaseClient _client = SupabaseService.client;

  // Get all transactions for a user
  Future<List<TransactionModel>> getUserTransactions({
    required String userId,
    int? limit,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('transaction_date', ascending: false);

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

  // Get transactions by group
  Future<List<TransactionModel>> getGroupTransactions({
    required String groupId,
    int? limit,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select()
          .eq('group_id', groupId)
          .order('transaction_date', ascending: false);

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

  // Create a new transaction
  Future<TransactionModel> createTransaction({
    required String groupId,
    required String userId,
    required TransactionType type,
    required double amount,
    String? description,
    String? referenceId,
  }) async {
    try {
      final response = await _client.from('transactions').insert({
        'group_id': groupId,
        'user_id': userId,
        'type': type.toDbString(),
        'amount': amount,
        'description': description,
        'reference_id': referenceId,
        'status': 'completed',
      }).select().single();

      return TransactionModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get transaction summary (total income and expense)
  Future<Map<String, double>> getTransactionSummary({
    required String userId,
    String? groupId,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select('type, amount')
          .eq('user_id', userId)
          .eq('status', 'completed');

      if (groupId != null) {
        query = query.eq('group_id', groupId);
      }

      final response = await query;

      double totalIncome = 0;
      double totalExpense = 0;

      for (var transaction in response as List) {
        final type = TransactionType.fromString(transaction['type']);
        final amount = (transaction['amount'] as num).toDouble();

        if (type.isIncome) {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      return {
        'income': totalIncome,
        'expense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Filter transactions by type
  Future<List<TransactionModel>> getTransactionsByType({
    required String userId,
    required TransactionType type,
  }) async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('type', type.toDbString())
          .order('transaction_date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Filter transactions by date range
  Future<List<TransactionModel>> getTransactionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .gte('transaction_date', startDate.toIso8601String())
          .lte('transaction_date', endDate.toIso8601String())
          .order('transaction_date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Stream transactions in real-time
  Stream<List<TransactionModel>> streamUserTransactions({
    required String userId,
  }) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('transaction_date', ascending: false)
        .map((data) => data.map((json) => TransactionModel.fromJson(json)).toList());
  }
}
