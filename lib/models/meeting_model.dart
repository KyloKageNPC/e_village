class MeetingModel {
  final String id;
  final String groupId;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final String? location;
  final String? agenda;
  final String? minutes;
  final String createdBy;
  final MeetingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  MeetingModel({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    required this.scheduledDate,
    this.location,
    this.agenda,
    this.minutes,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      // Use meeting_date if available, otherwise fall back to scheduled_date
      scheduledDate: json['meeting_date'] != null
          ? DateTime.parse(json['meeting_date'] as String)
          : DateTime.parse(json['scheduled_date'] as String),
      location: json['location'] as String?,
      agenda: json['agenda'] as String?,
      minutes: json['minutes'] as String?,
      createdBy: json['created_by'] as String,
      // Handle missing status column - default to scheduled
      status: json['status'] != null 
          ? MeetingStatus.fromString(json['status'] as String)
          : MeetingStatus.scheduled,
      createdAt: DateTime.parse(json['created_at'] as String),
      // Handle missing updated_at column - use created_at as fallback
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      'description': description,
      'meeting_date': scheduledDate.toIso8601String(),
      'location': location,
      'agenda': agenda,
      'minutes': minutes,
      'created_by': createdBy,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPast => scheduledDate.isBefore(DateTime.now());
  bool get isUpcoming => scheduledDate.isAfter(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }
}

enum MeetingStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case MeetingStatus.scheduled:
        return 'scheduled';
      case MeetingStatus.inProgress:
        return 'in_progress';
      case MeetingStatus.completed:
        return 'completed';
      case MeetingStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case MeetingStatus.scheduled:
        return 'Scheduled';
      case MeetingStatus.inProgress:
        return 'In Progress';
      case MeetingStatus.completed:
        return 'Completed';
      case MeetingStatus.cancelled:
        return 'Cancelled';
    }
  }

  static MeetingStatus fromString(String value) {
    switch (value) {
      case 'scheduled':
        return MeetingStatus.scheduled;
      case 'in_progress':
        return MeetingStatus.inProgress;
      case 'completed':
        return MeetingStatus.completed;
      case 'cancelled':
        return MeetingStatus.cancelled;
      default:
        return MeetingStatus.scheduled;
    }
  }
}
