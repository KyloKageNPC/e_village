import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import 'chat_service.dart';
import 'supabase_service.dart';

/// Service for sending automated alert messages to group chats
/// These alerts are used for transparency between group members
class GroupAlertService {
  final ChatService _chatService = ChatService();
  final SupabaseClient _client = SupabaseService.client;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  // System sender ID for automated messages
  static const String systemSenderId = 'system';
  static const String systemSenderName = '📢 Group Alert';

  /// Fetch user's full name by their ID
  Future<String> getUserName(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && response['full_name'] != null) {
        return response['full_name'] as String;
      }
      return 'Unknown Member';
    } catch (e) {
      developer.log('❌ Failed to get user name: $e', error: e, name: 'GroupAlertService');
      return 'Unknown Member';
    }
  }

  /// Send a loan approval alert to the group chat
  Future<void> sendLoanApprovalAlert({
    required String groupId,
    required String borrowerName,
    required double amount,
    required String approverName,
    required String purpose,
  }) async {
    try {
      final message = '✅ Loan Approved!\n\n'
          '👤 Borrower: $borrowerName\n'
          '💰 Amount: ${_currencyFormat.format(amount)}\n'
          '📝 Purpose: $purpose\n'
          '✍️ Approved by: $approverName';

      await _chatService.sendMessage(
        groupId: groupId,
        senderId: systemSenderId,
        senderName: systemSenderName,
        message: message,
        type: MessageType.system,
      );

      developer.log('✅ Loan approval alert sent to group chat', name: 'GroupAlertService');
    } catch (e) {
      developer.log('❌ Failed to send loan approval alert: $e', error: e, name: 'GroupAlertService');
      // Don't rethrow - alerts are non-critical
    }
  }

  /// Send a loan rejection alert to the group chat
  Future<void> sendLoanRejectionAlert({
    required String groupId,
    required String borrowerName,
    required double amount,
    required String purpose,
  }) async {
    try {
      final message = '❌ Loan Request Rejected\n\n'
          '👤 Borrower: $borrowerName\n'
          '💰 Amount: ${_currencyFormat.format(amount)}\n'
          '📝 Purpose: $purpose';

      await _chatService.sendMessage(
        groupId: groupId,
        senderId: systemSenderId,
        senderName: systemSenderName,
        message: message,
        type: MessageType.system,
      );

      developer.log('✅ Loan rejection alert sent to group chat', name: 'GroupAlertService');
    } catch (e) {
      developer.log('❌ Failed to send loan rejection alert: $e', error: e, name: 'GroupAlertService');
    }
  }

  /// Send a contribution alert to the group chat
  Future<void> sendContributionAlert({
    required String groupId,
    required String memberName,
    required double amount,
    String? description,
  }) async {
    try {
      final message = '💵 New Contribution!\n\n'
          '👤 Member: $memberName\n'
          '💰 Amount: ${_currencyFormat.format(amount)}'
          '${description != null && description.isNotEmpty ? '\n📝 Note: $description' : ''}';

      await _chatService.sendMessage(
        groupId: groupId,
        senderId: systemSenderId,
        senderName: systemSenderName,
        message: message,
        type: MessageType.system,
      );

      developer.log('✅ Contribution alert sent to group chat', name: 'GroupAlertService');
    } catch (e) {
      developer.log('❌ Failed to send contribution alert: $e', error: e, name: 'GroupAlertService');
    }
  }

  /// Send a loan disbursement alert to the group chat
  Future<void> sendLoanDisbursementAlert({
    required String groupId,
    required String borrowerName,
    required double amount,
  }) async {
    try {
      final message = '💸 Loan Disbursed!\n\n'
          '👤 Borrower: $borrowerName\n'
          '💰 Amount: ${_currencyFormat.format(amount)}\n'
          '📅 Funds have been released';

      await _chatService.sendMessage(
        groupId: groupId,
        senderId: systemSenderId,
        senderName: systemSenderName,
        message: message,
        type: MessageType.system,
      );

      developer.log('✅ Loan disbursement alert sent to group chat', name: 'GroupAlertService');
    } catch (e) {
      developer.log('❌ Failed to send loan disbursement alert: $e', error: e, name: 'GroupAlertService');
    }
  }

  /// Send a loan repayment alert to the group chat
  Future<void> sendLoanRepaymentAlert({
    required String groupId,
    required String borrowerName,
    required double amount,
    required double remainingBalance,
  }) async {
    try {
      final message = '💳 Loan Repayment Received!\n\n'
          '👤 Borrower: $borrowerName\n'
          '💰 Payment: ${_currencyFormat.format(amount)}\n'
          '📊 Remaining: ${_currencyFormat.format(remainingBalance)}';

      await _chatService.sendMessage(
        groupId: groupId,
        senderId: systemSenderId,
        senderName: systemSenderName,
        message: message,
        type: MessageType.system,
      );

      developer.log('✅ Loan repayment alert sent to group chat', name: 'GroupAlertService');
    } catch (e) {
      developer.log('❌ Failed to send loan repayment alert: $e', error: e, name: 'GroupAlertService');
    }
  }

  /// Send a new loan request alert to the group chat
  Future<void> sendNewLoanRequestAlert({
    required String groupId,
    required String borrowerName,
    required double amount,
    required String purpose,
    required int durationMonths,
  }) async {
    try {
      final message = '📋 New Loan Request!\n\n'
          '👤 Borrower: $borrowerName\n'
          '💰 Amount: ${_currencyFormat.format(amount)}\n'
          '📝 Purpose: $purpose\n'
          '⏱️ Duration: $durationMonths months';

      await _chatService.sendMessage(
        groupId: groupId,
        senderId: systemSenderId,
        senderName: systemSenderName,
        message: message,
        type: MessageType.system,
      );

      developer.log('✅ New loan request alert sent to group chat', name: 'GroupAlertService');
    } catch (e) {
      developer.log('❌ Failed to send new loan request alert: $e', error: e, name: 'GroupAlertService');
    }
  }
}
