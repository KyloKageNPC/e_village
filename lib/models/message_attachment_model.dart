class MessageAttachmentModel {
  final String id;
  final String messageId;
  final String fileName;
  final String fileUrl;
  final String fileType; // image, document, video, etc.
  final int? fileSize; // in bytes
  final DateTime createdAt;

  MessageAttachmentModel({
    required this.id,
    required this.messageId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    this.fileSize,
    required this.createdAt,
  });

  factory MessageAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MessageAttachmentModel(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isImage =>
      fileType == 'image' ||
      fileName.toLowerCase().endsWith('.jpg') ||
      fileName.toLowerCase().endsWith('.jpeg') ||
      fileName.toLowerCase().endsWith('.png') ||
      fileName.toLowerCase().endsWith('.gif');

  bool get isDocument =>
      fileType == 'document' ||
      fileName.toLowerCase().endsWith('.pdf') ||
      fileName.toLowerCase().endsWith('.doc') ||
      fileName.toLowerCase().endsWith('.docx');

  bool get isVideo =>
      fileType == 'video' ||
      fileName.toLowerCase().endsWith('.mp4') ||
      fileName.toLowerCase().endsWith('.mov');

  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown size';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
