class TherapySession {
  final String id;
  final String userId;
  final String categoryId;
  final SessionType sessionType;
  final SessionStatus status;
  final int totalItems;
  final int completedItems;
  final int correctAnswers;
  final double score;
  final int durationSeconds;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? sessionData;

  const TherapySession({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.sessionType,
    this.status = SessionStatus.started,
    this.totalItems = 0,
    this.completedItems = 0,
    this.correctAnswers = 0,
    this.score = 0.0,
    this.durationSeconds = 0,
    this.startedAt,
    this.completedAt,
    this.sessionData,
  });

  factory TherapySession.fromJson(Map<String, dynamic> json) {
    return TherapySession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      sessionType: SessionType.values.firstWhere(
        (type) => type.name == json['session_type'],
        orElse: () => SessionType.vocabulary,
      ),
      status: SessionStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => SessionStatus.started,
      ),
      totalItems: json['total_items'] as int? ?? 0,
      completedItems: json['completed_items'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      sessionData: json['session_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'session_type': sessionType.name,
      'status': status.name,
      'total_items': totalItems,
      'completed_items': completedItems,
      'correct_answers': correctAnswers,
      'score': score,
      'duration_seconds': durationSeconds,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'session_data': sessionData,
    };
  }
}

enum SessionType {
  vocabulary,
  verbal,
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
  started,
  inProgress,
  completed,
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