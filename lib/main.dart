import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/device_service.dart';
import 'services/location_service.dart';
import 'services/firestore_service.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/request_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  } catch (e) {
    debugPrint('Firebase init failed (dummy keys): $e');
  }

  runApp(const KlinikAlmiftahApp());
}

class KlinikAlmiftahApp extends StatelessWidget {
  const KlinikAlmiftahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klinik Al-Miftah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE06A00)),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      home: const SplashScreen(),
    );
  }
}

// ===== SPLASH SCREEN =====
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE06A00),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 120, height: 120),
              const SizedBox(height: 16),
              const Text('Klinik Al-Miftah', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              const Text('Sistem Absensi Pegawai', style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== LOGIN SCREEN =====
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message ?? 'Login gagal. Periksa email dan password Anda.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Image.asset('assets/logo.png', height: 80),
                const SizedBox(height: 24),
                const Text('Selamat Datang', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Masuk dengan akun pegawai Anda', style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Masukkan email valid' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Password minimal 6 karakter' : null,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _loading ? null : _login,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFFE06A00),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('MASUK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== MAIN SHELL dengan BottomNavigationBar (PRD Bab 4) =====
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const HistoryScreen(),
    const RequestHubScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
    const BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Riwayat'),
    const BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Pengajuan'),
    const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFFE06A00),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }
}

// ===== REQUEST HUB — Pilih jenis pengajuan (PRD Bab 24-27) =====
class RequestHubScreen extends StatelessWidget {
  const RequestHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'Izin',     'icon': Icons.event_busy_outlined,      'type': 'Izin',    'color': Colors.blue},
      {'title': 'Sakit',    'icon': Icons.sick_outlined,             'type': 'Sakit',   'color': Colors.red},
      {'title': 'Cuti',     'icon': Icons.beach_access_outlined,     'type': 'Cuti',    'color': Colors.teal},
      {'title': 'Dinas',    'icon': Icons.work_outline,              'type': 'Dinas',   'color': Colors.orange},
      {'title': 'Koreksi',  'icon': Icons.edit_calendar_outlined,   'type': 'Koreksi', 'color': Colors.purple},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan'),
        backgroundColor: const Color(0xFFE06A00),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.grey.shade50,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Pilih Jenis Pengajuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          ...items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 24),
                ),
                title: Text('Pengajuan ${item['title']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_getSubtitle(item['type'] as String), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RequestScreen(requestType: item['type'] as String),
                  ));
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getSubtitle(String type) {
    switch (type) {
      case 'Izin':    return 'Pengajuan izin tidak masuk kerja';
      case 'Sakit':   return 'Laporan sakit dengan atau tanpa surat dokter';
      case 'Cuti':    return 'Pengajuan cuti beberapa hari (BR-19)';
      case 'Dinas':   return 'Tugas luar klinik / perjalanan dinas';
      case 'Koreksi': return 'Koreksi lupa absen masuk / pulang (BR-21)';
      default:        return '';
    }
  }
}

// ===== DASHBOARD SCREEN =====
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  String _statusAbsensi = 'Memuat...';
  Color _statusColor = Colors.grey;
  bool _hasCheckedIn = false;
  String? _attendanceId;

  double? branchLat;
  double? branchLng;
  double? branchRadius;
  String shiftStart = '08:00';
  int shiftTolerance = 15;
  String? branchId;
  String? shiftId;
  String employeeName = 'Pegawai';
  String shiftDisplay = '--:--';
  List<Map<String, dynamic>> recentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final empDoc = await FirebaseFirestore.instance.collection('employees').doc(user.uid).get();
      if (!empDoc.exists) {
        if (mounted) _showError('Data pegawai tidak ditemukan.');
        setState(() => _isLoading = false);
        return;
      }

      final empData = empDoc.data()!;
      employeeName = empData['name'] ?? 'Pegawai';
      branchId = empData['branchId'];
      shiftId = empData['currentShiftId'] ?? 'shift_1';

      if (branchId != null) {
        final branchDoc = await FirebaseFirestore.instance.collection('branches').doc(branchId).get();
        if (branchDoc.exists) {
          final bData = branchDoc.data()!;
          branchLat = bData['latitude']?.toDouble();
          branchLng = bData['longitude']?.toDouble();
          branchRadius = bData['radius']?.toDouble();
        }
      }

      if (shiftId != null) {
        final shiftDoc = await FirebaseFirestore.instance.collection('shifts').doc(shiftId).get();
        if (shiftDoc.exists) {
          final sData = shiftDoc.data()!;
          shiftStart = sData['startTime'] ?? '08:00';
          shiftTolerance = sData['toleranceMinutes'] ?? 15;
          shiftDisplay = '${shiftStart} - ${sData['endTime'] ?? '--:--'}';
        }
      }

      final now = DateTime.now();
      final workDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final attendanceQuery = await FirebaseFirestore.instance
          .collection('attendance')
          .where('employeeId', isEqualTo: user.uid)
          .where('workDate', isEqualTo: workDate)
          .limit(1)
          .get();

      if (attendanceQuery.docs.isNotEmpty) {
        final doc = attendanceQuery.docs.first;
        _attendanceId = doc.id;
        final data = doc.data();
        if (data['checkOut'] != null) {
          _statusAbsensi = 'Selesai kerja hari ini ✓';
          _statusColor = Colors.blue;
          _hasCheckedIn = true;
        } else {
          _hasCheckedIn = true;
          _statusAbsensi = 'Masuk pukul ${data['checkIn']?['timestamp'] != null ? TimeOfDay.fromDateTime((data['checkIn']['timestamp'] as Timestamp).toDate()).format(context) : '...'}';
          _statusColor = const Color(0xFFE06A00);
        }
      } else {
         _statusAbsensi = 'Belum Absen';
         _statusColor = Colors.orange;
      }

      final historyQuery = await FirebaseFirestore.instance
          .collection('attendance')
          .where('employeeId', isEqualTo: user.uid)
          .orderBy('workDate', descending: true)
          .limit(3)
          .get();
      
      recentHistory = historyQuery.docs.map((d) => d.data()).toList();

    } catch (e) {
      if (mounted) _showError('Gagal memuat data.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isTimeValid(String timeStr, int toleranceMins) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    final shiftTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    final toleranceTime = shiftTime.add(Duration(minutes: toleranceMins));
    final earlyBound = shiftTime.subtract(const Duration(minutes: 60));
    return now.isAfter(earlyBound) && now.isBefore(toleranceTime);
  }

  Future<void> _prosesAbsen() async {
    setState(() => _isLoading = true);
    try {
      if (branchLat == null || branchLng == null || branchRadius == null) {
        _showError('Konfigurasi cabang tidak valid.');
        return;
      }

      // Validasi Shift
      if (!_hasCheckedIn && !_isTimeValid(shiftStart, shiftTolerance)) {
        _showError('Di luar batas waktu absen.\nShift: $shiftStart | Toleransi: $shiftTolerance mnt');
        return;
      }

      _showLoading('Memverifikasi Perangkat...');
      final deviceResult = await DeviceService.checkDeviceIntegrity();
      if (!deviceResult.isValid) { _pop(); _showError(deviceResult.message); return; }

      _pop();
      _showLoading('Memverifikasi Lokasi & GPS...');
      final locationResult = await LocationService.getCurrentLocation();
      if (!locationResult.isValid) {
        _pop();
        _showError(locationResult.message);
        if (locationResult.message.contains('Fake GPS')) {
           FirestoreService.logSecurityEvent(
             type: 'mock_location', branchId: branchId ?? 'unknown', deviceId: deviceResult.deviceId ?? 'unknown'
           );
        }
        return;
      }

      final inRange = LocationService.isWithinRadius(
        userLat: locationResult.position!.latitude, userLng: locationResult.position!.longitude,
        branchLat: branchLat!, branchLng: branchLng!, radiusInMeters: branchRadius!,
      );
      _pop();

      if (!inRange) { 
        _showError('Anda berada di luar area klinik.\nPastikan Anda sudah di lokasi kerja.'); 
        FirestoreService.logSecurityEvent(
          type: 'outside_geofence', branchId: branchId ?? 'unknown', deviceId: deviceResult.deviceId ?? 'unknown'
        );
        return; 
      }

      if (!_hasCheckedIn) {
        final now = DateTime.now();
        final parts = shiftStart.split(':');
        final shiftTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
        final lateMinutes = now.difference(shiftTime).inMinutes > 0 ? now.difference(shiftTime).inMinutes : 0;
        
        // Cek double sebelum simpan
        final workDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final check = await FirebaseFirestore.instance.collection('attendance')
          .where('employeeId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('workDate', isEqualTo: workDate).limit(1).get();
          
        if (check.docs.isNotEmpty) {
           _showError('Anda sudah absen masuk hari ini.');
           return;
        }

        _attendanceId = await FirestoreService.checkIn(
          location: locationResult,
          device: deviceResult,
          branchId: branchId ?? 'unknown', 
          shiftId: shiftId ?? 'unknown',
          distanceMeters: 0.0,
          lateMinutes: lateMinutes,
        );
        setState(() {
          _hasCheckedIn = true;
          _statusAbsensi = 'Masuk pukul ${TimeOfDay.now().format(context)}';
          _statusColor = const Color(0xFFE06A00);
        });
      } else {
        await FirestoreService.checkOut(
          location: locationResult,
          device: deviceResult,
          attendanceId: _attendanceId!,
          distanceMeters: 0.0,
          earlyCheckoutMinutes: 0,
        );
        setState(() {
          _statusAbsensi = 'Selesai kerja hari ini ✓';
          _statusColor = Colors.blue;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_hasCheckedIn ? '✓ Absensi Pulang Berhasil!' : '✓ Absensi Masuk Berhasil!'),
        backgroundColor: _hasCheckedIn ? Colors.blue.shade700 : const Color(0xFFE06A00),
      ));
    } catch (e) {
      if (Navigator.canPop(context)) _pop();
      _showError('Terjadi kesalahan pada sistem.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLoading(String msg) => showDialog(
    context: context, barrierDismissible: false,
    builder: (_) => Dialog(child: Padding(padding: const EdgeInsets.all(20),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(), const SizedBox(width: 16), Expanded(child: Text(msg)),
      ]),
    )),
  );

  void _pop() { if (Navigator.canPop(context)) Navigator.pop(context); }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    final isDone = _statusAbsensi.startsWith('Selesai');
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const CircleAvatar(radius: 22, backgroundColor: Color(0xFFE06A00),
                    child: Icon(Icons.person, color: Colors.white, size: 24)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Selamat datang,', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 20),

              // Status Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Shift Hari Ini', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(shiftDisplay, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          ]),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _statusColor.withOpacity(0.3)),
                            ),
                            child: Text(_statusAbsensi, style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: (isDone || _isLoading) ? null : _prosesAbsen,
                          icon: Icon(_hasCheckedIn ? Icons.logout : Icons.fingerprint),
                          label: Text(isDone ? 'Absensi Selesai' : _hasCheckedIn ? 'ABSEN PULANG' : 'ABSEN MASUK'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _hasCheckedIn ? Colors.blue.shade700 : const Color(0xFFE06A00),
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Riwayat singkat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Absensi Terakhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton(onPressed: () {}, child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFFE06A00)))),
                ],
              ),
              const SizedBox(height: 8),
              if (recentHistory.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Center(child: Text('Belum ada riwayat absensi', style: TextStyle(color: Colors.grey))),
                )
              else
                ...recentHistory.map((hist) {
                  final status = hist['status'] ?? 'unknown';
                  String checkIn = '--';
                  String checkOut = '--';
                  if (hist['checkIn']?['timestamp'] != null) {
                    checkIn = TimeOfDay.fromDateTime((hist['checkIn']['timestamp'] as Timestamp).toDate()).format(context);
                  }
                  if (hist['checkOut']?['timestamp'] != null) {
                    checkOut = TimeOfDay.fromDateTime((hist['checkOut']['timestamp'] as Timestamp).toDate()).format(context);
                  }
                  Color color = Colors.grey;
                  String statusLabel = status;
                  if (status == 'present') { color = const Color(0xFFE06A00); statusLabel = 'Hadir'; }
                  else if (status == 'late') { color = Colors.orange; statusLabel = 'Terlambat'; }
                  else if (status == 'permission') { color = Colors.blue; statusLabel = 'Izin'; }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildRecentCard(hist['workDate'] ?? '--', checkIn, checkOut, statusLabel, color),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCard(String date, String checkIn, String checkOut, String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 14),
          Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 14),
          Text('$checkIn → $checkOut', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
