class VillageGroup {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? meetingSchedule;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int? memberCount;

  VillageGroup({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.meetingSchedule,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.memberCount,
  });

  factory VillageGroup.fromJson(Map<String, dynamic> json) {
    return VillageGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      meetingSchedule: json['meeting_schedule'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      memberCount: json['member_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'meeting_schedule': meetingSchedule,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'member_count': memberCount,
    };
  }

  VillageGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? meetingSchedule,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? memberCount,
  }) {
    return VillageGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      meetingSchedule: meetingSchedule ?? this.meetingSchedule,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
