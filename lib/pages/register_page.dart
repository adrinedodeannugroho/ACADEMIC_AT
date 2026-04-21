import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _selectedRole = 'student'; // Default role
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _register() async {
    String inputId = _idController.text.trim().toLowerCase();
    String name = _nameController.text.trim();
    String password = _passwordController.text.trim();

    if (inputId.isEmpty || name.isEmpty || password.isEmpty) {
      _showError("Semua kolom wajib diisi bray!");
      return;
    }

    if (password.length < 6) {
      _showError("Password minimal 6 karakter!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Buat format email dari NIM/NIDN
      String emailForFirebase = "$inputId@gmail.com";

      // 2. Daftarkan ke Firebase Authentication
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailForFirebase,
        password: password,
      );

      // 3. Simpan data profil awal ke Firestore Database
      Map<String, dynamic> userData = {
        'name': name,
        'role': _selectedRole,
        'email': emailForFirebase,
        'phone': '',
        'fcmToken': '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // KUNCI ALUR: Jika dia mahasiswa, pastikan mentorId KOSONG secara default
      if (_selectedRole == 'student') {
        userData['thesis_title'] = 'Belum mendaftarkan judul';
        userData['seminar_date'] = null;
        userData['sidang_date'] = null;
        userData['mentorId'] = ''; // <-- Ini yang memutus koneksi otomatis di awal
      }

      // Simpan ke tabel 'users' dengan ID dokumen berupa NIM/NIDN
      await FirebaseFirestore.instance.collection('users').doc(inputId).set(userData);

      // 4. Logout otomatis agar user terpaksa login ulang
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registrasi Berhasil! Silakan Login."), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Kembali ke halaman Login
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showError("NIM/NIDN ini sudah terdaftar!");
      } else {
        _showError("Error: ${e.message}");
      }
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
                colors: [Colors.teal, Colors.blueAccent],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text('Daftar Akun Baru', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 30),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _idController, 
                          decoration: const InputDecoration(labelText: 'NIM / NIDN', prefixIcon: Icon(Icons.badge))
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _nameController, 
                          decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person))
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Password (Min. 6 Karakter)',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        const Text("Mendaftar Sebagai:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'student', child: Text("Mahasiswa")),
                                DropdownMenuItem(value: 'mentor', child: Text("Dosen Pembimbing")),
                              ],
                              onChanged: (value) => setState(() => _selectedRole = value!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal, 
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('DAFTAR SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Sudah punya akun? Login di sini", style: TextStyle(color: Colors.blueAccent)),
                          ),
                        )
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