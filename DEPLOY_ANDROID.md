# Android Deployment Guide — ApplyMate

## Prerequisites
- Flutter SDK installed (`flutter doctor` passes)
- Java 17+ installed
- Android SDK with API 36 (set in build.gradle.kts)

---

## Step 1 — Generate a release keystore (one-time)

Run this in your terminal (outside the project):

```bash
keytool -genkey -v \
  -keystore ~/applymate-release.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias applymate
```

When prompted, fill in your name/org details and pick a strong password.

---

## Step 2 — Create `android/key.properties`

Create the file `android/key.properties` (already git-ignored):

```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=applymate
storeFile=/Users/YOUR_NAME/applymate-release.jks
```

> **Never commit this file.** It's already in `.gitignore`.

---

## Step 3 — Build the release APK (sideload / direct install)

```bash
cd resume-builder
flutter pub get
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Transfer this APK to your Android device and install it.

---

## Step 4 — Build App Bundle (Google Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload this `.aab` file to Google Play Console → Production or Internal Testing.

---

## Google Play Console checklist

- [ ] App name: **ApplyMate**
- [ ] Package name: `com.applymate.app`
- [ ] Upload `app-release.aab`
- [ ] Add screenshots (at least 2 phone screenshots)
- [ ] Fill in store listing (short + full description)
- [ ] Set content rating
- [ ] Add privacy policy URL (required)
- [ ] Submit for review

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `key.properties not found` | Make sure the file is at `android/key.properties`, not `android/app/` |
| `minSdk` error | Run `flutter doctor` and check Android SDK version |
| Build fails on compileSdk 36 | Run `sdkmanager "platforms;android-36"` |
| App crashes on launch | Run `flutter run --release` with a device connected to see logs |

---

## iOS (later)

When ready for iOS:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Set Bundle Identifier to `com.applymate.app`
3. Sign with your Apple Developer account
4. Archive → Distribute via App Store Connect
