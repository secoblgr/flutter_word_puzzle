import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:word_puzzle/core/utils/constants.dart';

/// Top-level handler for background messages (required by FCM).
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the system notification tray automatically.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Singleton that manages Firebase Cloud Messaging and local notifications.
///
/// Call [init] once after Firebase is initialized and user is authenticated.
/// Call [saveToken] after each login to keep the FCM token up-to-date.
class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize FCM, request permissions, and set up local notifications.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Request notification permissions.
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Initialize local notifications for foreground display.
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        'word_puzzle_channel',
        'Word Puzzle',
        description: 'Duel invites, daily quests and game notifications',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Listen to foreground messages.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen to message taps (app in background/terminated).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Handle initial message (app opened from terminated state via notification).
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  /// Save the current FCM token to the user's Firestore document.
  /// Call this after login / app start.
  Future<void> saveToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null && userId.isNotEmpty) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update({'fcmToken': token});
      }

      // Also listen for token refresh.
      _messaging.onTokenRefresh.listen((newToken) {
        if (userId.isNotEmpty) {
          _firestore
              .collection(AppConstants.usersCollection)
              .doc(userId)
              .update({'fcmToken': newToken});
        }
      });
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  /// Remove FCM token from Firestore (e.g., on logout).
  Future<void> removeToken(String userId) async {
    try {
      if (userId.isNotEmpty) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update({'fcmToken': ''});
      }
    } catch (e) {
      debugPrint('[FCM] Failed to remove token: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Foreground message handling
  // ---------------------------------------------------------------------------

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Show a local notification so the user sees it while the app is open.
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'word_puzzle_channel',
          'Word Puzzle',
          channelDescription: 'Duel invites and game notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ---------------------------------------------------------------------------
  // Notification tap handling
  // ---------------------------------------------------------------------------

  void _handleMessageTap(RemoteMessage message) {
    // Future: navigate to specific page based on message.data['type'].
    // e.g., duel_invite → go to duel room, daily_quest → go to home.
    debugPrint('[FCM] Message tap: ${message.data}');
  }

  void _onNotificationTap(NotificationResponse response) {
    // Future: parse payload and navigate.
    debugPrint('[FCM] Local notification tap: ${response.payload}');
  }

  // ---------------------------------------------------------------------------
  // Send local notification (for in-app use)
  // ---------------------------------------------------------------------------

  /// Show a local notification (e.g., for daily quest reminders).
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'word_puzzle_channel',
          'Word Puzzle',
          channelDescription: 'Game notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }
}
