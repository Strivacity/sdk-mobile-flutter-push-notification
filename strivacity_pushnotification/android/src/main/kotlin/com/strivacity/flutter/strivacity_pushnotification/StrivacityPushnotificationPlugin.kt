package com.strivacity.flutter.strivacity_pushnotification

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import com.strivacity.android.pushnotification.PushNotification
import com.strivacity.android.pushnotification.model.EnrollmentGrant
import com.strivacity.android.pushnotification.storage.DefaultPushNotificationStorage
import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Connects the Dart push notification API to the native Android SDK. */
class StrivacityPushnotificationPlugin : FlutterPlugin {
    @SuppressLint("UseKtx")
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext
        val host =
            PushNotificationHost(
                sdkFactory = { allowSoftwareBackedKeys -> createSdk(context, allowSoftwareBackedKeys) },
                parseGrant = { url -> EnrollmentGrant.parse(Uri.parse(url)) },
            )
        PushNotificationPlatformApi.setUp(flutterPluginBinding.binaryMessenger, host)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PushNotificationPlatformApi.setUp(binding.binaryMessenger, null)
    }

    private fun createSdk(
        context: Context,
        allowSoftwareBackedKeys: Boolean,
    ): PushNotification =
        PushNotification(
            DefaultPushNotificationStorage(
                context.getSharedPreferences(ENROLLMENTS_PREFERENCES, Context.MODE_PRIVATE),
                allowSoftwareBackedKeys,
            ),
        )

    private companion object {
        const val ENROLLMENTS_PREFERENCES = "com.strivacity.pushnotification.enrollments"
    }
}
