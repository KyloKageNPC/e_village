import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  RealtimeChannel? _subscription;

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load messages for a group
  Future<void> loadMessages({required String groupId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages = await _chatService.getGroupMessages(groupId: groupId);
      _isLoading = false;
      notifyListeners();
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
      print('❌ CHAT SEND ERROR: $e');
      print('Error details: ${e.runtimeType}');
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
    unsubscribeFromMessages();
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribeFromMessages();
    super.dispose();
  }
}
