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

## 1. AI keys — production-safe setup

AI provider keys belong in **Supabase Edge Function secrets**, not in Flutter.
Mobile apps can be decompiled, so shipping `OPENAI_API_KEY` or `CLAUDE_API_KEY`
inside `.env` is not safe for production.

Use:

- **Claude API** for planning/writing: summaries, bullets, LinkedIn, interview
  prep, skills, cover letters.
- **OpenAI API** for vision/extraction/ATS: uploaded files/photos and ATS JSON.

Set them server-side:

```bash
supabase secrets set \
  CLAUDE_API_KEY=sk-ant-... \
  CLAUDE_MODEL=claude-3-5-sonnet-20241022 \
  OPENAI_API_KEY=sk-...
```

If Supabase is not configured, the app uses deterministic mock AI responses so
screens are still testable.

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
   supabase functions deploy ai-plan
   supabase functions deploy ai-generate
   supabase functions deploy ats-check
   supabase functions deploy cover-letter
   supabase functions deploy ai-extract
   supabase functions deploy create-checkout
   supabase functions deploy stripe-webhook --no-verify-jwt
   ```
4. Set server-side secrets:

   ```bash
   supabase secrets set CLAUDE_API_KEY=sk-ant-... OPENAI_API_KEY=sk-... \
     STRIPE_SECRET_KEY=sk_test_... \
     STRIPE_WEBHOOK_SECRET=whsec_... STRIPE_PRICE_ID=price_...
   ```
5. **Google sign-in:** enable the Google provider in Supabase and add the
   `applymate://login-callback` redirect (see `supabase/README.md`).
6. Rebuild the app. With Supabase configured, AI automatically routes through the
   Edge Functions.

---

## 3. Google Places — address autocomplete (optional)

Powers suggestions on the **Location / address** field in the Resume Builder.
Without it, that field is a normal text input.

1. Go to <https://console.cloud.google.com> → create/select a project.
2. **APIs & Services → Library** → enable **"Places API"** (and ensure billing is on).
3. **APIs & Services → Credentials → Create credentials → API key** → copy it (starts with `AIza...`).
4. **Restrict the key** (recommended): Application restriction → Android apps (package
   `com.example.applymate` + your SHA-1); API restriction → Places API only.
5. In `.env`:

   ```env
   GOOGLE_PLACES_API_KEY=AIza...your-key
   ```
6. Rebuild. Start typing an address in the builder and suggestions appear.

## 4. Stripe — subscriptions (optional for dev)

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
| `CLAUDE_API_KEY` | Supabase secret only | AI planning/writing |
| `OPENAI_API_KEY` | Supabase secret only | File/photo extraction, ATS |
| `SUPABASE_URL` | App `.env` (public) | Auth, DB, storage, server AI |
| `SUPABASE_ANON_KEY` | App `.env` (public, safe with RLS) | Same as above |
| `STRIPE_PUBLISHABLE_KEY` | App `.env` (public) | Checkout |
| `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` / `STRIPE_PRICE_ID` | Supabase secret **only** | Billing |

After any `.env` change: **full rebuild**, not hot reload.
