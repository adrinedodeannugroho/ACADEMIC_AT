import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import 'home/student_dashboard.dart';
import 'home/supervisor_mentees.dart';
import 'register_page.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  void _login() async {
    String inputId = _idController.text.trim();
    String password = _passwordController.text.trim();

    if (inputId.isEmpty || password.isEmpty) {
      _showError("Isi data dulu bray!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String emailForFirebase = "${inputId.toLowerCase()}@gmail.com";
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailForFirebase,
        password: password,
      );

      String userId = userCredential.user!.email!.split('@')[0];
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        // SIMPAN TOKEN NOTIFIKASI
        await NotificationService.saveTokenToDatabase(userId);

        String role = userDoc['role'];
        if (mounted) {
          if (role == 'student') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboard()));
          } else if (role == 'mentor') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SupervisorMentees()));
          }
        }
      } else {
        _showError("User tidak ditemukan.");
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login Gagal.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.teal],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  const Icon(Icons.school_rounded, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text('Academic Atelier', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        TextField(controller: _idController, decoration: const InputDecoration(labelText: 'NIM / NIDN', prefixIcon: Icon(Icons.person))),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent, 
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        
                        // INI BAGIAN TOMBOL REGISTER-NYA
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                          },
                          child: const Text("Belum punya akun? Daftar di sini", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        ),
                        
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}