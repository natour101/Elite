# تشغيل نسخة PC

هذا المشروع يفتح **لوحة الإدارة** تلقائيًا على Windows Desktop.

## المطلوب قبل التشغيل

1. ثبّت Flutter SDK
2. تأكد أن الأمر `flutter` يعمل من PowerShell
3. افتح المشروع من هذا المسار:

```powershell
C:\Users\natou\Documents\GitHub\Elite
```

## أسهل طريقة

لتشغيل برنامج الـ PC:

```powershell
.\run_windows.ps1
```

لبناء نسخة EXE:

```powershell
.\run_windows.ps1 -Mode build
```

## إذا أردت الأوامر يدويًا

أول مرة فقط:

```powershell
flutter create . --platforms=windows,web
flutter pub get
```

ثم للتشغيل:

```powershell
flutter run -d windows
```

وللبناء:

```powershell
flutter build windows --release
```

## ملاحظة

إذا لم تكن ملفات Windows موجودة، فالسكربت `run_windows.ps1` سيولدها تلقائيًا ثم يكمل التشغيل أو البناء.
