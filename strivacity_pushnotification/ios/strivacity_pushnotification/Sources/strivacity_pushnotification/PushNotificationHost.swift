import Foundation
@_spi(PluginBridge) import PushNotification

/// Answers the calls from Dart with the native push notification SDK.
///
/// The SDK is built by `sdkFactory` when Dart calls `create`. Callers do not overlap calls for the
/// same issuer and account.
///
/// An actor, so the state of the built SDK is protected without manual locking. The generated Pigeon
/// handlers call into it from different tasks.
actor PushNotificationHost: PushNotificationPlatformApi {
    private struct Configured {
        let allowSoftwareBackedKeys: Bool
        let sdk: any PushNotificationInterface
    }

    private let sdkFactory: (_ allowSoftwareBackedKeys: Bool) -> any PushNotificationInterface
    private let parseGrant: (_ url: String) throws -> EnrollmentGrant
    private var configured: Configured?

    init(
        sdkFactory: @escaping (_ allowSoftwareBackedKeys: Bool) -> any PushNotificationInterface,
        parseGrant: @escaping (_ url: String) throws -> EnrollmentGrant
    ) {
        self.sdkFactory = sdkFactory
        self.parseGrant = parseGrant
    }

    func create(options: PlatformCreateOptions) async throws {
        try await guarded {
            try createSdk(options: options)
        }
    }

    func parseEnrollmentGrant(url: String) async throws -> PlatformEnrollmentGrant {
        try await guarded { try parseGrant(url).platformValue }
    }

    func enrollDevice(
        grant: PlatformEnrollmentGrant,
        deviceToken: String,
        deviceTokenType: PlatformDeviceTokenType,
        deviceName: String
    ) async throws -> PlatformEnrollment {
        try await guarded {
            try await sdk().enrollDevice(
                grant: grant.sdkValue,
                deviceToken: deviceToken,
                deviceTokenType: deviceTokenType.sdkValue,
                deviceName: deviceName
            ).platformValue
        }
    }

    func unenrollDevice(issuer: String, accountId: String) async throws {
        try await guarded { try await sdk().unenrollDevice(issuer: issuer, accountId: accountId) }
    }

    func hasEnrollment(issuer: String, accountId: String) async throws -> Bool {
        try await guarded { try await sdk().hasEnrollment(issuer: issuer, accountId: accountId) }
    }

    func listEnrollments() async throws -> [PlatformEnrollment] {
        try await guarded { try await sdk().listEnrollments().map(\.platformValue) }
    }

    func updateDeviceToken(
        issuer: String,
        accountId: String,
        deviceToken: String,
        deviceTokenType: PlatformDeviceTokenType
    ) async throws {
        try await guarded {
            try await sdk().updateDeviceToken(
                issuer: issuer,
                accountId: accountId,
                deviceToken: deviceToken,
                deviceTokenType: deviceTokenType.sdkValue
            )
        }
    }

    func canHandleMessage(payload: [String: Any?]) async throws -> Bool {
        try await guarded { try await sdk().canHandleMessage(MessageData.from(userInfo: payload.userInfo)) }
    }

    func handleMessage(payload: [String: Any?]) async throws -> PlatformChallenge {
        try await guarded {
            try await sdk().handleMessage(MessageData.from(userInfo: payload.userInfo)).platformValue()
        }
    }

    func resolveChallenge(resolution: PlatformChallengeResolution) async throws -> PlatformResolutionResult {
        try await guarded {
            let challenge = try deserializeChallenge(resolution.serialized)
            return try await sdk().resolveChallenge(resolutionFor(challenge, resolution)).platformValue
        }
    }

    private func resolutionFor(
        _ challenge: Challenge,
        _ resolution: PlatformChallengeResolution
    ) throws -> ChallengeResolution {
        switch resolution.action {
        case .approve:
            guard case let .simple(simple) = challenge else { throw wrongKind("approved") }
            return simple.approve()
        case .deny:
            return challenge.deny()
        case .select:
            guard let option = resolution.option else {
                throw PigeonError(code: unexpectedCode, message: "A selection needs an option.", details: nil)
            }
            guard case let .contextMatching(matching) = challenge else { throw wrongKind("answered with an option") }
            return try matching.select(option)
        }
    }

    private func createSdk(options: PlatformCreateOptions) throws {
        guard let current = configured else {
            configured = Configured(
                allowSoftwareBackedKeys: options.allowSoftwareBackedKeys,
                sdk: sdkFactory(options.allowSoftwareBackedKeys)
            )
            return
        }
        guard current.allowSoftwareBackedKeys == options.allowSoftwareBackedKeys else {
            throw PigeonError(
                code: configurationConflictCode,
                message: "The SDK is already created with allowSoftwareBackedKeys: "
                    + "\(current.allowSoftwareBackedKeys).",
                details: nil
            )
        }
    }

    private func sdk() throws -> any PushNotificationInterface {
        guard let sdk = configured?.sdk else {
            throw PigeonError(code: unexpectedCode, message: "The push notification SDK is not created.", details: nil)
        }
        return sdk
    }

    private func wrongKind(_ action: String) -> PigeonError {
        PigeonError(code: unexpectedCode, message: "This challenge cannot be \(action).", details: nil)
    }
}
