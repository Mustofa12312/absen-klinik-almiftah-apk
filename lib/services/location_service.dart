import 'package:geolocator/geolocator.dart';

class LocationResult {
  final bool isValid;
  final String message;
  final Position? position;

  LocationResult({required this.isValid, required this.message, this.position});
}

class LocationService {
  /// Memeriksa layanan GPS, izin, mock location, dan mengambil lokasi terkini.
  static Future<LocationResult> getCurrentLocation({double maxAccuracy = 50.0}) async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan GPS aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult(isValid: false, message: 'Layanan GPS tidak aktif. Silakan nyalakan GPS Anda.');
    }

    // 2. Cek izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult(isValid: false, message: 'Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult(isValid: false, message: 'Izin lokasi ditolak permanen, kami tidak dapat meminta izin.');
    }

    // 3 & 4. Ambil lokasi dengan tingkat akurasi tinggi
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Deteksi Mock Location (Fake GPS) menggunakan property isMocked dari Geolocator
    if (position.isMocked) {
      // BR-06: Mock Location terdeteksi -> Absensi Ditolak
      return LocationResult(isValid: false, message: 'Fake GPS / Mock Location terdeteksi! Absensi dibatalkan demi keamanan.');
    }



    // 5. Cek akurasi (BR-05)
    if (position.accuracy > maxAccuracy) {
      return LocationResult(
        isValid: false, 
        message: 'Akurasi GPS terlalu rendah (${position.accuracy.toStringAsFixed(1)}m). Pastikan Anda berada di luar ruangan atau gunakan koneksi internet yang lebih stabil.'
      );
    }

    return LocationResult(isValid: true, message: 'Lokasi valid', position: position);
  }

  /// Menghitung jarak antara pengguna dengan cabang (BR-04, BR-11)
  static bool isWithinRadius({
    required double userLat, 
    required double userLng, 
    required double branchLat, 
    required double branchLng, 
    required double radiusInMeters
  }) {
    double distanceInMeters = Geolocator.distanceBetween(
      userLat, userLng, 
      branchLat, branchLng
    );

    return distanceInMeters <= radiusInMeters;
  }
}
