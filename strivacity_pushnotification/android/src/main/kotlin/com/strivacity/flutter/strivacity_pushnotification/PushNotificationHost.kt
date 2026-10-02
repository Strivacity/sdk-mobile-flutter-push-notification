package com.strivacity.flutter.strivacity_pushnotification

import com.strivacity.android.pushnotification.PushNotificationInterface
import com.strivacity.android.pushnotification.internal.PluginBridgeApi
import com.strivacity.android.pushnotification.internal.deserializeChallenge
import com.strivacity.android.pushnotification.model.Challenge
import com.strivacity.android.pushnotification.model.ChallengeResolution
import com.strivacity.android.pushnotification.model.EnrollmentGrant
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Answers the calls from Dart with the native push notification SDK.
 *
 * The SDK is built by [sdkFactory] when Dart calls [create]. Callers do not overlap calls for the
 * same issuer and account.
 *
 * The generated Pigeon handlers run every call on the main thread. [configured] is only read and
 * written there, in code that does not suspend between its check and its update, so the state
 * needs no locking. Revisit this if the generated code starts dispatching elsewhere.
 */
@OptIn(PluginBridgeApi::class)
@Suppress("TooManyFunctions")
internal class PushNotificationHost(
    private val sdkFactory: (allowSoftwareBackedKeys: Boolean) -> PushNotificationInterface,
    private val parseGrant: (String) -> EnrollmentGrant,
) : PushNotificationPlatformApi {
    private var configured: Configured? = null

    override suspend fun create(options: PlatformCreateOptions) =
        guarded {
            if (configured == null) {
                // Building the SDK loads the Keystore and the HTTP client, so it stays off the main
                // thread. Another create can finish while this one builds; its SDK is kept.
                val sdk = withContext(Dispatchers.IO) { sdkFactory(options.allowSoftwareBackedKeys) }
                if (configured == null) {
                    configured = Configured(options.allowSoftwareBackedKeys, sdk)
                }
            }

            val current = checkNotNull(configured)
            if (current.allowSoftwareBackedKeys != options.allowSoftwareBackedKeys) {
                throw FlutterError(
                    CONFIGURATION_CONFLICT_CODE,
                    "The SDK is already created with allowSoftwareBackedKeys: " +
                        "${current.allowSoftwareBackedKeys}.",
                    null,
                )
            }
        }

    override suspend fun parseEnrollmentGrant(url: String): PlatformEnrollmentGrant =
        guarded { parseGrant(url).toPlatform() }

    override suspend fun enrollDevice(
        grant: PlatformEnrollmentGrant,
        deviceToken: String,
        deviceTokenType: PlatformDeviceTokenType,
        deviceName: String,
    ): PlatformEnrollment =
        guarded {
            sdk()
                .enrollDevice(grant.toSdk(), deviceToken, deviceTokenType.toSdk(), deviceName)
                .toPlatform()
        }

    override suspend fun unenrollDevice(
        issuer: String,
        accountId: String,
    ) = guarded { sdk().unenrollDevice(issuer, accountId) }

    override suspend fun hasEnrollment(
        issuer: String,
        accountId: String,
    ): Boolean = guarded { sdk().hasEnrollment(issuer, accountId) }

    override suspend fun listEnrollments(): List<PlatformEnrollment> =
        guarded { sdk().listEnrollments().map { it.toPlatform() } }

    override suspend fun updateDeviceToken(
        issuer: String,
        accountId: String,
        deviceToken: String,
        deviceTokenType: PlatformDeviceTokenType,
    ) = guarded { sdk().updateDeviceToken(issuer, accountId, deviceToken, deviceTokenType.toSdk()) }

    override suspend fun canHandleMessage(payload: Map<String, Any?>): Boolean =
        guarded { sdk().canHandleMessage(payload.stringEntries()) }

    override suspend fun handleMessage(payload: Map<String, Any?>): PlatformChallenge =
        guarded { sdk().handleMessage(payload.stringEntries()).toPlatform() }

    override suspend fun resolveChallenge(resolution: PlatformChallengeResolution): PlatformResolutionResult =
        guarded {
            val challenge = deserializeChallenge(resolution.serialized)
            sdk().resolveChallenge(resolutionFor(challenge, resolution)).toPlatform()
        }

    private fun resolutionFor(
        challenge: Challenge,
        resolution: PlatformChallengeResolution,
    ): ChallengeResolution =
        when (resolution.action) {
            PlatformResolutionAction.APPROVE -> {
                (challenge as? Challenge.Simple)?.approve() ?: throw wrongKind("approved")
            }

            PlatformResolutionAction.DENY -> {
                challenge.deny()
            }

            PlatformResolutionAction.SELECT -> {
                val option =
                    resolution.option ?: throw FlutterError(UNEXPECTED_CODE, "A selection needs an option.", null)
                (challenge as? Challenge.ContextMatching)?.select(option) ?: throw wrongKind("answered with an option")
            }
        }

    private fun wrongKind(action: String) = FlutterError(UNEXPECTED_CODE, "This challenge cannot be $action.", null)

    private fun sdk(): PushNotificationInterface =
        configured?.sdk
            ?: throw FlutterError(UNEXPECTED_CODE, "The push notification SDK is not created.", null)

    private class Configured(
        val allowSoftwareBackedKeys: Boolean,
        val sdk: PushNotificationInterface,
    )
}
