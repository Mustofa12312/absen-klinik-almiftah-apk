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
          return DeviceResult(isValid: false, message: 'Aplikasi tidak dapat berjalan di Emulator.');
        }

        // Generate unique device identifier (Kombinasi model dan ID)
        deviceId = androidInfo.id;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
        
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        
        if (!iosInfo.isPhysicalDevice) {
          return DeviceResult(isValid: false, message: 'Aplikasi tidak dapat berjalan di Simulator.');
        }

        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_id';
        deviceName = iosInfo.name;

      } else {
        return DeviceResult(isValid: false, message: 'Platform tidak didukung.');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final deviceDoc = await FirebaseFirestore.instance.collection('devices').doc(deviceId).get();
        if (deviceDoc.exists) {
          final data = deviceDoc.data()!;
          if (data['employeeId'] != user.uid) {
            return DeviceResult(isValid: false, message: 'Perangkat ini terdaftar untuk akun lain.');
          }
          if (data['isActive'] == false) {
            return DeviceResult(isValid: false, message: 'Perangkat ini telah dinonaktifkan oleh Admin.');
          }
        } else {
          return DeviceResult(isValid: false, message: 'Perangkat belum terdaftar. Hubungi Admin.');
        }
      }

      return DeviceResult(
        isValid: true, 
        message: 'Device aman', 
        deviceId: deviceId, 
        deviceName: deviceName
      );
    } catch (e) {
      return DeviceResult(isValid: false, message: 'Gagal membaca identitas perangkat.');
    }
  }
}
