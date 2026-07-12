param(
  [string]$DeviceId = "emulator-5554"
)

$ErrorActionPreference = "Stop"

$env:FLUTTER_SUPPRESS_ANALYTICS = "true"
$env:CI = "true"

Write-Host "Checking adb devices..." -ForegroundColor Yellow
adb devices

Write-Host "Running Flutter on $DeviceId..." -ForegroundColor Green
flutter run -d $DeviceId
