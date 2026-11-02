import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import 'fakes/fake_platform_api.dart';

/// Exercises `PushNotification.getInstance`.
void main() {
  late FakePlatformApi api;

  setUp(() {
    PushNotification.resetInstance();
    api = FakePlatformApi();
  });

  test(
    'builds the native SDK without software-backed keys by default',
    () async {
      await PushNotification.getInstanceWith(api);

      expect(api.callsTo('create'), [
        [false],
      ]);
    },
  );

  test(
    'builds the native SDK with the requested software-backed key setting',
    () async {
      await PushNotification.getInstanceWith(
        api,
        allowSoftwareBackedKeys: true,
      );

      expect(api.callsTo('create'), [
        [true],
      ]);
    },
  );

  test('returns the same instance on repeated calls', () async {
    final first = await PushNotification.getInstanceWith(api);
    final second = await PushNotification.getInstanceWith(api);

    expect(second, same(first));
  });

  test('builds the native SDK once across repeated calls', () async {
    await PushNotification.getInstanceWith(api);
    await PushNotification.getInstanceWith(api);

    expect(api.callsTo('create'), hasLength(1));
  });

  test('builds the native SDK once across concurrent calls', () async {
    await Future.wait([
      PushNotification.getInstanceWith(api),
      PushNotification.getInstanceWith(api),
    ]);

    expect(api.callsTo('create'), hasLength(1));
  });

  test(
    'throws a StateError when a repeated call asks for different options',
    () async {
      await PushNotification.getInstanceWith(api);

      await expectLater(
        PushNotification.getInstanceWith(api, allowSoftwareBackedKeys: true),
        throwsStateError,
      );
    },
  );

  test(
    'throws a StateError when the native SDK reports a configuration conflict',
    () async {
      api.failureOnNextCall = PlatformException(code: 'configuration_conflict');

      await expectLater(
        PushNotification.getInstanceWith(api),
        throwsStateError,
      );
    },
  );

  test('reports a failed creation as a PushNotificationException', () async {
    api.failureOnNextCall = PlatformException(code: 'storage_failure');

    await expectLater(
      PushNotification.getInstanceWith(api),
      throwsA(isA<StorageFailureException>()),
    );
  });

  test('allows another attempt after a failed creation', () async {
    api.failureOnNextCall = PlatformException(code: 'storage_failure');
    await expectLater(
      PushNotification.getInstanceWith(api),
      throwsA(isA<PushNotificationException>()),
    );

    await PushNotification.getInstanceWith(api);

    expect(api.callsTo('create'), hasLength(2));
  });
}
