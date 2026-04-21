import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ThesisProgress extends StatefulWidget {
  const ThesisProgress({super.key});

  @override
  State<ThesisProgress> createState() => _ThesisProgressState();
}

class _ThesisProgressState extends State<ThesisProgress> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  // Helper Warna Status
  Color _getColor(String? status) {
    if (status == 'Disetujui') return Colors.green;
    if (status == 'Revisi') return Colors.orange;
    return Colors.blueAccent;
  }

  // --- FITUR 1: CETAK PDF (DIPERBAIKI) ---
  Future<void> _generatePdf(String nim) async {
    final pdf = pw.Document();
    
    // Pastikan data diambil secara sinkron sebelum proses PDF dimulai
    final snapshot = await FirebaseFirestore.instance
        .collection('thesis_data')
        .doc(nim)
        .collection('chapters')
        .orderBy('timestamp', descending: false)
        .get();

    if (snapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data kosong, tidak ada yang bisa dicetak!'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Persiapan data tabel dengan proteksi nilai null
    final List<List<String>> tableData = [
      ['No', 'Judul Bab', 'Status', 'Catatan Dosen']
    ];

    for (var i = 0; i < snapshot.docs.length; i++) {
      final data = snapshot.docs[i].data();
      tableData.add([
        (i + 1).toString(),
        (data['title'] ?? '-').toString(),
        (data['status'] ?? '-').toString(),
        (data['notes'] ?? '-').toString(),
      ]);
    }

    // Proses pembuatan layout PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('LOG BIMBINGAN SKRIPSI - ACADEMIC ATELIER', 
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('NIM: $nim'),
              pw.Text('Tanggal Cetak: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: tableData[0],
                data: tableData.sublist(1),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    // Menampilkan preview print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Log_Bimbingan_$nim',
    );
  }

  // --- FITUR 2: TAMBAH BAB (DIKEMBALIKAN) ---
  void _showAddDialog(String nim) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Progres Bab'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController, 
              decoration: const InputDecoration(labelText: 'Judul (Contoh: Bab 1)')
            ),
            TextField(
              controller: _linkController, 
              decoration: const InputDecoration(labelText: 'Link Google Drive')
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('thesis_data')
                    .doc(nim)
                    .collection('chapters')
                    .add({
                  'title': _titleController.text.trim(),
                  'drive_link': _linkController.text.trim(),
                  'status': 'Menunggu Review',
                  'notes': '-',
                  'timestamp': FieldValue.serverTimestamp(),
                });
                _titleController.clear();
                _linkController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nim = FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Progress Skripsi'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak Log PDF',
            onPressed: () => _generatePdf(nim),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('thesis_data')
            .doc(nim)
            .collection('chapters')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada progres. Tambahkan bab pertama kamu!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColor(data['status']),
                    child: const Icon(Icons.description, color: Colors.white),
                  ),
                  title: Text(data['title'] ?? 'Bab Tanpa Judul', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: ${data['status']}\nCatatan: ${data['notes']}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      // FLOATING ACTION BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(nim),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}