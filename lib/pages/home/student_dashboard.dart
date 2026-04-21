import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login_page.dart';
import '../chat_page.dart';
import 'profile_page.dart';
import 'schedule_page.dart';
import 'progress_page.dart';
import 'select_mentor_page.dart';
import 'notifications_page.dart'; // IMPORT HALAMAN NOTIF BARU

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;
  String get nim => user?.email?.split('@')[0] ?? '';

  Future<void> _openChatWithMentor(BuildContext context, String mentorId, bool isApproved) async {
    if (mentorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Dosen dulu bray!"), backgroundColor: Colors.orange));
      return;
    }
    if (!isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sabar, Dosen belum ACC permohonanmu!"), backgroundColor: Colors.redAccent));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      DocumentSnapshot mentorDoc = await FirebaseFirestore.instance.collection('users').doc(mentorId).get();
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverId: mentorId, receiverName: mentorDoc['name'])));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, elevation: 0,
        actions: [
          // LONCENG NOTIFIKASI DENGAN BADGE MERAH
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(nim)
                .collection('notifications')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage())),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 10, top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                ],
              );
            },
          ),
          IconButton(icon: const Icon(Icons.person_pin, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()))),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout)
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(nim).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          
          String mentorId = data.containsKey('mentorId') ? data['mentorId'] : '';
          bool isApproved = data.containsKey('isMentorApproved') ? data['isMentorApproved'] : false;
          
          return Column(
            children: [
              Container(
                width: double.infinity, padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Halo, ${data['name'] ?? 'Mahasiswa'}!", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text("NIM: $nim", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 15),
                    
                    if (mentorId.isEmpty)
                      _statusBadge("Belum Punya Dosen", Colors.orangeAccent)
                    else
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(mentorId).get(),
                        builder: (context, mentorSnapshot) {
                          String mentorName = mentorSnapshot.hasData ? mentorSnapshot.data!['name'] : "Memuat...";
                          if (!isApproved) return _statusBadge("Menunggu ACC: $mentorName", Colors.amber.shade600);
                          return _statusBadge("Dosen: $mentorName", Colors.tealAccent.shade700);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(20), crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20,
                  children: [
                    _buildMenuCard(context, title: mentorId.isEmpty ? "Pilih Dosen" : (isApproved ? "Ganti Dosen" : "Batalkan Pengajuan"), icon: Icons.person_search_outlined, color: Colors.indigo, 
                      onTap: () {
                        if (!isApproved && mentorId.isNotEmpty) {
                          FirebaseFirestore.instance.collection('users').doc(nim).update({'mentorId': '', 'isMentorApproved': false});
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectMentorPage()));
                        }
                      }),
                    _buildMenuCard(context, title: "Jadwal/Agenda", icon: Icons.calendar_month_outlined, color: Colors.orange, onTap: () => isApproved ? Navigator.push(context, MaterialPageRoute(builder: (context) => SchedulePage(studentId: nim, studentName: data['name']))) : _showWarning(context)),
                    _buildMenuCard(context, title: "Progres Skripsi", icon: Icons.analytics_outlined, color: Colors.green, onTap: () => isApproved ? Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressPage())) : _showWarning(context)),
                    _buildMenuCard(context, title: "Chat Dosen", icon: Icons.chat_bubble_outline, color: Colors.teal, onTap: () => _openChatWithMentor(context, mentorId, isApproved)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)));
  }

  void _showWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur terkunci! Tunggu dosen ACC permohonanmu."), backgroundColor: Colors.redAccent));
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.1), child: Icon(icon, size: 30, color: color)), const SizedBox(height: 15), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)])));
  }
}