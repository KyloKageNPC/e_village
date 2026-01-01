import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _firebaseMessaging;

  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Firebase should already be initialized in main.dart
      // Initialize FirebaseMessaging instance after Firebase is ready
      _firebaseMessaging = FirebaseMessaging.instance;

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _initializeFirebaseMessaging() async {
    if (_firebaseMessaging == null) {
      debugPrint('Firebase Messaging not initialized');
      return;
    }
    
    try {
      // Request permission
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');

        // Get FCM token
        _fcmToken = await _firebaseMessaging!.getToken();
        debugPrint('FCM Token: $_fcmToken');

        // Listen to token refresh
        _firebaseMessaging!.onTokenRefresh.listen((token) {
          _fcmToken = token;
          debugPrint('FCM Token refreshed: $token');
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      } else {
        debugPrint('User declined notification permission');
      }
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      showNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Background message opened: ${message.notification?.title}');
    // Handle navigation based on notification data
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  // Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.general,
  }) async {
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      type.channelId,
      type.channelName,
      channelDescription: type.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: type.color != null ? Color(type.color!) : null,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Show notification for new loan request
  Future<void> notifyLoanRequest({
    required String borrowerName,
    required double amount,
    required String loanId,
  }) async {
    await showNotification(
      title: 'New Loan Request',
      body: '$borrowerName requested a loan of \$$amount',
      payload: 'loan:$loanId',
      type: NotificationType.loan,
    );
  }

  // Show notification for loan approval
  Future<void> notifyLoanApproval({
    required String status,
    required double amount,
    required String loanId,
  }) async {
    await showNotification(
      title: 'Loan $status',
      body: 'Your loan request of \$$amount has been $status',
      payload: 'loan:$loanId',
      type: NotificationType.loan,
    );
  }

  // Show notification for guarantor request
  Future<void> notifyGuarantorRequest({
    required String borrowerName,
    required double amount,
    required String loanId,
  }) async {
    await showNotification(
      title: 'Guarantor Request',
      body: '$borrowerName wants you to guarantee their \$$amount loan',
      payload: 'guarantor:$loanId',
      type: NotificationType.guarantor,
    );
  }

  // Show notification for meeting
  Future<void> notifyMeeting({
    required String title,
    required String date,
    required String meetingId,
  }) async {
    await showNotification(
      title: 'Upcoming Meeting',
      body: '$title on $date',
      payload: 'meeting:$meetingId',
      type: NotificationType.meeting,
    );
  }

  // Show notification for new chat message
  Future<void> notifyNewMessage({
    required String senderName,
    required String message,
    required String groupId,
  }) async {
    await showNotification(
      title: 'New Message from $senderName',
      body: message,
      payload: 'chat:$groupId',
      type: NotificationType.chat,
    );
  }

  // Show notification for contribution reminder
  Future<void> notifyContributionReminder({
    required String groupName,
    required double amount,
  }) async {
    await showNotification(
      title: 'Contribution Reminder',
      body: 'Time to make your \$$amount contribution to $groupName',
      type: NotificationType.contribution,
    );
  }

  // Show notification for repayment due
  Future<void> notifyRepaymentDue({
    required double amount,
    required String dueDate,
    required String loanId,
  }) async {
    await showNotification(
      title: 'Loan Repayment Due',
      body: '\$$amount payment due on $dueDate',
      payload: 'repayment:$loanId',
      type: NotificationType.loan,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

// Notification types with channel configurations
enum NotificationType {
  general,
  loan,
  guarantor,
  meeting,
  chat,
  contribution;

  String get channelId {
    switch (this) {
      case NotificationType.general:
        return 'general_notifications';
      case NotificationType.loan:
        return 'loan_notifications';
      case NotificationType.guarantor:
        return 'guarantor_notifications';
      case NotificationType.meeting:
        return 'meeting_notifications';
      case NotificationType.chat:
        return 'chat_notifications';
      case NotificationType.contribution:
        return 'contribution_notifications';
    }
  }

  String get channelName {
    switch (this) {
      case NotificationType.general:
        return 'General Notifications';
      case NotificationType.loan:
        return 'Loan Notifications';
      case NotificationType.guarantor:
        return 'Guarantor Requests';
      case NotificationType.meeting:
        return 'Meeting Reminders';
      case NotificationType.chat:
        return 'Chat Messages';
      case NotificationType.contribution:
        return 'Contribution Reminders';
    }
  }

  String get channelDescription {
    switch (this) {
      case NotificationType.general:
        return 'General app notifications';
      case NotificationType.loan:
        return 'Loan requests, approvals, and repayments';
      case NotificationType.guarantor:
        return 'Guarantor approval requests';
      case NotificationType.meeting:
        return 'Meeting schedules and reminders';
      case NotificationType.chat:
        return 'New messages in group chat';
      case NotificationType.contribution:
        return 'Contribution reminders and alerts';
    }
  }

  int? get color {
    switch (this) {
      case NotificationType.general:
        return 0xFFFF9800; // Orange
      case NotificationType.loan:
        return 0xFF4CAF50; // Green
      case NotificationType.guarantor:
        return 0xFF9C27B0; // Purple
      case NotificationType.meeting:
        return 0xFF2196F3; // Blue
      case NotificationType.chat:
        return 0xFF009688; // Teal
      case NotificationType.contribution:
        return 0xFFFFEB3B; // Yellow
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
}
