import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('employees').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE06A00)));
          }
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'Pegawai';
          final role = data['role'] ?? 'Staff';
          
          String employeeId = data['employeeId'] ?? snapshot.data?.id ?? 'EMP-XXX';
          // Singkat UID panjang agar rapi dipandang
          if (employeeId.length > 15) {
            employeeId = 'EMP-${employeeId.substring(0, 6).toUpperCase()}';
          }
          
          final branchId = data['branchId'] ?? 'HQ-01';

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('branches').doc(branchId).get(),
            builder: (context, branchSnapshot) {
              final branchData = branchSnapshot.data?.data() as Map<String, dynamic>?;
              final branchName = branchData?['name'] ?? branchId;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Header dengan Gradient dan Curve
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 100, 24, 60),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF8C00), Color(0xFFE06A00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            )
                          ),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                                ),
                                child: const CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Colors.white24,
                                  child: Icon(Icons.person_rounded, size: 64, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(name, 
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2), 
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.3))
                                ),
                                child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Info Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildInfoCard('Informasi Pegawai', [
                            _buildInfoRow(Icons.badge_rounded, 'ID Pegawai', employeeId),
                            _buildInfoRow(Icons.email_rounded, 'Email / Kontak', user?.email ?? '-'),
                          ]),
                          const SizedBox(height: 16),
                          _buildInfoCard('Informasi Kerja', [
                            _buildInfoRow(Icons.domain_rounded, 'Cabang', branchName),
                            _buildInfoRow(Icons.schedule_rounded, 'Shift Aktif', 'Tergantung Jadwal'),
                            _buildInfoRow(Icons.verified_rounded, 'Status', 'Aktif', valueColor: Colors.green.shade600),
                          ]),
                          const SizedBox(height: 16),
                          _buildInfoCard('Perangkat Terdaftar', [
                            _buildInfoRow(Icons.phonelink_lock_rounded, 'Status Keamanan', 'Device Binding Aktif', valueColor: Colors.blue.shade700),
                          ]),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                              icon: const Icon(Icons.logout_rounded, color: Colors.white),
                              label: const Text('Keluar dari Akun', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.red.shade900,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          );
        }
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFFE06A00))),
          ),
          Container(height: 1, color: Colors.grey.shade100),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  value, 
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.w700, 
                    color: valueColor ?? const Color(0xFF2D3142)
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Removed Placeholder
