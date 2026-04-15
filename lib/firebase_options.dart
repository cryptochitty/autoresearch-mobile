import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAdMcjXTwZHvB7G5wm0sgKs6Lro1Dlggnc',
    appId: '1:656992151459:android:2ee5476e70bf64d73c5c16',
    messagingSenderId: '656992151459',
    projectId: 'autoresearch-caf86',
    storageBucket: 'autoresearch-caf86.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '656992151459',
    projectId: 'autoresearch-caf86',
    storageBucket: 'autoresearch-caf86.firebasestorage.app',
    iosBundleId: 'com.cryptochitty.autoresearch',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBM9cRA4iv2JgAllCo-THqRyYb4w0XQVb8',
    appId: '1:656992151459:web:1711532cf09e691b3c5c16',
    messagingSenderId: '656992151459',
    projectId: 'autoresearch-caf86',
    storageBucket: 'autoresearch-caf86.firebasestorage.app',
    authDomain: 'autoresearch-caf86.firebaseapp.com',
  );
}
