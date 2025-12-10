import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meeting_model.dart';
import 'supabase_service.dart';

class MeetingService {
  final SupabaseClient _client = SupabaseService.client;

  // Create a new meeting
  Future<MeetingModel> createMeeting({
    required String groupId,
    required String title,
    String? description,
    required DateTime scheduledDate,
    String? location,
    String? agenda,
    required String createdBy,
  }) async {
    try {
      final response = await _client.from('meetings').insert({
        'group_id': groupId,
        'title': title,
        'description': description,
        'scheduled_date': scheduledDate.toIso8601String(),
        'location': location,
        'agenda': agenda,
        'created_by': createdBy,
        'status': 'scheduled',
      }).select().single();

      return MeetingModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get meetings for a group
  Future<List<MeetingModel>> getGroupMeetings({
    required String groupId,
    MeetingStatus? status,
    bool upcomingOnly = false,
  }) async {
    try {
      dynamic query = _client
          .from('meetings')
          .select()
          .eq('group_id', groupId)
          .order('scheduled_date', ascending: false);

      if (status != null) {
        query = query.eq('status', status.value);
      }

      if (upcomingOnly) {
        query = query.gte('scheduled_date', DateTime.now().toIso8601String());
      }

      final response = await query;

      return (response as List)
          .map((json) => MeetingModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get a single meeting by ID
  Future<MeetingModel> getMeetingById(String meetingId) async {
    try {
      final response = await _client
          .from('meetings')
          .select()
          .eq('id', meetingId)
          .single();

      return MeetingModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update meeting status
  Future<MeetingModel> updateMeetingStatus({
    required String meetingId,
    required MeetingStatus status,
  }) async {
    try {
      final response = await _client
          .from('meetings')
          .update({
            'status': status.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', meetingId)
          .select()
          .single();

      return MeetingModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update meeting minutes
  Future<MeetingModel> updateMeetingMinutes({
    required String meetingId,
    required String minutes,
  }) async {
    try {
      final response = await _client
          .from('meetings')
          .update({
            'minutes': minutes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', meetingId)
          .select()
          .single();

      return MeetingModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update meeting details
  Future<MeetingModel> updateMeeting({
    required String meetingId,
    String? title,
    String? description,
    DateTime? scheduledDate,
    String? location,
    String? agenda,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (scheduledDate != null) {
        updates['scheduled_date'] = scheduledDate.toIso8601String();
      }
      if (location != null) updates['location'] = location;
      if (agenda != null) updates['agenda'] = agenda;

      final response = await _client
          .from('meetings')
          .update(updates)
          .eq('id', meetingId)
          .select()
          .single();

      return MeetingModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Cancel a meeting
  Future<MeetingModel> cancelMeeting(String meetingId) async {
    return await updateMeetingStatus(
      meetingId: meetingId,
      status: MeetingStatus.cancelled,
    );
  }

  // Get upcoming meetings count
  Future<int> getUpcomingMeetingsCount({required String groupId}) async {
    try {
      final meetings = await getGroupMeetings(
        groupId: groupId,
        status: MeetingStatus.scheduled,
        upcomingOnly: true,
      );
      return meetings.length;
    } catch (e) {
      return 0;
    }
  }
}
