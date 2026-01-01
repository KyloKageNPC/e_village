import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import '../models/message_reaction_model.dart';
import '../models/poll_model.dart';
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
      developer.log('🔵 Sending message to chat_messages table... Group: $groupId, Sender: $senderId, Name: $senderName', name: 'ChatService');

      final response = await _client.from('chat_messages').insert({
        'group_id': groupId,
        'sender_id': senderId,
        'sender_name': senderName,
        'message': message,
        'type': type.value,
      }).select().single();

      developer.log('✅ Message sent successfully!', name: 'ChatService');
      return ChatMessageModel.fromJson(response);
    } catch (e) {
      developer.log('❌ DATABASE ERROR: $e', error: e, name: 'ChatService');
      developer.log('Error type: ${e.runtimeType}', name: 'ChatService');
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

  // =============================================
  // REACTION METHODS
  // =============================================

  // Add a reaction to a message
  Future<MessageReactionModel> addReaction({
    required String messageId,
    required String userId,
    required String userName,
    required String emoji,
  }) async {
    try {
      developer.log('🔵 Adding reaction: $emoji to message $messageId', name: 'ChatService');

      final response = await _client.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': userId,
        'user_name': userName,
        'emoji': emoji,
      }).select().single();

      developer.log('✅ Reaction added successfully!', name: 'ChatService');
      return MessageReactionModel.fromJson(response);
    } catch (e) {
      developer.log('❌ Error adding reaction: $e', error: e, name: 'ChatService');
      rethrow;
    }
  }

  // Remove a reaction from a message
  Future<void> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      developer.log('🔵 Removing reaction: $emoji from message $messageId', name: 'ChatService');

      await _client
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji);

      developer.log('✅ Reaction removed successfully!', name: 'ChatService');
    } catch (e) {
      developer.log('❌ Error removing reaction: $e', error: e, name: 'ChatService');
      rethrow;
    }
  }

  // Get reactions for a message
  Future<List<MessageReactionModel>> getMessageReactions({
    required String messageId,
  }) async {
    try {
      final response = await _client
          .from('message_reactions')
          .select()
          .eq('message_id', messageId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => MessageReactionModel.fromJson(json))
          .toList();
    } catch (e) {
      developer.log('❌ Error getting reactions: $e', error: e, name: 'ChatService');
      return [];
    }
  }

  // Get all reactions for multiple messages
  Future<Map<String, List<MessageReactionModel>>> getReactionsForMessages({
    required List<String> messageIds,
  }) async {
    try {
      if (messageIds.isEmpty) return {};

      final response = await _client
          .from('message_reactions')
          .select()
          .inFilter('message_id', messageIds)
          .order('created_at', ascending: true);

      // Group reactions by message ID
      final Map<String, List<MessageReactionModel>> reactionsMap = {};
      for (var json in response as List) {
        final reaction = MessageReactionModel.fromJson(json);
        if (!reactionsMap.containsKey(reaction.messageId)) {
          reactionsMap[reaction.messageId] = [];
        }
        reactionsMap[reaction.messageId]!.add(reaction);
      }

      return reactionsMap;
    } catch (e) {
      developer.log('❌ Error getting reactions for messages: $e', error: e, name: 'ChatService');
      return {};
    }
  }

  // Subscribe to reactions for a message (real-time)
  RealtimeChannel subscribeToReactions({
    required String messageId,
    required Function(MessageReactionModel) onReactionAdded,
    required Function(String reactionId) onReactionRemoved,
  }) {
    final channel = _client
        .channel('message_reactions_$messageId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'message_reactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'message_id',
            value: messageId,
          ),
          callback: (payload) {
            final newReaction = MessageReactionModel.fromJson(payload.newRecord);
            onReactionAdded(newReaction);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'message_reactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'message_id',
            value: messageId,
          ),
          callback: (payload) {
            final reactionId = payload.oldRecord['id'] as String;
            onReactionRemoved(reactionId);
          },
        )
        .subscribe();

    return channel;
  }

  // =============================================
  // POLL METHODS
  // =============================================

  // Create a poll
  Future<PollModel> createPoll({
    required String groupId,
    required String question,
    required List<String> options,
    required String createdBy,
    DateTime? endDate,
    bool allowMultipleVotes = false,
    bool isAnonymous = false,
  }) async {
    try {
      developer.log('🔵 Creating poll: $question', name: 'ChatService');

      // First, create a system message for the poll
      final messageResponse = await _client.from('chat_messages').insert({
        'group_id': groupId,
        'sender_id': createdBy,
        'sender_name': 'Poll',
        'message': question,
        'type': 'system',
      }).select().single();

      final messageId = messageResponse['id'] as String;

      // Create poll options as JSONB array
      final optionsJson = options.asMap().entries.map((entry) {
        return {
          'id': 'option_${entry.key}',
          'text': entry.value,
        };
      }).toList();

      // Create the poll
      final pollResponse = await _client.from('chat_polls').insert({
        'message_id': messageId,
        'group_id': groupId,
        'question': question,
        'options': optionsJson,
        'end_date': endDate?.toIso8601String(),
        'allow_multiple_votes': allowMultipleVotes,
        'is_anonymous': isAnonymous,
        'created_by': createdBy,
      }).select().single();

      developer.log('✅ Poll created successfully!', name: 'ChatService');

      // Get votes (empty for new poll)
      final voteRecords = await _getPollVoteRecords(pollId: pollResponse['id'] as String);

      return PollModel.fromJsonWithVotes(pollResponse, voteRecords);
    } catch (e) {
      developer.log('❌ Error creating poll: $e', error: e, name: 'ChatService');
      rethrow;
    }
  }

  // Get poll by message ID
  Future<PollModel?> getPollByMessageId(String messageId) async {
    try {
      final response = await _client
          .from('chat_polls')
          .select()
          .eq('message_id', messageId)
          .maybeSingle();

      if (response == null) return null;

      final voteRecords = await _getPollVoteRecords(pollId: response['id'] as String);
      return PollModel.fromJsonWithVotes(response, voteRecords);
    } catch (e) {
      developer.log('❌ Error getting poll: $e', error: e, name: 'ChatService');
      return null;
    }
  }

  // Get all polls for a group
  Future<Map<String, PollModel>> getGroupPolls(String groupId) async {
    try {
      final response = await _client
          .from('chat_polls')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      final Map<String, PollModel> polls = {};

      for (var pollJson in response as List) {
        final pollId = pollJson['id'] as String;
        final messageId = pollJson['message_id'] as String;
        final voteRecords = await _getPollVoteRecords(pollId: pollId);
        polls[messageId] = PollModel.fromJsonWithVotes(pollJson, voteRecords);
      }

      return polls;
    } catch (e) {
      developer.log('❌ Error getting group polls: $e', error: e, name: 'ChatService');
      return {};
    }
  }

  // Vote on a poll
  Future<bool> votePoll({
    required String pollId,
    required String optionId,
    required String userId,
    required String userName,
  }) async {
    try {
      developer.log('🔵 Voting on poll: $pollId, option: $optionId', name: 'ChatService');

      await _client.from('poll_votes').insert({
        'poll_id': pollId,
        'option_id': optionId,
        'user_id': userId,
        'user_name': userName,
      });

      developer.log('✅ Vote recorded successfully!', name: 'ChatService');
      return true;
    } catch (e) {
      developer.log('❌ Error voting on poll: $e', error: e, name: 'ChatService');
      return false;
    }
  }

  // Remove vote from a poll
  Future<bool> removeVote({
    required String pollId,
    required String optionId,
    required String userId,
  }) async {
    try {
      developer.log('🔵 Removing vote from poll: $pollId', name: 'ChatService');

      await _client
          .from('poll_votes')
          .delete()
          .eq('poll_id', pollId)
          .eq('option_id', optionId)
          .eq('user_id', userId);

      developer.log('✅ Vote removed successfully!', name: 'ChatService');
      return true;
    } catch (e) {
      developer.log('❌ Error removing vote: $e', error: e, name: 'ChatService');
      return false;
    }
  }

  // Get raw vote records for a poll (internal helper)
  Future<List<Map<String, dynamic>>> _getPollVoteRecords({required String pollId}) async {
    try {
      final response = await _client
          .from('poll_votes')
          .select()
          .eq('poll_id', pollId)
          .order('voted_at', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('❌ Error getting poll votes: $e', error: e, name: 'ChatService');
      return [];
    }
  }

  // Get user's votes for a poll
  Future<List<String>> getUserVotes({
    required String pollId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('poll_votes')
          .select('option_id')
          .eq('poll_id', pollId)
          .eq('user_id', userId);

      return (response as List)
          .map((json) => json['option_id'] as String)
          .toList();
    } catch (e) {
      developer.log('❌ Error getting user votes: $e', error: e, name: 'ChatService');
      return [];
    }
  }
}
