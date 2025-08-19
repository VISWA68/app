import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static const String oneSignalAppId = 'd4659fae-a932-4b14-83d3-771070f87c54';

  Future<void> initialize() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);
    OneSignal.initialize(oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);

    // Set up notification event listeners
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // You can choose to display or suppress the notification
      event.preventDefault();
      event.notification.display();
    });
    OneSignal.Notifications.addClickListener((event) {
      print('Notification opened: ${event.notification.jsonRepresentation()}');
      // Implement navigation or logic here
    });
    OneSignal.User.pushSubscription.addObserver((state) {
      print('Push subscription changed: ${state.current.jsonRepresentation()}');
    });
    OneSignal.User.addObserver((state) {
      print('OneSignal user changed: ${state.jsonRepresentation()}');
    });
    OneSignal.Notifications.addPermissionObserver((state) {
      print('Notification permission changed: $state');
    });
  }

  // Core method to send a notification via OneSignal REST API
  Future<void> sendNotificationToUser({
    required String externalUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization':
          'Basic os_v2_app_2rsz7lvjgjfrja6to4ihb6d4krq4t6hfwhgulludfjzlbkwhdtzfzkepl2tkbysg5vtillvssrajopadhgn5wsphxyg22o3mruwmj4q', // <-- Paste your REST API key here
    };
    final payload = {
      'app_id': oneSignalAppId,
      'include_external_user_ids': [externalUserId],
      'headings': {'en': title},
      'contents': {'en': body},
      if (data != null) 'data': data,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );
    print('Notification response: ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Failed to send notification: ${response.body}');
    }
  }

  // Event-specific methods
  Future<void> notifyDailyPromptUpdate(String externalUserId) async {
    await sendNotificationToUser(
      externalUserId: externalUserId,
      title: 'Daily Prompt Updated',
      body: 'A new daily prompt is available!',
    );
  }

  Future<void> notifyMoodUpdate(String externalUserId, String mood) async {
    await sendNotificationToUser(
      externalUserId: externalUserId,
      title: 'Mood Updated',
      body: 'Mood updated to $mood.',
    );
  }

  Future<void> notifyQuizEvent(String externalUserId, String eventType) async {
    String body;
    switch (eventType) {
      case 'created':
        body = 'A new quiz has been created!';
        break;
      case 'validated':
        body = 'A quiz has been validated!';
        break;
      case 'completed':
        body = 'A quiz has been completed!';
        break;
      default:
        body = 'Quiz event: $eventType';
    }
    await sendNotificationToUser(
      externalUserId: externalUserId,
      title: 'Quiz Update',
      body: body,
    );
  }

  /// Set the external user ID for this device (for targeting notifications)
  Future<void> setExternalUserId(String externalUserId) async {
    await OneSignal.login(externalUserId);
  }

  /// Remove the external user ID (logout)
  Future<void> removeExternalUserId() async {
    await OneSignal.logout();
  }
}
