@_spi(PluginBridge) import PushNotification
@testable import strivacity_pushnotification
import Testing

/// Exercises how SDK failures reach Dart.
struct ErrorMappingTests {
    let fixture = HostFixture()

    private struct UnknownFailure: Error {
        let secret = "secret-value"
    }

    private func failure(of error: Error) async throws -> PigeonError {
        let host = try await fixture.created()
        fixture.sdk.failureOnNextCall = error
        return try await #require(throws: PigeonError.self) {
            _ = try await host.hasEnrollment(issuer: "https://issuer.example.com", accountId: "account-1")
        }
    }

    @Test func anSdkFailureKeepsItsErrorCode() async throws {
        let result = try await failure(of: PushNotificationError.notEnrolled(accountId: "account-1"))

        #expect(result.code == "not_enrolled")
    }

    @Test func anSdkFailureKeepsItsMessage() async throws {
        let error = PushNotificationError.notEnrolled(accountId: "account-1")

        let result = try await failure(of: error)

        #expect(result.message == error.message)
    }

    @Test func aBackendStatusIsReportedInTheDetails() async throws {
        let result = try await failure(
            of: PushNotificationError.enrollmentRejected(message: "rejected", status: 401, cause: nil)
        )

        #expect(result.details as? [String: Int] == ["status": 401])
    }

    @Test func aFailureWithoutAStatusHasNoDetails() async throws {
        let result = try await failure(of: PushNotificationError.networkFailure(message: "offline", cause: nil))

        #expect(result.details == nil)
    }

    @Test func anUnknownFailureReportsTheUnexpectedCode() async throws {
        let result = try await failure(of: UnknownFailure())

        #expect(result.code == unexpectedCode)
    }

    @Test func anUnknownFailureDoesNotReportItsOwnDescription() async throws {
        let result = try await failure(of: UnknownFailure())

        #expect(!(result.message ?? "").contains("secret-value"))
    }

    @Test func cancellationPassesThroughUnchanged() async throws {
        let host = try await fixture.created()
        fixture.sdk.failureOnNextCall = CancellationError()

        await #expect(throws: CancellationError.self) {
            _ = try await host.hasEnrollment(issuer: "https://issuer.example.com", accountId: "account-1")
        }
    }
}
