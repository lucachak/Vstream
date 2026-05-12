# VStream - Video Streaming Flutter App

This is a minimal but scalable Flutter project for a video streaming application.

## Tech Stack
- **UI**: CustomScrollView + Slivers
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Video**: Chewie + VideoPlayer (HLS supported)
- **Backend**: Supabase (Auth, DB, Real-time)
- **Persistence**: Hive + CachedNetworkImage

## Setup Instructions

### 1. Install Flutter (Fast way for Linux)
If AUR (`paru`/`yay`) is taking too long, use the official binary:
```bash
# Download and extract
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.2-stable.tar.xz
tar xf flutter_linux_3.22.2-stable.tar.xz
export PATH="$PATH:$HOME/flutter/bin"

# Verify
flutter doctor
```

### 2. Install Project Dependencies
```bash
cd /home/lucas/Documents/Code/Dev/Dart/vstream
flutter pub get
```

3. **Configure Supabase**:
   Edit `lib/core/config/supabase_config.dart` and add your URL and Anon Key.

4. **Run the App**:
   ```bash
   flutter run
   ```

5. **Generate Code** (for Riverpod/Hive generators):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## Folder Structure
```
lib/
├── core/
│   ├── config/         # Environment configs, constants
│   ├── network/        # API clients, interceptors
│   ├── errors/         # Error handling
│   └── utils/          # Helpers, extensions
├── features/
│   ├── auth/           # Login/Signup
│   ├── browse/         # Home screen, category list
│   ├── player/         # Video player
│   └── profile/        # User settings
├── shared/
│   ├── widgets/        # Reusable components
│   ├── models/         # Data models
│   └── providers/      # Global state
└── main.dart
```
