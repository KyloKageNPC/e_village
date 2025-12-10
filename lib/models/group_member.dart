enum MemberRole {
  member,
  treasurer,
  chairperson,
  secretary;

  String get displayName {
    switch (this) {
      case MemberRole.member:
        return 'Member';
      case MemberRole.treasurer:
        return 'Treasurer';
      case MemberRole.chairperson:
        return 'Chairperson';
      case MemberRole.secretary:
        return 'Secretary';
    }
  }

  static MemberRole fromString(String value) {
    switch (value) {
      case 'member':
        return MemberRole.member;
      case 'treasurer':
        return MemberRole.treasurer;
      case 'chairperson':
        return MemberRole.chairperson;
      case 'secretary':
        return MemberRole.secretary;
      default:
        return MemberRole.member;
    }
  }
}

enum MemberStatus {
  active,
  inactive,
  suspended;

  String get displayName {
    switch (this) {
      case MemberStatus.active:
        return 'Active';
      case MemberStatus.inactive:
        return 'Inactive';
      case MemberStatus.suspended:
        return 'Suspended';
    }
  }

  static MemberStatus fromString(String value) {
    switch (value) {
      case 'active':
        return MemberStatus.active;
      case 'inactive':
        return MemberStatus.inactive;
      case 'suspended':
        return MemberStatus.suspended;
      default:
        return MemberStatus.active;
    }
  }
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final MemberRole role;
  final MemberStatus status;
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.role = MemberRole.member,
    this.status = MemberStatus.active,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: MemberRole.fromString(json['role'] as String),
      status: MemberStatus.fromString(json['status'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role.name,
      'status': status.name,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  bool get isLeader => role != MemberRole.member;

  bool get canApproveLoans => role == MemberRole.treasurer || role == MemberRole.chairperson;

  bool get canManageGroup => role == MemberRole.chairperson;

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    MemberRole? role,
    MemberStatus? status,
    DateTime? joinedAt,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
