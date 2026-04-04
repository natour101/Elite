# Windows Run

This project opens the **Admin Dashboard** automatically on Windows Desktop.

## Requirements

1. Install Flutter SDK
2. Make sure `flutter` works in PowerShell
3. Open the project from:

```powershell
C:\Users\natou\Documents\GitHub\Elite
```

## Quick run

```powershell
.\run_windows.ps1
```

## Build EXE

```powershell
.\run_windows.ps1 -Mode build
```

## Manual commands

```powershell
flutter create . --platforms=windows,web
flutter pub get
flutter run -d windows
```

## Release build

```powershell
flutter build windows --release
```

The EXE will usually be created under:

```powershell
build\windows\x64\runner\Release
```

## If PowerShell blocks the script

Run this once in the same terminal:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```
