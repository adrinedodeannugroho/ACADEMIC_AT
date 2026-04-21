import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final fln.FlutterLocalNotificationsPlugin _localPlugin = fln.FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Request Permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Android Setup
    const fln.AndroidInitializationSettings androidSettings = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const fln.InitializationSettings initSettings = fln.InitializationSettings(
      android: androidSettings,
    );

    // 3. Initialize Plugin dengan Named Parameter untuk keamanan versi
    await _localPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse details) {
        // Logika saat notifikasi diklik
      },
    );

    // 4. Listen Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(message);
      }
    });
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    const fln.AndroidNotificationDetails androidDetails = fln.AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    );

    const fln.NotificationDetails platformDetails = fln.NotificationDetails(android: androidDetails);

    await _localPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
    );
  }

  static Future<void> saveTokenToDatabase(String userId) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint("Gagal simpan token: $e");
    }
  }
}