# ApplyMate — Supabase backend

Database schema, Row Level Security, storage policies, and Edge Functions for
ApplyMate. Mirrors blueprint Parts D (schema), G (AI), H (Stripe), and L (security).

Until these are deployed and the Flutter `.env` is filled, the app runs in **mock
mode** (see `lib/services/supabase_service.dart`).

## Layout

```
supabase/
├── config.toml                  # CLI config (stripe-webhook has verify_jwt=false)
├── migrations/
│   └── 0001_init.sql            # 11 tables, RLS, storage bucket+policies, delete_user()
└── functions/
    ├── _shared/                 # cors, auth/rate-limit, openai prompt helpers
    ├── ai-generate/             # Part G3 — summary, bullet, linkedin, skills, interview
    ├── ats-check/               # ATS score + keyword analysis
    ├── cover-letter/            # 3 formats (full / short email / recruiter)
    ├── create-checkout/         # Part H3 — Stripe Checkout session
    └── stripe-webhook/          # Part H4 — sync subscription status
```

## One-time setup

1. Create a project at https://supabase.com, then install the CLI
   (https://supabase.com/docs/guides/cli) and log in:
   ```bash
   supabase login
   ```
2. From the repo root, link to your project (find the ref in Project Settings → General):
   ```bash
   supabase link --project-ref <your-project-ref>
   ```

## Deploy the database

```bash
supabase db push          # applies migrations/0001_init.sql
```
This creates all tables with RLS, the `documents` storage bucket + per-user
folder policies, the profile-on-signup trigger, and `delete_user()`.

## Deploy the Edge Functions

```bash
supabase functions deploy ai-generate
supabase functions deploy ats-check
supabase functions deploy cover-letter
supabase functions deploy create-checkout
supabase functions deploy stripe-webhook --no-verify-jwt
```
(`stripe-webhook` must skip JWT verification — Stripe calls it unauthenticated and
it verifies the signing secret instead. `config.toml` already sets this for local
serve; the flag is still required on `deploy`.)

## Set Edge Function secrets

Never put these in the Flutter app (blueprint Part L2). `SUPABASE_URL`,
`SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically;
set the rest:

```bash
supabase secrets set \
  OPENAI_API_KEY=sk-... \
  STRIPE_SECRET_KEY=sk_test_... \
  STRIPE_WEBHOOK_SECRET=whsec_... \
  STRIPE_PRICE_ID=price_...
```

## Stripe configuration (Part H1)

1. Create a **Pro** product: AUD $14.99 / month, 7-day free trial → copy its **Price ID**.
2. Add a webhook endpoint pointing at:
   `https://<project-ref>.functions.supabase.co/stripe-webhook`
   Enable events: `customer.subscription.created`, `customer.subscription.updated`,
   `customer.subscription.deleted`, `invoice.payment_failed`. Copy the **signing
   secret** into `STRIPE_WEBHOOK_SECRET`.

## Point the Flutter app at the backend

Fill `.env` in the repo root (copy from `.env.example`). Real (non-`your-…`)
values flip the app out of mock mode:

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon key from Project Settings → API>
STRIPE_PUBLISHABLE_KEY=pk_test_...   # publishable (public) key only
```

## Verify

- DB: Supabase Studio → Table editor shows all tables with RLS enabled.
- Functions: `supabase functions list` shows all five deployed.
- AI: from the app (signed in), trigger an AI action — `ai_generation_logs` gets a row.
- Stripe: use a test card on Checkout; `stripe-webhook` flips `subscriptions.status`
  to `trialing` and `payment_events` records the event.
