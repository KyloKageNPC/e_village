import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/meeting_model.dart';
import '../models/attendance_model.dart';
import '../providers/meeting_provider.dart';
import '../providers/group_provider.dart';
import '../services/meeting_service.dart';

class MeetingDetailsScreen extends StatefulWidget {
  final MeetingModel meeting;

  const MeetingDetailsScreen({
    super.key,
    required this.meeting,
  });

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MeetingService _meetingService = MeetingService();

  List<AttendanceModel> _attendance = [];
  Map<String, int> _attendanceStats = {};
  bool _isLoadingAttendance = false;
  bool _isEditingMinutes = false;
  final TextEditingController _minutesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _minutesController.text = widget.meeting.minutes ?? '';
    _loadAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoadingAttendance = true);
    try {
      final attendance = await _meetingService.getMeetingAttendance(
        meetingId: widget.meeting.id,
      );
      final stats = await _meetingService.getAttendanceStats(
        meetingId: widget.meeting.id,
      );
      setState(() {
        _attendance = attendance;
        _attendanceStats = stats;
        _isLoadingAttendance = false;
      });
    } catch (e) {
      setState(() => _isLoadingAttendance = false);
      _showMessage('Error loading attendance: $e', isError: true);
    }
  }

  Future<void> _updateMeetingStatus(MeetingStatus status) async {
    final meetingProvider = context.read<MeetingProvider>();
    final success = await meetingProvider.updateMeetingStatus(
      meetingId: widget.meeting.id,
      status: status,
    );

    if (success) {
      _showMessage('Meeting status updated', isError: false);
      setState(() {}); // Refresh UI
    } else {
      _showMessage('Failed to update status', isError: true);
    }
  }

  Future<void> _saveMinutes() async {
    final meetingProvider = context.read<MeetingProvider>();
    final success = await meetingProvider.updateMeetingMinutes(
      meetingId: widget.meeting.id,
      minutes: _minutesController.text,
    );

    if (success) {
      _showMessage('Minutes saved successfully', isError: false);
      setState(() => _isEditingMinutes = false);
    } else {
      _showMessage('Failed to save minutes', isError: true);
    }
  }

  Future<void> _markAttendance(String memberId, String memberName, AttendanceStatus status) async {
    try {
      await _meetingService.markAttendance(
        meetingId: widget.meeting.id,
        memberId: memberId,
        memberName: memberName,
        status: status,
      );
      await _loadAttendance();
      _showMessage('Attendance marked', isError: false);
    } catch (e) {
      _showMessage('Error marking attendance: $e', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final groupProvider = context.watch<GroupProvider>();

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(
          'Meeting Details',
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
            Tab(text: 'Details'),
            Tab(text: 'Attendance'),
            Tab(text: 'Minutes'),
          ],
        ),
        actions: [
          if (groupProvider.canManageGroup)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'start':
                    _updateMeetingStatus(MeetingStatus.inProgress);
                    break;
                  case 'complete':
                    _updateMeetingStatus(MeetingStatus.completed);
                    break;
                  case 'cancel':
                    _updateMeetingStatus(MeetingStatus.cancelled);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'start',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Start Meeting'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Mark Complete'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancel Meeting'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(dateFormat),
          _buildAttendanceTab(),
          _buildMinutesTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(DateFormat dateFormat) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meeting Title Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.event,
                          color: Colors.orange.shade600,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.meeting.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            _buildStatusBadge(widget.meeting.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.meeting.description != null) ...[
                    SizedBox(height: 16),
                    Text(
                      widget.meeting.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Date, Time & Location Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Date & Time',
                    dateFormat.format(widget.meeting.scheduledDate),
                  ),
                  if (widget.meeting.location != null) ...[
                    Divider(height: 32),
                    _buildInfoRow(
                      Icons.location_on,
                      'Location',
                      widget.meeting.location!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Agenda Card
          if (widget.meeting.agenda != null) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list, color: Colors.orange.shade600),
                        SizedBox(width: 8),
                        Text(
                          'Agenda',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      widget.meeting.agenda!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
          ],

          // Attendance Summary Card
          if (_attendanceStats.isNotEmpty) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.orange.shade600),
                        SizedBox(width: 8),
                        Text(
                          'Attendance Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Present',
                          _attendanceStats['present'] ?? 0,
                          Colors.green,
                        ),
                        _buildStatItem(
                          'Absent',
                          _attendanceStats['absent'] ?? 0,
                          Colors.red,
                        ),
                        _buildStatItem(
                          'Late',
                          _attendanceStats['late'] ?? 0,
                          Colors.orange,
                        ),
                        _buildStatItem(
                          'Excused',
                          _attendanceStats['excused'] ?? 0,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return Column(
      children: [
        if (_attendanceStats.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatChip('Present', _attendanceStats['present'] ?? 0, Colors.green),
                _buildStatChip('Absent', _attendanceStats['absent'] ?? 0, Colors.red),
                _buildStatChip('Late', _attendanceStats['late'] ?? 0, Colors.orange),
                _buildStatChip('Excused', _attendanceStats['excused'] ?? 0, Colors.blue),
              ],
            ),
          ),
        Expanded(
          child: _isLoadingAttendance
              ? Center(child: CircularProgressIndicator())
              : _attendance.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 64,
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No attendance recorded yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _attendance.length,
                      itemBuilder: (context, index) {
                        final record = _attendance[index];
                        return _buildAttendanceCard(record);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMinutesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, color: Colors.orange.shade600),
                          SizedBox(width: 8),
                          Text(
                            'Meeting Minutes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      if (!_isEditingMinutes)
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange.shade600),
                          onPressed: () => setState(() => _isEditingMinutes = true),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (_isEditingMinutes)
                    Column(
                      children: [
                        TextFormField(
                          controller: _minutesController,
                          maxLines: 15,
                          decoration: InputDecoration(
                            hintText: 'Enter meeting minutes...\n\n1. Opening remarks\n2. Discussion points\n3. Decisions made\n4. Action items',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => _isEditingMinutes = false);
                                  _minutesController.text = widget.meeting.minutes ?? '';
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade400,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text('Cancel'),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveMinutes,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text('Save Minutes'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    widget.meeting.minutes == null || widget.meeting.minutes!.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.note_add_outlined,
                                    size: 64,
                                    color: Colors.black.withValues(alpha: 0.3),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No minutes recorded yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap the edit icon to add minutes',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Text(
                            widget.meeting.minutes!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.8,
                              color: Colors.black.withValues(alpha: 0.8),
                            ),
                          ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MeetingStatus status) {
    Color color;
    IconData icon;
    switch (status) {
      case MeetingStatus.scheduled:
        color = Colors.blue;
        icon = Icons.schedule;
        break;
      case MeetingStatus.inProgress:
        color = Colors.green;
        icon = Icons.play_circle;
        break;
      case MeetingStatus.completed:
        color = Colors.purple;
        icon = Icons.check_circle;
        break;
      case MeetingStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
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
        Icon(icon, color: Colors.orange.shade600, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel record) {
    Color statusColor;
    IconData statusIcon;

    switch (record.status) {
      case AttendanceStatus.present:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case AttendanceStatus.absent:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case AttendanceStatus.late:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case AttendanceStatus.excused:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          record.memberName,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              record.status.displayName,
              style: TextStyle(color: statusColor, fontSize: 12),
            ),
            if (record.checkInTime != null)
              Text(
                'Checked in: ${DateFormat('hh:mm a').format(record.checkInTime!)}',
                style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.5)),
              ),
            if (record.notes != null && record.notes!.isNotEmpty)
              Text(
                record.notes!,
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor, size: 16),
        ),
      ),
    );
  }
}
