import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Hadir', 'Terlambat', 'Tidak Hadir', 'Izin', 'Sakit', 'Cuti'];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'late': return Colors.orange;
      case 'absent': return Colors.red;
      case 'permission': return Colors.blue;
      case 'sick': return Colors.purple;
      case 'leave': return Colors.teal;
      case 'business_trip': return Colors.indigo;
      case 'early_checkout': return Colors.amber.shade700;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'present': return 'Hadir';
      case 'late': return 'Terlambat';
      case 'absent': return 'Tidak Hadir';
      case 'permission': return 'Izin';
      case 'sick': return 'Sakit';
      case 'leave': return 'Cuti';
      case 'business_trip': return 'Dinas';
      case 'early_checkout': return 'Pulang Cepat';
      default: return status;
    }
  }

  String _getStatusFilterValue(String filter) {
    switch (filter) {
      case 'Hadir': return 'present';
      case 'Terlambat': return 'late';
      case 'Tidak Hadir': return 'absent';
      case 'Izin': return 'permission';
      case 'Sakit': return 'sick';
      case 'Cuti': return 'leave';
      case 'Dinas': return 'business_trip';
      case 'Pulang Cepat': return 'early_checkout';
      default: return 'all';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: const Color(0xFF138D5B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter chip row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = f),
                      selectedColor: const Color(0xFF138D5B),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('employeeId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .orderBy('workDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                final docs = snapshot.data?.docs ?? [];
                
                final filterValue = _getStatusFilterValue(_selectedFilter);
                final filteredDocs = filterValue == 'all'
                    ? docs
                    : docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == filterValue).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('Tidak ada data untuk filter ini.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    
                    final String status = data['status'] ?? 'unknown';
                    final Color color = _getStatusColor(status);
                    final String statusLabel = _getStatusLabel(status);
                    
                    String checkInTime = '--';
                    String checkOutTime = '--';
                    int lateMin = 0;
                    
                    if (data['checkIn'] != null) {
                      final Timestamp? ts = data['checkIn']['timestamp'];
                      if (ts != null) {
                         checkInTime = DateFormat('HH:mm').format(ts.toDate());
                      }
                      lateMin = data['lateMinutes'] ?? 0;
                    }
                    if (data['checkOut'] != null) {
                      final Timestamp? ts = data['checkOut']['timestamp'];
                      if (ts != null) {
                         checkOutTime = DateFormat('HH:mm').format(ts.toDate());
                      }
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 60,
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['workDate'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.login, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('Masuk: $checkInTime', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.logout, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('Pulang: $checkOutTime', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                    ],
                                  ),
                                  if (lateMin > 0) ...[
                                    const SizedBox(height: 4),
                                    Text('Terlambat $lateMin menit', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                              child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                            ),
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
