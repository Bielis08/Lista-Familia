class Product {
  final String id;
  String name;
  bool isChecked;
  bool isImportant;
  int quantity;
  final String createdBy;
  final DateTime createdAt;
  int position;
  String listId;

  Product({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.isImportant = false,
    this.quantity = 1,
    required this.createdBy,
    required this.createdAt,
    this.position = 0,
    this.listId = 'supermercado',
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      isChecked: map['is_checked'] as bool? ?? false,
      isImportant: map['is_important'] as bool? ?? false,
      quantity: map['quantity'] as int? ?? 0,
      createdBy: map['created_by'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      position: map['position'] as int? ?? 0,
      listId: map['list_id'] as String? ?? 'supermercado',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_checked': isChecked,
      'is_important': isImportant,
      'quantity': quantity,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'position': position,
      'list_id': listId,
    };
  }

  Product copyWith({
    String? name,
    bool? isChecked,
    bool? isImportant,
    int? quantity,
    int? position,
    String? listId,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      isImportant: isImportant ?? this.isImportant,
      quantity: quantity ?? this.quantity,
      createdBy: createdBy,
      createdAt: createdAt,
      position: position ?? this.position,
      listId: listId ?? this.listId,
    );
  }
}