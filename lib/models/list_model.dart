class ListModel {
  final String id;
  String name;
  String icon;
  int position;
  final DateTime createdAt;

  ListModel({
    required this.id,
    required this.name,
    this.icon = '',
    this.position = 0,
    required this.createdAt,
  });

  factory ListModel.fromMap(Map<String, dynamic> map) {
    return ListModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '',
      position: map['position'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'position': position,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ListModel copyWith({
    String? name,
    String? icon,
    int? position,
  }) {
    return ListModel(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      position: position ?? this.position,
      createdAt: createdAt,
    );
  }
}
