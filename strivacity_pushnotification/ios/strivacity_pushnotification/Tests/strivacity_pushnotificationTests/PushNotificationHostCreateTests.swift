@testable import strivacity_pushnotification
import Testing

/// Exercises building the SDK from Dart.
struct PushNotificationHostCreateTests {
    let fixture = HostFixture()

    @Test func createBuildsTheSdkWithTheRequestedSoftwareBackedKeySetting() async throws {
        _ = try await fixture.created(allowSoftwareBackedKeys: true)

        #expect(fixture.factoryCalls == [true])
    }

    @Test func repeatingCreateWithTheSameOptionsBuildsTheSdkOnce() async throws {
        _ = try await fixture.created()
        _ = try await fixture.created()

        #expect(fixture.factoryCalls.count == 1)
    }

    @Test func repeatingCreateWithDifferentOptionsFailsWithAConfigurationConflict() async throws {
        _ = try await fixture.created(allowSoftwareBackedKeys: false)

        let failure = try await #require(throws: PigeonError.self) {
            _ = try await fixture.created(allowSoftwareBackedKeys: true)
        }

        #expect(failure.code == configurationConflictCode)
    }

    @Test func aCallBeforeCreateFailsWithTheUnexpectedCode() async throws {
        let failure = try await #require(throws: PigeonError.self) {
            _ = try await fixture.host.listEnrollments()
        }

        #expect(failure.code == unexpectedCode)
    }
}
