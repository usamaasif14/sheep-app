# 📱 How to Test & Install Sheep Farm Manager on Your Mobile Phone

You have **3 simple options** to test and install the app on your mobile device:

---

## 🚀 Option 1: Test on Your Mobile Phone RIGHT NOW (Instant - No Setup Required!)

Your computer is already running a live mobile test server on your local Wi-Fi network!

1. Make sure your mobile phone is connected to the same Wi-Fi network as your computer.
2. Open Chrome (or any browser) on your mobile phone.
3. Type this URL into your phone's browser address bar:
   ```
   http://192.168.1.8:8080
   ```
4. **Result:** You will see the Sheep Farm Manager mobile interface immediately! You can register sheep with tags, test flock metrics, log financial sales and expenses, and verify everything right on your physical phone!

*(Tip on Android: In Chrome, tap the 3 dots menu `⋮` and select **"Add to Home screen"** to install it like a real app icon on your phone!)*

---

## 📦 Option 2: Build the Native Android `.apk` File on Your PC

To compile the native Android installation file (`.apk`), Flutter and the Android build tools are required on your PC:

### Step 1: Install Flutter SDK
1. Download the Flutter SDK for Windows from: [https://docs.flutter.dev/get-started/install/windows/mobile](https://docs.flutter.dev/get-started/install/windows/mobile)
2. Extract the zip file (e.g., to `C:\src\flutter`).
3. Add `C:\src\flutter\bin` to your Windows System `PATH` environment variable.

### Step 2: Install Android Studio & Command Line Tools
1. Download and install [Android Studio](https://developer.android.com/studio).
2. Open Android Studio → **SDK Manager** → **SDK Tools** tab.
3. Check and install:
   - **Android SDK Build-Tools**
   - **Android SDK Command-line Tools**
4. Run `flutter doctor` in PowerShell to verify everything is green.

### Step 3: Build the `.apk`
In your project directory (`d:\Development\Sheep App`), run:

```bash
flutter build apk --release
```

When the build finishes, your APK file will be ready at:
```
d:\Development\Sheep App\build\app\outputs\flutter-apk\app-release.apk
```

### Step 4: Install on Your Phone
1. Send `app-release.apk` to your phone via:
   - USB cable
   - Google Drive or Dropbox
   - WhatsApp / Telegram (sent to yourself)
2. On your Android phone, tap the file `app-release.apk`.
3. If prompted, toggle **"Allow from this source"** (enable Install Unknown Apps).
4. Tap **Install** and open the app!

---

## ☁️ Option 3: Free 1-Click Cloud APK Build (Using GitHub Actions)

If you don't want to download 15GB of Android Studio on your PC, you can let GitHub build the APK for you in the cloud for free:

1. Push this project to your GitHub account (public or private):
   ```bash
   git init
   git add .
   git commit -m "Sheep farm manager app"
   git remote add origin https://github.com/YOUR_USERNAME/sheep-app.git
   git push -u origin main
   ```
2. In your GitHub repository, click the **Actions** tab.
3. GitHub will automatically run the `.github/workflows/build_apk.yml` workflow and compile `app-release.apk`.
4. Click on the completed workflow and download **`sheep-manager-release-apk`**.
5. Transfer and install the `.apk` directly on your Android phone!
