# ApplyMate

AI-powered job-application assistant for Android (Flutter). Build ATS-friendly
resumes, cover letters, LinkedIn copy, and interview answers — and let AI scan
your uploaded files to reuse your real info everywhere.

> The app runs in **mock mode** out of the box (no keys needed) so every screen
> works for development. Add Supabase secrets to switch on real AI and the backend — see
> **[SETUP.md](SETUP.md)**.

## Quick start

```bash
flutter pub get
cp .env.example .env      # then add your keys (optional for mock mode)
flutter run
```

For real AI, deploy the Supabase backend and set provider keys as Edge Function
secrets (`CLAUDE_API_KEY`, `OPENAI_API_KEY`). Do not ship provider keys inside
the Flutter app. Full steps are in **[SETUP.md](SETUP.md)**.

## Features

- **Resume Builder** — 7-step builder, live preview, 3 templates, PDF export
- **Smart Import** — upload a resume photo/PDF or paste text; AI extracts and pre-fills the builder
- **My Materials** — upload pics/PDFs/notes; AI scans them into reusable data, available as context in generators
- **ATS Checker** — paste a job description, get a score + keyword analysis
- **Cover Letter** — 3 formats (full / short email / recruiter) with tone selection
- **LinkedIn Helper** — headline, About, recruiter message, skill suggestions
- **Interview Prep** — 10 role questions, each with a STAR answer
- **Job Tracker** — Kanban pipeline (Saved → Applied → Interview → Offer → Rejected)
- **Documents** — saved/exported PDFs
- **Auth** — email/password + Google sign-in; subscription (Stripe) screens

## Architecture

- **Flutter** (Riverpod state, GoRouter navigation), feature-based folders under `lib/features/`.
- **Services** (`lib/services/`) gate on configuration: real **Supabase** /
  server-side **AI** / **Stripe** when configured, otherwise mock — so the app always runs.
- **Supabase backend** (`supabase/`): 13 tables with RLS, storage buckets, and
  6 Edge Functions (AI generate/extract/ATS/cover-letter + Stripe checkout/webhook).
  Deploy steps in **[supabase/README.md](supabase/README.md)**.

## Configuration

| File | Purpose |
|------|---------|
| [`.env`](.env.example) | App-side public keys only (Supabase URL/anon, Stripe publishable, Google Places). Git-ignored. |
| [`SETUP.md`](SETUP.md) | Step-by-step: how to insert API keys and go live. |
| [`supabase/README.md`](supabase/README.md) | Deploy the DB schema + Edge Functions + secrets. |

## Tests

```bash
flutter analyze
flutter test
```
