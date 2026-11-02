package com.strivacity.flutter.strivacity_pushnotification.support

import com.strivacity.android.pushnotification.model.EnrollmentGrant
import com.strivacity.flutter.strivacity_pushnotification.PlatformCreateOptions
import com.strivacity.flutter.strivacity_pushnotification.PushNotificationHost
import com.strivacity.flutter.strivacity_pushnotification.fakes.FakePushNotification

/** A [PushNotificationHost] wired to a [FakePushNotification]. */
internal class HostFixture {
    val sdk = FakePushNotification()
    val factoryCalls = mutableListOf<Boolean>()
    val parsedUrls = mutableListOf<String>()
    var parsedGrant = EnrollmentGrant("https://issuer.example.com", "one-time-token", "account-1", "Ada")
    var parseFailure: Exception? = null

    val host =
        PushNotificationHost(
            sdkFactory = { allowSoftwareBackedKeys ->
                factoryCalls += allowSoftwareBackedKeys
                sdk
            },
            parseGrant = { url ->
                parsedUrls += url
                parseFailure?.let { throw it }
                parsedGrant
            },
        )

    /** The host after Dart has created the SDK. */
    suspend fun created(allowSoftwareBackedKeys: Boolean = false): PushNotificationHost {
        host.create(PlatformCreateOptions(allowSoftwareBackedKeys))
        return host
    }
}
