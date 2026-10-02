package com.strivacity.flutter.strivacity_pushnotification

import com.strivacity.android.pushnotification.model.DeviceTokenType
import com.strivacity.android.pushnotification.model.Enrollment
import com.strivacity.android.pushnotification.model.InvalidGrantException
import com.strivacity.flutter.strivacity_pushnotification.support.HostFixture
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/** Exercises enrolling, un-enrolling, listing and token updates. */
internal class PushNotificationHostEnrollmentTest {
    private val fixture = HostFixture()

    private val grant =
        PlatformEnrollmentGrant("https://issuer.example.com", "one-time-token", "account-1", "Ada")

    @Test
    fun `parsing a grant URL returns the parsed grant`() =
        runTest {
            val parsed = fixture.created().parseEnrollmentGrant("https://example.com/grant")

            assertEquals(grant, parsed)
        }

    @Test
    fun `parsing passes the URL to the SDK unchanged`() =
        runTest {
            fixture.created().parseEnrollmentGrant("https://example.com/grant")

            assertEquals(listOf("https://example.com/grant"), fixture.parsedUrls)
        }

    @Test
    fun `an unusable grant reports the invalid grant code`() =
        runTest {
            fixture.parseFailure = InvalidGrantException("bad grant")

            val failure =
                assertFailsWith<FlutterError> { fixture.created().parseEnrollmentGrant("nope") }

            assertEquals("invalid_grant", failure.code)
        }

    @Test
    fun `enrolling passes the grant, token, token type and device name to the SDK`() =
        runTest {
            fixture.created().enrollDevice(grant, "token-1", PlatformDeviceTokenType.FCM_TOKEN, "Pixel")

            val call = fixture.sdk.callsTo("enrollDevice").single()
            assertEquals(
                listOf("one-time-token", "token-1", DeviceTokenType.FCM_TOKEN, "Pixel"),
                listOf((call[0] as com.strivacity.android.pushnotification.model.EnrollmentGrant).oneTimeToken) +
                    call.drop(1),
            )
        }

    @Test
    fun `enrolling returns the enrollment the SDK created`() =
        runTest {
            val enrollment =
                fixture.created().enrollDevice(grant, "token-1", PlatformDeviceTokenType.FCM_TOKEN, "Pixel")

            assertEquals(
                PlatformEnrollment("https://issuer.example.com", "account-1", "key-1", "Ada", "Pixel"),
                enrollment,
            )
        }

    @Test
    fun `enrolling with an APNs token is rejected without calling the SDK`() =
        runTest {
            val failure =
                assertFailsWith<FlutterError> {
                    fixture.created().enrollDevice(grant, "token-1", PlatformDeviceTokenType.APNS, "Pixel")
                }

            assertEquals(UNEXPECTED_CODE, failure.code)
            assertEquals(emptyList(), fixture.sdk.callsTo("enrollDevice"))
        }

    @Test
    fun `un-enrolling passes the issuer and account to the SDK`() =
        runTest {
            fixture.created().unenrollDevice("https://issuer.example.com", "account-1")

            assertEquals(
                listOf(listOf<Any?>("https://issuer.example.com", "account-1")),
                fixture.sdk.callsTo("unenrollDevice"),
            )
        }

    @Test
    fun `hasEnrollment returns what the SDK reports`() =
        runTest {
            fixture.sdk.hasKey = false

            assertEquals(false, fixture.created().hasEnrollment("https://issuer.example.com", "account-1"))
        }

    @Test
    fun `listing returns the enrollments the SDK holds`() =
        runTest {
            fixture.sdk.enrollments = listOf(Enrollment("https://issuer.example.com", "account-1", "key-1", null, null))

            val enrollments = fixture.created().listEnrollments()

            assertEquals(listOf("key-1"), enrollments.map { it.keyId })
        }

    @Test
    fun `a token update passes the token and its type to the SDK`() =
        runTest {
            fixture.created().updateDeviceToken(
                "https://issuer.example.com",
                "account-1",
                "token-2",
                PlatformDeviceTokenType.FCM_FID,
            )

            assertEquals(
                listOf(listOf<Any?>("https://issuer.example.com", "account-1", "token-2", DeviceTokenType.FCM_FID)),
                fixture.sdk.callsTo("updateDeviceToken"),
            )
        }

    @Test
    fun `a token update with an APNs token is rejected without calling the SDK`() =
        runTest {
            val failure =
                assertFailsWith<FlutterError> {
                    fixture.created().updateDeviceToken(
                        "https://issuer.example.com",
                        "account-1",
                        "token-2",
                        PlatformDeviceTokenType.APNS,
                    )
                }

            assertEquals(UNEXPECTED_CODE, failure.code)
            assertEquals(emptyList(), fixture.sdk.callsTo("updateDeviceToken"))
        }
}
