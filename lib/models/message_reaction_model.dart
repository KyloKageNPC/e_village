class MessageReactionModel {
  final String id;
  final String messageId;
  final String userId;
  final String userName;
  final String emoji;
  final DateTime createdAt;

  MessageReactionModel({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.userName,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReactionModel.fromJson(Map<String, dynamic> json) {
    return MessageReactionModel(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      emoji: json['emoji'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'user_name': userName,
      'emoji': emoji,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Common emoji reactions
class EmojiReactions {
  static const String thumbsUp = '👍';
  static const String heart = '❤️';
  static const String laughing = '😂';
  static const String surprised = '😮';
  static const String sad = '😢';
  static const String celebrate = '🎉';

  static List<String> get defaultReactions => [
        thumbsUp,
        heart,
        laughing,
        surprised,
        sad,
        celebrate,
      ];
}
