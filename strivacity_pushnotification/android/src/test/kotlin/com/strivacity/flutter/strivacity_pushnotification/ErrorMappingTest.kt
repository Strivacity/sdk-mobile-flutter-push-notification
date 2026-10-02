package com.strivacity.flutter.strivacity_pushnotification

import com.strivacity.android.pushnotification.model.EnrollmentException
import com.strivacity.android.pushnotification.model.NetworkException
import com.strivacity.android.pushnotification.model.NotEnrolledException
import com.strivacity.flutter.strivacity_pushnotification.support.HostFixture
import kotlinx.coroutines.test.runTest
import kotlin.coroutines.cancellation.CancellationException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull

/** Exercises how SDK failures reach Dart. */
internal class ErrorMappingTest {
    private val fixture = HostFixture()

    private suspend fun failureOfList(failure: Exception): FlutterError {
        val host = fixture.created()
        fixture.sdk.failureOnNextCall = failure
        return assertFailsWith<FlutterError> { host.listEnrollments() }
    }

    @Test
    fun `an SDK failure keeps its error code`() =
        runTest {
            val failure = failureOfList(NotEnrolledException("account-1"))

            assertEquals("not_enrolled", failure.code)
        }

    @Test
    fun `an SDK failure keeps its message`() =
        runTest {
            val failure = failureOfList(NotEnrolledException("account-1"))

            assertEquals("No enrollment is held for account 'account-1'", failure.message)
        }

    @Test
    fun `a backend status is reported in the details`() =
        runTest {
            val failure = failureOfList(EnrollmentException("rejected", status = 401))

            assertEquals(mapOf("status" to 401), failure.details)
        }

    @Test
    fun `a failure without a status has no details`() =
        runTest {
            val failure = failureOfList(NetworkException("offline"))

            assertNull(failure.details)
        }

    @Test
    fun `an unknown failure reports the unexpected code`() =
        runTest {
            val failure = failureOfList(IllegalStateException("secret-value"))

            assertEquals(UNEXPECTED_CODE, failure.code)
        }

    @Test
    fun `an unknown failure does not report its own message`() =
        runTest {
            val failure = failureOfList(IllegalStateException("secret-value"))

            assertFalse(failure.message.orEmpty().contains("secret-value"))
        }

    @Test
    fun `cancellation passes through unchanged`() =
        runTest {
            val host = fixture.created()
            fixture.sdk.failureOnNextCall = CancellationException("cancelled")

            assertFailsWith<CancellationException> { host.listEnrollments() }
        }
}
