class Product {
  final String id;
  String name;
  bool isChecked;
  int quantity;
  final String createdBy;
  final DateTime createdAt;
  int position;

  Product({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.quantity = 1,
    required this.createdBy,
    required this.createdAt,
    this.position = 0,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      isChecked: map['is_checked'] as bool? ?? false,
      quantity: map['quantity'] as int? ?? 0,
      createdBy: map['created_by'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      position: map['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_checked': isChecked,
      'quantity': quantity,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'position': position,
    };
  }

  Product copyWith({
    String? name,
    bool? isChecked,
    int? quantity,
    int? position,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      quantity: quantity ?? this.quantity,
      createdBy: createdBy,
      createdAt: createdAt,
      position: position ?? this.position,
    );
  }
}