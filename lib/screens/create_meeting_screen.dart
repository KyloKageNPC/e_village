import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/meeting_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _agendaController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _agendaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showMessage('Please select a date for the meeting', isError: true);
      return;
    }

    if (_selectedTime == null) {
      _showMessage('Please select a time for the meeting', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();
    final meetingProvider = context.read<MeetingProvider>();

    if (authProvider.currentUser == null) {
      _showMessage('Please log in to create a meeting', isError: true);
      return;
    }

    if (groupProvider.selectedGroup == null) {
      _showMessage('Please select a village group first', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    // Combine date and time
    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final success = await meetingProvider.createMeeting(
      groupId: groupProvider.selectedGroup!.id,
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      scheduledDate: scheduledDateTime,
      location: _locationController.text.isEmpty
          ? null
          : _locationController.text,
      agenda:
          _agendaController.text.isEmpty ? null : _agendaController.text,
      createdBy: authProvider.currentUser!.id,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      _showMessage('Meeting created successfully!', isError: false);
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } else {
      _showMessage(
        meetingProvider.errorMessage ?? 'Failed to create meeting',
        isError: true,
      );
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
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      appBar: AppBar(
        title: Text(
          'Create Meeting',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.event,
                  size: 60,
                  color: Colors.orange.shade600,
                ),
                SizedBox(height: 16),
                Text(
                  'Schedule New Meeting',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Set up a meeting for your village group',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 32),

                // Title
                _buildLabel('Meeting Title *'),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    hint: 'Monthly Group Meeting',
                    icon: Icons.title,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a meeting title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Description
                _buildLabel('Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    hint: 'Brief description of the meeting',
                    icon: Icons.description,
                  ),
                ),
                SizedBox(height: 20),

                // Date and Time
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Date *'),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedDate == null
                                      ? Colors.red.shade300
                                      : Colors.black.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.orange.shade600,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedDate == null
                                          ? 'Select date'
                                          : dateFormat.format(_selectedDate!),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedDate == null
                                            ? Colors.black
                                                .withValues(alpha: 0.4)
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Time *'),
                          InkWell(
                            onTap: () => _selectTime(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedTime == null
                                      ? Colors.red.shade300
                                      : Colors.black.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.orange.shade600,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedTime == null
                                          ? 'Select time'
                                          : _selectedTime!.format(context),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedTime == null
                                            ? Colors.black
                                                .withValues(alpha: 0.4)
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Location
                _buildLabel('Location'),
                TextFormField(
                  controller: _locationController,
                  decoration: _inputDecoration(
                    hint: 'Village community center',
                    icon: Icons.location_on,
                  ),
                ),
                SizedBox(height: 20),

                // Agenda
                _buildLabel('Agenda'),
                TextFormField(
                  controller: _agendaController,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    hint: '1. Opening remarks\n2. Financial report\n3. New business\n4. Closing',
                    icon: Icons.list,
                  ),
                ),
                SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitMeeting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Create Meeting',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.orange.shade600),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
