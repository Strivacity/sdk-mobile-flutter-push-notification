package com.strivacity.flutter.strivacity_pushnotification

import com.strivacity.flutter.strivacity_pushnotification.fakes.FakePushNotification
import com.strivacity.flutter.strivacity_pushnotification.support.HostFixture
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/** Exercises building the SDK from Dart. */
internal class PushNotificationHostCreateTest {
    private val fixture = HostFixture()

    @Test
    fun `create builds the SDK with the requested software-backed key setting`() =
        runTest {
            fixture.created(allowSoftwareBackedKeys = true)

            assertEquals(listOf(true), fixture.factoryCalls)
        }

    @Test
    fun `repeating create with the same options builds the SDK once`() =
        runTest {
            fixture.created()
            fixture.created()

            assertEquals(1, fixture.factoryCalls.size)
        }

    @Test
    fun `repeating create with different options fails with a configuration conflict`() =
        runTest {
            fixture.created(allowSoftwareBackedKeys = false)

            val failure = assertFailsWith<FlutterError> { fixture.created(allowSoftwareBackedKeys = true) }

            assertEquals(CONFIGURATION_CONFLICT_CODE, failure.code)
        }

    @Test
    fun `a call before create fails with the unexpected code`() =
        runTest {
            val failure = assertFailsWith<FlutterError> { fixture.host.listEnrollments() }

            assertEquals(UNEXPECTED_CODE, failure.code)
        }

    @Test
    fun `when two creates overlap, the SDK that finishes building first is kept`() =
        runTest {
            val builds = SlowFirstBuild()
            val first = async { builds.host.create(PlatformCreateOptions(false)) }
            builds.waitUntilFirstBuildStarts()

            builds.host.create(PlatformCreateOptions(false))
            builds.releaseFirstBuild.countDown()
            first.await()
            builds.host.hasEnrollment("https://issuer.example.com", "account-1")

            assertEquals(
                listOf(1, 0),
                listOf(builds.fast.callsTo("hasEnrollment").size, builds.slow.callsTo("hasEnrollment").size),
            )
        }

    @Test
    fun `when two creates with different options overlap, the one that finishes last reports a conflict`() =
        runTest {
            val builds = SlowFirstBuild()
            val first = async { runCatching { builds.host.create(PlatformCreateOptions(false)) } }
            builds.waitUntilFirstBuildStarts()

            builds.host.create(PlatformCreateOptions(true))
            builds.releaseFirstBuild.countDown()
            val failure = first.await().exceptionOrNull()

            assertEquals(CONFIGURATION_CONFLICT_CODE, (failure as FlutterError).code)
        }

    /** A host whose first SDK build waits until it is released, while later builds return at once. */
    private class SlowFirstBuild {
        val slow = FakePushNotification()
        val fast = FakePushNotification()
        val releaseFirstBuild = CountDownLatch(1)
        private val firstBuildStarted = CountDownLatch(1)
        private val builds = AtomicInteger()

        val host =
            PushNotificationHost(
                sdkFactory = {
                    if (builds.getAndIncrement() == 0) {
                        firstBuildStarted.countDown()
                        check(releaseFirstBuild.await(WAIT_SECONDS, TimeUnit.SECONDS))
                        slow
                    } else {
                        fast
                    }
                },
                parseGrant = { error("not used") },
            )

        suspend fun waitUntilFirstBuildStarts() {
            check(withContext(Dispatchers.IO) { firstBuildStarted.await(WAIT_SECONDS, TimeUnit.SECONDS) })
        }

        private companion object {
            const val WAIT_SECONDS = 5L
        }
    }
}
