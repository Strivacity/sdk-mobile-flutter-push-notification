import Foundation
@_spi(PluginBridge) import PushNotification
@testable import strivacity_pushnotification

/// A `PushNotificationInterface` that records its calls and answers with configured values.
final class FakePushNotification: PushNotificationInterface, @unchecked Sendable {
    static let simpleSnapshot =
        #"{"version":1,"type":"simple","challengeId":"challenge-1","challengeValue":"challenge-value","#
            + #""issuer":"https://issuer.example.com","accountId":"account-1","#
            + #""expiresAt":"2026-10-01T14:30:00Z","metadata":{"place":"New York","device":null}}"#

    static let contextMatchingSnapshot =
        #"{"version":1,"type":"contextMatching","challengeId":"challenge-2","challengeValue":"challenge-value","#
            + #""issuer":"https://issuer.example.com","accountId":"account-1","#
            + #""expiresAt":"2026-10-01T14:30:00Z","metadata":{},"options":["12","26","84"]}"#

    var enrollment = Enrollment(
        issuer: "https://issuer.example.com",
        accountId: "account-1",
        keyId: "key-1",
        userName: "Ada",
        deviceName: "iPhone"
    )
    var enrollments: [Enrollment] = []
    var hasKey = true
    var canHandle = true
    var challenge: Challenge = FakePushNotification.challenge(from: simpleSnapshot)
    var resolutionResult = ResolutionResult.ok

    /// Thrown by the next call, then cleared.
    var failureOnNextCall: Error?

    var enrollCalls: [(grant: EnrollmentGrant, token: String, type: DeviceTokenType, name: String)] = []
    var unenrollCalls: [(issuer: String, accountId: String)] = []
    var tokenUpdateCalls: [(issuer: String, accountId: String, token: String, type: DeviceTokenType)] = []
    var messageDataCalls: [[String: String]?] = []
    var resolutions: [ChallengeResolution] = []

    static func challenge(from snapshot: String) -> Challenge {
        // The snapshots above are valid by construction.
        // swiftlint:disable:next force_try
        try! deserializeChallenge(snapshot)
    }

    private func failIfConfigured() throws {
        if let failure = failureOnNextCall {
            failureOnNextCall = nil
            throw failure
        }
    }

    func enrollDevice(
        grant: EnrollmentGrant,
        deviceToken: String,
        deviceTokenType: DeviceTokenType,
        deviceName: String
    ) async throws -> Enrollment {
        enrollCalls.append((grant, deviceToken, deviceTokenType, deviceName))
        try failIfConfigured()
        return enrollment
    }

    func unenrollDevice(issuer: String, accountId: String) async throws {
        unenrollCalls.append((issuer, accountId))
        try failIfConfigured()
    }

    func hasEnrollment(issuer _: String, accountId _: String) async throws -> Bool {
        try failIfConfigured()
        return hasKey
    }

    func listEnrollments() async -> [Enrollment] {
        enrollments
    }

    func updateDeviceToken(
        issuer: String,
        accountId: String,
        deviceToken: String,
        deviceTokenType: DeviceTokenType
    ) async throws {
        tokenUpdateCalls.append((issuer, accountId, deviceToken, deviceTokenType))
        try failIfConfigured()
    }

    func canHandleMessage(_ messageData: [String: String]?) async throws -> Bool {
        messageDataCalls.append(messageData)
        try failIfConfigured()
        return canHandle
    }

    func handleMessage(_ messageData: [String: String]?) async throws -> Challenge {
        messageDataCalls.append(messageData)
        try failIfConfigured()
        return challenge
    }

    func resolveChallenge(_ resolution: ChallengeResolution) async throws -> ResolutionResult {
        resolutions.append(resolution)
        try failIfConfigured()
        return resolutionResult
    }
}

/// A `PushNotificationHost` wired to a `FakePushNotification`.
final class HostFixture {
    let sdk = FakePushNotification()
    private(set) var factoryCalls: [Bool] = []
    private(set) var parsedUrls: [String] = []
    var parsedGrant = EnrollmentGrant(
        issuer: "https://issuer.example.com",
        oneTimeToken: "one-time-token",
        accountId: "account-1",
        displayUserName: "Ada"
    )
    var parseFailure: Error?

    lazy var host = PushNotificationHost(
        sdkFactory: { [self] allowSoftwareBackedKeys in
            factoryCalls.append(allowSoftwareBackedKeys)
            return sdk
        },
        parseGrant: { [self] url in
            parsedUrls.append(url)
            if let parseFailure {
                throw parseFailure
            }
            return parsedGrant
        }
    )

    /// The host after Dart has created the SDK.
    func created(allowSoftwareBackedKeys: Bool = false) async throws -> PushNotificationHost {
        try await host.create(options: PlatformCreateOptions(allowSoftwareBackedKeys: allowSoftwareBackedKeys))
        return host
    }
}
