import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'location_service.dart';
import 'device_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check-In: Membuat dokumen attendance baru (PRD Bab 47, BR-09, BR-10)
  /// Schema nested: { checkIn: { timestamp(server), lat, lng, accuracy, distance, deviceId } }
  static Future<String> checkIn({
    required LocationResult location,
    required DeviceResult device,
    required String branchId,
    required String shiftId,
    required double distanceMeters,
    required int lateMinutes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Pegawai belum login');

    final now = DateTime.now();
    final workDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final attendanceRef = _db.collection('attendance').doc();

    await attendanceRef.set({
      'employeeId': user.uid,
      'branchId': branchId,
      'shiftId': shiftId,
      'workDate': workDate,
      'checkIn': {
        'timestamp': FieldValue.serverTimestamp(), // BR-09
        'latitude': location.position?.latitude,
        'longitude': location.position?.longitude,
        'accuracy': location.position?.accuracy,
        'distanceMeters': distanceMeters,
        'deviceId': device.deviceId,
      },
      'checkOut': null,
      'status': lateMinutes > 0 ? 'late' : 'present',
      'lateMinutes': lateMinutes,
      'earlyCheckoutMinutes': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return attendanceRef.id;
  }

  /// Check-Out: Update dokumen yang sama (BR-11, BR-15, PRD Bab 15)
  static Future<void> checkOut({
    required LocationResult location,
    required DeviceResult device,
    required String attendanceId,
    required double distanceMeters,
    required int earlyCheckoutMinutes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Pegawai belum login');

    await _db.collection('attendance').doc(attendanceId).update({
      'checkOut': {
        'timestamp': FieldValue.serverTimestamp(), // BR-09
        'latitude': location.position?.latitude,
        'longitude': location.position?.longitude,
        'accuracy': location.position?.accuracy,
        'distanceMeters': distanceMeters,
        'deviceId': device.deviceId,
      },
      'earlyCheckoutMinutes': earlyCheckoutMinutes,
      'status': earlyCheckoutMinutes > 0 ? 'early_checkout' : 'present',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Security Event IMMUTABLE (BR-06, BR-07, BR-22) — PRD Bab 51
  static Future<void> logSecurityEvent({
    required String type, // mock_location | emulator_detected | invalid_device | ...
    required String branchId,
    required String deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('security_events').add({
      'employeeId': user.uid,
      'branchId': branchId,
      'deviceId': deviceId,
      'type': type,
      'action': 'attendance_blocked',
      'metadata': metadata ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Koreksi Absensi (BR-21) — PRD Bab 48
  static Future<void> submitCorrection({
    required String attendanceId,
    required String branchId,
    required String type, // missing_check_in | missing_check_out | wrong_data
    required String reason,
    String? requestedCheckIn,
    String? requestedCheckOut,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Pegawai belum login');

    await _db.collection('correction_requests').add({
      'employeeId': user.uid,
      'attendanceId': attendanceId,
      'branchId': branchId,
      'type': type,
      'requestedCheckIn': requestedCheckIn,
      'requestedCheckOut': requestedCheckOut,
      'reason': reason,
      'status': 'pending',
      'reviewedBy': null,
      'reviewedAt': null,
      'reviewNote': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Leave Request Izin/Sakit/Cuti/Dinas (BR-17~20) — PRD Bab 49
  static Future<void> submitLeaveRequest({
    required String branchId,
    required String type, // permission | sick | leave | business_trip
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Pegawai belum login');

    await _db.collection('leave_requests').add({
      'employeeId': user.uid,
      'branchId': branchId,
      'type': type,
      'startDate': startDate,
      'endDate': endDate,
      'reason': reason,
      'attachmentUrl': attachmentUrl,
      'status': 'pending',
      'reviewedBy': null,
      'reviewedAt': null,
      'reviewNote': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Registrasi Device (BR-08) — PRD Bab 50
  static Future<void> registerDevice({
    required DeviceResult device,
    required String appVersion,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('devices').doc(device.deviceId).set({
      'employeeId': user.uid,
      'uid': user.uid,
      'deviceId': device.deviceId,
      'manufacturer': device.deviceName?.split(' ').first ?? 'Unknown',
      'model': device.deviceName ?? 'Unknown',
      'androidVersion': 'Unknown',
      'appVersion': appVersion,
      'isActive': true,
      'registeredAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
