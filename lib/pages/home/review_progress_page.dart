import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewProgressPage extends StatefulWidget {
  final String studentId; // NIM Mahasiswa
  final String studentName; // Nama Mahasiswa

  const ReviewProgressPage({super.key, required this.studentId, required this.studentName});

  @override
  State<ReviewProgressPage> createState() => _ReviewProgressPageState();
}

class _ReviewProgressPageState extends State<ReviewProgressPage> {
  // Fungsi memunculkan form review
  void _showReviewModal(String babId, Map<String, dynamic> data) {
    final TextEditingController feedbackController = TextEditingController(text: data['feedback'] ?? '');
    String selectedStatus = data['status'] ?? 'Menunggu ACC';
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Review ${data['bab']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 15),
                
                // Pilihan Status
                const Text("Tentukan Status:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Menunggu ACC', 'Revisi', 'ACC'].map((status) {
                    bool isSelected = selectedStatus == status;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      selectedColor: _getStatusColor(status).withOpacity(0.3),
                      labelStyle: TextStyle(color: isSelected ? _getStatusColor(status) : Colors.black, fontWeight: FontWeight.bold),
                      onSelected: (val) => setModalState(() => selectedStatus = status),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                TextField(
                  controller: feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Catatan Revisi / Feedback',
                    hintText: 'Tuliskan apa yang perlu diperbaiki...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 25),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      setModalState(() => isLoading = true);
                      
                      // Update data ke sub-collection progress milik mahasiswa tersebut
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.studentId)
                          .collection('progress')
                          .doc(babId)
                          .update({
                        'status': selectedStatus,
                        'feedback': feedbackController.text.trim(),
                        'reviewedAt': FieldValue.serverTimestamp(),
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Berhasil mengirim review!"), backgroundColor: Colors.teal),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SIMPAN REVIEW", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          );
        }
      ),
    );
  }

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Review Progres", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.studentName, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.studentId)
            .collection('progress')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Mahasiswa belum mengirimkan progres apapun."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'Menunggu ACC';

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ExpansionTile(
                  leading: Icon(Icons.description_outlined, color: _getStatusColor(status)),
                  title: Text(data['bab'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Status: $status", style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Link Dokumen:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(data['link'] ?? '-', style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                          const SizedBox(height: 10),
                          const Text("Catatan Mahasiswa:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(data['notes'] ?? 'Tidak ada catatan'),
                          const Divider(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showReviewModal(doc.id, data),
                              icon: const Icon(Icons.rate_review_outlined),
                              label: const Text("BERI REVIEW / ACC"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}