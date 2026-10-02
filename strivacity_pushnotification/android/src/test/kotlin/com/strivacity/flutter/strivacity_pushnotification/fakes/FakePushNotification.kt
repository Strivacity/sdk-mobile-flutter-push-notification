package com.strivacity.flutter.strivacity_pushnotification.fakes

import com.strivacity.android.pushnotification.PushNotificationInterface
import com.strivacity.android.pushnotification.internal.PluginBridgeApi
import com.strivacity.android.pushnotification.internal.deserializeChallenge
import com.strivacity.android.pushnotification.model.Challenge
import com.strivacity.android.pushnotification.model.ChallengeResolution
import com.strivacity.android.pushnotification.model.DeviceTokenType
import com.strivacity.android.pushnotification.model.Enrollment
import com.strivacity.android.pushnotification.model.EnrollmentGrant
import com.strivacity.android.pushnotification.model.ResolutionResult

/** A [PushNotificationInterface] that records its calls and answers with configured values. */
@OptIn(PluginBridgeApi::class)
internal class FakePushNotification : PushNotificationInterface {
    /** The calls made so far, as the method name and the arguments passed. */
    val calls = mutableListOf<Pair<String, List<Any?>>>()

    /** Thrown by the next call, then cleared. */
    var failureOnNextCall: Exception? = null

    var enrollment = Enrollment("https://issuer.example.com", "account-1", "key-1", "Ada", "Pixel")
    var enrollments = listOf<Enrollment>()
    var hasKey = true
    var canHandle = true
    var challenge: Challenge = deserializeChallenge(SIMPLE_SNAPSHOT)
    var resolutionResult = ResolutionResult.OK

    fun callsTo(method: String): List<List<Any?>> = calls.filter { it.first == method }.map { it.second }

    private fun <T> record(
        method: String,
        arguments: List<Any?>,
        result: T,
    ): T {
        calls += method to arguments
        failureOnNextCall?.let {
            failureOnNextCall = null
            throw it
        }
        return result
    }

    override suspend fun enrollDevice(
        grant: EnrollmentGrant,
        deviceToken: String,
        deviceTokenType: DeviceTokenType,
        deviceName: String,
    ): Enrollment = record("enrollDevice", listOf(grant, deviceToken, deviceTokenType, deviceName), enrollment)

    override suspend fun unenrollDevice(
        issuer: String,
        accountId: String,
    ) = record("unenrollDevice", listOf(issuer, accountId), Unit)

    override suspend fun hasEnrollment(
        issuer: String,
        accountId: String,
    ): Boolean = record("hasEnrollment", listOf(issuer, accountId), hasKey)

    override suspend fun listEnrollments(): List<Enrollment> = record("listEnrollments", listOf(), enrollments)

    override suspend fun updateDeviceToken(
        issuer: String,
        accountId: String,
        deviceToken: String,
        deviceTokenType: DeviceTokenType,
    ) = record("updateDeviceToken", listOf(issuer, accountId, deviceToken, deviceTokenType), Unit)

    override suspend fun canHandleMessage(messageData: Map<String, String>?): Boolean =
        record("canHandleMessage", listOf(messageData), canHandle)

    override suspend fun handleMessage(messageData: Map<String, String>?): Challenge =
        record("handleMessage", listOf(messageData), challenge)

    override suspend fun resolveChallenge(resolution: ChallengeResolution): ResolutionResult =
        record("resolveChallenge", listOf(resolution), resolutionResult)

    companion object {
        /** A snapshot the SDK's challenge codec reads as a simple challenge. */
        const val SIMPLE_SNAPSHOT =
            """{"version":1,"type":"simple","challengeId":"challenge-1","challengeValue":"challenge-value",""" +
                """"issuer":"https://issuer.example.com","accountId":"account-1",""" +
                """"expiresAt":"2026-10-01T14:30:00Z","metadata":{"place":"New York","device":null}}"""

        /** A snapshot the SDK's challenge codec reads as a context-matching challenge. */
        const val CONTEXT_MATCHING_SNAPSHOT =
            """{"version":1,"type":"contextMatching","challengeId":"challenge-2",""" +
                """"challengeValue":"challenge-value","issuer":"https://issuer.example.com",""" +
                """"accountId":"account-1","expiresAt":"2026-10-01T14:30:00Z","metadata":{},""" +
                """"options":["12","26","84"]}"""
    }
}
