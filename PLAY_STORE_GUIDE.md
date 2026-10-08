# Google Play Store Release & Deployment Guide

This guide provides exact step-by-step instructions to build, sign, and publish **Sheep Farm Manager** to the Google Play Store.

---

## 1. Prerequisites Check

- **Package Name:** `com.sheepmanager.app`
- **Minimum SDK:** 21 (Android 5.0)
- **Target SDK:** 34 (Android 14 - compliant with Google Play Console 2024/2025/2026 mandates)
- **App Version:** `1.0.0` (Version code: `1`)
- **App Icon:** `512x512 PNG` located in `assets/icons/app_icon.png` and mipmap folders.

---

## 2. Generate Release Keystore (One-Time Setup)

Open PowerShell or terminal in your project directory and run:

```powershell
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

*Note: You will be prompted to enter a password and your developer name/organization. Save the keystore and password in a safe place.*

---

## 3. Create `key.properties` for Signing

Create a file named `android/key.properties` with the following content (replace with your password):

```properties
storePassword=your_keystore_password
keyPassword=your_keystore_password
keyAlias=upload
storeFile=upload-keystore.jks
```

*Ensure `android/key.properties` is included in your `.gitignore` to keep credentials secure.*

---

## 4. Build the Release Android App Bundle (.aab)

Google Play requires an **Android App Bundle (.aab)** format instead of `.apk`.

Run the following command in terminal:

```bash
flutter build appbundle --release
```

When finished, your signed release bundle will be available at:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## 5. Google Play Console Setup

1. Open [Google Play Console](https://play.google.com/console).
2. Click **Create App**:
   - **App name:** `Sheep Farm Manager`
   - **Default language:** English (or preferred language)
   - **App or game:** App
   - **Free or paid:** Free
3. **Store Listing Details**:
   - **Short Description (max 80 chars):**
     *Complete sheep farm management: flock records, breeding, health & finance.*
   - **Full Description:**
     *Sheep Farm Manager is an all-in-one offline livestock tracking solution built for sheep farmers, shepherds, and commercial breeders. Easily log your flock with digital ear tags, monitor breeding and estimated lambing dates, schedule vaccinations and medical treatments with notifications, record weight gains with visual growth charts, and track farm sales and expenses. Includes secure Google Cloud backup and JSON export.*
   - **App Icon:** Upload `assets/icons/app_icon.png` (512x512).
   - **Feature Graphic:** 1024x500 banner highlighting key features.
4. **App Content & Policies**:
   - **Privacy Policy:** Paste the URL where `PRIVACY_POLICY.md` is hosted (e.g. GitHub Pages or your farm website).
   - **Target Audience:** General (18 and above).
   - **Data Safety:** Declare that data is encrypted in transit, stored locally, and optionally synced to user's Google Cloud storage.
5. **Production Release**:
   - Go to **Release > Production** > **Create new release**.
   - Upload `build/app/outputs/bundle/release/app-release.aab`.
   - Enter Release Notes: *"Initial release of Sheep Farm Manager v1.0.0"*.
   - Review and rollout release to Production!

---

## 6. Python Suite Companion

For desktop management or local backup sync:
```bash
cd python_service
python cli.py           # Launch interactive CLI
python server.py        # Launch local REST API and sync server on http://localhost:8080
python reports.py       # Generate flock inventory and financial CSV spreadsheets
```
