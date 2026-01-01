import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/village_group.dart';
import '../models/group_member.dart';
import '../services/group_service.dart';

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();

  VillageGroup? _selectedGroup;
  final List<VillageGroup> _userGroups = [];
  final List<VillageGroup> _allGroups = [];
  List<GroupMember> _groupMembers = [];
  GroupMember? _currentMembership;
  final bool _isLoading = false;
  String? _errorMessage;

  VillageGroup? get selectedGroup => _selectedGroup;
  List<VillageGroup> get userGroups => _userGroups;
  List<VillageGroup> get allGroups => _allGroups;
  List<GroupMember> get groupMembers => _groupMembers;
  GroupMember? get currentMembership => _currentMembership;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  // Consider both currently selected and saved group when determining if user has a group
  bool get hasSelectedGroup => _selectedGroup != null || _savedGroupId != null;

  bool get isChairperson => _currentMembership?.role == MemberRole.chairperson;
  bool get isTreasurer => _currentMembership?.role == MemberRole.treasurer;
  bool get isSecretary => _currentMembership?.role == MemberRole.secretary;
  bool get isOfficer => isChairperson || isTreasurer || isSecretary;
  bool get canApproveLoans => _currentMembership?.canApproveLoans ?? false;
  bool get canManageGroup => _currentMembership?.canManageGroup ?? false;

  // Store saved group ID for later restoration
  String? _savedGroupId;
  String? get savedGroupId => _savedGroupId;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedGroupId = prefs.getString('selected_group_id');
      // Just load the saved group ID, full restoration happens in restoreGroupSelection
    } catch (e) {
      debugPrint('Error initializing GroupProvider: $e');
    }
  }

  // Call this after user is authenticated to fully restore group selection
  Future<void> restoreGroupSelection(String userId) async {
    if (_savedGroupId == null) return;
    
    try {
      final group = await _groupService.getGroupById(_savedGroupId!);
      // Verify user is still a member and fully select the group
      final membership = await _groupService.getMemberRole(
        groupId: group.id,
        userId: userId,
      );

      if (membership != null && membership.status == MemberStatus.active) {
        _selectedGroup = group;
        _currentMembership = membership;
        await loadGroupMembers(groupId: group.id);
        notifyListeners();
        debugPrint('✅ Group selection restored: ${group.name}');
      } else {
        // User is no longer a member, clear saved selection
        await clearGroupSelection();
        debugPrint('⚠️ User is no longer a member of the saved group');
      }
    } catch (e) {
      // Group no longer exists or other error - clear saved selection
      await clearGroupSelection();
      debugPrint('Error restoring group selection: $e');
    }
  }

  // Clear the saved group selection
  Future<void> clearGroupSelection() async {
    _selectedGroup = null;
    _currentMembership = null;
    _groupMembers = [];
    _savedGroupId = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_group_id');
    notifyListeners();
  }

  Future<void> selectGroup(VillageGroup group, String userId) async {
    try {
      final membership = await _groupService.getMemberRole(
        groupId: group.id,
        userId: userId,
      );

      if (membership != null && membership.status == MemberStatus.active) {
        _selectedGroup = group;
        _currentMembership = membership;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_group_id', group.id);

        await loadGroupMembers(groupId: group.id);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadGroupMembers({required String groupId}) async {
    try {
      _groupMembers = await _groupService.getGroupMembers(groupId: groupId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading group members: $e');
    }
  }

  // Load all groups user is a member of
  Future<List<VillageGroup>> loadUserGroups({required String userId}) async {
    try {
      final groups = await _groupService.getUserGroups(userId: userId);
      _userGroups.clear();
      _userGroups.addAll(groups);
      notifyListeners();
      return groups;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Load all available groups
  Future<List<VillageGroup>> loadAllGroups() async {
    try {
      final groups = await _groupService.getAllGroups();
      _allGroups.clear();
      _allGroups.addAll(groups);
      notifyListeners();
      return groups;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Create a new group
  Future<VillageGroup?> createGroup({
    required String name,
    String? description,
    String? location,
    String? meetingSchedule,
    required String createdBy,
  }) async {
    try {
      debugPrint('🔵 Creating group: $name by user: $createdBy');
      
      final group = await _groupService.createGroup(
        name: name,
        description: description,
        location: location,
        meetingSchedule: meetingSchedule,
        createdBy: createdBy,
      );

      debugPrint('✅ Group created successfully: ${group.id}');

      // Add creator as chairperson
      debugPrint('🔵 Adding creator as chairperson...');
      await _groupService.addMemberToGroup(
        groupId: group.id,
        userId: createdBy,
        role: MemberRole.chairperson,
      );

      debugPrint('✅ Creator added as chairperson');
      notifyListeners();
      return group;
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating group: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = e.toString();
      notifyListeners();
      rethrow; // Re-throw to let the UI handle it
    }
  }

  // Join a group
  Future<bool> joinGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _groupService.addMemberToGroup(
        groupId: groupId,
        userId: userId,
        role: MemberRole.member,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
