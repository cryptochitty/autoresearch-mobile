# AutoResearch — CI/CD Deployment Guide

> Deploy Android & iOS automatically via GitHub + Codemagic (or GitHub Actions)
> Note: Vercel is for web apps only. For Flutter mobile apps, use Codemagic or GitHub Actions.

---

## Architecture

```
GitHub (code push)
    ↓
Codemagic / GitHub Actions (build + sign)
    ↓                    ↓
Play Store (Android)   App Store (iOS)
```

---

## OPTION A — Codemagic (Easiest, Recommended)

Codemagic builds both Android and iOS in the cloud. No Mac required for iOS.

### Step 1 — Sign Up
1. Go to codemagic.io
2. Click **Sign up with GitHub**
3. Authorize access to your repos

### Step 2 — Add App
1. Click **Add application**
2. Select **GitHub** → choose `cryptochitty/autoresearch-mobile`
3. Framework: **Flutter App**
4. Click **Finish: Add application**

### Step 3 — Configure Android Build
1. Go to **Workflow Editor** → **Android**
2. Under **Build**:
   - Flutter version: `3.27.4`
   - Build format: `Android App Bundle (.aab)`
   - Build mode: `release`
3. Under **Distribution** → Google Play:
   - Upload `google-services.json` (from Firebase)
   - Add your keystore file
   - Set keystore password, key alias, key password

### Step 4 — Configure iOS Build
1. Under **iOS** → **Build**:
   - Build mode: `release`
   - Xcode version: latest
2. Under **Code signing**:
   - Upload your Apple Distribution certificate (.p12)
   - Upload your provisioning profile
3. Under **Distribution** → App Store Connect:
   - Add your App Store Connect API key

### Step 5 — Set Environment Variables
In Codemagic → Environment variables, add:
```
ANTHROPIC_API_KEY = your_key
REVENUECAT_ANDROID_KEY = your_key
REVENUECAT_IOS_KEY = your_key
```

### Step 6 — Auto-deploy on Push
1. Go to **Triggers**
2. Enable **Trigger on push** for branch `main`
3. Every `git push` to main will auto-build and upload to stores

---

## OPTION B — GitHub Actions (Free, Manual Setup)

### Step 1 — Add Secrets to GitHub
Go to your repo → Settings → Secrets → Actions → Add:

```
KEYSTORE_BASE64        # base64 encoded keystore file
KEYSTORE_PASSWORD      # keystore password
KEY_ALIAS              # key alias
KEY_PASSWORD           # key alias password
GOOGLE_PLAY_JSON       # service account JSON for Play Store upload
ANTHROPIC_API_KEY      # your AI key
```

To encode keystore:
```bash
base64 -i upload-keystore.jks | pbcopy   # Mac
certutil -encode upload-keystore.jks tmp.b64 && type tmp.b64  # Windows
```

### Step 2 — Create Workflow File
Create `.github/workflows/android-release.yml`:

```yaml
name: Android Release

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.4'
          channel: 'stable'

      - name: Decode keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties <<EOF
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=upload-keystore.jks
          EOF

      - name: Install dependencies
        run: flutter pub get

      - name: Build AAB
        run: flutter build appbundle --release

      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_JSON }}
          packageName: com.cryptochitty.autoresearch
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
```

### Step 3 — iOS Workflow (requires Mac runner — paid GitHub Actions)
Create `.github/workflows/ios-release.yml`:

```yaml
name: iOS Release

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.4'

      - name: Install dependencies
        run: flutter pub get

      - name: Build iOS
        run: flutter build ios --release --no-codesign

      - name: Sign and upload
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/iphoneos/Runner.app
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

---

## Backend Deployment (Render — Already Live)

Your Flask backend auto-deploys from GitHub via Render.

### Auto-deploy setup (if not already on)
1. Go to render.com → your service
2. Settings → **Auto-Deploy**: Enable
3. Connect to: `cryptochitty/autoResearch` branch `main`

Every push to `autoResearch` main branch → Render rebuilds automatically.

---

## Vercel — Web Version (Optional)

Vercel cannot deploy Flutter mobile apps. However you can deploy a **Flutter Web** version.

### Deploy Flutter Web to Vercel

#### Step 1 — Build web
```bash
flutter build web --release
```
Output: `build/web/`

#### Step 2 — Create `vercel.json` in project root
```json
{
  "buildCommand": "flutter/bin/flutter build web --release",
  "outputDirectory": "build/web",
  "installCommand": "bash scripts/install_flutter.sh"
}
```

#### Step 3 — Create `scripts/install_flutter.sh`
```bash
#!/bin/bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1
flutter/bin/flutter config --enable-web
flutter/bin/flutter pub get
```

#### Step 4 — Deploy
```bash
npm i -g vercel
vercel --prod
```

Or connect your GitHub repo to vercel.com for auto-deploy on push.

---

## Release Checklist

### Before every release
- [ ] Bump version in `pubspec.yaml` (e.g. `1.0.1+2`)
- [ ] Test on real Android device
- [ ] Test on iOS simulator or TestFlight
- [ ] Check Firebase Auth is working
- [ ] Check RevenueCat subscription flow
- [ ] Verify `/ai/ask` backend is responding

### Version bump example
```yaml
version: 1.0.1+2   # format: versionName+versionCode
```
`versionCode` must increase with every Play Store upload.

---

## Quick Reference

| Platform | Tool | Build Command |
|----------|------|---------------|
| Android | Flutter | `flutter build appbundle --release` |
| iOS | Flutter + Xcode | `flutter build ios --release` |
| Web | Flutter | `flutter build web --release` |
| Backend | Render (auto) | `git push` to autoResearch repo |

| Service | Purpose | URL |
|---------|---------|-----|
| Codemagic | Mobile CI/CD | codemagic.io |
| GitHub Actions | Free CI/CD | github.com/features/actions |
| Render | Backend hosting | render.com |
| Vercel | Web hosting | vercel.com |
| Firebase | Auth + DB | console.firebase.google.com |
| RevenueCat | Subscriptions | app.revenuecat.com |
| Play Console | Android store | play.google.com/console |
| App Store Connect | iOS store | appstoreconnect.apple.com |
