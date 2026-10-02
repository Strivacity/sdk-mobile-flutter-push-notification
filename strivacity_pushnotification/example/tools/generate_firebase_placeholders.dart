/// Writes placeholder Firebase configuration for the example app, so it analyzes and builds
/// without a Firebase project. Meant for CI. The app cannot connect to Firebase with these values.
///
/// Files that already exist are left alone, so running this on a machine set up with
/// `flutterfire configure` changes nothing.
///
/// Usage, from the example directory: `dart run tools/generate_firebase_placeholders.dart`
library;

import 'dart:io';

const _androidPackage = 'com.strivacity.flutter.strivacity_pushnotification_example';
const _iosBundleId = 'com.strivacity.flutter.strivacityPushnotificationExample';

void main(List<String> args) {
  final exampleDirectory = args.isEmpty ? File.fromUri(Platform.script).parent.parent.path : args.first;

  _writeIfMissing(exampleDirectory, 'lib/firebase_options.dart', _firebaseOptions);
  _writeIfMissing(exampleDirectory, 'android/app/google-services.json', _googleServicesJson);
  _writeIfMissing(exampleDirectory, 'ios/Runner/GoogleService-Info.plist', _googleServiceInfoPlist);
}

void _writeIfMissing(String exampleDirectory, String path, String contents) {
  final file = File('$exampleDirectory/$path');
  if (file.existsSync()) {
    stdout.writeln('Keeping existing $path');
    return;
  }
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
  stdout.writeln('Created placeholder $path');
}

const _firebaseOptions =
    '''
// Placeholder Firebase options for builds without a Firebase project.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Placeholder Firebase options exist for Android and iOS only.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'placeholder-project',
    storageBucket: 'placeholder-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'placeholder-project',
    storageBucket: 'placeholder-project.appspot.com',
    iosBundleId: '$_iosBundleId',
  );
}
''';

const _googleServicesJson =
    '''
{
  "project_info": {
    "project_number": "000000000000",
    "project_id": "placeholder-project",
    "storage_bucket": "placeholder-project.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:000000000000:android:0000000000000000",
        "android_client_info": {
          "package_name": "$_androidPackage"
        }
      },
      "oauth_client": [],
      "api_key": [{ "current_key": "placeholder-api-key" }],
      "services": {
        "appinvite_service": { "other_platform_oauth_client": [] }
      }
    }
  ],
  "configuration_version": "1"
}
''';

const _googleServiceInfoPlist =
    '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>API_KEY</key>
  <string>placeholder-api-key</string>
  <key>GCM_SENDER_ID</key>
  <string>000000000000</string>
  <key>PLIST_VERSION</key>
  <string>1</string>
  <key>BUNDLE_ID</key>
  <string>$_iosBundleId</string>
  <key>PROJECT_ID</key>
  <string>placeholder-project</string>
  <key>STORAGE_BUCKET</key>
  <string>placeholder-project.appspot.com</string>
  <key>IS_ADS_ENABLED</key>
  <false/>
  <key>IS_ANALYTICS_ENABLED</key>
  <false/>
  <key>IS_APPINVITE_ENABLED</key>
  <false/>
  <key>IS_GCM_ENABLED</key>
  <true/>
  <key>IS_SIGNIN_ENABLED</key>
  <false/>
  <key>GOOGLE_APP_ID</key>
  <string>1:000000000000:ios:0000000000000000</string>
</dict>
</plist>
''';
