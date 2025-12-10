import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/meeting_provider.dart';
import '../providers/group_provider.dart';
import '../models/meeting_model.dart';
import 'create_meeting_screen.dart';

class MeetingsListScreen extends StatefulWidget {
  const MeetingsListScreen({super.key});

  @override
  State<MeetingsListScreen> createState() => _MeetingsListScreenState();
}

class _MeetingsListScreenState extends State<MeetingsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeetings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetings() async {
    final groupProvider = context.read<GroupProvider>();
    final meetingProvider = context.read<MeetingProvider>();

    if (groupProvider.selectedGroup != null) {
      await meetingProvider.loadGroupMeetings(
        groupId: groupProvider.selectedGroup!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();

    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      appBar: AppBar(
        title: Text(
          'Meetings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Consumer<MeetingProvider>(
        builder: (context, meetingProvider, _) {
          if (meetingProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.orange.shade600,
              ),
            );
          }

          if (meetingProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 60, color: Colors.red.shade400),
                  SizedBox(height: 16),
                  Text(
                    'Error loading meetings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      meetingProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMeetings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Upcoming meetings
              _buildMeetingsList(meetingProvider.upcomingMeetings, true),
              // Past meetings
              _buildMeetingsList(meetingProvider.pastMeetings, false),
            ],
          );
        },
      ),
      floatingActionButton: groupProvider.canManageGroup
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateMeetingScreen(),
                  ),
                );
                if (result == true) {
                  _loadMeetings();
                }
              },
              backgroundColor: Colors.orange.shade600,
              icon: Icon(Icons.add, color: Colors.white),
              label: Text(
                'New Meeting',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildMeetingsList(List<MeetingModel> meetings, bool isUpcoming) {
    if (meetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.event_busy,
              size: 80,
              color: Colors.orange.shade400,
            ),
            SizedBox(height: 16),
            Text(
              isUpcoming ? 'No Upcoming Meetings' : 'No Past Meetings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              isUpcoming
                  ? 'Schedule a meeting to get started'
                  : 'No meeting history yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMeetings,
      color: Colors.orange.shade600,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: meetings.length,
        itemBuilder: (context, index) {
          final meeting = meetings[index];
          return _buildMeetingCard(meeting, isUpcoming);
        },
      ),
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting, bool isUpcoming) {
    final timeFormat = DateFormat('h:mm a');

    Color statusColor;
    IconData statusIcon;

    switch (meeting.status) {
      case MeetingStatus.scheduled:
        statusColor = Colors.blue.shade600;
        statusIcon = Icons.schedule;
        break;
      case MeetingStatus.inProgress:
        statusColor = Colors.green.shade600;
        statusIcon = Icons.play_circle;
        break;
      case MeetingStatus.completed:
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.check_circle;
        break;
      case MeetingStatus.cancelled:
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with date/time
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: meeting.isToday
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : [Colors.orange.shade400, Colors.orange.shade500],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        meeting.scheduledDate.day.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(meeting.scheduledDate),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            timeFormat.format(meeting.scheduledDate),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        meeting.status.displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meeting.description != null) ...[
                  Text(
                    meeting.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                if (meeting.location != null)
                  _buildInfoRow(
                    Icons.location_on,
                    'Location',
                    meeting.location!,
                  ),
                if (meeting.location != null && meeting.agenda != null)
                  SizedBox(height: 12),
                if (meeting.agenda != null)
                  _buildInfoRow(
                    Icons.list,
                    'Agenda',
                    meeting.agenda!,
                  ),
                if (meeting.minutes != null) ...[
                  SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.notes,
                    'Minutes',
                    meeting.minutes!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.orange.shade600,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
