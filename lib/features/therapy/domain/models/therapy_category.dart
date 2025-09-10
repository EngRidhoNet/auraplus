class TherapyCategory {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String color;
  final bool isActive;
  final DateTime? createdAt;

  const TherapyCategory({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.color = '#2196F3',
    this.isActive = true,
    this.createdAt,
  });

  factory TherapyCategory.fromJson(Map<String, dynamic> json) {
    return TherapyCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      color: json['color'] as String? ?? '#2196F3',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'color': color,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}