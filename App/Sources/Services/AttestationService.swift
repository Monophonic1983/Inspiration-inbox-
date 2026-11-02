import Foundation
import DeviceCheck
import CryptoKit
import IntelligenceKit

/// App Attest for the Enhanced-mode proxy. The key is generated once and attested by the backend on first use.
/// First-use attestation (POST /attest) is a Phase 4 task to verify against the real backend on a device.
final class AttestationService: AttestationProvider, @unchecked Sendable {
    private let service = DCAppAttestService.shared
    private let keyDefaultsKey = "appAttestKeyID"

    func assertion(for body: Data) async throws -> (keyID: String, assertion: Data) {
        guard service.isSupported else { throw ThoughtProcessorError.network("App Attest unavailable") }
        let keyID: String
        if let saved = UserDefaults.standard.string(forKey: keyDefaultsKey) { keyID = saved }
        else {
            keyID = try await service.generateKey()
            UserDefaults.standard.set(keyID, forKey: keyDefaultsKey)
        }
        let hash = Data(SHA256.hash(data: body))
        let assertion = try await service.generateAssertion(keyID, clientDataHash: hash)
        return (keyID, assertion)
    }
}
