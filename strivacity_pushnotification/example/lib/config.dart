import 'firebase_options.dart';

/// App wide configuration
///
/// `iOSPushService` sets which Push Notification service to use on iOS
/// `firebaseOptions` sets which Firebase options used by Firebase when initializing
final appConfiguration = (iOSPushService: IOSPushService.apns, firebaseOptions: DefaultFirebaseOptions.currentPlatform);

enum IOSPushService { apns, fcm }
