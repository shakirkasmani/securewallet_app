# Secure Wallet 💳

A secure, offline, and beautifully designed Credit Card Wallet application built with Flutter.

This project was developed for **Kaggle's AI Agents: Intensive Vibe Coding Capstone Project** under the **"Agents for good"** submission track.

---

## 🌟 The Problem
Managing and utilizing multiple credit cards across various mobile apps is often a highly frustrating experience:
* **App Fatigue**: Users are forced to navigate and open multiple banking apps to fetch card numbers, CVVs, and expiry dates.
* **Complex Authentication**: Accessing details often requires logging into each separate bank app, facing verification loops, and waiting for SMS/email OTPs.
* **Transaction Friction**: If a specific card fails during checkout, searching for and logging into an alternative bank app to retrieve another card's details introduces severe transaction delays.

## 🚀 The Solution
**Secure Wallet** resolves these pain points by consolidating all your credit and debit cards in a single, local, and hardware-secured vault. It enables you to instantly copy your card numbers, view masked credentials, and switch between cards in seconds.

---

## 🔑 Key Features
* **🔒 Biometric Lock Screen**: Secure login protected by device hardware-backed biometric verification (Face ID / Touch ID on iOS, Fingerprint/Biometric Prompt on Android).
* **🛡️ Encrypted Secure Storage**: Card details are serialized and extra-encrypted using symmetric cryptography (XOR-cipher + Base64) before being saved to the device's hardware-backed Keychain/Keystore via `flutter_secure_storage`.
* **📸 Silent AI/ML Card Scanner**: Auto-detects card number, cardholder, and expiry date hands-free using real-time frame streams and on-device machine learning OCR (`google_mlkit_text_recognition`). The process runs completely in memory, avoiding native iOS camera shutter sounds for quiet usability.
* **⚡ Frame-Rate Throttling**: The live camera image stream is throttled to 1 FPS to eliminate UI thread saturation, keeping the scan screen fluid and preventing application freezes.
* **🎨 Adaptive System Themes**: Follows device-level light and dark system settings automatically with premium visual styling, customized status bar overlay overlays, and tactile touch targets.
* **📋 Clipboard & Copy Alerts**: One-tap copy triggers local foreground notification alerts to quickly grab credentials.
* **⚖️ License Transparency**: Includes an open-source MIT license in the root directory and a built-in in-app license page showing the licenses of all third-party package dependencies.

---

## 🛠️ Technical Stack & Architecture
* **Frontend Framework**: Flutter & Dart (supports iOS & Android).
* **Local Biometrics**: `local_auth` (forces `FlutterFragmentActivity` on Android).
* **On-Device OCR**: `google_mlkit_text_recognition` + `camera`.
* **Encrypted Database**: `flutter_secure_storage`.
* **Alert Notifications**: `flutter_local_notifications` (configured with compile-time Java 8 desugaring).

---

## ⚙️ Requirements & Configuration
### Android
* **Minimum SDK**: API 21
* **Desugaring**: Configured with core library desugaring (`desugar_jdk_libs:2.1.4`) in the app-level `build.gradle.kts` to compile Java 8 LocalDateTime features.
* **Activity**: `MainActivity` inherits from `FlutterFragmentActivity` to allow hardware biometric dialog sheets.

### iOS
* **Deployment Target**: iOS 15.5+ (configured in `project.pbxproj` and `Podfile`).
* **Privacy Permissions**: Info.plist requests permissions for:
  - `NSCameraUsageDescription` (Card scanning stream)
  - `NSFaceIDUsageDescription` (Secure biometric vault authentication)

---

## 🚀 Getting Started
### Clone & Install
```bash
git clone https://github.com/shakirkasmani/credit-card-app.git
cd credit-card-app
flutter pub get
```

### Run on iOS / Android Device
```bash
flutter run
```

### Run Tests
```bash
flutter test
```

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
