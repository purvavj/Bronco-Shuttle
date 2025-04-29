import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyDqetxGiWiMX4k7cFKqmftj25i7r18h6IY',
    appId: '1:23037718376:web:9ae2752a1f2ffcc99fb0dd',
    messagingSenderId: '23037718376',
    projectId: 'broncoshuttle-ed6a6',
    authDomain: 'broncoshuttle-ed6a6.firebaseapp.com',
    databaseURL: 'https://broncoshuttle-ed6a6-default-rtdb.firebaseio.com',
    storageBucket: 'broncoshuttle-ed6a6.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABQpX03M62IXvUMomi89e8Fef-YmyUDdE',
    appId: '1:23037718376:android:358af2eea27e69e89fb0dd',
    messagingSenderId: '23037718376',
    projectId: 'broncoshuttle-ed6a6',
    databaseURL: 'https://broncoshuttle-ed6a6-default-rtdb.firebaseio.com',
    storageBucket: 'broncoshuttle-ed6a6.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBoMGqCuCAa1CiD2dnv7NONYKABp5tEoEM',
    appId: '1:23037718376:ios:cb6423afaa9b837c9fb0dd',
    messagingSenderId: '23037718376',
    projectId: 'broncoshuttle-ed6a6',
    databaseURL: 'https://broncoshuttle-ed6a6-default-rtdb.firebaseio.com',
    storageBucket: 'broncoshuttle-ed6a6.appspot.com',
    iosBundleId: 'com.example.broncoShuttle',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBoMGqCuCAa1CiD2dnv7NONYKABp5tEoEM',
    appId: '1:23037718376:ios:cb6423afaa9b837c9fb0dd',
    messagingSenderId: '23037718376',
    projectId: 'broncoshuttle-ed6a6',
    databaseURL: 'https://broncoshuttle-ed6a6-default-rtdb.firebaseio.com',
    storageBucket: 'broncoshuttle-ed6a6.appspot.com',
    iosBundleId: 'com.example.broncoShuttle',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDqetxGiWiMX4k7cFKqmftj25i7r18h6IY',
    appId: '1:23037718376:web:1a57b1f1a88bb9f09fb0dd',
    messagingSenderId: '23037718376',
    projectId: 'broncoshuttle-ed6a6',
    authDomain: 'broncoshuttle-ed6a6.firebaseapp.com',
    databaseURL: 'https://broncoshuttle-ed6a6-default-rtdb.firebaseio.com',
    storageBucket: 'broncoshuttle-ed6a6.appspot.com',
  );
}
