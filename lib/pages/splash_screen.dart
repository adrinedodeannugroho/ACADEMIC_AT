import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart'; 
import 'home/student_dashboard.dart';
import 'home/supervisor_mentees.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  void _startApp() async {
    // 1. Beri waktu 2 detik SAJA agar animasi membesarnya punya waktu untuk selesai
    await Future.delayed(const Duration(seconds: 2));

    // 2. Langsung gas cek data tanpa bengong nunggu timer!
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.email!.split('@')[0];
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

        if (userDoc.exists && mounted) {
          String role = userDoc['role'];
          if (role == 'student') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboard()));
          } else if (role == 'mentor') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SupervisorMentees()));
          }
        } else {
          _goToLogin();
        }
      } catch (e) {
        _goToLogin();
      }
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 2), // Ini durasi animasi aslimu
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(scale: value, child: child),
                );
              },
              child: const Icon(Icons.school_rounded, size: 130, color: Colors.white),
            ),
            const SizedBox(height: 30),
            const Text(
              'ACADEMIC ATELIER',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Modern Thesis Monitoring System',
              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1),
            ),
            const SizedBox(height: 60),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}