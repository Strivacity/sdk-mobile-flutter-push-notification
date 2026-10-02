@_spi(PluginBridge) import PushNotification

extension PlatformDeviceTokenType {
    var sdkValue: DeviceTokenType {
        switch self {
        case .apns: .apns
        case .fcmToken: .fcmToken
        case .fcmFid: .fcmFid
        }
    }
}

extension ResolutionResult {
    var platformValue: PlatformResolutionResult {
        switch self {
        case .ok: .ok
        case .notOk: .notOk
        }
    }
}

extension PlatformEnrollmentGrant {
    var sdkValue: EnrollmentGrant {
        EnrollmentGrant(
            issuer: issuer,
            oneTimeToken: oneTimeToken,
            accountId: accountId,
            displayUserName: displayUserName
        )
    }
}

extension EnrollmentGrant {
    var platformValue: PlatformEnrollmentGrant {
        PlatformEnrollmentGrant(
            issuer: issuer,
            oneTimeToken: oneTimeToken,
            accountId: accountId,
            displayUserName: displayUserName
        )
    }
}

extension Enrollment {
    var platformValue: PlatformEnrollment {
        PlatformEnrollment(
            issuer: issuer,
            accountId: accountId,
            keyId: keyId,
            userName: userName,
            deviceName: deviceName
        )
    }
}

extension Challenge {
    func platformValue() throws -> PlatformChallenge {
        let type: PlatformChallengeType
        let options: [String]?
        switch self {
        case .simple:
            type = .simple
            options = nil
        case let .contextMatching(matching):
            type = .contextMatching
            options = matching.options
        }

        return try PlatformChallenge(
            type: type,
            challengeId: challengeId,
            issuer: issuer,
            accountId: accountId,
            expiresAt: expiresAt,
            metadata: metadata,
            serialized: serializeChallenge(self),
            options: options
        )
    }
}

extension Dictionary where Key == String, Value == Any? {
    /// The entries of a push payload that hold a value, in the shape the SDK's payload reader takes.
    var userInfo: [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = [:]
        for (key, value) in self {
            if let value {
                userInfo[key] = value
            }
        }
        return userInfo
    }
}
