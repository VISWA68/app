import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/database_helper.dart';

// Create a global instance of the local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here, e.g., set up a global navigator key
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Android-specific initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS-specific initialization (empty for now)
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: initializationSettingsDarwin,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permission for push notifications
    await _fcm.requestPermission();
    
    // Get the FCM token and store it in Firestore
    final fcmToken = await _fcm.getToken();
    if (fcmToken != null) {
      final userRole = await DatabaseHelper().getCharacterChoice();
      if (userRole != null) {
        await _firestore.collection('users').doc(userRole).set({
          'fcmToken': fcmToken,
        }, SetOptions(merge: true));
      }
    }

    // This is a handler for when a notification is received while the app is in the foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // id
              'High Importance Notifications', // title
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // This is a handler for when a user taps on a notification to open the app.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // You can implement deep linking or specific navigation here
      print("A message was opened!");
      // Example: Navigator.of(GlobalKey().currentContext!).pushNamed('/quiz', arguments: message.data);
    });
    
    // This is a handler for when a notification is received while the app is in the background or terminated.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}