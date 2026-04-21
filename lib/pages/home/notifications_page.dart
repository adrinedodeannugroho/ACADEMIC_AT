import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? '';

  @override
  void initState() {
    super.initState();
    _markAllAsRead(); // Otomatis hapus badge merah saat halaman ini dibuka
  }

  void _markAllAsRead() async {
    var unreadDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadDocs.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pusat Notifikasi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 15),
                  const Text("Belum ada notifikasi baru.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              DateTime time = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              bool isRead = data['isRead'] ?? true;

              return Card(
                elevation: isRead ? 0 : 3, // Notif baru lebih menonjol
                color: isRead ? Colors.white : Colors.blue.shade50,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: const Icon(Icons.notifications_active, color: Colors.blueAccent),
                  ),
                  title: Text(data['title'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(data['body'] ?? ''),
                  ),
                  trailing: Text(DateFormat('HH:mm').format(time), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}