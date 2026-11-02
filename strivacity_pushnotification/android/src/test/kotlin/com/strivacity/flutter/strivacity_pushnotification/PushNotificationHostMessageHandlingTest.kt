package com.strivacity.flutter.strivacity_pushnotification

import com.strivacity.android.pushnotification.internal.PluginBridgeApi
import com.strivacity.android.pushnotification.internal.deserializeChallenge
import com.strivacity.android.pushnotification.model.ResolutionResult
import com.strivacity.flutter.strivacity_pushnotification.fakes.FakePushNotification
import com.strivacity.flutter.strivacity_pushnotification.support.HostFixture
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

/** Exercises handling a push payload and answering the challenge it carries. */
@OptIn(PluginBridgeApi::class)
internal class PushNotificationHostMessageHandlingTest {
    private val fixture = HostFixture()

    private val payload = mapOf<String, Any?>("com.strivacity" to "{}", "aps" to mapOf("alert" to "Approve"), "n" to 1)

    private fun approve(serialized: String) = PlatformChallengeResolution(serialized, PlatformResolutionAction.APPROVE)

    private fun deny(serialized: String) = PlatformChallengeResolution(serialized, PlatformResolutionAction.DENY)

    private fun select(
        serialized: String,
        option: String,
    ) = PlatformChallengeResolution(serialized, PlatformResolutionAction.SELECT, option)

    private fun resolvedAction(): String =
        fixture.sdk
            .callsTo("resolveChallenge")
            .single()
            .single()
            .toString()

    @Test
    fun `canHandleMessage passes only the string entries of the payload`() =
        runTest {
            fixture.created().canHandleMessage(payload)

            assertEquals(
                listOf<Any?>(mapOf("com.strivacity" to "{}")),
                fixture.sdk.callsTo("canHandleMessage").single(),
            )
        }

    @Test
    fun `canHandleMessage returns what the SDK reports`() =
        runTest {
            fixture.sdk.canHandle = false

            assertEquals(false, fixture.created().canHandleMessage(payload))
        }

    @Test
    fun `handling a message returns a simple challenge for a simple SDK challenge`() =
        runTest {
            val challenge = fixture.created().handleMessage(payload)

            assertEquals(PlatformChallengeType.SIMPLE, challenge.type)
        }

    @Test
    fun `handling a message carries the challenge fields and metadata`() =
        runTest {
            val challenge = fixture.created().handleMessage(payload)

            assertEquals(
                listOf<Any?>(
                    "challenge-1",
                    "https://issuer.example.com",
                    "account-1",
                    "2026-10-01T14:30:00Z",
                    mapOf("place" to "New York", "device" to null),
                ),
                listOf(
                    challenge.challengeId,
                    challenge.issuer,
                    challenge.accountId,
                    challenge.expiresAt,
                    challenge.metadata,
                ),
            )
        }

    @Test
    fun `handling a message returns the options of a context-matching challenge`() =
        runTest {
            fixture.sdk.challenge = deserializeChallenge(FakePushNotification.CONTEXT_MATCHING_SNAPSHOT)

            val challenge = fixture.created().handleMessage(payload)

            assertEquals(listOf("12", "26", "84"), challenge.options)
        }

    @Test
    fun `a handled challenge carries a serialized form for resolving it`() =
        runTest {
            val challenge = fixture.created().handleMessage(payload)

            assertTrue(challenge.serialized.isNotBlank())
        }

    @Test
    fun `approving resolves a simple challenge with the approve action`() =
        runTest {
            val host = fixture.created()

            host.resolveChallenge(approve(host.handleMessage(payload).serialized))

            assertTrue(resolvedAction().contains("action=approve"))
        }

    @Test
    fun `denying resolves a challenge with the deny action`() =
        runTest {
            val host = fixture.created()

            host.resolveChallenge(deny(host.handleMessage(payload).serialized))

            assertTrue(resolvedAction().contains("action=deny"))
        }

    @Test
    fun `selecting resolves a context-matching challenge with the chosen option`() =
        runTest {
            fixture.sdk.challenge = deserializeChallenge(FakePushNotification.CONTEXT_MATCHING_SNAPSHOT)
            val host = fixture.created()

            host.resolveChallenge(select(host.handleMessage(payload).serialized, "26"))

            assertTrue(resolvedAction().contains("action=26"))
        }

    @Test
    fun `selecting an option that was not offered reports the invalid challenge option code`() =
        runTest {
            fixture.sdk.challenge = deserializeChallenge(FakePushNotification.CONTEXT_MATCHING_SNAPSHOT)
            val host = fixture.created()
            val serialized = host.handleMessage(payload).serialized

            val failure = assertFailsWith<FlutterError> { host.resolveChallenge(select(serialized, "99")) }

            assertEquals("invalid_challenge_option", failure.code)
        }

    @Test
    fun `approving a context-matching challenge reports the unexpected code`() =
        runTest {
            fixture.sdk.challenge = deserializeChallenge(FakePushNotification.CONTEXT_MATCHING_SNAPSHOT)
            val host = fixture.created()
            val serialized = host.handleMessage(payload).serialized

            val failure = assertFailsWith<FlutterError> { host.resolveChallenge(approve(serialized)) }

            assertEquals(UNEXPECTED_CODE, failure.code)
        }

    @Test
    fun `selecting an option on a simple challenge reports the unexpected code`() =
        runTest {
            val host = fixture.created()
            val serialized = host.handleMessage(payload).serialized

            val failure = assertFailsWith<FlutterError> { host.resolveChallenge(select(serialized, "12")) }

            assertEquals(UNEXPECTED_CODE, failure.code)
        }

    @Test
    fun `a selection without an option reports the unexpected code`() =
        runTest {
            fixture.sdk.challenge = deserializeChallenge(FakePushNotification.CONTEXT_MATCHING_SNAPSHOT)
            val host = fixture.created()
            val serialized = host.handleMessage(payload).serialized

            val failure =
                assertFailsWith<FlutterError> {
                    host.resolveChallenge(PlatformChallengeResolution(serialized, PlatformResolutionAction.SELECT))
                }

            assertEquals(UNEXPECTED_CODE, failure.code)
        }

    @Test
    fun `an unreadable serialized challenge reports the challenge unavailable code`() =
        runTest {
            val failure =
                assertFailsWith<FlutterError> { fixture.created().resolveChallenge(approve("not a snapshot")) }

            assertEquals("challenge_unavailable", failure.code)
        }

    @Test
    fun `an accepted resolution is reported as ok`() =
        runTest {
            val host = fixture.created()

            assertEquals(
                PlatformResolutionResult.OK,
                host.resolveChallenge(approve(host.handleMessage(payload).serialized)),
            )
        }

    @Test
    fun `a refused resolution is reported as not ok`() =
        runTest {
            fixture.sdk.resolutionResult = ResolutionResult.NOT_OK
            val host = fixture.created()

            assertEquals(
                PlatformResolutionResult.NOT_OK,
                host.resolveChallenge(approve(host.handleMessage(payload).serialized)),
            )
        }
}
