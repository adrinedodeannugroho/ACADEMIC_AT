import 'package:flutter/material.dart';

class FindMentor extends StatelessWidget {
  const FindMentor({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy dosen
    final List<Map<String, String>> mentors = [
      {'name': 'Dr. Budi Santoso, M.Kom', 'expertise': 'Artificial Intelligence, Machine Learning'},
      {'name': 'Siti Aminah, S.T., M.T.', 'expertise': 'UI/UX Design, Mobile Development'},
      {'name': 'Ahmad Fauzi, M.Cs.', 'expertise': 'Cyber Security, Jaringan Komputer'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Dosen Pembimbing'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mentors.length,
        itemBuilder: (context, index) {
          final mentor = mentors[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(mentor['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Keahlian: ${mentor['expertise']}'),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pengajuan ke ${mentor['name']} terkirim!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                child: const Text('Ajukan'),
              ),
            ),
          );
        },
      ),
    );
  }
}