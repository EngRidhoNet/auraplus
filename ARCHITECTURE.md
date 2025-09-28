# Arsitektur
- Pattern: Feature-first
- State: Riverpod (Providers: ...)
- Data Flow: UI -> Application Service -> Repository -> Data Source
- Integrasi AR: Widget AR3DModelViewer membungkus controller X
- Audio: TTS wrapper di core/audio/tts_service.dart
- Error Handling: Either<Failure, T> via dartz (jika pakai)
- Routing: go_router (contoh)
- Diagram singkat: (tuliskan)
