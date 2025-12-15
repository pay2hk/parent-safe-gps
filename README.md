# Parent Safe GPS

**Real-time location tracking app for elderly care with Firebase & Traccar integration**

## Features

✅ **Live GPS Tracking** - Real-time position updates every 30 seconds  
✅ **Traccar Integration** - Direct connection to your LostMod Traccar server  
✅ **Firebase Backend** - Firestore for location history and alerts  
✅ **SOS Alerts** - One-tap emergency button for immediate notifications  
✅ **Geofencing** - Define safe zones (home, temple, market) with entry/exit alerts  
✅ **Push Notifications** - Firebase Cloud Messaging for instant alerts  
✅ **Offline Support** - Works with poor connectivity  
✅ **Battery Optimization** - Smart location tracking to save battery  
✅ **Multi-family Support** - Multiple caregivers, multiple elderly  

## Project Setup

### Prerequisites
- Flutter 3.0+
- Android SDK 21+
- Google Maps API Key
- Firebase Project (already configured)
- Traccar Server: `http://62.171.156.81:5055`

### Installation

```bash
# Clone the repository
git clone https://github.com/pay2hk/parent-safe-gps.git
cd parent-safe-gps

# Get dependencies
flutter pub get

# Configure Firebase
flutterfire configure --project=lostmod-56321

# Run the app
flutter run
```

## Building APK

### Option 1: Local Build
```bash
flutter build apk --release --split-per-abi
```
APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Option 2: Codemagic Cloud Build
1. Go to https://codemagic.io
2. Connect this GitHub repo
3. Select Flutter platform
4. Choose Android build
5. Codemagic builds APK automatically

## Firebase Configuration

**Project ID:** `lostmod-56321`

**Collections:**
- `devices` - Device information and mapping
- `locations` - GPS location history
- `alerts` - SOS and geofence alerts

## Traccar Configuration

**Server URL:** `http://62.171.156.81:5055`
**Communication Port:** 5055
**Protocol:** OsmAnd

The app sends location data in this format:
```
http://62.171.156.81:5055/?id=DEVICE_ID&lat=LAT&lon=LON&timestamp=UNIX_MS&speed=SPEED&bearing=COURSE
```

## App Structure

```
lib/
├── main.dart
├── screens/
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── map_screen.dart
│   ├── alerts_screen.dart
│   └── settings_screen.dart
├── services/
│   ├── location_service.dart
│   ├── firebase_service.dart
│   ├── traccar_service.dart
│   └── notification_service.dart
├── models/
│   ├── device_model.dart
│   ├── location_model.dart
│   └── alert_model.dart
└── widgets/
    ├── custom_map.dart
    └── alert_card.dart
```

## Permissions Required

- `ACCESS_FINE_LOCATION` - Precise GPS
- `ACCESS_BACKGROUND_LOCATION` - Background tracking
- `INTERNET` - Firebase & Traccar
- `CAMERA` - Optional for future features

## Download APK

Download pre-built APK from [Releases](https://github.com/pay2hk/parent-safe-gps/releases)

## Support

For issues and feature requests, please create an [Issue](https://github.com/pay2hk/parent-safe-gps/issues)
