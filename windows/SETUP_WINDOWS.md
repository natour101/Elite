# Windows Setup

تم إنشاء المشروع في بيئة لا تحتوي على Flutter SDK، لذلك لم أتمكن من توليد ملفات ويندوز الأصلية عبر `flutter create`.

بعد تثبيت Flutter نفّذ:

```bash
flutter create . --platforms=windows,web
```

ثم شغّل:

```bash
flutter build windows --release
```
