import Foundation
import Persistence

/// Records the user's explicit opt-in to Enhanced mode (FR-15). Default is "no consent".
public protocol ConsentStore: Sendable {
    var hasConsented: Bool { get }
}

public struct StaticConsent: ConsentStore {
    public var hasConsented: Bool
    public init(_ value: Bool) { hasConsented = value }
}

/// Produces an App Attest assertion for a request body. Implemented in the app target with DCAppAttestService.
public protocol AttestationProvider: Sendable {
    func assertion(for body: Data) async throws -> (keyID: String, assertion: Data)
}

public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    public init() {}
    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }
}

/// Opt-in cloud processing. Sends only the transcript text (never audio). Makes no network call unless consent is recorded.
public struct CloudProcessor: ThoughtProcessor {
    public let endpoint: URL
    private let consent: ConsentStore
    private let attestation: AttestationProvider
    private let transport: HTTPTransport
    public var version: String { "\(Prompt.version)+cloud" }

    public init(endpoint: URL, consent: ConsentStore, attestation: AttestationProvider, transport: HTTPTransport = URLSessionTransport()) {
        self.endpoint = endpoint; self.consent = consent; self.attestation = attestation; self.transport = transport
    }

    public func structure(transcript: String, script: ChineseScript) async throws -> StructuredThought {
        guard consent.hasConsented else { throw ThoughtProcessorError.consentRequired }   // before ANY network activity, attestation included
        let body = try JSONEncoder().encode(["transcript": transcript, "script": script.rawValue, "promptVersion": Prompt.version])
        let attested = try await attestation.assertion(for: body)
        var request = URLRequest(url: endpoint.appendingPathComponent("structure"))
        request.httpMethod = "POST"
        request.httpBody = body
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(attested.keyID, forHTTPHeaderField: "X-App-Attest-Key-Id")
        request.setValue(attested.assertion.base64EncodedString(), forHTTPHeaderField: "X-App-Attest-Assertion")
        let (data, http) = try await transport.send(request)
        guard (200..<300).contains(http.statusCode) else { throw ThoughtProcessorError.network("HTTP \(http.statusCode)") }
        return try SchemaValidator.decode(data)
    }
}
