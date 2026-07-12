@echo off
set FLUTTER_SUPPRESS_ANALYTICS=true
set CI=true
adb devices
flutter run -d emulator-5554
