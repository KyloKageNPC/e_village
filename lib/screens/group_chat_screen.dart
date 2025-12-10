import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../models/chat_message_model.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
      _subscribeToMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    final chatProvider = context.read<ChatProvider>();
    chatProvider.unsubscribeFromMessages();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final groupProvider = context.read<GroupProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (groupProvider.selectedGroup != null) {
      await chatProvider.loadMessages(
        groupId: groupProvider.selectedGroup!.id,
      );
      _scrollToBottom();
    }
  }

  void _subscribeToMessages() {
    final groupProvider = context.read<GroupProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (groupProvider.selectedGroup != null) {
      chatProvider.subscribeToMessages(
        groupId: groupProvider.selectedGroup!.id,
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.currentUser == null) {
      _showMessage('Please log in to send messages', isError: true);
      return;
    }

    if (groupProvider.selectedGroup == null) {
      _showMessage('Please select a group first', isError: true);
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    final success = await chatProvider.sendMessage(
      groupId: groupProvider.selectedGroup!.id,
      senderId: authProvider.currentUser!.id,
      senderName: authProvider.userProfile?.fullName ?? 'Unknown User',
      message: message,
    );

    setState(() => _isSending = false);

    if (success) {
      _scrollToBottom();
    } else {
      _showMessage(
        chatProvider.errorMessage ?? 'Failed to send message',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupProvider.selectedGroup?.name ?? 'Group Chat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '${groupProvider.groupMembers.length} members',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.orange.shade600,
                    ),
                  );
                }

                if (chatProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 60, color: Colors.red.shade400),
                        SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            chatProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.6)),
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMessages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.orange.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isMe = message.isSentByMe(
                      authProvider.currentUser?.id ?? '',
                    );

                    // Show date separator if date changed
                    bool showDateSeparator = false;
                    if (index == 0) {
                      showDateSeparator = true;
                    } else {
                      final prevMessage = chatProvider.messages[index - 1];
                      final prevDate = DateTime(
                        prevMessage.createdAt.year,
                        prevMessage.createdAt.month,
                        prevMessage.createdAt.day,
                      );
                      final currentDate = DateTime(
                        message.createdAt.year,
                        message.createdAt.month,
                        message.createdAt.day,
                      );
                      showDateSeparator = !prevDate.isAtSameMomentAs(currentDate);
                    }

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _buildDateSeparator(message.createdAt),
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate.isAtSameMomentAs(today)) {
      dateText = 'Today';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.black.withValues(alpha: 0.2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    final timeFormat = DateFormat('h:mm a');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.orange.shade600 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 20 : 4),
                  topRight: Radius.circular(isMe ? 4 : 20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    timeFormat.format(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
