import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/village_group.dart';
import '../models/group_member.dart';
import '../services/group_service.dart';

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();

  List<VillageGroup> _groups = [];
  VillageGroup? _selectedGroup;
  List<GroupMember> _groupMembers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<VillageGroup> get groups => _groups;
  VillageGroup? get selectedGroup => _selectedGroup;
  List<GroupMember> get groupMembers => _groupMembers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize and load saved group selection
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGroupId = prefs.getString('selected_group_id');

    if (savedGroupId != null) {
      try {
        _selectedGroup = await _groupService.getGroupById(savedGroupId);
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading saved group: $e');
      }
    }
  }

  // Select a group and save to preferences
  Future<void> selectGroup(VillageGroup group) async {
    _selectedGroup = group;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_group_id', group.id);

    notifyListeners();

    // Load group members after selection
    await loadGroupMembers(group.id);
  }

  // Clear group selection
  Future<void> clearSelection() async {
    _selectedGroup = null;
    _groupMembers = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_group_id');

    notifyListeners();
  }

  // Load all available groups
  Future<void> loadAllGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groups = await _groupService.getAllGroups();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final group = await _groupService.createGroup(
        name: name,
        description: description,
        location: location,
        meetingSchedule: meetingSchedule,
        createdBy: createdBy,
      );

      _groups.insert(0, group);
      _isLoading = false;
      notifyListeners();

      return group;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Join a group
  Future<bool> joinGroup({
    required String groupId,
    required String userId,
    MemberRole role = MemberRole.member,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _groupService.addMemberToGroup(
        groupId: groupId,
        userId: userId,
        role: role,
      );

      // Reload the group to get updated member count
      final group = await _groupService.getGroupById(groupId);
      await selectGroup(group);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load group members
  Future<void> loadGroupMembers(String groupId) async {
    try {
      _groupMembers = await _groupService.getGroupMembers(groupId: groupId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading group members: $e');
    }
  }

  // Get user's groups
  Future<void> loadUserGroups(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groups = await _groupService.getUserGroups(userId: userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
