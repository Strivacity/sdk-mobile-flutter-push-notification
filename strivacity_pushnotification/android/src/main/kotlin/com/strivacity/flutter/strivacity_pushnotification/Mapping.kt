package com.strivacity.flutter.strivacity_pushnotification

import com.strivacity.android.pushnotification.internal.PluginBridgeApi
import com.strivacity.android.pushnotification.internal.serializeChallenge
import com.strivacity.android.pushnotification.model.Challenge
import com.strivacity.android.pushnotification.model.DeviceTokenType
import com.strivacity.android.pushnotification.model.Enrollment
import com.strivacity.android.pushnotification.model.EnrollmentGrant
import com.strivacity.android.pushnotification.model.ResolutionResult

internal fun PlatformDeviceTokenType.toSdk(): DeviceTokenType =
    when (this) {
        PlatformDeviceTokenType.APNS -> {
            throw FlutterError(UNEXPECTED_CODE, "APNs tokens are not supported on Android.", null)
        }

        PlatformDeviceTokenType.FCM_TOKEN -> {
            DeviceTokenType.FCM_TOKEN
        }

        PlatformDeviceTokenType.FCM_FID -> {
            DeviceTokenType.FCM_FID
        }
    }

internal fun ResolutionResult.toPlatform(): PlatformResolutionResult =
    when (this) {
        ResolutionResult.OK -> PlatformResolutionResult.OK
        ResolutionResult.NOT_OK -> PlatformResolutionResult.NOT_OK
    }

internal fun PlatformEnrollmentGrant.toSdk(): EnrollmentGrant =
    EnrollmentGrant(
        issuer = issuer,
        oneTimeToken = oneTimeToken,
        accountId = accountId,
        displayUserName = displayUserName,
    )

internal fun EnrollmentGrant.toPlatform(): PlatformEnrollmentGrant =
    PlatformEnrollmentGrant(
        issuer = issuer,
        oneTimeToken = oneTimeToken,
        accountId = accountId,
        displayUserName = displayUserName,
    )

internal fun Enrollment.toPlatform(): PlatformEnrollment =
    PlatformEnrollment(
        issuer = issuer,
        accountId = accountId,
        keyId = keyId,
        userName = userName,
        deviceName = deviceName,
    )

@OptIn(PluginBridgeApi::class)
internal fun Challenge.toPlatform(): PlatformChallenge =
    PlatformChallenge(
        type =
            when (this) {
                is Challenge.Simple -> PlatformChallengeType.SIMPLE
                is Challenge.ContextMatching -> PlatformChallengeType.CONTEXT_MATCHING
            },
        challengeId = challengeId,
        issuer = issuer,
        accountId = accountId,
        expiresAt = expiresAt,
        metadata = metadata,
        serialized = serializeChallenge(this),
        options = (this as? Challenge.ContextMatching)?.options,
    )

/** The string-valued entries of a push payload, the only ones the SDK reads. */
internal fun Map<String, Any?>.stringEntries(): Map<String, String> =
    entries
        .mapNotNull { (key, value) -> (value as? String)?.let { key to it } }
        .toMap()
