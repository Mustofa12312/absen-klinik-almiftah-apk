import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'services/device_service.dart';
import 'services/location_service.dart';
import 'screens/request_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Inisialisasi Firebase App Check (BR-04)
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug, // Ganti PlayIntegrity untuk production
      appleProvider: AppleProvider.debug,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed (dummy keys used): $e');
  }

  runApp(const KlinikAlmiftahApp());
}

class KlinikAlmiftahApp extends StatelessWidget {
  const KlinikAlmiftahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klinik Al-Miftah',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF138D5B)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital, size: 80, color: Color(0xFF138D5B)),
            SizedBox(height: 20),
            Text(
              'Klinik Al-Miftah',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF138D5B),
              ),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.local_hospital, size: 60, color: Color(0xFF138D5B)),
              const SizedBox(height: 32),
              const Text(
                'Selamat Datang',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan masuk dengan akun pegawai Anda',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('MASUK', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  String _statusAbsensi = 'Belum Absen';
  Color _statusColor = Colors.orange;
  
  bool _hasCheckedIn = false;
  String? _attendanceId;

  // Mock data untuk Cabang HQ-01 (Klinik Al-Miftah Pusat)
  final double branchLat = -6.2088;
  final double branchLng = 106.8456;
  final double branchRadius = 100.0;
  
  // Data Shift Dummy
  final String shiftStart = '08:00';
  final String shiftEnd = '14:00';
  final int shiftTolerance = 15; // menit

  bool _isTimeValid(String timeStr, int toleranceMins) {
    // Implementasi simpel cek shift untuk BR-12 & BR-14
    final now = DateTime.now();
    final parts = timeStr.split(':');
    final shiftTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    final toleranceTime = shiftTime.add(Duration(minutes: toleranceMins));
    final earlyBound = shiftTime.subtract(const Duration(minutes: 60)); // bisa absen 1 jam lebih awal

    return now.isAfter(earlyBound) && now.isBefore(toleranceTime);
  }

  Future<void> _prosesAbsen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validasi Shift (BR-12 & BR-14)
      if (!_hasCheckedIn) {
        if (!_isTimeValid(shiftStart, shiftTolerance)) {
          _showErrorSnackBar('Di luar batas waktu absen (Shift: $shiftStart, Toleransi: $shiftTolerance mnt)');
          return;
        }
      }

      // Tahap 1: Validasi Device (Emulator / Binding)
      _showLoadingDialog('Memverifikasi Perangkat...');
      DeviceResult deviceResult = await DeviceService.checkDeviceIntegrity();
      
      if (!deviceResult.isValid) {
        Navigator.pop(context); // Tutup dialog
        _showErrorSnackBar(deviceResult.message);
        return;
      }
      
      // Tahap 2: Validasi Lokasi (Mock GPS, Radius, Akurasi)
      Navigator.pop(context); // Tutup dialog pertama
      _showLoadingDialog('Memverifikasi Lokasi & GPS...');
      LocationResult locationResult = await LocationService.getCurrentLocation();
      
      if (!locationResult.isValid) {
        Navigator.pop(context);
        _showErrorSnackBar(locationResult.message);
        
        // Simulasikan pembuatan Security Event ke Firebase jika Fake GPS
        if (locationResult.message.contains('Fake GPS')) {
           print("SECURITY EVENT RECORDED TO FIREBASE!");
        }
        return;
      }

      // Tahap 3: Validasi Geofence Radius
      bool dalamRadius = LocationService.isWithinRadius(
        userLat: locationResult.position!.latitude,
        userLng: locationResult.position!.longitude,
        branchLat: branchLat,
        branchLng: branchLng,
        radiusInMeters: branchRadius,
      );

      Navigator.pop(context); // Tutup dialog

      if (!dalamRadius) {
        _showErrorSnackBar('Absensi ditolak: Anda berada di luar area klinik.');
        return;
      }

      // Berhasil - Simulasikan Simpan ke Firebase dan Ganti State
      setState(() {
        if (!_hasCheckedIn) {
          _statusAbsensi = 'Hadir (Masuk)';
          _statusColor = Colors.green;
          _hasCheckedIn = true;
          _attendanceId = 'simulated_id_123';
        } else {
          _statusAbsensi = 'Hadir (Selesai)';
          _statusColor = Colors.blue;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!_hasCheckedIn ? 'Absensi Pulang Berhasil!' : 'Absensi Masuk Berhasil!'),
          backgroundColor: !_hasCheckedIn ? Colors.blue : Colors.green,
          duration: const Duration(seconds: 3),
        )
      );

    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Terjadi kesalahan sistem: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selamat datang,', style: TextStyle(color: Colors.grey)),
                  const Text('Ahmad Fauzan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Shift Hari Ini'),
                      Text('08:00 - 14:00', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status Absensi'),
                      Text(_statusAbsensi, style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_isLoading || _statusAbsensi == 'Hadir (Selesai)') ? null : _prosesAbsen,
                      icon: Icon(_hasCheckedIn ? Icons.directions_walk : Icons.fingerprint),
                      label: Text(_hasCheckedIn ? 'ABSEN PULANG' : 'ABSEN MASUK'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _hasCheckedIn ? Colors.blue.shade700 : const Color(0xFF138D5B),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Menu Utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildMenuCard(context, Icons.history, 'Riwayat', 'Riwayat'),
              _buildMenuCard(context, Icons.edit_document, 'Koreksi', 'Koreksi'),
              _buildMenuCard(context, Icons.sick, 'Izin / Sakit', 'Sakit'),
              _buildMenuCard(context, Icons.person, 'Profil', 'Profil'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, IconData icon, String title, String actionType) {
    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade100)
      ),
      child: InkWell(
        onTap: () {
          if (actionType == 'Koreksi' || actionType == 'Sakit') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestScreen(requestType: actionType),
              ),
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur sedang dalam pengembangan.'))
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF138D5B)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF138D5B))),
          ],
        ),
      ),
    );
  }
}
