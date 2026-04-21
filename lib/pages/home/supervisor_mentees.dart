import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_page.dart';
import '../chat_page.dart';
import 'review_progress_page.dart';
import 'schedule_page.dart';

class SupervisorMentees extends StatefulWidget {
  const SupervisorMentees({super.key});

  @override
  State<SupervisorMentees> createState() => _SupervisorMenteesState();
}

class _SupervisorMenteesState extends State<SupervisorMentees> {
  final User? user = FirebaseAuth.instance.currentUser;
  String get nidn => user?.email?.split('@')[0] ?? '';

  // Controller untuk fitur pencarian
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleApproval(String studentId, bool isAccepted) async {
    if (isAccepted) {
      await FirebaseFirestore.instance.collection('users').doc(studentId).update({'isMentorApproved': true});
    } else {
      await FirebaseFirestore.instance.collection('users').doc(studentId).update({'mentorId': '', 'isMentorApproved': false});
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
        title: const Text('Mahasiswa Bimbingan', style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.teal, 
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      body: Column(
        children: [
          // 1. BAGIAN SEARCH BAR
          Container(
            color: Colors.teal,
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: "Cari nama mahasiswa...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ) 
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. DAFTAR MAHASISWA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users')
                  .where('role', isEqualTo: 'student')
                  .where('mentorId', isEqualTo: nidn)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada mahasiswa.", style: TextStyle(color: Colors.grey)));

                // LOGIKA FILTER PENCARIAN
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text("Mahasiswa '$_searchQuery' tidak ditemukan.", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20), 
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var studentDoc = filteredDocs[index];
                    var studentData = studentDoc.data() as Map<String, dynamic>;
                    String studentId = studentDoc.id;
                    
                    bool isApproved = studentData.containsKey('isMentorApproved') ? studentData['isMentorApproved'] : false;

                    return Card(
                      elevation: 3, margin: const EdgeInsets.only(bottom: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 25, backgroundColor: isApproved ? Colors.teal.withOpacity(0.1) : Colors.orange.withOpacity(0.1), child: Icon(Icons.person, color: isApproved ? Colors.teal : Colors.orange)),
                                const SizedBox(width: 15),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(studentData['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text("NIM: $studentId", style: const TextStyle(color: Colors.grey))])),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                            
                            if (!isApproved) ...[
                              Container(
                                padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Text("Mahasiswa ini mengajukan diri untuk Anda bimbing.", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(onPressed: () => _handleApproval(studentId, false), child: const Text("Tolak", style: TextStyle(color: Colors.red))),
                                  const SizedBox(width: 10),
                                  ElevatedButton(onPressed: () => _handleApproval(studentId, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text("Terima")),
                                ],
                              )
                            ] else ...[
                              const Text("Judul Skripsi:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text(studentData['thesis_title'] ?? '', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: Wrap(
                                  spacing: 8, runSpacing: 8, alignment: WrapAlignment.end,
                                  children: [
                                    OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverId: studentId, receiverName: studentData['name']))), icon: const Icon(Icons.chat_outlined, size: 16), label: const Text("Chat"), style: OutlinedButton.styleFrom(foregroundColor: Colors.teal)),
                                    OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SchedulePage(studentId: studentId, studentName: studentData['name']))), icon: const Icon(Icons.calendar_month_outlined, size: 16), label: const Text("Jadwal"), style: OutlinedButton.styleFrom(foregroundColor: Colors.orange)),
                                    ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewProgressPage(studentId: studentId, studentName: studentData['name']))), icon: const Icon(Icons.analytics_outlined, size: 16), label: const Text("Progres"), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white)),
                                  ],
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}