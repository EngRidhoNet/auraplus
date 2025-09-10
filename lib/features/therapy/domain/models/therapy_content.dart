// Replace isi therapy_content.dart dengan manual model:
enum ContentType { word, phrase, sentence }

class TherapyContent {
  final String id;
  final String categoryId;
  final String title;
  final String? description;
  final ContentType contentType;
  final int difficultyLevel;
  final String targetWord;
  final String? pronunciation;
  final String? imageUrl;
  final String? audioUrl;
  final String? model3dUrl;
  final Map<String, dynamic>? arPlacementData;
  final bool isActive;
  final DateTime createdAt;

  const TherapyContent({
    required this.id,
    required this.categoryId,
    required this.title,
    this.description,
    required this.contentType,
    required this.difficultyLevel,
    required this.targetWord,
    this.pronunciation,
    this.imageUrl,
    this.audioUrl,
    this.model3dUrl,
    this.arPlacementData,
    this.isActive = true,
    required this.createdAt,
  });

  factory TherapyContent.fromJson(Map<String, dynamic> json) {
    return TherapyContent(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      contentType: ContentType.values.firstWhere(
        (type) => type.name == json['content_type'],
        orElse: () => ContentType.word,
      ),
      difficultyLevel: json['difficulty_level'] as int,
      targetWord: json['target_word'] as String,
      pronunciation: json['pronunciation'] as String?,
      imageUrl: json['image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      model3dUrl: json['model_3d_url'] as String?,
      arPlacementData: json['ar_placement_data'] as Map<String, dynamic>?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'content_type': contentType.name,
      'difficulty_level': difficultyLevel,
      'target_word': targetWord,
      'pronunciation': pronunciation,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'model_3d_url': model3dUrl,
      'ar_placement_data': arPlacementData,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}