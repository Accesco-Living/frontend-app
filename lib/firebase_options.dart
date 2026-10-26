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
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: 'AIzaSyBon3Q156u3xNWW2nZw8Z6RxWbfNQezIFM'),
    appId: '1:113387637108:web:1c4b181334431c00190421',
    messagingSenderId: '113387637108',
    projectId: 'accesco-db',
    authDomain: 'accesco-db.firebaseapp.com',
    storageBucket: 'accesco-db.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: 'AIzaSyAOIpjtfg8NDJD9f5-ADI6GgJj-0BVnzXU'),
    appId: '1:113387637108:android:0f0b628bb21b0002190421',
    messagingSenderId: '113387637108',
    projectId: 'accesco-db',
    storageBucket: 'accesco-db.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: 'AIzaSyBon3Q156u3xNWW2nZw8Z6RxWbfNQezIFM'),
    appId: '1:113387637108:ios:0000000000000000000000',
    messagingSenderId: '113387637108',
    projectId: 'accesco-db',
    storageBucket: 'accesco-db.firebasestorage.app',
    iosBundleId: 'com.accesco.living',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: 'AIzaSyBon3Q156u3xNWW2nZw8Z6RxWbfNQezIFM'),
    appId: '1:113387637108:ios:0000000000000000000000',
    messagingSenderId: '113387637108',
    projectId: 'accesco-db',
    storageBucket: 'accesco-db.firebasestorage.app',
    iosBundleId: 'com.accesco.living',
  );
}
