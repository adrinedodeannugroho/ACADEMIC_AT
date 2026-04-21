import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SchedulePage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const SchedulePage({super.key, required this.studentId, required this.studentName});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? '';
  
  bool get isStudent => currentUserId == widget.studentId;

  // FUNGSI DOSEN UNTUK KONFIRMASI (TERIMA/TOLAK)
  void _showConfirmationDialog(String docId, Map<String, dynamic> data) {
    if (isStudent) return; // Mahasiswa tidak bisa konfirmasi jadwal sendiri

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Jadwal"),
        content: Text("Apakah Anda menerima pengajuan bimbingan: ${data['title']}?"),
        actions: [
          TextButton(
            onPressed: () async {
              await _updateStatus(docId, 'Ditolak');
              Navigator.pop(context);
            },
            child: const Text("Tolak", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateStatus(docId, 'Diterima');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Terima"),
          ),
        ],
      ),
    );
  }

  // FUNGSI UPDATE STATUS + TEMBAK NOTIFIKASI
  Future<void> _updateStatus(String docId, String newStatus) async {
    // 1. Update status jadwal
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentId)
        .collection('schedules')
        .doc(docId)
        .update({'status': newStatus});
    
    // 2. Tembak notifikasi ke mahasiswa
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentId)
        .collection('notifications')
        .add({
      'title': newStatus == 'Diterima' ? 'Jadwal Di-ACC! 🎉' : 'Jadwal Ditolak ❌',
      'body': 'Dosen pembimbing telah $newStatus pengajuan jadwal bimbinganmu.',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Jadwal $newStatus"), backgroundColor: _getStatusColor(newStatus)),
      );
    }
  }

  void _showAddScheduleModal() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    DateTime? selectedDate;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              children: [
                Text(isStudent ? "Ajukan Jadwal" : "Atur Jadwal", 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Agenda', prefixIcon: const Icon(Icons.event), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: 'Lokasi', prefixIcon: const Icon(Icons.location_on), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (picked != null) {
                      TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (time != null) {
                        setModalState(() => selectedDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
                      }
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(selectedDate == null ? "Pilih Waktu" : DateFormat('dd MMM, HH:mm').format(selectedDate!)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (titleController.text.isEmpty || selectedDate == null) return;
                      setModalState(() => isLoading = true);

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.studentId)
                          .collection('schedules')
                          .add({
                        'title': titleController.text.trim(),
                        'location': locationController.text.trim(),
                        'date': Timestamp.fromDate(selectedDate!),
                        'createdBy': currentUserId,
                        'status': isStudent ? 'Menunggu Konfirmasi' : 'Diterima', 
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("SIMPAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diterima': return Colors.green;
      case 'Ditolak': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jadwal Bimbingan"), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: _showAddScheduleModal, backgroundColor: Colors.orange, child: const Icon(Icons.add, color: Colors.white)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.studentId)
            .collection('schedules')
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'Menunggu Konfirmasi';
              DateTime date = (data['date'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  onTap: () => _showConfirmationDialog(doc.id, data),
                  leading: Icon(Icons.event_available, color: _getStatusColor(status)),
                  title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${DateFormat('dd MMM, HH:mm').format(date)}\nStatus: $status"),
                  isThreeLine: true,
                  trailing: isStudent ? null : const Icon(Icons.touch_app, size: 16, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}