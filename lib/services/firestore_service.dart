import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'location_service.dart';
import 'device_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mencatat absensi masuk ke Firestore
  static Future<void> checkIn({
    required LocationResult location,
    required DeviceResult device,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Pegawai belum login');

    final attendanceRef = _db.collection('attendances').doc();

    await attendanceRef.set({
      'employeeId': user.uid,
      'type': 'CHECK_IN',
      // Menggunakan ServerTimestamp agar tidak bisa dimanipulasi dari HP (BR-09)
      'timestamp': FieldValue.serverTimestamp(),
      'location': {
        'latitude': location.position?.latitude,
        'longitude': location.position?.longitude,
        'accuracy': location.position?.accuracy,
      },
      'device': {
        'deviceId': device.deviceId,
        'deviceName': device.deviceName,
      },
      'status': 'present'
    });
  }

  /// Mencatat keamanan / pelanggaran (BR-06 & BR-07)
  static Future<void> logSecurityEvent(String eventType, String details) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('security_events').add({
      'employeeId': user.uid,
      'type': eventType,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'BLOCKED'
    });
  }

  /// Mengirim pengajuan izin/sakit/koreksi (BR-17 s.d BR-21)
  static Future<void> submitRequest({
    required String requestType,
    required String reason,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Pegawai belum login');

    await _db.collection('requests').add({
      'employeeId': user.uid,
      'type': requestType,
      'reason': reason,
      'date': Timestamp.fromDate(date),
      'status': 'PENDING', // Hanya Super Admin yang bisa ubah
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
