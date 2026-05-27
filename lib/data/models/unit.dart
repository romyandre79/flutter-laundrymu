class Unit {
  final int? id;
  final String name;
  final String? createdAt;

  const Unit({
    this.id,
    required this.name,
    this.createdAt,
  });

  Unit copyWith({
    int? id,
    String? name,
    String? createdAt,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: map['created_at'] as String?,
    );
  }
}
