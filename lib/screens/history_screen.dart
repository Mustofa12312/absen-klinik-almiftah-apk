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
      case 'present': return const Color(0xFFE06A00);
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Riwayat Absensi', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFE06A00),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter chip row
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedFilter = f),
                        selectedColor: const Color(0xFFE06A00),
                        backgroundColor: Colors.grey.shade100,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide.none,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('employeeId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .orderBy('workDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFE06A00)));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Terjadi kesalahan:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                
                final filterValue = _getStatusFilterValue(_selectedFilter);
                final filteredDocs = filterValue == 'all'
                    ? docs
                    : docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == filterValue).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ]
                          ),
                          child: Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Belum Ada Riwayat',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada data untuk filter "$_selectedFilter"',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    
                    final String status = data['status'] ?? 'unknown';
                    final Color color = _getStatusColor(status);
                    final String statusLabel = _getStatusLabel(status);
                    
                    String checkInTime = '--:--';
                    String checkOutTime = '--:--';
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
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                color: color,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            data['workDate'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: Color(0xFF2D3142),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTimeCol('Masuk', checkInTime, Icons.login_rounded),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 30,
                                            color: Colors.grey.shade200,
                                          ),
                                          Expanded(
                                            child: _buildTimeCol('Pulang', checkOutTime, Icons.logout_rounded),
                                          ),
                                        ],
                                      ),
                                      if (lateMin > 0) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.warning_rounded, size: 14, color: Colors.red.shade400),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Terlambat $lateMin menit',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildTimeCol(String label, String time, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
      ],
    );
  }
}
