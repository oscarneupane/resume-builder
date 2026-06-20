# ApplyMate — Play Store upload package

Console link: https://play.google.com/console  (one-time $25 developer fee)

---

## 1) Build the file to upload (your machine)
```bash
# a) one-time keystore (BACK IT UP — losing it = can't update the app)
keytool -genkey -v -keystore android/app/applymate-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias applymate
# b) create android/key.properties from android/key.properties.example (fill passwords)
# c) build the App Bundle
flutter build appbundle
# -> upload: build/app/outputs/bundle/release/app-release.aab
```

## 2) Files to upload (already in this repo)
| Slot | File |
|------|------|
| App bundle (.aab) | build/app/outputs/bundle/release/app-release.aab (after step 1) |
| App icon (512x512) | assets/icon/icon_store_512.png |
| Feature graphic (1024x500) | assets/store/feature_graphic.png |
| Phone screenshot 1 | assets/store/screenshot_1_dashboard.png |
| Phone screenshot 2 | assets/store/screenshot_2_resumes.png |
| Phone screenshot 3 | assets/store/screenshot_3_builder.png |

## 3) Text to paste
**App name:** ApplyMate

**Short description (<=80 chars):**
AI resume builder, cover letters, ATS checker & interview prep — all free.

**Full description:**
ApplyMate — Smart Documents. Better Applications. More Confidence.

ApplyMate is your AI-powered job-application assistant. Turn a rough draft into a polished, ATS-friendly resume, generate tailored cover letters in seconds, and walk into interviews prepared — all in one free app. ApplyMate is not a job board; it gives you the tools to apply with confidence.

AI Resume Builder
Build a clean, ATS-optimized resume step by step — or let AI write the whole thing from your details. Export to a polished PDF in one tap.

Cover Letters from a job post
Screenshot or paste a job ad and AI writes a tailored cover letter using your details, in three formats: full letter, short email, and recruiter message.

ATS Checker
Paste a job description and see how your resume scores, with matched and missing keywords, so you can get past applicant tracking systems.

More tools
• LinkedIn headline & "About" generator
• Interview prep: role-specific questions, STAR answers, and AI feedback on your own answers
• Job tracker: saved -> applied -> interview -> offer
• Smart Import: scan an existing resume photo or PDF and reuse your info everywhere
• Address autocomplete, premium PDF export, secure cloud storage

Private & secure
Your data is protected with row-level security — only you can access it. Export or delete your data anytime from Settings. We never sell your data or use your content to train AI models.

100% free. No subscriptions, no in-app purchases.

Built for job seekers who want to apply faster and stand out.

**App category:** Productivity (or Business)
**Contact email:** your support email
**Privacy policy URL:** https://oscarneupane.github.io/resume-builder/privacy.html

## 4) Form answers
**Content rating:** answer the questionnaire honestly — no violence/sexual/gambling content -> rated "Everyone".

**Data safety (declare you collect):**
- Personal info: name, email (account) — collected, encrypted in transit, user can request deletion
- App activity / user content: resumes, cover letters, job applications — collected, not shared, deletable
- Data is NOT sold; users can delete their account/data in-app (Settings -> Data & Privacy)

**Target audience:** 18+ (or 13+); not directed at children.

## 5) Release flow
Internal testing (upload .aab, add your email as tester, install & verify) -> Closed/Open testing (optional) -> Production -> submit for review (first review ~1-7 days).
