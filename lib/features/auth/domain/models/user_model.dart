import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required UserRole role,
    String? displayName,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    int? age,
    String? gender,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

enum UserRole {
  @JsonValue('child')
  child,
  @JsonValue('parent')
  parent,
  @JsonValue('therapist')
  therapist;
  
  // Add getter for display name
  String get displayName {
    switch (this) {
      case UserRole.child:
        return 'Child';
      case UserRole.parent:
        return 'Parent';
      case UserRole.therapist:
        return 'Therapist';
    }
  }
}