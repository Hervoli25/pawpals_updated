# PawPals

A Flutter application for dog owners to connect, schedule playdates, find dog-friendly places, and manage their pets' care.

## Migration from Supabase to Firebase

This project is being migrated from Supabase to Firebase. Follow the steps below to complete the migration:

### 1. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 2. Configure Firebase for Your App

```bash
flutterfire configure --project=pawpals
```

This will:
- Connect to your Firebase project
- Configure platforms (Android, iOS, etc.)
- Generate the necessary configuration files

### 3. Update Dependencies

The pubspec.yaml file has been updated to use Firebase packages instead of Supabase. Run:

```bash
flutter pub get
```

### 4. Set Up Firebase Services

Follow the detailed instructions in the `firebase/README.md` file to set up:
- Authentication
- Firestore Database
- Storage
- Security Rules

## Features

- User authentication
- Dog profile management
- Playdate scheduling
- Dog-friendly places map
- Appointment tracking
- Meal planning

## Getting Started

1. Clone the repository
2. Follow the Firebase setup instructions
3. Run the app with `flutter run`

## Project Structure

- `lib/` - Dart source code
  - `main.dart` - Entry point
  - `models/` - Data models
  - `providers/` - State management
  - `screens/` - UI screens
  - `services/` - Firebase services
  - `utils/` - Utilities and helpers
  - `widgets/` - Reusable UI components
- `assets/` - Images, icons, and other assets
- `firebase/` - Firebase setup documentation
