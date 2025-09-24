# Firebase Configuration Setup

## Overview
This document explains how to set up Firebase configuration files for iOS and Android platforms. These files contain sensitive API keys and are excluded from Git tracking for security reasons.

## Required Files

### iOS Configuration
- **File**: `ios/Runner/GoogleService-Info.plist`
- **Template**: `ios/Runner/GoogleService-Info.plist.example`
- **Source**: Download from Firebase Console → Project Settings → iOS App

### Android Configuration
- **File**: `android/app/google-services.json`
- **Template**: `android/app/google-services.json.example`
- **Source**: Download from Firebase Console → Project Settings → Android App

## Setup Instructions

### 1. Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `gcp-f06-barcode`
3. Navigate to **Project Settings** (gear icon)
4. Go to **General** tab

### 2. iOS Setup
1. In Firebase Console, find the iOS app section
2. Click **Download GoogleService-Info.plist**
3. Copy the downloaded file to `ios/Runner/GoogleService-Info.plist`
4. Verify the Bundle ID matches: `com.hackathon.f06.barcodeScanner`

### 3. Android Setup
1. In Firebase Console, find the Android app section
2. Click **Download google-services.json**
3. Copy the downloaded file to `android/app/google-services.json`
4. Verify the package names match:
   - `com.f06team.fridgemanager`
   - `com.hackathon.f06.barcode_scanner`

### 4. Verification
Run the following commands to verify setup:
```bash
# Check iOS file exists
ls -la ios/Runner/GoogleService-Info.plist

# Check Android file exists
ls -la android/app/google-services.json

# Build and run
flutter clean
flutter pub get
flutter run
```

## Security Notes

⚠️ **IMPORTANT**: These files contain sensitive API keys and credentials:
- Never commit these files to Git
- Keep them secure and don't share publicly
- Rotate keys if compromised
- Use different Firebase projects for development/production

## Troubleshooting

### Common Issues
1. **Build Error**: "GoogleService-Info.plist not found"
   - Ensure file is in correct location: `ios/Runner/GoogleService-Info.plist`
   - Check file permissions are readable

2. **Android Build Error**: "google-services.json not found"
   - Ensure file is in correct location: `android/app/google-services.json`
   - Verify JSON syntax is valid

3. **Authentication Issues**
   - Verify Bundle ID/Package Name matches Firebase configuration
   - Check API keys are not expired
   - Ensure Firebase Authentication is enabled in console

### Getting Help
- Check [Firebase Documentation](https://firebase.google.com/docs)
- Review project-specific setup in `CLAUDE.md`
- Contact team members for project credentials

## File Templates

The repository includes template files with placeholder values:
- `ios/Runner/GoogleService-Info.plist.example`
- `android/app/google-services.json.example`

Copy these templates and replace placeholder values with your actual Firebase configuration.
