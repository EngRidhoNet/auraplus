import 'package:freezed_annotation/freezed_annotation.dart';

part 'therapy_content.freezed.dart';
part 'therapy_content.g.dart';

@freezed
class TherapyContent with _$TherapyContent {
  const factory TherapyContent({
    required String id,
    required String categoryId,
    required String title,
    String? description,
    required ContentType contentType,
    @Default(1) int difficultyLevel,
    required String targetWord,
    String? pronunciation,
    String? imageUrl,
    String? audioUrl,
    String? model3dUrl,
    Map<String, dynamic>? arPlacementData,
    @Default(true) bool isActive,
    DateTime? createdAt,
  }) = _TherapyContent;

  factory TherapyContent.fromJson(Map<String, dynamic> json) =>
      _$TherapyContentFromJson(json);
}

enum ContentType {
  @JsonValue('word')
  word,
  @JsonValue('phrase')
  phrase,
  @JsonValue('sentence')
  sentence;
  
  String get displayName {
    switch (this) {
      case ContentType.word:
        return 'Word';
      case ContentType.phrase:
        return 'Phrase';
      case ContentType.sentence:
        return 'Sentence';
    }
  }
}