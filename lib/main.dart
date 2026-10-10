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
    // await FirebaseAppCheck.instance.activate(
    //   androidProvider: AndroidProvider.playIntegrity,
    //   appleProvider: AppleProvider.deviceCheck,
    // );
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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
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
              const Text(
                'Klinik Al-Miftah',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sistem Absensi Pegawai',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
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
      String phone = _emailCtrl.text.trim().replaceAll(' ', '');
      String email = phone.contains('@') ? phone : '$phone@almiftah.com';
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Terjadi kesalahan. Silakan coba lagi.';
        if (e is FirebaseAuthException) {
          msg = e.message ?? 'Login gagal. Periksa email dan password Anda.';
        } else {
          msg = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE06A00).withOpacity(0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/logo.png', height: 80),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Assalamualaikum\nWr Wb',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF2D3142), height: 1.2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Masuk dengan akun pegawai Anda',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Nomor HP / Email',
                      labelStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFE06A00)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE06A00), width: 1.5),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Masukkan Nomor HP atau Email' : null,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFFE06A00)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE06A00), width: 1.5),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Password minimal 6 karakter' : null,
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8F49), Color(0xFFE06A00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE06A00).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'MASUK',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: const Color(0xFFE06A00).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFFE06A00)),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFFE06A00)),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: Color(0xFFE06A00)),
            label: 'Pengajuan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFE06A00)),
            label: 'Profil',
          ),
        ],
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
      {
        'title': 'Izin',
        'icon': Icons.event_busy_outlined,
        'type': 'Izin',
        'color': Colors.blue,
      },
      {
        'title': 'Sakit',
        'icon': Icons.sick_outlined,
        'type': 'Sakit',
        'color': Colors.red,
      },
      {
        'title': 'Cuti',
        'icon': Icons.beach_access_outlined,
        'type': 'Cuti',
        'color': Colors.teal,
      },
      {
        'title': 'Dinas',
        'icon': Icons.work_outline,
        'type': 'Dinas',
        'color': Colors.orange,
      },
      {
        'title': 'Koreksi',
        'icon': Icons.edit_calendar_outlined,
        'type': 'Koreksi',
        'color': Colors.purple,
      },
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
          Text(
            'Pilih Jenis Pengajuan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 24,
                  ),
                ),
                title: Text(
                  'Pengajuan ${item['title']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _getSubtitle(item['type'] as String),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RequestScreen(requestType: item['type'] as String),
                    ),
                  );
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
      case 'Izin':
        return 'Pengajuan izin tidak masuk kerja';
      case 'Sakit':
        return 'Laporan sakit dengan atau tanpa surat dokter';
      case 'Cuti':
        return 'Pengajuan cuti beberapa hari (BR-19)';
      case 'Dinas':
        return 'Tugas luar klinik / perjalanan dinas';
      case 'Koreksi':
        return 'Koreksi lupa absen masuk / pulang (BR-21)';
      default:
        return '';
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
  String employeeName = 'Mustofa';
  String shiftDisplay = '--:--';
  List<Map<String, dynamic>> recentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final empDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(user.uid)
          .get();
      if (!empDoc.exists) {
        if (mounted) _showError('Data pegawai tidak ditemukan.');
        setState(() => _isLoading = false);
        return;
      }

      final empData = empDoc.data()!;
      employeeName = empData['name'] ?? user.displayName ?? 'Mustofa';
      branchId = empData['branchId'];
      shiftId = empData['currentShiftId'];

      if (branchId != null) {
        final branchDoc = await FirebaseFirestore.instance
            .collection('branches')
            .doc(branchId)
            .get();
        if (branchDoc.exists) {
          final bData = branchDoc.data()!;
          branchLat = bData['latitude']?.toDouble();
          branchLng = bData['longitude']?.toDouble();
          branchRadius = bData['radius']?.toDouble();
        }
      }

      final shiftsSnap = await FirebaseFirestore.instance.collection('shifts').get();
      if (shiftsSnap.docs.isNotEmpty) {
        final now = DateTime.now();
        final nowMinutes = now.hour * 60 + now.minute;
        
        Map<String, dynamic>? activeShift;
        int minDiff = 24 * 60; // Max minutes in a day
        String? foundShiftId;

        for (var doc in shiftsSnap.docs) {
          final sData = doc.data();
          final start = sData['startTime'] as String? ?? '08:00';
          final parts = start.split(':');
          if (parts.length < 2) continue;
          
          final shiftMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          final diff = (shiftMins - nowMinutes).abs();
          
          final tolerance = sData['tolerance'] ?? sData['toleranceMinutes'] ?? 15;
          final earlyBound = shiftMins - 60; // Can check in 1 hr before
          final lateBound = shiftMins + tolerance;
          
          // Prioritaskan shift yang sedang aktif saat ini
          if (nowMinutes >= earlyBound && nowMinutes <= lateBound) {
            activeShift = sData;
            foundShiftId = doc.id;
            break; 
          }
          
          // Jika tidak ada yang aktif, cari yang jamnya paling dekat (fallback)
          if (diff < minDiff) {
            minDiff = diff;
            activeShift = sData;
            foundShiftId = doc.id;
          }
        }
        
        if (activeShift != null) {
          shiftId = foundShiftId;
          shiftStart = activeShift['startTime'] ?? '08:00';
          shiftTolerance = activeShift['tolerance'] ?? activeShift['toleranceMinutes'] ?? 15;
          shiftDisplay = '${activeShift['name'] ?? 'Shift'} ($shiftStart - ${activeShift['endTime'] ?? '--:--'})';
        }
      }

      final now = DateTime.now();
      final workDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

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
          _statusAbsensi =
              'Masuk pukul ${data['checkIn']?['timestamp'] != null ? TimeOfDay.fromDateTime((data['checkIn']['timestamp'] as Timestamp).toDate()).format(context) : '...'}';
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
    final shiftTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final earlyBound = shiftTime.subtract(const Duration(minutes: 60));
    
    // Tidak lagi ditolak jika lewat batas toleransi. 
    // Batas toleransi hanya dipakai untuk memberi status "Terlambat" di database.
    // Selama dia absen setelah batas awal (earlyBound), izinkan masuk.
    return now.isAfter(earlyBound);
  }

  Future<void> _prosesAbsen() async {
    setState(() => _isLoading = true);
    try {
      if (branchLat == null || branchLng == null || branchRadius == null) {
        _showError('Konfigurasi cabang tidak valid.');
        return;
      }

      // Validasi Shift: Ditolak jika terlalu cepat (sebelum earlyBound)
      if (!_hasCheckedIn && !_isTimeValid(shiftStart, shiftTolerance)) {
        _showError(
          'Belum masuk waktu absen.\nShift dimulai pukul: $shiftStart',
        );
        return;
      }

      _showLoading('Memverifikasi Perangkat...');
      final deviceResult = await DeviceService.checkDeviceIntegrity();
      if (!deviceResult.isValid) {
        _pop();
        _showError(deviceResult.message);
        return;
      }

      _pop();
      _showLoading('Memverifikasi Lokasi & GPS...');
      final locationResult = await LocationService.getCurrentLocation();
      if (!locationResult.isValid) {
        _pop();
        _showError(locationResult.message);
        if (locationResult.message.contains('Fake GPS')) {
          FirestoreService.logSecurityEvent(
            type: 'mock_location',
            branchId: branchId ?? 'unknown',
            deviceId: deviceResult.deviceId ?? 'unknown',
          );
        }
        return;
      }

      final inRange = LocationService.isWithinRadius(
        userLat: locationResult.position!.latitude,
        userLng: locationResult.position!.longitude,
        branchLat: branchLat!,
        branchLng: branchLng!,
        radiusInMeters: branchRadius!,
      );
      _pop();

      if (!inRange) {
        _showError(
          'Anda berada di luar area klinik.\nPastikan Anda sudah di lokasi kerja.',
        );
        FirestoreService.logSecurityEvent(
          type: 'outside_geofence',
          branchId: branchId ?? 'unknown',
          deviceId: deviceResult.deviceId ?? 'unknown',
        );
        return;
      }

      // Simpan nilai sebelum update untuk pesan snackbar
      final wasCheckedIn = _hasCheckedIn;

      if (!_hasCheckedIn) {
        final now = DateTime.now();
        final parts = shiftStart.split(':');
        final shiftTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        final diffMins = now.difference(shiftTime).inMinutes;
        final lateMinutes = diffMins > shiftTolerance ? diffMins : 0;

        // Cek double sebelum simpan
        final workDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final check = await FirebaseFirestore.instance
            .collection('attendance')
            .where(
              'employeeId',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .where('workDate', isEqualTo: workDate)
            .limit(1)
            .get();

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasCheckedIn
                ? '✓ Absensi Pulang Berhasil!'
                : '✓ Absensi Masuk Berhasil!',
          ),
          backgroundColor: wasCheckedIn
              ? Colors.blue.shade700
              : const Color(0xFFE06A00),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) _pop();
      _showError('Terjadi kesalahan pada sistem.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLoading(String msg) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    ),
  );

  void _pop() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDone = _statusAbsensi.startsWith('Selesai');
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE06A00).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0xFFE06A00),
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assalamualaikum Wr Wb,',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Color(0xFF2D3142),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF2D3142),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Status Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE06A00).withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shift Hari Ini',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shiftDisplay,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: Color(0xFF2D3142),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            _statusAbsensi,
                            style: TextStyle(
                              color: _statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: (isDone || _isLoading)
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : _hasCheckedIn
                              ? [Colors.blue.shade400, Colors.blue.shade600]
                              : [
                                  const Color(0xFFFF8F49),
                                  const Color(0xFFE06A00),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          if (!isDone && !_isLoading)
                            BoxShadow(
                              color:
                                  (_hasCheckedIn
                                          ? Colors.blue
                                          : const Color(0xFFE06A00))
                                      .withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: (isDone || _isLoading) ? null : _prosesAbsen,
                        icon: Icon(
                          _hasCheckedIn
                              ? Icons.logout_rounded
                              : Icons.fingerprint_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        label: Text(
                          isDone
                              ? 'Absensi Selesai'
                              : _hasCheckedIn
                              ? 'ABSEN PULANG'
                              : 'ABSEN MASUK',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Riwayat singkat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Absensi Terakhir',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(4),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: Color(0xFFE06A00),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada riwayat absensi',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentHistory.map((hist) {
                  final status = hist['status'] ?? 'unknown';
                  String checkIn = '--';
                  String checkOut = '--';
                  if (hist['checkIn']?['timestamp'] != null) {
                    checkIn = TimeOfDay.fromDateTime(
                      (hist['checkIn']['timestamp'] as Timestamp).toDate(),
                    ).format(context);
                  }
                  if (hist['checkOut']?['timestamp'] != null) {
                    checkOut = TimeOfDay.fromDateTime(
                      (hist['checkOut']['timestamp'] as Timestamp).toDate(),
                    ).format(context);
                  }
                  Color color = Colors.grey;
                  String statusLabel = status;
                  if (status == 'present') {
                    color = const Color(0xFFE06A00);
                    statusLabel = 'Hadir';
                  } else if (status == 'late') {
                    color = Colors.orange;
                    statusLabel = 'Terlambat';
                  } else if (status == 'permission') {
                    color = Colors.blue;
                    statusLabel = 'Izin';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildRecentCard(
                      hist['workDate'] ?? '--',
                      checkIn,
                      checkOut,
                      statusLabel,
                      color,
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCard(
    String date,
    String checkIn,
    String checkOut,
    String status,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.access_time_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$checkIn  →  $checkOut',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
