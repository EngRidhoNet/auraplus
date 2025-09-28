# AURA+ – Project Brief
## Tujuan
- Aplikasi terapi vokabulari untuk anak ASD dengan mode AR & pelafalan.

## Fitur Inti
- AR Vocabulary (model 3D, animasi, tap-to-place)
- Pronunciation Guide (TTS + evaluasi sederhana)
- Progress Tracking (lokal + optional sync)

## Stack
- Flutter 3.x, Dart
- AR: ar_flutter_plugin / Unity as lib (sebutkan yang dipakai)
- State mgmt: Riverpod
- Storage: Hive / SQflite
- Platform: Android (minSdk ?), iOS (minIOS ?)

## Constraint & Non-Functional
- Latensi render AR < 50ms/frame pada device target
- Offline-first untuk materi dasar
- Aksesibilitas (ukuran teks, kontras)

## Peta Folder
- lib/features/therapy/...
- lib/core/...
- assets/models/...
