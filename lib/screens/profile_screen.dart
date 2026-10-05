import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: const Color(0xFF138D5B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFF138D5B),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 56, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text('Ahmad Fauzan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: const Text('Dokter Umum', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildInfoCard('Informasi Pegawai', [
                    _buildInfoRow(Icons.badge_outlined, 'ID Pegawai', 'EMP001'),
                    _buildInfoRow(Icons.email_outlined, 'Email', 'ahmad.fauzan@almiftah.com'),
                    _buildInfoRow(Icons.phone_outlined, 'Nomor HP', '0812-3456-7890'),
                    _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal Bergabung', '01 Januari 2026'),
                  ]),
                  const SizedBox(height: 12),
                  _buildInfoCard('Informasi Kerja', [
                    _buildInfoRow(Icons.business_outlined, 'Cabang', 'Klinik Al-Miftah Pusat'),
                    _buildInfoRow(Icons.schedule_outlined, 'Shift Aktif', 'Shift Pagi (08:00 - 14:00)'),
                    _buildInfoRow(Icons.check_circle_outline, 'Status', 'Aktif'),
                  ]),
                  const SizedBox(height: 12),
                  _buildInfoCard('Perangkat Terdaftar', [
                    _buildInfoRow(Icons.smartphone_outlined, 'Model', 'Samsung Galaxy A15'),
                    _buildInfoRow(Icons.android_outlined, 'Android', '14'),
                    _buildInfoRow(Icons.verified_outlined, 'Status Binding', 'Terikat (Device Binding aktif)'),
                  ]),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const _LoginPlaceholder()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF138D5B))),
          ),
          const Divider(height: 1),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder untuk routing — akan diganti dengan LoginScreen ketika dipasang di main.dart
class _LoginPlaceholder extends StatelessWidget {
  const _LoginPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Kembali ke Login...')));
  }
}
