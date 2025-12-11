class PollModel {
  final String id;
  final String messageId;
  final String groupId;
  final String question;
  final List<PollOption> options;
  final DateTime? endDate;
  final bool allowMultipleVotes;
  final bool isAnonymous;
  final String createdBy;
  final DateTime createdAt;

  PollModel({
    required this.id,
    required this.messageId,
    required this.groupId,
    required this.question,
    required this.options,
    this.endDate,
    this.allowMultipleVotes = false,
    this.isAnonymous = false,
    required this.createdBy,
    required this.createdAt,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      groupId: json['group_id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List)
          .map((o) => PollOption.fromJson(o))
          .toList(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      allowMultipleVotes: json['allow_multiple_votes'] as bool? ?? false,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'group_id': groupId,
      'question': question,
      'options': options.map((o) => o.toJson()).toList(),
      'end_date': endDate?.toIso8601String(),
      'allow_multiple_votes': allowMultipleVotes,
      'is_anonymous': isAnonymous,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive {
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  bool get hasEnded {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  int get totalVotes {
    return options.fold(0, (sum, option) => sum + option.votes.length);
  }

  PollOption? getWinningOption() {
    if (options.isEmpty) return null;
    return options.reduce((a, b) => a.votes.length > b.votes.length ? a : b);
  }
}

class PollOption {
  final String id;
  final String text;
  final List<PollVote> votes;

  PollOption({
    required this.id,
    required this.text,
    required this.votes,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      text: json['text'] as String,
      votes: (json['votes'] as List?)
              ?.map((v) => PollVote.fromJson(v))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'votes': votes.map((v) => v.toJson()).toList(),
    };
  }

  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0.0;
    return (votes.length / totalVotes) * 100;
  }
}

class PollVote {
  final String userId;
  final String userName;
  final DateTime votedAt;

  PollVote({
    required this.userId,
    required this.userName,
    required this.votedAt,
  });

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      votedAt: DateTime.parse(json['voted_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'voted_at': votedAt.toIso8601String(),
    };
  }
}
