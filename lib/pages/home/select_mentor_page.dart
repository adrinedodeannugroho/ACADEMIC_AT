import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SelectMentorPage extends StatefulWidget {
  const SelectMentorPage({super.key});

  @override
  State<SelectMentorPage> createState() => _SelectMentorPageState();
}

class _SelectMentorPageState extends State<SelectMentorPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? '';

  void _assignMentor(String mentorId, String mentorName) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Dosen"),
        content: Text("Ajukan permohonan bimbingan ke $mentorName?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            child: const Text("Ya, Ajukan"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // PERUBAHAN DI SINI: Tambahkan isMentorApproved: false
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'mentorId': mentorId,
        'isMentorApproved': false, // Statusnya Menunggu Persetujuan
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Permohonan terkirim ke $mentorName!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Dosen Pembimbing", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil semua user yang role-nya 'mentor'
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'mentor').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada dosen yang terdaftar di sistem."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var mentorData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String mentorId = snapshot.data!.docs[index].id;
              String mentorName = mentorData['name'] ?? 'Dosen';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: const Icon(Icons.person, color: Colors.blueAccent),
                  ),
                  title: Text(mentorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("NIDN: $mentorId"),
                  trailing: ElevatedButton(
                    onPressed: () => _assignMentor(mentorId, mentorName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Pilih"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}