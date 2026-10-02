@_spi(PluginBridge) import PushNotification

/// The error code reported for failures outside the SDK's own error codes.
let unexpectedCode = "unexpected"

/// The error code reported when the SDK is already built with other options.
let configurationConflictCode = "configuration_conflict"

/// Runs `body` and turns any failure into a `PigeonError` that carries only the SDK's error code,
/// its message and the backend status. Cancellation passes through.
func guarded<T>(_ body: () async throws -> T) async throws -> T {
    do {
        return try await body()
    } catch let failure as PigeonError {
        throw failure
    } catch let failure as CancellationError {
        throw failure
    } catch let failure as PushNotificationError {
        throw PigeonError(
            code: failure.code,
            message: failure.message,
            details: failure.status.map { ["status": $0] }
        )
    } catch {
        // Only the type is reported; the description of an unknown failure could hold anything.
        throw PigeonError(code: unexpectedCode, message: "Unexpected failure: \(type(of: error))", details: nil)
    }
}
