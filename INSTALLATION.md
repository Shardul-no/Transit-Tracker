# Transit Tracker - Complete Installation Guide

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

1. **Node.js** (v18 or higher)
   - Download from: https://nodejs.org/
   - Verify: `node --version`

2. **npm** or **yarn**
   - Comes with Node.js
   - Verify: `npm --version`

3. **Git** (optional, for cloning)
   - Download from: https://git-scm.com/

### Platform-Specific Requirements

#### For iOS Development (macOS only)

1. **Xcode** (14.0 or higher)
   - Download from Mac App Store
   - Install Command Line Tools: `xcode-select --install`

2. **CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

3. **iOS Simulator** (included with Xcode)

#### For Android Development

1. **Android Studio**
   - Download from: https://developer.android.com/studio

2. **Android SDK** (API Level 23+)
   - Install via Android Studio SDK Manager
   - Required: Android SDK Platform 34
   - Required: Android SDK Build-Tools 34.0.0

3. **Environment Variables**
   ```bash
   # Add to ~/.bashrc or ~/.zshrc (macOS/Linux)
   export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
   # export ANDROID_HOME=$HOME/Android/Sdk        # Linux
   # export ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk  # Windows
   
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/tools
   export PATH=$PATH:$ANDROID_HOME/tools/bin
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   ```

4. **Java Development Kit (JDK)**
   - JDK 17 recommended
   - Verify: `java -version`

## 🚀 Installation Steps

### Step 1: Get the Project

#### Option A: Clone Repository (if using Git)
```bash
git clone <repository-url>
cd Transit-Tracker
```

#### Option B: Download ZIP
1. Download the project ZIP file
2. Extract to your desired location
3. Open terminal in the project folder

### Step 2: Install Dependencies

```bash
npm install
```

This will install all required packages including:
- React Native
- Navigation libraries
- Map components
- SQLite storage
- Geolocation services
- Permissions handling
- State management (Zustand)

**Expected time**: 2-5 minutes depending on internet speed

### Step 3: iOS Setup (macOS only)

```bash
cd ios
pod install
cd ..
```

This installs iOS native dependencies via CocoaPods.

**Expected time**: 1-3 minutes

**Troubleshooting iOS Setup**:
```bash
# If pod install fails, try:
cd ios
pod deintegrate
pod install
cd ..

# Or update CocoaPods:
sudo gem install cocoapods
```

### Step 4: Android Setup

No additional setup required! Gradle will handle dependencies automatically on first build.

**Optional**: Open Android Studio and sync project to verify setup:
1. Open Android Studio
2. Select "Open an Existing Project"
3. Navigate to `Transit Tracker/android`
4. Wait for Gradle sync to complete

## ▶️ Running the App

### Start Metro Bundler

In the project root, start the Metro bundler:

```bash
npm start
```

Keep this terminal window open. Metro will bundle your JavaScript code.

### Run on iOS

**Option 1: Using npm script**
```bash
npm run ios
```

**Option 2: Specific simulator**
```bash
npx react-native run-ios --simulator="iPhone 15 Pro"
```

**Option 3: Using Xcode**
1. Open `ios/TransitTracker.xcworkspace` in Xcode
2. Select target device/simulator
3. Click Run (▶️) button

**First build time**: 5-10 minutes

### Run on Android

**Option 1: Using npm script**
```bash
npm run android
```

**Option 2: Specific device**
```bash
npx react-native run-android --deviceId=<device-id>
```

**Option 3: Using Android Studio**
1. Open `android` folder in Android Studio
2. Select target device/emulator
3. Click Run (▶️) button

**First build time**: 5-10 minutes

### List Connected Devices

**iOS**:
```bash
xcrun simctl list devices
```

**Android**:
```bash
adb devices
```

## 🔧 Configuration

### OpenStreetMap Tiles

The app uses OpenStreetMap by default. No API key required!

**To use a different tile server**, edit `src/screens/MapScreen.tsx`:

```typescript
<MapView
  // Add custom tile URL
  urlTemplate="https://your-tile-server.com/{z}/{x}/{y}.png"
  // ... other props
/>
```

### Permissions

Permissions are pre-configured in:
- **iOS**: `ios/TransitTracker/Info.plist`
- **Android**: `android/app/src/main/AndroidManifest.xml`

No changes needed unless you want to customize permission messages.

### App Name & Bundle ID

**iOS** (`ios/TransitTracker/Info.plist`):
```xml
<key>CFBundleDisplayName</key>
<string>Your App Name</string>
<key>CFBundleIdentifier</key>
<string>com.yourcompany.appname</string>
```

**Android** (`android/app/build.gradle`):
```gradle
defaultConfig {
    applicationId "com.yourcompany.appname"
    // ...
}
```

## 🧪 Testing

### Run on Physical Device

#### iOS Device
1. Connect iPhone via USB
2. Open Xcode
3. Select your device from device list
4. Enable "Developer Mode" on iPhone (Settings > Privacy & Security)
5. Trust your Mac on iPhone
6. Click Run in Xcode

#### Android Device
1. Enable Developer Options on phone:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging in Developer Options
3. Connect phone via USB
4. Authorize computer on phone
5. Run: `npm run android`

### Verify Installation

After app launches:
1. ✅ App opens without crashes
2. ✅ Map loads and shows your location
3. ✅ Location permission dialog appears
4. ✅ Start button is visible
5. ✅ No error messages in console

## 🐛 Troubleshooting

### Common Issues

#### 1. Metro Bundler Port Conflict

**Error**: Port 8081 already in use

**Solution**:
```bash
# Kill process on port 8081
npx react-native start --reset-cache

# Or manually:
lsof -ti:8081 | xargs kill  # macOS/Linux
```

#### 2. iOS Build Fails

**Error**: "Command PhaseScriptExecution failed"

**Solution**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
npm start -- --reset-cache
```

#### 3. Android Build Fails

**Error**: "SDK location not found"

**Solution**:
Create `android/local.properties`:
```properties
sdk.dir=/Users/YOUR_USERNAME/Library/Android/sdk  # macOS
# sdk.dir=C:\\Users\\YOUR_USERNAME\\AppData\\Local\\Android\\Sdk  # Windows
```

#### 4. Module Not Found

**Error**: "Unable to resolve module..."

**Solution**:
```bash
# Clear all caches
npm start -- --reset-cache
rm -rf node_modules
npm install

# iOS
cd ios && pod install && cd ..

# Android
cd android && ./gradlew clean && cd ..
```

#### 5. Location Permission Not Working

**iOS**: Check Info.plist has location usage descriptions
**Android**: Check AndroidManifest.xml has location permissions

#### 6. Map Not Showing

**Solution**:
- Check internet connection (needed for tiles)
- Verify INTERNET permission (Android)
- Check console for errors
- Try different tile server

#### 7. SQLite Errors

**Solution**:
- Uninstall and reinstall app
- Check device storage space
- Verify react-native-sqlite-storage is installed

### Clean Build

If all else fails, perform a complete clean build:

```bash
# Clean everything
rm -rf node_modules
rm -rf ios/Pods
rm -rf ios/build
rm -rf android/build
rm -rf android/app/build

# Reinstall
npm install
cd ios && pod install && cd ..

# Clear cache and rebuild
npm start -- --reset-cache

# In another terminal:
npm run ios  # or npm run android
```

## 📱 Building for Production

### iOS Production Build

1. **Archive in Xcode**:
   - Open `ios/TransitTracker.xcworkspace`
   - Select "Any iOS Device" as target
   - Product > Archive
   - Wait for archive to complete

2. **Distribute**:
   - Window > Organizer
   - Select your archive
   - Click "Distribute App"
   - Follow App Store Connect workflow

3. **Requirements**:
   - Apple Developer Account ($99/year)
   - App Store Connect setup
   - Provisioning profiles
   - App icons and screenshots

### Android Production Build

1. **Generate Release APK**:
   ```bash
   cd android
   ./gradlew assembleRelease
   ```

2. **Find APK**:
   ```
   android/app/build/outputs/apk/release/app-release.apk
   ```

3. **Generate AAB (for Play Store)**:
   ```bash
   cd android
   ./gradlew bundleRelease
   ```

4. **Find AAB**:
   ```
   android/app/build/outputs/bundle/release/app-release.aab
   ```

5. **Requirements**:
   - Google Play Developer Account ($25 one-time)
   - Signing key (generate with Android Studio)
   - Play Store listing
   - App icons and screenshots

### Code Signing

**iOS**: Managed by Xcode automatically for development

**Android**: Create signing key:
```bash
keytool -genkeypair -v -storetype PKCS12 -keystore my-release-key.keystore -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000
```

Add to `android/gradle.properties`:
```properties
MYAPP_RELEASE_STORE_FILE=my-release-key.keystore
MYAPP_RELEASE_KEY_ALIAS=my-key-alias
MYAPP_RELEASE_STORE_PASSWORD=*****
MYAPP_RELEASE_KEY_PASSWORD=*****
```

## 🔄 Updating Dependencies

### Check for Updates
```bash
npm outdated
```

### Update All Dependencies
```bash
npm update
```

### Update React Native
```bash
npx react-native upgrade
```

**Note**: Always test thoroughly after updates!

## 📊 Performance Optimization

### Enable Hermes (Already Enabled)

Hermes is enabled by default in `android/gradle.properties`:
```properties
hermesEnabled=true
```

### Reduce Bundle Size

```bash
# Analyze bundle
npx react-native bundle --platform android --dev false --entry-file index.js --bundle-output android-bundle.js --assets-dest android-assets

# Enable ProGuard (Android)
# Edit android/app/build.gradle:
def enableProguardInReleaseBuilds = true
```

## 📚 Next Steps

After successful installation:

1. **Read Documentation**:
   - QUICKSTART.md - Quick start guide
   - USAGE_GUIDE.md - User manual
   - FEATURES.md - Feature list

2. **Test the App**:
   - Start a tracking session
   - Walk around to test GPS
   - Stop and view summary
   - Check history

3. **Customize**:
   - Change app name
   - Update bundle ID
   - Customize colors
   - Add app icons

4. **Deploy**:
   - Test on physical device
   - Build for production
   - Submit to app stores

## 🆘 Getting Help

### Resources
- React Native Docs: https://reactnative.dev/
- React Navigation: https://reactnavigation.org/
- Stack Overflow: Tag with `react-native`

### Common Commands Reference

```bash
# Start Metro
npm start

# Run iOS
npm run ios

# Run Android
npm run android

# Clean cache
npm start -- --reset-cache

# Install dependencies
npm install

# iOS pods
cd ios && pod install && cd ..

# Android clean
cd android && ./gradlew clean && cd ..

# Check devices
adb devices                    # Android
xcrun simctl list devices      # iOS

# Logs
npx react-native log-ios       # iOS logs
npx react-native log-android   # Android logs
```

## ✅ Installation Checklist

- [ ] Node.js installed (v18+)
- [ ] Platform tools installed (Xcode/Android Studio)
- [ ] Project dependencies installed (`npm install`)
- [ ] iOS pods installed (macOS only)
- [ ] App runs on simulator/emulator
- [ ] Location permissions work
- [ ] Map displays correctly
- [ ] GPS tracking works
- [ ] Database saves data
- [ ] Export functionality works

## 🎉 Success!

If you've completed all steps, you should have a fully functional Transit Tracker app running on your device!

**Next**: Read USAGE_GUIDE.md to learn how to use all features.

---

**Need help?** Check SETUP.md for additional troubleshooting or open an issue on GitHub.
