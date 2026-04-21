import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final String userId = FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? '';

  // Daftar Milestone Paten
  final List<String> _babList = [
    'BAB 1: Pendahuluan',
    'BAB 2: Tinjauan Pustaka',
    'BAB 3: Metodologi Penelitian',
    'BAB 4: Hasil dan Pembahasan',
    'BAB 5: Kesimpulan dan Saran',
  ];

  // Fungsi memunculkan form pop-up dari bawah
  void _showSubmissionModal(String babTitle, Map<String, dynamic>? existingData) {
    final TextEditingController linkController = TextEditingController(text: existingData?['link'] ?? '');
    final TextEditingController notesController = TextEditingController(text: existingData?['notes'] ?? '');
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, 
              left: 25, right: 25, top: 25
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Pengajuan $babTitle", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const SizedBox(height: 5),
                const Text("Kirimkan link dokumen dan catatan untuk dosen.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: linkController,
                  decoration: InputDecoration(
                    labelText: 'Link G-Drive / Dokumen',
                    prefixIcon: const Icon(Icons.link_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    prefixIcon: const Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (linkController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link wajib diisi!")));
                        return;
                      }
                      setModalState(() => isLoading = true);
                      
                      // Simpan data ke sub-collection 'progress'
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('progress')
                          .doc(babTitle) // Nama dokumen pakai nama BAB
                          .set({
                        'bab': babTitle,
                        'link': linkController.text.trim(),
                        'notes': notesController.text.trim(),
                        'status': 'Menunggu ACC', // Otomatis masuk status antrean
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));

                      setModalState(() => isLoading = false);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Progres berhasil diajukan!"), backgroundColor: Colors.green),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("KIRIM PENGAJUAN", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  // Fungsi penentu warna badge otomatis
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu ACC': return Colors.orange;
      case 'Revisi': return Colors.redAccent;
      case 'ACC': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Progres Skripsi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil data real-time dari sub-collection
        stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('progress').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Map data agar mudah dicocokkan dengan list BAB
          Map<String, Map<String, dynamic>> progressData = {};
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              progressData[doc.id] = doc.data() as Map<String, dynamic>;
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _babList.length,
            itemBuilder: (context, index) {
              String babTitle = _babList[index];
              Map<String, dynamic>? currentBabData = progressData[babTitle];
              String status = currentBabData?['status'] ?? 'Belum Dimulai';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    title: Text(babTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Badge Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                          ),
                          child: Text(
                            status.toUpperCase(), 
                            style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        if (currentBabData?['notes'] != null && currentBabData!['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text("Catatan Anda: ${currentBabData['notes']}", style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
                        ],
                        // Jika ada catatan revisi dari dosen
                        if (currentBabData?['feedback'] != null && currentBabData!['feedback'].toString().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.feedback_outlined, size: 16, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Expanded(child: Text("Dosen: ${currentBabData['feedback']}", style: const TextStyle(fontSize: 12, color: Colors.redAccent))),
                              ],
                            ),
                          )
                        ]
                      ],
                    ),
                    trailing: CircleAvatar(
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      child: IconButton(
                        icon: const Icon(Icons.upload_file_rounded, color: Colors.blueAccent),
                        onPressed: () => _showSubmissionModal(babTitle, currentBabData),
                      ),
                    ),
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