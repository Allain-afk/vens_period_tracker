# iOS Build Instructions for Ven's Period Tracker

This document contains instructions for building the iOS version of Ven's Period Tracker app.

## Prerequisites

- macOS operating system
- Xcode 14.0 or later (latest version recommended)
- CocoaPods (`sudo gem install cocoapods`)
- Flutter SDK installed and configured
- Apple Developer account (for distribution)

## Setup and Build Instructions

1. **Clone the repository** (if you haven't already):
   ```bash
   git clone <repository-url>
   cd vens_period_tracker
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Set up iOS build environment**:
   ```bash
   cd ios
   pod install
   ```
   
   If you encounter any issues with pod install, try:
   ```bash
   pod repo update
   pod install --repo-update
   ```

4. **Open the project in Xcode**:
   ```bash
   open Runner.xcworkspace
   ```
   Note: Always use `.xcworkspace` file, not `.xcodeproj`

5. **Configure signing and capabilities**:
   - In Xcode, select the "Runner" project in the left sidebar
   - Go to the "Signing & Capabilities" tab
   - Select your Team (Apple Developer account)
   - Update the Bundle Identifier if needed (e.g., com.yourcompany.vensPeriodTracker)

6. **Update app version and build number** (if needed):
   - Update version in pubspec.yaml
   - The current version is 1.3.0+3

7. **Test on Simulator**:
   ```bash
   flutter run -d ios
   ```

8. **Build for testing on physical device**:
   - Connect your iOS device
   - Select your device in Xcode
   - Press the "Run" button in Xcode or use:
   ```bash
   flutter run -d ios --release
   ```

9. **Build for distribution**:
   ```bash
   flutter build ios --release
   ```

10. **Archive and distribute**:
    - In Xcode, select "Product" > "Archive"
    - In the Archives window, select your archive
    - Click "Distribute App" and follow the instructions for App Store submission or ad-hoc distribution

## Features to Test on iOS

Please ensure that these features specific to iOS work correctly:

1. **Notifications**: Test that pill reminders are delivered correctly
2. **Background updates**: Ensure notifications are scheduled even when the app is closed
3. **Widget compatibility**: If any iOS widgets are implemented
4. **iOS UI consistency**: Verify that UI elements follow iOS design guidelines

## Troubleshooting

- **Pod install issues**: Try removing Podfile.lock and running pod install again
- **Signing issues**: Verify your Apple Developer account is active and has the correct permissions
- **Build errors**: Check that the minimum iOS version (12.0) is compatible with all dependencies

## Contact

If you encounter any iOS-specific issues during the build process, please contact:
[Your contact information] 