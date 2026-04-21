import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

import 'pages/splash_screen.dart';
import 'pages/login_page.dart';

// 1. IMPORT FILE ANTENA BARU KITA
// (Pastikan file push_notification_service.dart ada di dalam folder lib/)
import 'push_notification_service.dart'; 

void main() async {
  // Wajib dipanggil sebelum inisialisasi plugin apapun
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase Utama
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 2. NYALAKAN ANTENA NOTIFIKASI DI SINI
  // (Menggantikan NotificationService yang lama agar tidak bentrok)
  await PushNotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academic Atelier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}