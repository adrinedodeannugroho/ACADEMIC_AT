import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  // Mendapatkan ID user dari email (NIM/NIDN)
  String get userId => user?.email?.split('@')[0] ?? '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- FUNGSI UPDATE DATA ---
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil Berhasil Diperbarui!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save_rounded : Icons.edit_rounded),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text("Data user tidak ditemukan."));

          var data = snapshot.data!.data() as Map<String, dynamic>;
          
          // Set initial value jika controller kosong
          if (!_isEditing) {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
          }

          String role = data['role'] ?? 'User';
          Color themeColor = role == 'student' ? Colors.blueAccent : Colors.teal;

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. HEADER PROFIL
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 40),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: Text(
                          _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: themeColor),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        role.toUpperCase(),
                        style: const TextStyle(color: Colors.white70, letterSpacing: 2, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // 2. FORM DATA
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoTile("NIM / NIDN", userId, Icons.badge_outlined, isEditable: false),
                      const SizedBox(height: 20),
                      _buildInfoTile("Nama Lengkap", _nameController.text, Icons.person_outline, 
                        controller: _nameController, isEditable: _isEditing),
                      const SizedBox(height: 20),
                      _buildInfoTile("No. WhatsApp", _phoneController.text, Icons.phone_android_outlined, 
                        controller: _phoneController, isEditable: _isEditing, keyboardType: TextInputType.phone),
                      const SizedBox(height: 20),
                      if (role == 'student')
                        _buildInfoTile("Judul Skripsi", data['thesis_title'] ?? '-', Icons.book_outlined, isEditable: false),
                      
                      const SizedBox(height: 40),
                      if (_isLoading) const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, {
    TextEditingController? controller, 
    bool isEditable = false,
    TextInputType keyboardType = TextInputType.text
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: isEditable ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isEditable ? Colors.blueAccent : Colors.transparent),
          ),
          child: TextField(
            controller: controller ?? TextEditingController(text: value),
            enabled: isEditable,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.blueAccent, size: 20),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}