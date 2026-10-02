package com.strivacity.flutter.strivacity_pushnotification

import com.strivacity.android.pushnotification.model.ChallengeException
import com.strivacity.android.pushnotification.model.EnrollmentException
import com.strivacity.android.pushnotification.model.PushNotificationException
import com.strivacity.android.pushnotification.model.UnenrollmentException
import com.strivacity.android.pushnotification.model.UpdateTokenException
import kotlin.coroutines.cancellation.CancellationException

/** The error code reported for failures outside the SDK's own error codes. */
internal const val UNEXPECTED_CODE = "unexpected"

/** The error code reported when the SDK is already built with other options. */
internal const val CONFIGURATION_CONFLICT_CODE = "configuration_conflict"

/**
 * Runs [block] and turns any failure into a [FlutterError] that carries only the SDK's error code,
 * its message and the backend status. Cancellation passes through.
 */
@Suppress("TooGenericExceptionCaught")
internal inline fun <T> guarded(block: () -> T): T =
    try {
        block()
    } catch (failure: FlutterError) {
        throw failure
    } catch (failure: CancellationException) {
        throw failure
    } catch (failure: PushNotificationException) {
        throw failure.toFlutterError()
    } catch (failure: Exception) {
        // Only the type is reported; the message of an unknown failure could hold anything.
        throw FlutterError(UNEXPECTED_CODE, "Unexpected failure: ${failure::class.simpleName}", null)
    }

private fun PushNotificationException.toFlutterError(): FlutterError {
    val status = status()
    return FlutterError(code, message, status?.let { mapOf("status" to it) })
}

private fun PushNotificationException.status(): Int? =
    when (this) {
        is EnrollmentException -> status
        is UnenrollmentException -> status
        is UpdateTokenException -> status
        is ChallengeException -> status
        else -> null
    }
