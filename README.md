# 🐑 Sheep Farm Manager (Flutter Android + Python Suite)

A comprehensive, production-ready sheep farm and flock management ecosystem engineered for commercial sheep farmers, breeders, and shepherds. Built with **Flutter (Android Mobile App)** and a **Python Management & Sync Backend Suite**.

---

## 🌟 Key Features

### 1. 🐑 Flock & Sheep Management
- **Individual Digital ID**: Unique tag numbers, photos, breed, gender, DOB, weight, color, mother ID, and father ID (pedigree tracking).
- **Flock Overview & Filters**: Filter by status (*Active*, *Sold*, *Deceased*, *Quarantine*) or gender (*Ewes*, *Rams*).
- **Search**: Instant search across tag numbers, names, and breeds.
- **Weight Tracking & Growth Velocity**: Log historical weigh-ins with interactive growth trend charts (`LineChart`).

### 2. 💉 Health, Vaccinations & Treatments
- **Health Logs**: Categorize records into *Vaccination*, *Treatment*, *Checkup*, and *Deworming*.
- **Medicine & Dosage Tracking**: Record prescribed medicine, dosage, dosage unit (`ml`, `mg`, `tablets`), and veterinarian name.
- **Automated Alerts & Push Reminders**: Scheduled local device notifications for upcoming booster vaccinations and deworming due dates.

### 3. 🧬 Breeding & Lambing Cycles
- **Mating Registry**: Record mating events linking ewes with active rams.
- **Lambing Predictor**: Automatically computes expected lambing dates based on standard gestation period (~147 days).
- **Lambing Logs**: Record actual lambing dates, total lambs born, and survival count.

### 4. 💰 Farm Financial Ledger & Analytics
- **Sales & Revenue**: Track income from live sheep sales, wool/shearing clips, meat, milk, and stud fees.
- **Operational Costs**: Track expenses for feed, alfalfa bales, medications, vet visits, shearing labor, and equipment.
- **Profit & Loss Metrics**: Real-time Net Profit / Loss calculation.
- **Visual Analytics**: 6-month monthly financial bar charts and category expense breakdown.

### 5. ☁️ Complete Data Backup & Sync
- **Local SQLite Database**: Full offline-first capability; works anywhere without requiring an active internet connection.
- **Google Cloud & Firebase Backup**: One-tap cloud backup and restore using Google Sign-In and Cloud Firestore / Storage.
- **JSON Offline Backup**: Export and import full database backup JSON files anytime.
- **Python Sync API**: Connect with the local Python server to sync data across devices.

---

## 📁 Project Architecture

```
Sheep App/
├── android/                             # Android Native Configuration (Google Play Ready)
│   ├── app/
│   │   ├── build.gradle                 # Target SDK 34, compileSdk 34, desugaring enabled
│   │   ├── proguard-rules.pro           # Proguard optimization rules
│   │   └── src/main/
│   │       ├── AndroidManifest.xml      # Camera, notification, and storage permissions
│   │       ├── kotlin/.../MainActivity.kt
│   │       └── res/                     # Mipmap launcher icons & splash themes
│   ├── build.gradle
│   ├── settings.gradle
│   └── gradle.properties
├── assets/
│   ├── icons/app_icon.png               # 512x512 High-res app launcher icon
│   └── images/splash_logo.png           # Splash screen branding
├── lib/                                 # Flutter Application Source Code
│   ├── models/                          # Data Models (Sheep, Health, Breeding, Finance)
│   ├── providers/                       # State Management (SheepProvider, FinanceProvider)
│   ├── screens/                         # UI Screens
│   │   ├── main_navigation.dart         # Bottom navigation bar
│   │   ├── dashboard_screen.dart        # Farm metrics, quick actions & charts
│   │   ├── sheep_list_screen.dart       # Flock list, grid, filters & search
│   │   ├── sheep_detail_screen.dart     # Comprehensive sheep profile (4 tabs)
│   │   ├── add_sheep_screen.dart        # Add/edit sheep form with photo picker
│   │   ├── health_screen.dart           # Health overview & upcoming medical tasks
│   │   ├── add_health_record_screen.dart# Health & vaccination logging
│   │   ├── breeding_screen.dart         # Breeding tracker & lambing schedule
│   │   ├── finance_screen.dart          # Income, expense ledger & financial charts
│   │   └── settings_screen.dart         # Cloud backup, JSON export & farm profile
│   ├── services/                        # Database, Backup & Notification Services
│   ├── utils/                           # Theme & Styling (Deep Forest & Gold Palette)
│   └── widgets/                         # Reusable UI Components
├── python_service/                      # Python Management & Sync Suite
│   ├── db_manager.py                    # SQLite engine with identical schema
│   ├── server.py                        # REST API server (zero-dependency http.server)
│   ├── cli.py                           # Interactive terminal management tool
│   ├── reports.py                       # CSV spreadsheet & HTML report generator
│   └── requirements.txt
├── PRIVACY_POLICY.md                    # Ready for Google Play Console compliance
├── PLAY_STORE_GUIDE.md                  # Step-by-step keystore & Play Store publishing guide
└── pubspec.yaml
```

---

## 🚀 How to Run

### 1. Flutter Android App
```bash
# Get dependencies
flutter pub get

# Run on connected Android device / emulator
flutter run

# Build production Android App Bundle (.aab) for Google Play Store
flutter build appbundle --release
```

### 2. Python Suite
The Python suite runs out-of-the-box on standard Python 3.8+ without mandatory external dependencies:

```bash
cd python_service

# Launch interactive CLI
python cli.py

# Launch REST API server on http://localhost:8080
python server.py

# Generate flock inventory & financial CSV spreadsheets
python reports.py
```

---

## 📦 Google Play Store Submission
Consult [PLAY_STORE_GUIDE.md](file:///d:/Development/Sheep%20App/PLAY_STORE_GUIDE.md) and [PRIVACY_POLICY.md](file:///d:/Development/Sheep%20App/PRIVACY_POLICY.md) for full instructions on signing and releasing to the Google Play Console.
