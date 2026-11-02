# Enhanced-mode proxy

One serverless endpoint, `POST /structure`, for the opt-in Enhanced mode (FR-15). It holds the API key, checks App Attest,
validates the model output against the same schema as the app, and stores nothing.

    npm install && npm test
    wrangler secret put ANTHROPIC_API_KEY
    npm run deploy

Then set `AppConfig.cloudEndpoint` in the app. **Before shipping Enhanced mode**, implement full App Attest verification in
`src/attest.ts` (it currently refuses every request unless `ATTEST_MODE=dev`), and add per-key rate limiting.
