import 'package:flutter/material.dart';

class RevisionAlerts extends StatelessWidget {
  const RevisionAlerts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Revisi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.teal, size: 36),
            title: const Text('Azhar Khoirul (24SA11A149)'),
            subtitle: const Text('Telah mengupload revisi Bab 2'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.orange, size: 36),
            title: const Text('Sistem Academic Atelier'),
            subtitle: const Text('Batas waktu penilaian proposal sisa 3 hari.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}