import 'package:freezed_annotation/freezed_annotation.dart';

part 'therapy_session.freezed.dart';
part 'therapy_session.g.dart';

@freezed
class TherapySession with _$TherapySession {
  const factory TherapySession({
    required String id,
    required String userId,
    required String categoryId,
    required SessionType sessionType,
    @Default(SessionStatus.started) SessionStatus status,
    @Default(0) int totalItems,
    @Default(0) int completedItems,
    @Default(0) int correctAnswers,
    @Default(0.0) double score,
    @Default(0) int durationSeconds,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? sessionData,
  }) = _TherapySession;

  factory TherapySession.fromJson(Map<String, dynamic> json) =>
      _$TherapySessionFromJson(json);
}

enum SessionType {
  @JsonValue('vocabulary')
  vocabulary,
  @JsonValue('verbal')
  verbal,
  @JsonValue('aac')
  aac;
  
  String get displayName {
    switch (this) {
      case SessionType.vocabulary:
        return 'Vocabulary Therapy';
      case SessionType.verbal:
        return 'Verbal Therapy';
      case SessionType.aac:
        return 'AAC Therapy';
    }
  }
}

enum SessionStatus {
  @JsonValue('started')
  started,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('paused')
  paused;
  
  String get displayName {
    switch (this) {
      case SessionStatus.started:
        return 'Started';
      case SessionStatus.inProgress:
        return 'In Progress';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.paused:
        return 'Paused';
    }
  }
}