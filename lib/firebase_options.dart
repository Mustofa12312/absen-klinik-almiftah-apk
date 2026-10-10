import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAKPNHGfP9YtT8Z9I-1tKXzt7QCoMRtRD0',
    appId: '1:664022797316:web:eb378574e2469f8b6c7951',
    messagingSenderId: '664022797316',
    projectId: 'klinik-almiftah',
    authDomain: 'klinik-almiftah.firebaseapp.com',
    storageBucket: 'klinik-almiftah.firebasestorage.app',
    measurementId: 'G-VX7WG5S3M6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAKPNHGfP9YtT8Z9I-1tKXzt7QCoMRtRD0',
    appId: '1:664022797316:web:eb378574e2469f8b6c7951', // Use Web App ID since Android App ID is unknown
    messagingSenderId: '664022797316',
    projectId: 'klinik-almiftah',
    storageBucket: 'klinik-almiftah.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAKPNHGfP9YtT8Z9I-1tKXzt7QCoMRtRD0',
    appId: '1:664022797316:ios:a1b2c3d4e5f6g7h8i9j0k1',
    messagingSenderId: '664022797316',
    projectId: 'klinik-almiftah',
    storageBucket: 'klinik-almiftah.firebasestorage.app',
    iosBundleId: 'com.klinikalmiftah.absen.employeeApp',
  );
}
