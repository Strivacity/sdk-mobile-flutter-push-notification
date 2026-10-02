import 'package:firebase_core/firebase_core.dart';

import '../../config.dart';

/// Starts Firebase.
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: appConfiguration.firebaseOptions);
}
