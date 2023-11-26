// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        return macos;
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
    apiKey: 'AIzaSyCgZ7bWwjvICe8TtNKleGigOtqXpHVDkVA',
    appId: '1:305121326743:web:7edf357dbf5f388dc4dbd2',
    messagingSenderId: '305121326743',
    projectId: 'learning-app-c8a25',
    authDomain: 'learning-app-c8a25.firebaseapp.com',
    storageBucket: 'learning-app-c8a25.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAs4rQpkqfjyaXQdG6QLK0eHpmW5njzCYw',
    appId: '1:305121326743:android:79542dfb82429a25c4dbd2',
    messagingSenderId: '305121326743',
    projectId: 'learning-app-c8a25',
    storageBucket: 'learning-app-c8a25.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAE37qZuVyeENePxQurg8HZOWBf4rOLy_g',
    appId: '1:305121326743:ios:aec8590551e994b6c4dbd2',
    messagingSenderId: '305121326743',
    projectId: 'learning-app-c8a25',
    storageBucket: 'learning-app-c8a25.appspot.com',
    iosBundleId: 'com.example.learningApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAE37qZuVyeENePxQurg8HZOWBf4rOLy_g',
    appId: '1:305121326743:ios:96b42ef3252c7ed3c4dbd2',
    messagingSenderId: '305121326743',
    projectId: 'learning-app-c8a25',
    storageBucket: 'learning-app-c8a25.appspot.com',
    iosBundleId: 'com.example.learningApp.RunnerTests',
  );
}
