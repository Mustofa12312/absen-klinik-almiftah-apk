import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Hadir', 'Terlambat', 'Tidak Hadir', 'Izin', 'Sakit', 'Cuti'];

  final List<Map<String, dynamic>> _dummyHistory = [
    {'date': '05 Okt 2026', 'checkIn': '07:56', 'checkOut': '14:03', 'status': 'Hadir', 'color': Colors.green, 'lateMin': 0},
    {'date': '04 Okt 2026', 'checkIn': '08:22', 'checkOut': '14:00', 'status': 'Terlambat', 'color': Colors.orange, 'lateMin': 22},
    {'date': '03 Okt 2026', 'checkIn': '--',    'checkOut': '--',    'status': 'Izin',     'color': Colors.blue, 'lateMin': 0},
    {'date': '02 Okt 2026', 'checkIn': '08:05', 'checkOut': '13:30', 'status': 'Pulang Cepat', 'color': Colors.amber.shade700, 'lateMin': 0},
    {'date': '01 Okt 2026', 'checkIn': '07:58', 'checkOut': '14:02', 'status': 'Hadir', 'color': Colors.green, 'lateMin': 0},
    {'date': '30 Sep 2026', 'checkIn': '--',    'checkOut': '--',    'status': 'Sakit',    'color': Colors.purple, 'lateMin': 0},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'Semua'
        ? _dummyHistory
        : _dummyHistory.where((r) => r['status'] == _selectedFilter).toList();

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
            child: filtered.isEmpty
                ? const Center(child: Text('Tidak ada data untuk filter ini.', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final record = filtered[index];
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
                                decoration: BoxDecoration(
                                  color: record['color'] as Color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(record['date'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.login, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('Masuk: ${record['checkIn']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.logout, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('Pulang: ${record['checkOut']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                      ],
                                    ),
                                    if ((record['lateMin'] as int) > 0) ...[
                                      const SizedBox(height: 4),
                                      Text('Terlambat ${record['lateMin']} menit', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: (record['color'] as Color).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  record['status'] as String,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: record['color'] as Color),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
