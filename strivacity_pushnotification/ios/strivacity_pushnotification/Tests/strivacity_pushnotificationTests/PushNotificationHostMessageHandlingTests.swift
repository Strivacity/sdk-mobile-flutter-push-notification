@_spi(PluginBridge) import PushNotification
@testable import strivacity_pushnotification
import Testing

/// Exercises handling a push payload and answering the challenge it carries.
struct PushNotificationHostMessageHandlingTests {
    let fixture = HostFixture()

    let payload: [String: Any?] = [
        "com.strivacity": "{}",
        "aps": ["alert": "Approve"],
        "n": 1,
        "empty": nil,
    ]

    private func approve(_ serialized: String) -> PlatformChallengeResolution {
        PlatformChallengeResolution(serialized: serialized, action: .approve)
    }

    private func deny(_ serialized: String) -> PlatformChallengeResolution {
        PlatformChallengeResolution(serialized: serialized, action: .deny)
    }

    private func select(_ serialized: String, _ option: String) -> PlatformChallengeResolution {
        PlatformChallengeResolution(serialized: serialized, action: .select, option: option)
    }

    private func resolvedDescription() throws -> String {
        try #require(fixture.sdk.resolutions.first).description
    }

    @Test func canHandleMessagePassesOnlyTheEnvelopeEntryOfThePayload() async throws {
        _ = try await fixture.created().canHandleMessage(payload: payload)

        #expect(fixture.sdk.messageDataCalls.count == 1)
        #expect(fixture.sdk.messageDataCalls.first == ["com.strivacity": "{}"])
    }

    @Test func aPayloadWithoutAnEnvelopeEntryReachesTheSdkAsNoMessageData() async throws {
        _ = try await fixture.created().canHandleMessage(payload: ["aps": ["alert": "x"]])

        #expect(try #require(fixture.sdk.messageDataCalls.first) == nil)
    }

    @Test func canHandleMessageReturnsWhatTheSdkReports() async throws {
        fixture.sdk.canHandle = false

        #expect(try await fixture.created().canHandleMessage(payload: payload) == false)
    }

    @Test func handlingAMessageReturnsASimpleChallengeForASimpleSdkChallenge() async throws {
        let challenge = try await fixture.created().handleMessage(payload: payload)

        #expect(challenge.type == .simple)
    }

    @Test func handlingAMessageCarriesTheChallengeFieldsAndMetadata() async throws {
        let challenge = try await fixture.created().handleMessage(payload: payload)

        #expect(
            [challenge.challengeId, challenge.issuer, challenge.accountId, challenge.expiresAt]
                == ["challenge-1", "https://issuer.example.com", "account-1", "2026-10-01T14:30:00Z"]
        )
        #expect(challenge.metadata == ["place": "New York", "device": nil])
    }

    @Test func handlingAMessageReturnsTheOptionsOfAContextMatchingChallenge() async throws {
        fixture.sdk.challenge = FakePushNotification.challenge(from: FakePushNotification.contextMatchingSnapshot)

        let challenge = try await fixture.created().handleMessage(payload: payload)

        #expect(challenge.options == ["12", "26", "84"])
    }

    @Test func aHandledChallengeCarriesASerializedFormForResolvingIt() async throws {
        let challenge = try await fixture.created().handleMessage(payload: payload)

        #expect(!challenge.serialized.isEmpty)
    }

    @Test func approvingResolvesASimpleChallengeWithTheApproveAction() async throws {
        let host = try await fixture.created()

        _ = try await host.resolveChallenge(resolution: approve(host.handleMessage(payload: payload).serialized))

        #expect(try resolvedDescription().contains("action: approve"))
    }

    @Test func denyingResolvesAChallengeWithTheDenyAction() async throws {
        let host = try await fixture.created()

        _ = try await host.resolveChallenge(resolution: deny(host.handleMessage(payload: payload).serialized))

        #expect(try resolvedDescription().contains("action: deny"))
    }

    @Test func selectingResolvesAContextMatchingChallengeWithTheChosenOption() async throws {
        fixture.sdk.challenge = FakePushNotification.challenge(from: FakePushNotification.contextMatchingSnapshot)
        let host = try await fixture.created()

        _ = try await host.resolveChallenge(
            resolution: select(host.handleMessage(payload: payload).serialized, "26")
        )

        #expect(try resolvedDescription().contains("action: 26"))
    }

    @Test func selectingAnOptionThatWasNotOfferedReportsTheInvalidChallengeOptionCode() async throws {
        fixture.sdk.challenge = FakePushNotification.challenge(from: FakePushNotification.contextMatchingSnapshot)
        let host = try await fixture.created()
        let serialized = try await host.handleMessage(payload: payload).serialized

        let failure = try await #require(throws: PigeonError.self) {
            _ = try await host.resolveChallenge(resolution: select(serialized, "99"))
        }

        #expect(failure.code == "invalid_challenge_option")
    }

    @Test func approvingAContextMatchingChallengeReportsTheUnexpectedCode() async throws {
        fixture.sdk.challenge = FakePushNotification.challenge(from: FakePushNotification.contextMatchingSnapshot)
        let host = try await fixture.created()
        let serialized = try await host.handleMessage(payload: payload).serialized

        let failure = try await #require(throws: PigeonError.self) {
            _ = try await host.resolveChallenge(resolution: approve(serialized))
        }

        #expect(failure.code == unexpectedCode)
    }

    @Test func selectingAnOptionOnASimpleChallengeReportsTheUnexpectedCode() async throws {
        let host = try await fixture.created()
        let serialized = try await host.handleMessage(payload: payload).serialized

        let failure = try await #require(throws: PigeonError.self) {
            _ = try await host.resolveChallenge(resolution: select(serialized, "12"))
        }

        #expect(failure.code == unexpectedCode)
    }

    @Test func aSelectionWithoutAnOptionReportsTheUnexpectedCode() async throws {
        fixture.sdk.challenge = FakePushNotification.challenge(from: FakePushNotification.contextMatchingSnapshot)
        let host = try await fixture.created()
        let serialized = try await host.handleMessage(payload: payload).serialized

        let failure = try await #require(throws: PigeonError.self) {
            _ = try await host.resolveChallenge(
                resolution: PlatformChallengeResolution(serialized: serialized, action: .select)
            )
        }

        #expect(failure.code == unexpectedCode)
    }

    @Test func anUnreadableSerializedChallengeReportsTheChallengeUnavailableCode() async throws {
        let host = try await fixture.created()

        let failure = try await #require(throws: PigeonError.self) {
            _ = try await host.resolveChallenge(resolution: approve("not a snapshot"))
        }

        #expect(failure.code == "challenge_unavailable")
    }

    @Test func anAcceptedResolutionIsReportedAsOk() async throws {
        let host = try await fixture.created()

        let serialized = try await host.handleMessage(payload: payload).serialized
        let result = try await host.resolveChallenge(resolution: approve(serialized))

        #expect(result == .ok)
    }

    @Test func aRefusedResolutionIsReportedAsNotOk() async throws {
        fixture.sdk.resolutionResult = .notOk
        let host = try await fixture.created()

        let serialized = try await host.handleMessage(payload: payload).serialized
        let result = try await host.resolveChallenge(resolution: approve(serialized))

        #expect(result == .notOk)
    }
}
