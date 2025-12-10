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
  bool get hasSelectedGroup => _selectedGroup != null;

  bool get isChairperson => _currentMembership?.role == MemberRole.chairperson;
  bool get isTreasurer => _currentMembership?.role == MemberRole.treasurer;
  bool get isSecretary => _currentMembership?.role == MemberRole.secretary;
  bool get isOfficer => isChairperson || isTreasurer || isSecretary;
  bool get canApproveLoans => _currentMembership?.canApproveLoans ?? false;
  bool get canManageGroup => _currentMembership?.canManageGroup ?? false;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGroupId = prefs.getString('selected_group_id');

      if (savedGroupId != null) {
        final group = await _groupService.getGroupById(savedGroupId);
        _selectedGroup = group;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error initializing GroupProvider: $e');
    }
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
