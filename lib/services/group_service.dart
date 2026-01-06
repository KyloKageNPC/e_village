import 'package:flutter/foundation.dart';
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
      debugPrint('🔵 GroupService: Creating group with data:');
      debugPrint('  Name: $name');
      debugPrint('  Created by: $createdBy');
      
      final response = await _client.from('village_groups').insert({
        'name': name,
        'description': description,
        'location': location,
        'meeting_schedule': meetingSchedule,
        'created_by': createdBy,
      }).select().single();

      debugPrint('✅ GroupService: Group created successfully');
      return VillageGroup.fromJson(response);
    } catch (e) {
      debugPrint('❌ GroupService ERROR: $e');
      debugPrint('Error type: ${e.runtimeType}');
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

  // =============================================
  // GROUP INVITE CODE METHODS
  // =============================================

  // Get group by invite code
  Future<VillageGroup?> getGroupByInviteCode(String code) async {
    try {
      final response = await _client
          .from('village_groups')
          .select()
          .ilike('invite_code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return VillageGroup.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting group by invite code: $e');
      return null;
    }
  }

  // Join group using invite code
  Future<GroupMember?> joinGroupByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      // First, find the group by invite code
      final group = await getGroupByInviteCode(inviteCode);
      if (group == null) {
        throw Exception('Invalid invite code. Please check and try again.');
      }

      // Check if user is already a member
      final existingMember = await _client
          .from('group_members')
          .select()
          .eq('group_id', group.id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('You are already a member of this group.');
      }

      // Add user to the group
      final member = await addMemberToGroup(
        groupId: group.id,
        userId: userId,
        role: MemberRole.member,
      );

      debugPrint('✅ User joined group via invite code: ${group.name}');
      return member;
    } catch (e) {
      debugPrint('❌ Error joining group by invite code: $e');
      rethrow;
    }
  }

  // Regenerate invite code for a group
  Future<String?> regenerateInviteCode(String groupId) async {
    try {
      // Generate a new 6-character code
      final newCode = _generateRandomCode();
      
      // Update the group with new code
      await _client
          .from('village_groups')
          .update({
            'invite_code': newCode,
            'invite_code_created_at': DateTime.now().toIso8601String(),
          })
          .eq('id', groupId);

      debugPrint('✅ Regenerated invite code for group: $newCode');
      return newCode;
    } catch (e) {
      debugPrint('❌ Error regenerating invite code: $e');
      return null;
    }
  }

  // Generate random 6-character code
  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    var seed = random;
    for (var i = 0; i < 6; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      code += chars[seed % chars.length];
    }
    return code;
  }

  // Get group preview for invite code (minimal info for non-members)
  Future<Map<String, dynamic>?> getGroupPreviewByCode(String code) async {
    try {
      final response = await _client
          .from('village_groups')
          .select('id, name, description, location')
          .ilike('invite_code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      // Get member count
      final memberCount = await _client
          .from('group_members')
          .select()
          .eq('group_id', response['id'])
          .eq('status', 'active');

      return {
        'id': response['id'],
        'name': response['name'],
        'description': response['description'],
        'location': response['location'],
        'member_count': (memberCount as List).length,
      };
    } catch (e) {
      debugPrint('❌ Error getting group preview: $e');
      return null;
    }
  }
}
