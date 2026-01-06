import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/chat_message_model.dart';
import '../../widgets/voice_message_bubble.dart';
import '../../widgets/voice_recorder_button.dart';
import '../../widgets/message_reaction_bar.dart';
import '../../widgets/poll_creator.dart';
import '../../widgets/poll_message_widget.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  Future<void> _loadMessages() async {
    final groupProvider = context.read<GroupProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (groupProvider.selectedGroup == null) return;

    await chatProvider.loadMessages(groupId: groupProvider.selectedGroup!.id);
    chatProvider.subscribeToMessages(groupId: groupProvider.selectedGroup!.id);

    _scrollToBottom();
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<ChatProvider>().unsubscribeFromMessages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();

    if (groupProvider.selectedGroup == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chat'),
          backgroundColor: Colors.orange.shade600,
        ),
        body: Center(
          child: Text('No group selected'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupProvider.selectedGroup!.name,
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
        actions: [
          IconButton(
            icon: Icon(Icons.poll, color: Colors.white),
            onPressed: _showPollCreator,
            tooltip: 'Create Poll',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.orange.shade600,
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
                          color: Colors.black26,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final authProvider = context.read<AuthProvider>();
                    final isMe = message.isSentByMe(
                      authProvider.currentUser?.id ?? '',
                    );

                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Text Input
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendTextMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),

                  // Voice Record Button
                  VoiceRecorderButton(
                    onVoiceSent: (String filePath) async {
                      await _sendVoiceMessage(filePath);
                    },
                  ),

                  SizedBox(width: 8),

                  // Send Button
                  CircleAvatar(
                    backgroundColor: Colors.orange.shade600,
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendTextMessage,
                      padding: EdgeInsets.zero,
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

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    final dateFormat = DateFormat('h:mm a');
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Check if this message is a poll
    if (message.type == MessageType.system) {
      final poll = chatProvider.getPollForMessage(message.id);
      if (poll != null && authProvider.currentUser != null) {
        return PollMessageWidget(
          poll: poll,
          currentUserId: authProvider.currentUser!.id,
          onVote: (optionId) => _handlePollVote(message.id, optionId),
        );
      }
      
      // Display system alert messages (loan approvals, contributions, etc.)
      return _buildSystemAlertBubble(message, dateFormat);
    }

    if (message.type == MessageType.voice) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: VoiceMessageBubble(
          message: message,
          isMe: isMe,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            GestureDetector(
              onLongPress: () => _showReactionPicker(message.id),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      dateFormat.format(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Reaction bar
            Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                final reactions = chatProvider.getReactionsForMessage(message.id);
                if (reactions.isEmpty) return SizedBox.shrink();

                return Padding(
                  padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 12, right: isMe ? 12 : 0),
                  child: MessageReactionBar(
                    reactions: reactions,
                    onReactionTap: (emoji) => _handleReactionTap(message.id, emoji),
                    onAddReaction: () => _showReactionPicker(message.id),
                    isMe: isMe,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show reaction picker bottom sheet
  void _showReactionPicker(String messageId) {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.currentUser == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => ReactionPicker(
        onEmojiSelected: (emoji) async {
          await chatProvider.toggleReaction(
            messageId: messageId,
            userId: authProvider.currentUser!.id,
            userName: authProvider.userProfile?.fullName ??
                     authProvider.currentUser!.email ?? 'Unknown',
            emoji: emoji,
          );
        },
      ),
    );
  }

  // Handle reaction tap (toggle reaction)
  void _handleReactionTap(String messageId, String emoji) {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.currentUser == null) return;

    chatProvider.toggleReaction(
      messageId: messageId,
      userId: authProvider.currentUser!.id,
      userName: authProvider.userProfile?.fullName ??
               authProvider.currentUser!.email ?? 'Unknown',
      emoji: emoji,
    );
  }

  // Show poll creator bottom sheet
  void _showPollCreator() {
    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.currentUser == null || groupProvider.selectedGroup == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => PollCreator(
        onCreatePoll: (question, options, endDate, allowMultiple, isAnonymous) async {
          // Capture ScaffoldMessenger before async operation
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          final success = await chatProvider.createPoll(
            groupId: groupProvider.selectedGroup!.id,
            question: question,
            options: options,
            createdBy: authProvider.currentUser!.id,
            endDate: endDate,
            allowMultipleVotes: allowMultiple,
            isAnonymous: isAnonymous,
          );

          if (success) {
            _scrollToBottom();
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Poll created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to create poll'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // Handle poll vote
  void _handlePollVote(String messageId, String optionId) {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.currentUser == null) return;

    chatProvider.toggleVote(
      messageId: messageId,
      optionId: optionId,
      userId: authProvider.currentUser!.id,
      userName: authProvider.userProfile?.fullName ??
               authProvider.currentUser!.email ?? 'Unknown',
    );
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.currentUser == null ||
        groupProvider.selectedGroup == null) {
      return;
    }

    _messageController.clear();

    final success = await chatProvider.sendMessage(
      groupId: groupProvider.selectedGroup!.id,
      senderId: authProvider.currentUser!.id,
      senderName:
          authProvider.userProfile?.fullName ?? authProvider.currentUser!.email ?? 'Unknown',
      message: text,
      type: MessageType.text,
    );

    if (success) {
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendVoiceMessage(String filePath) async {
    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.currentUser == null ||
        groupProvider.selectedGroup == null) {
      return;
    }

    // TODO: Upload voice file to Supabase Storage and get URL
    // For now, we'll use the local file path
    final success = await chatProvider.sendMessage(
      groupId: groupProvider.selectedGroup!.id,
      senderId: authProvider.currentUser!.id,
      senderName:
          authProvider.userProfile?.fullName ?? authProvider.currentUser!.email ?? 'Unknown',
      message: filePath, // Store file path or URL
      type: MessageType.voice,
    );

    if (success) {
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send voice message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build a system alert bubble for loan approvals, contributions, etc.
  Widget _buildSystemAlertBubble(ChatMessageModel message, DateFormat dateFormat) {
    // Determine the alert type and color based on message content
    Color alertColor;
    IconData alertIcon;
    
    if (message.message.contains('Loan Approved')) {
      alertColor = Colors.green;
      alertIcon = Icons.check_circle;
    } else if (message.message.contains('Loan Request Rejected') || message.message.contains('Loan Rejected')) {
      alertColor = Colors.red;
      alertIcon = Icons.cancel;
    } else if (message.message.contains('Contribution')) {
      alertColor = Colors.blue;
      alertIcon = Icons.savings;
    } else if (message.message.contains('Loan Disbursed')) {
      alertColor = Colors.purple;
      alertIcon = Icons.account_balance_wallet;
    } else if (message.message.contains('Loan Repayment')) {
      alertColor = Colors.teal;
      alertIcon = Icons.payment;
    } else if (message.message.contains('New Loan Request')) {
      alertColor = Colors.orange;
      alertIcon = Icons.request_page;
    } else {
      alertColor = Colors.grey;
      alertIcon = Icons.info;
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alertColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alertColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    alertIcon,
                    color: alertColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: alertColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  dateFormat.format(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              message.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
