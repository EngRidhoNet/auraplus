import 'package:freezed_annotation/freezed_annotation.dart';

part 'therapy_category.freezed.dart';
part 'therapy_category.g.dart';

@freezed
class TherapyCategory with _$TherapyCategory {
  const factory TherapyCategory({
    required String id,
    required String name,
    String? description,
    String? iconUrl,
    @Default('#2196F3') String color,
    @Default(true) bool isActive,
    DateTime? createdAt,
  }) = _TherapyCategory;

  factory TherapyCategory.fromJson(Map<String, dynamic> json) =>
      _$TherapyCategoryFromJson(json);
}