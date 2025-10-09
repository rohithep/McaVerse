// ignore_for_file: constant_identifier_names

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web configuration
      return FirebaseOptions(
        apiKey: "AIzaSyBi6RTHzppznxto7f3OojNFwms8CsYzUV4",
        authDomain: "mcaverse-1571e.firebaseapp.com",
        projectId: "mcaverse-1571e",
        storageBucket: "mcaverse-1571e.firebasestorage.app",
        messagingSenderId: "732036970603",
        appId: "1:732036970603:web:eab6ccd44453a12f97992e",
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: "AIzaSyB3O_b2iLWD-yFCGIJ4vSXlL0YF0_o2qSQ",
          appId: "1:732036970603:android:b4bea308896e36da97992e",
          messagingSenderId: "YOUR_ANDROID_SENDER_ID",
          projectId: "732036970603",
          storageBucket: "mcaverse-1571e.firebasestorage.app",
        );
      case TargetPlatform.iOS:
        return FirebaseOptions(
          apiKey: "YOUR_IOS_API_KEY",
          appId: "YOUR_IOS_APP_ID",
          messagingSenderId: "YOUR_IOS_SENDER_ID",
          projectId: "YOUR_PROJECT_ID",
          storageBucket: "YOUR_PROJECT_ID.appspot.com",
          iosBundleId: "YOUR_IOS_BUNDLE_ID",
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
