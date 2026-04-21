import 'package:flutter/material.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan & Diskusi'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: 3, // Dummy 3 pesan
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text('Dosen/Mahasiswa ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Baik, file revisi sudah saya terima. Nanti saya cek...'),
            trailing: const Text('10:45 AM', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membuka ruang chat...')),
              );
            },
          );
        },
      ),
    );
  }
}