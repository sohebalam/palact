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
    apiKey: 'AIzaSyC6wNLGIQgAwjn7msDhfe5FLM7ysY2Jb7c',
    appId: '1:217599382834:web:a1216ed5affa713426332b',
    messagingSenderId: '217599382834',
    projectId: 'palestineaction-33e71',
    authDomain: 'palestineaction-33e71.firebaseapp.com',
    storageBucket: 'palestineaction-33e71.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpXfBnJM_ZKKj8sFDbjY6GEKgtn1FCtRE',
    appId: '1:217599382834:android:e0ee95fdc5a0730e26332b',
    messagingSenderId: '217599382834',
    projectId: 'palestineaction-33e71',
    storageBucket: 'palestineaction-33e71.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDZOWuvRx3AZIKoklTL3lz0DPaQR4im-rY',
    appId: '1:217599382834:ios:abeae5ff899c612f26332b',
    messagingSenderId: '217599382834',
    projectId: 'palestineaction-33e71',
    storageBucket: 'palestineaction-33e71.appspot.com',
    iosClientId: '217599382834-tme6tnv8shrv75odqom4h3vkis4uuqbn.apps.googleusercontent.com',
    iosBundleId: 'com.example.palaction',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDZOWuvRx3AZIKoklTL3lz0DPaQR4im-rY',
    appId: '1:217599382834:ios:67fd6380c8d1efa026332b',
    messagingSenderId: '217599382834',
    projectId: 'palestineaction-33e71',
    storageBucket: 'palestineaction-33e71.appspot.com',
    iosClientId: '217599382834-kmpc0203qv0mhijbqo5i8io3t8qsjem4.apps.googleusercontent.com',
    iosBundleId: 'com.example.palaction.RunnerTests',
  );
}
