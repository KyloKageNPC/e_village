import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/village_group.dart';
import '../models/group_member.dart';
import 'supabase_service.dart';

class GroupService {
  final SupabaseClient _client = SupabaseService.client;

  // Create a new village group
  Future<VillageGroup> createGroup({
    required String name,
    String? description,
    String? location,
    String? meetingSchedule,
    required String createdBy,
  }) async {
    try {
      final response = await _client.from('village_groups').insert({
        'name': name,
        'description': description,
        'location': location,
        'meeting_schedule': meetingSchedule,
        'created_by': createdBy,
      }).select().single();

      return VillageGroup.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get all active groups
  Future<List<VillageGroup>> getAllGroups() async {
    try {
      final response = await _client
          .from('village_groups')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => VillageGroup.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get group by ID
  Future<VillageGroup> getGroupById(String groupId) async {
    try {
      final response = await _client
          .from('village_groups')
          .select()
          .eq('id', groupId)
          .single();

      return VillageGroup.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get groups user is a member of
  Future<List<VillageGroup>> getUserGroups({
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('group_members')
          .select('group_id, village_groups(*)')
          .eq('user_id', userId)
          .eq('status', 'active');

      return (response as List)
          .map((item) => VillageGroup.fromJson(item['village_groups']))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Add member to group
  Future<GroupMember> addMemberToGroup({
    required String groupId,
    required String userId,
    MemberRole role = MemberRole.member,
  }) async {
    try {
      final response = await _client.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': role.name,
        'status': 'active',
      }).select().single();

      return GroupMember.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get group members
  Future<List<GroupMember>> getGroupMembers({
    required String groupId,
  }) async {
    try {
      final response = await _client
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .order('joined_at', ascending: true);

      return (response as List)
          .map((json) => GroupMember.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Update member role
  Future<GroupMember> updateMemberRole({
    required String memberId,
    required MemberRole newRole,
  }) async {
    try {
      final response = await _client
          .from('group_members')
          .update({'role': newRole.name})
          .eq('id', memberId)
          .select()
          .single();

      return GroupMember.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update member status
  Future<GroupMember> updateMemberStatus({
    required String memberId,
    required MemberStatus newStatus,
  }) async {
    try {
      final response = await _client
          .from('group_members')
          .update({'status': newStatus.name})
          .eq('id', memberId)
          .select()
          .single();

      return GroupMember.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Remove member from group
  Future<void> removeMemberFromGroup({
    required String memberId,
  }) async {
    try {
      await _client
          .from('group_members')
          .delete()
          .eq('id', memberId);
    } catch (e) {
      rethrow;
    }
  }

  // Update group details
  Future<VillageGroup> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? location,
    String? meetingSchedule,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (location != null) updates['location'] = location;
      if (meetingSchedule != null) updates['meeting_schedule'] = meetingSchedule;

      final response = await _client
          .from('village_groups')
          .update(updates)
          .eq('id', groupId)
          .select()
          .single();

      return VillageGroup.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Deactivate group
  Future<void> deactivateGroup({required String groupId}) async {
    try {
      await _client
          .from('village_groups')
          .update({'is_active': false})
          .eq('id', groupId);
    } catch (e) {
      rethrow;
    }
  }

  // Get member's role in a group
  Future<GroupMember?> getMemberRole({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return GroupMember.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is a member of a group
  Future<bool> isGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final member = await getMemberRole(groupId: groupId, userId: userId);
      return member != null && member.status == MemberStatus.active;
    } catch (e) {
      return false;
    }
  }

  // Get group statistics
  Future<Map<String, dynamic>> getGroupStatistics({
    required String groupId,
  }) async {
    try {
      final members = await getGroupMembers(groupId: groupId);
      final activeMembers = members.where((m) => m.status == MemberStatus.active).length;

      return {
        'total_members': members.length,
        'active_members': activeMembers,
        'treasurers': members.where((m) => m.role == MemberRole.treasurer).length,
        'chairpersons': members.where((m) => m.role == MemberRole.chairperson).length,
      };
    } catch (e) {
      rethrow;
    }
  }
}
