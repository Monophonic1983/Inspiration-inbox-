export interface AttestEnv { ATTEST_MODE?: string }

/** Verifies the App Attest assertion sent by the app. Fails closed. */
export interface AttestVerifier { verify(keyId: string, assertionB64: string, body: string): Promise<boolean> }

/**
 * TODO(Phase 4, on a device): implement full App Attest verification:
 *  1. one-time POST /attest: verify the attestation object (CBOR, x5c chain to Apple's App Attest root, nonce, app id hash,
 *     counter 0) and store the public key + counter per keyId;
 *  2. per request: verify the assertion signature over sha256(body), check the app id hash, and require counter > stored counter.
 * Until then every request is refused unless ATTEST_MODE is "dev" (local testing only).
 */
export class UnimplementedVerifier implements AttestVerifier {
  async verify(): Promise<boolean> { return false; }
}

export function verifierFor(env: AttestEnv): AttestVerifier {
  if (env.ATTEST_MODE === "dev") return { verify: async (k, a) => k.length > 0 && a.length > 0 };
  return new UnimplementedVerifier();
}
