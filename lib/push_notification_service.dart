import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// 1. Fungsi ini WAJIB ada di luar class (Top-Level) untuk menangkap notif saat aplikasi ditutup
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Notifikasi masuk saat background: ${message.notification?.title}");
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 2. Minta Izin (Permission) dari HP user untuk nampilin pop-up
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Daftarkan fungsi background tadi
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Konfigurasi Pop-up Notifikasi untuk layar menyala (Foreground)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _localNotif.initialize(initSettings);

    // 5. Dengarkan jika ada pesan masuk saat aplikasi sedang dibuka
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _localNotif.show(
          message.hashCode,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'academic_atelier_channel', // ID Channel
              'Notifikasi Skripsi', // Nama Channel
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: const Color(0xFF448AFF), // Sesuai warna splash screen kamu
            ),
          ),
        );
      }
    });
  }

  // Fungsi untuk mendapatkan "Alamat HP" (Token FCM)
  static Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}