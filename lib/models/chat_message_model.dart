class ChatMessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String message;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String? ?? 'Unknown',
      message: json['message'] as String,
      type: MessageType.fromString(json['type'] as String? ?? 'text'),
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'type': type.value,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  bool isSentByMe(String userId) => senderId == userId;
}

enum MessageType {
  text,
  image,
  voice,
  system;

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.voice:
        return 'voice';
      case MessageType.system:
        return 'system';
    }
  }

  static MessageType fromString(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}
