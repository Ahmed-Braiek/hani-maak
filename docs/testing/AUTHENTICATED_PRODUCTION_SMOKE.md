# Authenticated production smoke test

The production smoke workflow uses the existing **synthetic Mariem/Fatma** demo account. It is not a real clinical-user test. There is no special bypass or mock mode in the application.

## One-time GitHub Actions configuration

Repository owner: **Settings > Secrets and variables > Actions > Repository secrets**.

Create these two secrets using the **existing** confirmed Supabase Auth demo account. Do not paste the credentials into GitHub files, issues, pull requests, comments, or logs:

- `HANI_SMOKE_DEMO_EMAIL` — the dedicated synthetic Supabase Auth demo user's login email.
- `HANI_SMOKE_DEMO_PASSWORD` — that same user's current password.

The project URL and **publishable** Supabase key are public app configuration, already in the Flutter workflow, and are supplied by `production-smoke.yml`. No Supabase service-role/secret key is used. After rotating the publishable key, update the public setting in the workflow and Flutter deployment as appropriate.

The job only runs with credentials on `main`. Keep repository write access limited to reviewed contributors. Consider protecting the `main` branch and requiring review before deploying secret-bearing workflow changes.

## Execution

- GitHub Actions > **Production smoke test** > Run workflow (choose `main`).
- The workflow also runs on relevant changes pushed to `main`.
- It logs in to Supabase using the regular email/password Auth endpoint, checks the access token with `/auth/v1/user`, then passes `Authorization: Bearer ...` to both Hani endpoints.
- Negative tests verify missing/invalid authentication and unrelated-patient requests are rejected.
- Authenticated positive tests cover the voice token, live WebSocket handshake, and chat, plus Flutter hosting and agent health.

All access and voice tokens stay in Python process memory, and no response body, credentials or signed WebSocket URLs are printed. An absent GitHub secret produces an explicit failed check naming only the missing variable.

## Success criteria

The GitHub Actions run must finish green, including the authenticated chat and voice tests. Record the Actions run URL and verify the production Vercel deployment commit SHA at test time. A passed smoke test is not proof of clinical safety, real patient eligibility, comprehensive privacy/authorization security, or FHIR/openEHR integration.
