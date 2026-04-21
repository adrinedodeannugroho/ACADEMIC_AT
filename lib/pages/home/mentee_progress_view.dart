import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';

class MenteeProgressView extends StatefulWidget {
  final String studentNim;
  final String studentName;

  const MenteeProgressView({
    super.key, 
    required this.studentNim, 
    required this.studentName
  });

  @override
  State<MenteeProgressView> createState() => _MenteeProgressViewState();
}

class _MenteeProgressViewState extends State<MenteeProgressView> {
  
  // --- FUNGSI 1: SET DEADLINE (TANGGAL) ---
  Future<void> _pilihTanggal(String field, String label) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      helpText: 'TETAPKAN TANGGAL $label',
    );

    if (picked != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentNim)
          .update({
        field: Timestamp.fromDate(picked),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jadwal $label Berhasil Disimpan!'), backgroundColor: Colors.teal),
        );
      }
    }
  }

  // --- FUNGSI 2: BUKA LINK ---
  Future<void> _bukaLink(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Gagal membuka link');
    }
  }

  // --- FUNGSI 3: WARNA STATUS ---
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui': return Colors.green;
      case 'Revisi': return Colors.orange;
      case 'Menunggu Review': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatPage(studentNim: widget.studentNim, studentName: widget.studentName)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // A. HEADER: TAMPILAN DEADLINE SAAT INI (FITUR BARU)
          _buildDeadlineBanner(),

          // B. LIST PROGRES BAB
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('thesis_data')
                  .doc(widget.studentNim)
                  .collection('chapters')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                
                if (docs.isEmpty) {
                  return const Center(child: Text('Belum ada bab yang diunggah mahasiswa.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id;
                    return _buildChapterCard(docId, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Banner untuk melihat dan menset deadline
  Widget _buildDeadlineBanner() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.studentNim).snapshots(),
      builder: (context, snapshot) {
        String sempro = "Belum Set";
        String sidang = "Belum Set";

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['seminar_date'] != null) {
            sempro = DateFormat('dd MMM yyyy').format((data['seminar_date'] as Timestamp).toDate());
          }
          if (data['sidang_date'] != null) {
            sidang = DateFormat('dd MMM yyyy').format((data['sidang_date'] as Timestamp).toDate());
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const Text('Target Milestone Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildDeadlineInfo('Seminar', sempro, 'seminar_date', Colors.orange),
                  const SizedBox(width: 10),
                  _buildDeadlineInfo('Sidang Akhir', sidang, 'sidang_date', Colors.red),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeadlineInfo(String label, String date, String field, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _pilihTanggal(field, label),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              const Icon(Icons.edit_calendar, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard(String docId, Map<String, dynamic> data) {
    String status = data['status'] ?? 'Menunggu Review';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data['title'] ?? 'Bab', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(status, style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Catatan: ${data['notes'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const Divider(height: 30),
            Row(
              children: [
                if (data['drive_link'] != null && data['drive_link'].toString().isNotEmpty)
                  IconButton(onPressed: () => _bukaLink(data['drive_link']), icon: const Icon(Icons.link, color: Colors.blue)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _showUpdatePopup(docId, status, data['notes'] ?? '-'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdatePopup(String docId, String currentStatus, String currentNote) {
    final TextEditingController noteController = TextEditingController(text: currentNote == '-' ? '' : currentNote);
    String selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Berikan Feedback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: ['Menunggu Review', 'Revisi', 'Disetujui'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setModalState(() => selectedStatus = val!),
                decoration: const InputDecoration(labelText: 'Ubah Status'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Catatan Revisi', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('thesis_data').doc(widget.studentNim).collection('chapters').doc(docId).update({
                  'status': selectedStatus,
                  'notes': noteController.text.trim().isEmpty ? '-' : noteController.text.trim(),
                });
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}