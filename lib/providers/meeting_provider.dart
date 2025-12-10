import 'package:flutter/material.dart';
import '../models/meeting_model.dart';
import '../services/meeting_service.dart';

class MeetingProvider with ChangeNotifier {
  final MeetingService _meetingService = MeetingService();

  List<MeetingModel> _meetings = [];
  MeetingModel? _currentMeeting;
  bool _isLoading = false;
  String? _errorMessage;

  List<MeetingModel> get meetings => _meetings;
  MeetingModel? get currentMeeting => _currentMeeting;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get upcoming meetings only
  List<MeetingModel> get upcomingMeetings {
    return _meetings.where((meeting) => meeting.isUpcoming).toList();
  }

  // Get past meetings only
  List<MeetingModel> get pastMeetings {
    return _meetings.where((meeting) => meeting.isPast).toList();
  }

  // Get today's meetings
  List<MeetingModel> get todayMeetings {
    return _meetings.where((meeting) => meeting.isToday).toList();
  }

  // Load meetings for a group
  Future<void> loadGroupMeetings({
    required String groupId,
    MeetingStatus? status,
    bool upcomingOnly = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _meetings = await _meetingService.getGroupMeetings(
        groupId: groupId,
        status: status,
        upcomingOnly: upcomingOnly,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new meeting
  Future<bool> createMeeting({
    required String groupId,
    required String title,
    String? description,
    required DateTime scheduledDate,
    String? location,
    String? agenda,
    required String createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newMeeting = await _meetingService.createMeeting(
        groupId: groupId,
        title: title,
        description: description,
        scheduledDate: scheduledDate,
        location: location,
        agenda: agenda,
        createdBy: createdBy,
      );

      _meetings.insert(0, newMeeting);
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

  // Load a specific meeting
  Future<void> loadMeeting(String meetingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentMeeting = await _meetingService.getMeetingById(meetingId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update meeting status
  Future<bool> updateMeetingStatus({
    required String meetingId,
    required MeetingStatus status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedMeeting = await _meetingService.updateMeetingStatus(
        meetingId: meetingId,
        status: status,
      );

      // Update in list
      final index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        _meetings[index] = updatedMeeting;
      }

      if (_currentMeeting?.id == meetingId) {
        _currentMeeting = updatedMeeting;
      }

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

  // Update meeting minutes
  Future<bool> updateMeetingMinutes({
    required String meetingId,
    required String minutes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedMeeting = await _meetingService.updateMeetingMinutes(
        meetingId: meetingId,
        minutes: minutes,
      );

      // Update in list
      final index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        _meetings[index] = updatedMeeting;
      }

      if (_currentMeeting?.id == meetingId) {
        _currentMeeting = updatedMeeting;
      }

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

  // Cancel a meeting
  Future<bool> cancelMeeting(String meetingId) async {
    return await updateMeetingStatus(
      meetingId: meetingId,
      status: MeetingStatus.cancelled,
    );
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _meetings = [];
    _currentMeeting = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
