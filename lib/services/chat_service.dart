import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import 'supabase_service.dart';

class ChatService {
  final SupabaseClient _client = SupabaseService.client;

  // Send a message
  Future<ChatMessageModel> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String message,
    MessageType type = MessageType.text,
  }) async {
    try {
      final response = await _client.from('chat_messages').insert({
        'group_id': groupId,
        'sender_id': senderId,
        'sender_name': senderName,
        'message': message,
        'type': type.value,
      }).select().single();

      return ChatMessageModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get messages for a group
  Future<List<ChatMessageModel>> getGroupMessages({
    required String groupId,
    int? limit,
  }) async {
    try {
      dynamic query = _client
          .from('chat_messages')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List)
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get recent messages
  Future<List<ChatMessageModel>> getRecentMessages({
    required String groupId,
    int limit = 50,
  }) async {
    return await getGroupMessages(groupId: groupId, limit: limit);
  }

  // Subscribe to new messages (real-time)
  RealtimeChannel subscribeToMessages({
    required String groupId,
    required Function(ChatMessageModel) onNewMessage,
  }) {
    final channel = _client
        .channel('group_chat_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            final newMessage = ChatMessageModel.fromJson(payload.newRecord);
            onNewMessage(newMessage);
          },
        )
        .subscribe();

    return channel;
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _client.from('chat_messages').update({
        'is_read': true,
      }).eq('id', messageId);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client.from('chat_messages').delete().eq('id', messageId);
    } catch (e) {
      rethrow;
    }
  }

  // Get unread message count
  Future<int> getUnreadCount({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('chat_messages')
          .select()
          .eq('group_id', groupId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
