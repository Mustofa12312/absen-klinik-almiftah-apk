import 'package:firebase_auth/firebase_auth.dart';

/// Mengubah pesan error teknis menjadi Bahasa Indonesia yang mudah dipahami.
String getIndonesianErrorMessage(dynamic error) {
  if (error == null) return 'Terjadi kesalahan sistem.';

  // Tangani FirebaseAuthException
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
        return 'Akun pegawai tidak ditemukan. Periksa nomor HP atau email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Nomor HP/Email atau kata sandi salah. Silakan coba lagi.';
      case 'invalid-email':
        return 'Format email atau nomor HP tidak valid.';
      case 'user-disabled':
        return 'Akun pegawai ini telah dinonaktifkan oleh administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat lagi.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      case 'requires-recent-login':
        return 'Sesi login telah kedaluwarsa. Silakan keluar dan login kembali.';
      default:
        return error.message ?? 'Gagal masuk. Periksa data login Anda.';
    }
  }

  // Tangani FirebaseException (termasuk Firestore)
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Akses ditolak: Anda tidak memiliki izin untuk melakukan tindakan ini.';
      case 'unavailable':
        return 'Layanan server sedang tidak tersedia. Periksa koneksi internet Anda.';
      case 'deadline-exceeded':
        return 'Waktu permintaan habis (timeout). Silakan coba lagi.';
      case 'not-found':
        return 'Data yang diminta tidak ditemukan di sistem.';
      case 'already-exists':
        return 'Data sudah terdaftar di sistem.';
      default:
        return 'Kendala server (${error.code}): ${error.message ?? 'Silakan coba lagi.'}';
    }
  }

  final s = error.toString();
  if (s.contains('permission-denied') || s.contains('insufficient permissions') || s.contains('Missing or insufficient permissions')) {
    return 'Akses ditolak: Izin akun Anda tidak mencukupi.';
  }
  if (s.contains('SocketException') || s.contains('Failed host lookup') || s.contains('network') || s.contains('TimeoutException')) {
    return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
  }

  return s.replaceFirst('Exception: ', '');
}
