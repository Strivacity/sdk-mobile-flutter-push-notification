@_spi(PluginBridge) import PushNotification
@testable import strivacity_pushnotification
import Testing

/// Exercises enrolling, un-enrolling, listing and token updates.
struct PushNotificationHostEnrollmentTests {
    let fixture = HostFixture()

    let grant = PlatformEnrollmentGrant(
        issuer: "https://issuer.example.com",
        oneTimeToken: "one-time-token",
        accountId: "account-1",
        displayUserName: "Ada"
    )

    @Test func parsingAGrantUrlReturnsTheParsedGrant() async throws {
        let parsed = try await fixture.created().parseEnrollmentGrant(url: "https://example.com/grant")

        #expect(parsed == grant)
    }

    @Test func parsingPassesTheUrlToTheSdkUnchanged() async throws {
        _ = try await fixture.created().parseEnrollmentGrant(url: "https://example.com/grant")

        #expect(fixture.parsedUrls == ["https://example.com/grant"])
    }

    @Test func anUnusableGrantReportsTheInvalidGrantCode() async throws {
        fixture.parseFailure = PushNotificationError.invalidGrant(message: "bad grant")
        let host = try await fixture.created()

        let failure = try await #require(throws: PigeonError.self) {
            _ = try await host.parseEnrollmentGrant(url: "nope")
        }

        #expect(failure.code == "invalid_grant")
    }

    @Test func enrollingPassesTheGrantTokenTokenTypeAndDeviceNameToTheSdk() async throws {
        _ = try await fixture.created().enrollDevice(
            grant: grant,
            deviceToken: "token-1",
            deviceTokenType: .fcmToken,
            deviceName: "iPhone"
        )

        let call = try #require(fixture.sdk.enrollCalls.first)
        #expect([call.grant.oneTimeToken, call.token, call.name] == ["one-time-token", "token-1", "iPhone"])
        #expect(call.type == .fcmToken)
    }

    @Test func enrollingReturnsTheEnrollmentTheSdkCreated() async throws {
        let enrollment = try await fixture.created().enrollDevice(
            grant: grant,
            deviceToken: "token-1",
            deviceTokenType: .apns,
            deviceName: "iPhone"
        )

        #expect(enrollment == PlatformEnrollment(
            issuer: "https://issuer.example.com",
            accountId: "account-1",
            keyId: "key-1",
            userName: "Ada",
            deviceName: "iPhone"
        ))
    }

    @Test func unEnrollingPassesTheIssuerAndAccountToTheSdk() async throws {
        try await fixture.created().unenrollDevice(issuer: "https://issuer.example.com", accountId: "account-1")

        let call = try #require(fixture.sdk.unenrollCalls.first)
        #expect([call.issuer, call.accountId] == ["https://issuer.example.com", "account-1"])
    }

    @Test func hasEnrollmentReturnsWhatTheSdkReports() async throws {
        fixture.sdk.hasKey = false

        let held = try await fixture.created().hasEnrollment(
            issuer: "https://issuer.example.com",
            accountId: "account-1"
        )

        #expect(held == false)
    }

    @Test func listingReturnsTheEnrollmentsTheSdkHolds() async throws {
        fixture.sdk.enrollments = [fixture.sdk.enrollment]

        let enrollments = try await fixture.created().listEnrollments()

        #expect(enrollments.map(\.keyId) == ["key-1"])
    }

    @Test func aTokenUpdatePassesTheTokenAndItsTypeToTheSdk() async throws {
        try await fixture.created().updateDeviceToken(
            issuer: "https://issuer.example.com",
            accountId: "account-1",
            deviceToken: "token-2",
            deviceTokenType: .apns
        )

        let call = try #require(fixture.sdk.tokenUpdateCalls.first)
        #expect([call.issuer, call.accountId, call.token] == ["https://issuer.example.com", "account-1", "token-2"])
        #expect(call.type == .apns)
    }
}
