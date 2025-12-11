import 'package:flutter/material.dart';
import '../models/message_reaction_model.dart';

class MessageReactionBar extends StatelessWidget {
  final List<MessageReactionModel> reactions;
  final Function(String emoji) onReactionTap;
  final Function() onAddReaction;
  final bool isMe;

  const MessageReactionBar({
    super.key,
    required this.reactions,
    required this.onReactionTap,
    required this.onAddReaction,
    this.isMe = false,
  });

  Map<String, List<MessageReactionModel>> _groupReactions() {
    final Map<String, List<MessageReactionModel>> grouped = {};
    for (var reaction in reactions) {
      if (!grouped.containsKey(reaction.emoji)) {
        grouped[reaction.emoji] = [];
      }
      grouped[reaction.emoji]!.add(reaction);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return SizedBox.shrink();

    final groupedReactions = _groupReactions();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...groupedReactions.entries.map((entry) => _buildReactionChip(
          context,
          entry.key,
          entry.value,
        )),
        _buildAddReactionButton(context),
      ],
    );
  }

  Widget _buildReactionChip(
    BuildContext context,
    String emoji,
    List<MessageReactionModel> reactionList,
  ) {
    final count = reactionList.length;

    return GestureDetector(
      onTap: () => onReactionTap(emoji),
      onLongPress: () {
        // Show who reacted
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('$emoji Reactions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: reactionList.map((r) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(r.userName),
              )).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.orange.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddReactionButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddReaction,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.orange.shade300,
          ),
        ),
        child: Icon(
          Icons.add_reaction_outlined,
          size: 16,
          color: isMe ? Colors.white : Colors.black54,
        ),
      ),
    );
  }
}

class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;

  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'React to message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: EmojiReactions.defaultReactions.map((emoji) {
              return GestureDetector(
                onTap: () {
                  onEmojiSelected(emoji);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
