import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceResult {
  final bool isValid;
  final String message;
  final String? deviceId;
  final String? deviceName;

  DeviceResult({required this.isValid, required this.message, this.deviceId, this.deviceName});
}

class DeviceService {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  /// Mendapatkan Device ID yang unik (BR-08 Device Binding) dan mendeteksi Emulator (BR-07)
  static Future<DeviceResult> checkDeviceIntegrity() async {
    try {
      String deviceId = '';
      String deviceName = '';

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        
        // Deteksi Emulator Android dasar
        if (!androidInfo.isPhysicalDevice) {
          return DeviceResult(isValid: false, message: 'Aplikasi tidak dapat berjalan di Emulator demi keamanan absensi.');
        }

        // Generate unique device identifier (Kombinasi model dan ID)
        deviceId = androidInfo.id;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
        
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        
        if (!iosInfo.isPhysicalDevice) {
          return DeviceResult(isValid: false, message: 'Aplikasi tidak dapat berjalan di Simulator demi keamanan absensi.');
        }

        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_id';
        deviceName = iosInfo.name;

      } else {
        return DeviceResult(isValid: false, message: 'Platform tidak didukung.');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Cek apakah akun pegawai sudah terikat pada perangkat aktif lain (BR-08)
        final existingUserDevices = await FirebaseFirestore.instance
            .collection('devices')
            .where('employeeId', isEqualTo: user.uid)
            .where('isActive', isEqualTo: true)
            .get();

        for (final doc in existingUserDevices.docs) {
          if (doc.id != deviceId) {
            final activeModel = (doc.data()['model'] as String?) ?? 'Perangkat Lain';
            return DeviceResult(
              isValid: false,
              message: 'Akun Anda sudah terikat pada perangkat lain ($activeModel). Silakan hubungi Super Admin untuk reset perangkat (BR-08).',
            );
          }
        }

        final deviceDoc = await FirebaseFirestore.instance.collection('devices').doc(deviceId).get();
        if (deviceDoc.exists) {
          final data = deviceDoc.data()!;
          if (data['isActive'] == true) {
            if (data['employeeId'] != user.uid) {
              return DeviceResult(isValid: false, message: 'Perangkat ini terdaftar untuk akun lain.');
            }
            // Update last seen
            try {
              await deviceDoc.reference.update({
                'lastSeenAt': FieldValue.serverTimestamp(),
              });
            } catch (_) {}

            return DeviceResult(
              isValid: true, 
              message: 'Device aman', 
              deviceId: deviceId, 
              deviceName: deviceName
            );
          }
          // Jika isActive == false, berarti sudah di-reset admin.
          // Aplikasi akan mendaftarkan ulang perangkat ini di blok bawah.
        }

        // Device belum terdaftar atau sudah di-reset: Auto-register (Device Binding) sesuai PRD Bab 50, BR-08
        await FirebaseFirestore.instance.collection('devices').doc(deviceId).set({
          'employeeId': user.uid,
          'uid': user.uid,
          'deviceId': deviceId,
          'manufacturer': deviceName.split(' ').first,
          'model': deviceName,
          'androidVersion': Platform.isAndroid ? 'Android' : 'iOS',
          'appVersion': '1.0.0',
          'isActive': true,
          'registeredAt': FieldValue.serverTimestamp(),
          'lastSeenAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Sinkronisasi status deviceBound ke dokumen pegawai
        try {
          await FirebaseFirestore.instance.collection('employees').doc(user.uid).update({
            'deviceBound': true,
            'deviceId': deviceId,
            'deviceName': deviceName,
          });
        } catch (_) {}
      }

      return DeviceResult(
        isValid: true, 
        message: 'Perangkat terverifikasi aman', 
        deviceId: deviceId, 
        deviceName: deviceName
      );
    } catch (e) {
      return DeviceResult(isValid: false, message: 'Gagal memverifikasi identitas perangkat: $e');
    }
  }
}
