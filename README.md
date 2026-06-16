# Resume Builder (Flutter)

An AI-assisted resume builder: fill in your details, let AI tighten up your
bullet points, pick from 3 templates, and export/share a PDF. Built for
Android & iOS.

## Important — read this first

This project was written without access to the Flutter SDK (the build
environment that generated it has no internet access to pub.dev and no
Flutter installed), so it has **not been compiled or run**. The code is
complete and should work, but there may be a small typo or import issue
here and there. If you hit an error when you run it, paste me the exact
error message and I'll fix it immediately.

## 1. Set up the project

You'll need Flutter installed locally (`flutter --version` to check).

```bash
flutter create resume_builder
cd resume_builder
```

This generates the `android/` and `ios/` native folders for you (not
included in this download — that's normal, `flutter create` always
generates them fresh).

Now replace the generated `lib/` folder and `pubspec.yaml` with the ones
from this download, then:

```bash
flutter pub get
flutter run
```

## 2. Project structure

```
lib/
  main.dart                      # app entry point
  theme/app_theme.dart           # colors, fonts, the 3 template styles
  models/resume_data.dart        # UserGoals, PersonalInfo, Education, Experience, ResumeData
  providers/resume_provider.dart # holds all resume state (Provider/ChangeNotifier)
  services/ai_service.dart       # calls your backend: improve a bullet, or parse+improve a whole resume
  widgets/bullet_editor.dart     # the bullet list + "Improve with AI" button
  screens/
    home_screen.dart             # "Create New Resume" or "Import Existing Resume"
    import_resume_screen.dart    # paste an old resume, AI restructures it into the wizard below
    resume_builder_screen.dart   # wizard that pages through the 5 steps below
    steps/goals_step.dart        # NEW: target field/title/experience level + what to highlight
    steps/personal_info_step.dart
    steps/education_step.dart
    steps/experience_step.dart
    steps/skills_step.dart
    template_screen.dart         # pick Classic / Modern / Minimal
    preview_screen.dart          # PDF preview + share/print
  templates/resume_pdf_builder.dart  # generates the actual PDF per template
```

### What's new in this version

- **Goals step (first screen in the wizard).** Asks target industry/field,
  target job title, experience level, and which things matter most
  (Leadership, Technical skills, Results, etc. — multi-select chips). These
  answers are passed into every "Improve with AI" bullet call so the
  rewrite is tailored, not generic.
- **Import Existing Resume (from the home screen).** A text box where the
  user pastes their whole current resume. AI parses it into the same
  structured fields (contact info, experience + bullets, education,
  skills) and improves the wording, then drops them straight into the
  normal wizard for review/editing before export.

## 3. Wiring up the real AI feature (important)

Right now `ai_service.dart` is in **mock mode** — it returns fake results so
you can test the whole app flow immediately without any backend:

- "Improve with AI" on a bullet returns the same text with a note appended,
  confirming the call worked.
- "Analyze & Improve with AI" on the import screen does a rough best-effort
  guess (pulls out an email/phone, guesses the name from the first line)
  and drops everything else into one experience entry for you to split
  manually — it's a placeholder, not real parsing.

**Do not** put your Anthropic/OpenAI API key directly in the Flutter app.
Mobile app binaries can be decompiled, and anyone could pull the key out and
rack up charges on your account. Instead:

1. Build a tiny backend with two endpoints. Easiest options:
   - A Cloudflare Worker (free tier is generous, no server to manage)
   - A Firebase Cloud Function
   - A small Node/Express app on Render or Railway
2. **POST /improve-bullet** — receives `{ bullet, role, company, targetField,
   targetJobTitle, priorities }`, calls the AI API server-side, returns
   `{ improved: "..." }`.
3. **POST /parse-resume** — receives `{ resumeText }`, prompts the AI to
   return the exact JSON shape documented in `ai_service.dart` (personalInfo,
   education[], experience[] with bullets[], skills[]), and returns that
   JSON directly.
4. In `lib/services/ai_service.dart`, set `_improveUrl` and `_parseUrl` to
   your endpoints and flip `_useMockFallback` to `false`.

I can build that backend with you next — it's a small job, maybe 60-80 lines
of code for both endpoints, and is the same pattern your existing job-application
tool likely already needs.

## 4. Known limitations / good next steps

- **No persistence yet.** Everything lives in memory (`ResumeProvider`), so
  closing the app loses your data. Adding the `shared_preferences` or
  `hive` package to save/load a resume locally would be the natural next
  step, especially if you want to support multiple saved resumes.
- **No form validation.** Empty/invalid emails etc. are currently allowed.
- **Only one resume at a time.** Multi-resume support (e.g. "Resume for
  retail roles" vs "Resume for dev roles") would need a list of ResumeData
  objects plus a "My Resumes" screen.
- **Templates are visually distinct but basic.** Easy to extend — add a 4th
  `TemplateStyle` in `app_theme.dart` and a matching `_buildXLayout` in
  `resume_pdf_builder.dart`.

## 5. Monetization ideas (since this is a side hustle)

- Free tier: 1 template, limited AI improvements/month.
- Paid tier: all templates, unlimited AI rewrites, PDF export without a
  watermark — via `in_app_purchase` or RevenueCat for subscriptions.
