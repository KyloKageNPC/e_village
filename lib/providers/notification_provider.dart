import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  // Notification preferences
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _loanAlerts = true;
  bool _meetingReminders = true;
  bool _chatNotifications = true;
  bool _contributionReminders = true;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get emailNotifications => _emailNotifications;
  bool get loanAlerts => _loanAlerts;
  bool get meetingReminders => _meetingReminders;
  bool get chatNotifications => _chatNotifications;
  bool get contributionReminders => _contributionReminders;
  String? get fcmToken => _notificationService.fcmToken;

  // Initialize
  Future<void> initialize() async {
    await _notificationService.initialize();
    await _loadPreferences();
  }

  // Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _loanAlerts = prefs.getBool('loan_alerts') ?? true;
      _meetingReminders = prefs.getBool('meeting_reminders') ?? true;
      _chatNotifications = prefs.getBool('chat_notifications') ?? true;
      _contributionReminders = prefs.getBool('contribution_reminders') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }
  }

  // Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('loan_alerts', _loanAlerts);
      await prefs.setBool('meeting_reminders', _meetingReminders);
      await prefs.setBool('chat_notifications', _chatNotifications);
      await prefs.setBool('contribution_reminders', _contributionReminders);
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
  }

  // Toggle notifications
  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    await _savePreferences();

    if (!value) {
      await _notificationService.cancelAllNotifications();
    }
  }

  Future<void> toggleEmailNotifications(bool value) async {
    _emailNotifications = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> toggleLoanAlerts(bool value) async {
    _loanAlerts = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> toggleMeetingReminders(bool value) async {
    _meetingReminders = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> toggleChatNotifications(bool value) async {
    _chatNotifications = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> toggleContributionReminders(bool value) async {
    _contributionReminders = value;
    notifyListeners();
    await _savePreferences();
  }

  // Send notification methods (only if enabled)
  Future<void> sendLoanRequestNotification({
    required String borrowerName,
    required double amount,
    required String loanId,
  }) async {
    if (!_notificationsEnabled || !_loanAlerts) return;

    await _notificationService.notifyLoanRequest(
      borrowerName: borrowerName,
      amount: amount,
      loanId: loanId,
    );
  }

  Future<void> sendLoanApprovalNotification({
    required String status,
    required double amount,
    required String loanId,
  }) async {
    if (!_notificationsEnabled || !_loanAlerts) return;

    await _notificationService.notifyLoanApproval(
      status: status,
      amount: amount,
      loanId: loanId,
    );
  }

  Future<void> sendGuarantorRequestNotification({
    required String borrowerName,
    required double amount,
    required String loanId,
  }) async {
    if (!_notificationsEnabled || !_loanAlerts) return;

    await _notificationService.notifyGuarantorRequest(
      borrowerName: borrowerName,
      amount: amount,
      loanId: loanId,
    );
  }

  Future<void> sendMeetingNotification({
    required String title,
    required String date,
    required String meetingId,
  }) async {
    if (!_notificationsEnabled || !_meetingReminders) return;

    await _notificationService.notifyMeeting(
      title: title,
      date: date,
      meetingId: meetingId,
    );
  }

  Future<void> sendChatMessageNotification({
    required String senderName,
    required String message,
    required String groupId,
  }) async {
    if (!_notificationsEnabled || !_chatNotifications) return;

    await _notificationService.notifyNewMessage(
      senderName: senderName,
      message: message,
      groupId: groupId,
    );
  }

  Future<void> sendContributionReminderNotification({
    required String groupName,
    required double amount,
  }) async {
    if (!_notificationsEnabled || !_contributionReminders) return;

    await _notificationService.notifyContributionReminder(
      groupName: groupName,
      amount: amount,
    );
  }

  Future<void> sendRepaymentDueNotification({
    required double amount,
    required String dueDate,
    required String loanId,
  }) async {
    if (!_notificationsEnabled || !_loanAlerts) return;

    await _notificationService.notifyRepaymentDue(
      amount: amount,
      dueDate: dueDate,
      loanId: loanId,
    );
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }
}
