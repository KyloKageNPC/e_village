import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import '../models/message_reaction_model.dart';
import '../models/poll_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  RealtimeChannel? _subscription;
  Map<String, List<MessageReactionModel>> _reactions = {}; // messageId -> reactions
  Map<String, PollModel> _polls = {}; // messageId -> poll

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, List<MessageReactionModel>> get reactions => _reactions;
  Map<String, PollModel> get polls => _polls;

  // Load messages for a group
  Future<void> loadMessages({required String groupId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages = await _chatService.getGroupMessages(groupId: groupId);
      _isLoading = false;
      notifyListeners();

      // Load reactions and polls for all messages
      await loadReactions();
      await loadPolls(groupId);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message
  Future<bool> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String message,
    MessageType type = MessageType.text,
  }) async {
    _errorMessage = null;

    try {
      final newMessage = await _chatService.sendMessage(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        type: type,
      );

      // Add to local list if not already added by real-time subscription
      if (!_messages.any((m) => m.id == newMessage.id)) {
        _messages.add(newMessage);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('❌ CHAT SEND ERROR: $e', error: e, name: 'ChatProvider');
      developer.log('Error details: ${e.runtimeType}', name: 'ChatProvider');
      notifyListeners();
      return false;
    }
  }

  // Subscribe to real-time messages
  void subscribeToMessages({required String groupId}) {
    _subscription = _chatService.subscribeToMessages(
      groupId: groupId,
      onNewMessage: (newMessage) {
        // Only add if not already in list
        if (!_messages.any((m) => m.id == newMessage.id)) {
          _messages.add(newMessage);
          notifyListeners();
        }
      },
    );
  }

  // Unsubscribe from real-time messages
  void unsubscribeFromMessages() {
    _subscription?.unsubscribe();
    _subscription = null;
  }

  // Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _chatService.markMessageAsRead(messageId);

      // Update local message
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = ChatMessageModel(
          id: _messages[index].id,
          groupId: _messages[index].groupId,
          senderId: _messages[index].senderId,
          senderName: _messages[index].senderName,
          message: _messages[index].message,
          type: _messages[index].type,
          createdAt: _messages[index].createdAt,
          isRead: true,
        );
        notifyListeners();
      }
    } catch (e) {
      // Silently fail for read receipts
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _messages = [];
    _isLoading = false;
    _errorMessage = null;
    _reactions = {};
    _polls = {};
    unsubscribeFromMessages();
    notifyListeners();
  }

  // =============================================
  // REACTION METHODS
  // =============================================

  // Get reactions for a specific message
  List<MessageReactionModel> getReactionsForMessage(String messageId) {
    return _reactions[messageId] ?? [];
  }

  // Load reactions for all current messages
  Future<void> loadReactions() async {
    if (_messages.isEmpty) return;

    try {
      final messageIds = _messages.map((m) => m.id).toList();
      _reactions = await _chatService.getReactionsForMessages(messageIds: messageIds);
      notifyListeners();
    } catch (e, st) {
      developer.log('❌ Error loading reactions: $e', error: e, stackTrace: st, name: 'ChatProvider');
    }
  }

  // Add a reaction to a message
  Future<bool> addReaction({
    required String messageId,
    required String userId,
    required String userName,
    required String emoji,
  }) async {
    try {
      final newReaction = await _chatService.addReaction(
        messageId: messageId,
        userId: userId,
        userName: userName,
        emoji: emoji,
      );

      // Update local reactions
      if (!_reactions.containsKey(messageId)) {
        _reactions[messageId] = [];
      }

      // Check if user already has this reaction
      final existingIndex = _reactions[messageId]!.indexWhere(
        (r) => r.userId == userId && r.emoji == emoji,
      );

      if (existingIndex == -1) {
        _reactions[messageId]!.add(newReaction);
        notifyListeners();
      }

      return true;
    } catch (e, st) {
      developer.log('❌ Error adding reaction: $e', error: e, stackTrace: st, name: 'ChatProvider');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove a reaction from a message
  Future<bool> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await _chatService.removeReaction(
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );

      // Update local reactions
      if (_reactions.containsKey(messageId)) {
        _reactions[messageId]!.removeWhere(
          (r) => r.userId == userId && r.emoji == emoji,
        );
        notifyListeners();
      }

      return true;
    } catch (e, st) {
      developer.log('❌ Error removing reaction: $e', error: e, stackTrace: st, name: 'ChatProvider');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle a reaction (add if doesn't exist, remove if exists)
  Future<bool> toggleReaction({
    required String messageId,
    required String userId,
    required String userName,
    required String emoji,
  }) async {
    // Check if user already has this reaction
    final reactions = getReactionsForMessage(messageId);
    final hasReaction = reactions.any(
      (r) => r.userId == userId && r.emoji == emoji,
    );

    if (hasReaction) {
      return await removeReaction(
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );
    } else {
      return await addReaction(
        messageId: messageId,
        userId: userId,
        userName: userName,
        emoji: emoji,
      );
    }
  }

  // =============================================
  // POLL METHODS
  // =============================================

  // Get poll for a specific message
  PollModel? getPollForMessage(String messageId) {
    return _polls[messageId];
  }

  // Load polls for a group
  Future<void> loadPolls(String groupId) async {
    try {
      _polls = await _chatService.getGroupPolls(groupId);
      notifyListeners();
    } catch (e, st) {
      developer.log('❌ Error loading polls: $e', error: e, stackTrace: st, name: 'ChatProvider');
    }
  }

  // Create a poll
  Future<bool> createPoll({
    required String groupId,
    required String question,
    required List<String> options,
    required String createdBy,
    DateTime? endDate,
    bool allowMultipleVotes = false,
    bool isAnonymous = false,
  }) async {
    try {
      final poll = await _chatService.createPoll(
        groupId: groupId,
        question: question,
        options: options,
        createdBy: createdBy,
        endDate: endDate,
        allowMultipleVotes: allowMultipleVotes,
        isAnonymous: isAnonymous,
      );

      // Add poll to local state
      _polls[poll.messageId] = poll;
      notifyListeners();

      // Reload messages to show the poll message
      await loadMessages(groupId: groupId);

      return true;
    } catch (e, st) {
      developer.log('❌ Error creating poll: $e', error: e, stackTrace: st, name: 'ChatProvider');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Vote on a poll
  Future<bool> votePoll({
    required String messageId,
    required String optionId,
    required String userId,
    required String userName,
  }) async {
    final poll = _polls[messageId];
    if (poll == null) return false;

    try {
      final success = await _chatService.votePoll(
        pollId: poll.id,
        optionId: optionId,
        userId: userId,
        userName: userName,
      );

      if (success) {
        // Reload the poll to get updated votes
        final updatedPoll = await _chatService.getPollByMessageId(messageId);
        if (updatedPoll != null) {
          _polls[messageId] = updatedPoll;
          notifyListeners();
        }
      }

      return success;
    } catch (e, st) {
      developer.log('❌ Error voting on poll: $e', error: e, stackTrace: st, name: 'ChatProvider');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove vote from a poll
  Future<bool> removeVote({
    required String messageId,
    required String optionId,
    required String userId,
  }) async {
    final poll = _polls[messageId];
    if (poll == null) return false;

    try {
      final success = await _chatService.removeVote(
        pollId: poll.id,
        optionId: optionId,
        userId: userId,
      );

      if (success) {
        // Reload the poll to get updated votes
        final updatedPoll = await _chatService.getPollByMessageId(messageId);
        if (updatedPoll != null) {
          _polls[messageId] = updatedPoll;
          notifyListeners();
        }
      }

      return success;
    } catch (e, st) {
      developer.log('❌ Error removing vote: $e', error: e, stackTrace: st, name: 'ChatProvider');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle vote on a poll option
  Future<bool> toggleVote({
    required String messageId,
    required String optionId,
    required String userId,
    required String userName,
  }) async {
    final poll = _polls[messageId];
    if (poll == null) return false;

    // Check if user has already voted for this option
    final option = poll.options.firstWhere((opt) => opt.id == optionId);
    final hasVoted = option.votes.any((vote) => vote.userId == userId);

    if (hasVoted) {
      // If poll doesn't allow multiple votes, don't allow toggling
      if (!poll.allowMultipleVotes) {
        return await removeVote(
          messageId: messageId,
          optionId: optionId,
          userId: userId,
        );
      } else {
        return await removeVote(
          messageId: messageId,
          optionId: optionId,
          userId: userId,
        );
      }
    } else {
      // If poll doesn't allow multiple votes, remove any existing votes first
      if (!poll.allowMultipleVotes) {
        for (var opt in poll.options) {
          final userVote = opt.votes.firstWhere(
            (v) => v.userId == userId,
            orElse: () => PollVote(userId: '', userName: '', votedAt: DateTime.now()),
          );
          if (userVote.userId.isNotEmpty) {
            await removeVote(
              messageId: messageId,
              optionId: opt.id,
              userId: userId,
            );
          }
        }
      }

      return await votePoll(
        messageId: messageId,
        optionId: optionId,
        userId: userId,
        userName: userName,
      );
    }
  }

  @override
  void dispose() {
    unsubscribeFromMessages();
    super.dispose();
  }
}
