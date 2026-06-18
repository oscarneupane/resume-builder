# ApplyMate — Setup & API Keys

The app reads configuration from a git-ignored **`.env`** file in the project root.
A template lives in [`.env.example`](.env.example) — copy it to `.env` and fill in keys.

```bash
cp .env.example .env
```

> **Important:** `.env` is bundled as a Flutter **asset at build time**. After you
> edit it you must do a **full rebuild** (`flutter run` / reinstall the APK).
> A hot reload or hot restart will **not** pick up the new values.

The app runs in **mock mode** until real keys are present, so every screen works
offline for development. Add keys to switch features to live data.

---

## 1. OpenAI — make the AI actually work (quickest win)

This powers AI summary, ATS check, cover letters, LinkedIn, interview answers,
and the "scan a file/photo" import.

1. Go to <https://platform.openai.com> → **Settings → API keys → Create new secret key**.
2. Set up billing (**Settings → Billing**) — the key won't work without credit. Set a low usage limit while testing.
3. In `.env`, replace the placeholder value (keep the name):

   ```env
   OPENAI_API_KEY=sk-your-real-key
   ```
   No quotes, no spaces around `=`. Any value starting with `sk-your` is treated as "not set".

4. **Rebuild:** stop the app, then `flutter run` (hot reload is not enough).

How it routes (see `lib/services/ai_service.dart`):
`Supabase configured → Edge Function` → else `OPENAI_API_KEY set → call OpenAI directly` → else `mock`.

> ⚠️ A key in `.env` is **bundled into the app build** — fine for dev/testing, **not** for a
> public release. For production, deploy the Edge Functions and store the key as a
> Supabase secret instead (see below). Keep `SUPABASE_URL`/`SUPABASE_ANON_KEY` as
> placeholders while using the direct-OpenAI path, or the app will call the
> (not-yet-deployed) Edge Functions.

---

## 2. Supabase — auth, database, storage, server-side AI (production path)

1. Create a project at <https://supabase.com>.
2. **Project Settings → API**: copy the **Project URL** and **anon key** into `.env`:

   ```env
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
3. Deploy the schema + functions (full steps in [`supabase/README.md`](supabase/README.md)):

   ```bash
   supabase link --project-ref <your-project-ref>
   supabase db push
   supabase functions deploy ai-generate
   supabase functions deploy ats-check
   supabase functions deploy cover-letter
   supabase functions deploy ai-extract
   supabase functions deploy create-checkout
   supabase functions deploy stripe-webhook --no-verify-jwt
   ```
4. Set server-side secrets (the OpenAI key lives here in production, never in the app):

   ```bash
   supabase secrets set OPENAI_API_KEY=sk-... STRIPE_SECRET_KEY=sk_test_... \
     STRIPE_WEBHOOK_SECRET=whsec_... STRIPE_PRICE_ID=price_...
   ```
5. **Google sign-in:** enable the Google provider in Supabase and add the
   `applymate://login-callback` redirect (see `supabase/README.md`).
6. Rebuild the app. With Supabase configured, AI automatically routes through the
   Edge Functions.

---

## 3. Stripe — subscriptions (optional for dev)

Only the **publishable** key goes in the app; secret/webhook keys are Supabase secrets.

```env
STRIPE_PUBLISHABLE_KEY=pk_test_your_key
```
Create the AUD $14.99/mo product with a 7-day trial and the webhook endpoint as
described in `supabase/README.md`.

---

## Quick reference — `.env`

| Key | Where it's safe | Needed for |
|-----|-----------------|-----------|
| `OPENAI_API_KEY` | App `.env` (dev only) **or** Supabase secret (prod) | All AI features |
| `SUPABASE_URL` | App `.env` (public) | Auth, DB, storage, server AI |
| `SUPABASE_ANON_KEY` | App `.env` (public, safe with RLS) | Same as above |
| `STRIPE_PUBLISHABLE_KEY` | App `.env` (public) | Checkout |
| `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` / `STRIPE_PRICE_ID` | Supabase secret **only** | Billing |

After any `.env` change: **full rebuild**, not hot reload.
