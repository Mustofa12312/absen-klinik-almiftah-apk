import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

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
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        
        // Deteksi Emulator Android dasar
        if (!androidInfo.isPhysicalDevice) {
          return DeviceResult(isValid: false, message: 'Aplikasi tidak dapat berjalan di Emulator.');
        }

        // Generate unique device identifier (Kombinasi model dan ID)
        String deviceId = androidInfo.id;
        String deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
        
        return DeviceResult(
          isValid: true, 
          message: 'Device aman', 
          deviceId: deviceId, 
          deviceName: deviceName
        );
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        
        if (!iosInfo.isPhysicalDevice) {
          return DeviceResult(isValid: false, message: 'Aplikasi tidak dapat berjalan di Simulator.');
        }

        String deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_id';
        String deviceName = iosInfo.name;

        return DeviceResult(
          isValid: true, 
          message: 'Device aman', 
          deviceId: deviceId, 
          deviceName: deviceName
        );
      }
      
      return DeviceResult(isValid: false, message: 'Platform tidak didukung.');
    } catch (e) {
      return DeviceResult(isValid: false, message: 'Gagal membaca identitas perangkat.');
    }
  }
}
