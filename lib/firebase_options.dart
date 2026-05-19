import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Placeholder FlutterFire configuration.
///
/// Run `flutterfire configure` in this repo and replace this file with the
/// generated version before running against a real Firebase project.
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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD3Dr2CyltObbE7t-lAHecducu_nuN2Y_A',
    appId: '1:144801441254:web:3126a24ff18780b4a7e227',
    messagingSenderId: '144801441254',
    projectId: 'moni-624c6',
    authDomain: 'moni-624c6.firebaseapp.com',
    storageBucket: 'moni-624c6.firebasestorage.app',
    measurementId: 'G-33Z654CV60',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbZL22y_Vv4NhyiDrkfgB1YJt9qWYM3Mc',
    appId: '1:144801441254:android:fc0e599184c80b57a7e227',
    messagingSenderId: '144801441254',
    projectId: 'moni-624c6',
    storageBucket: 'moni-624c6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCfVQsobt1X-D7Cy6YSLyNKgPKPd-LbgjU',
    appId: '1:144801441254:ios:3fa1c11d18ae0404a7e227',
    messagingSenderId: '144801441254',
    projectId: 'moni-624c6',
    storageBucket: 'moni-624c6.firebasestorage.app',
    iosBundleId: 'com.example.moni',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    projectId: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    iosBundleId: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    projectId: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    projectId: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE_CONFIG',
  );
}