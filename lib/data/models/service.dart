import 'package:equatable/equatable.dart';

class Service extends Equatable {
  final int? id;
  final String name;
  final String unit;
  final int price;
  final int durationDays;
  final bool isActive;
  final String? barcode;
  final int? serverId;
  final DateTime? createdAt;

  const Service({
    this.id,
    required this.name,
    required this.unit,
    required this.price,
    this.durationDays = 3,
    this.isActive = true,
    this.barcode,
    this.serverId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'price': price,
      'duration_days': durationDays,
      'is_active': isActive ? 1 : 0,
      'barcode': barcode,
      'server_id': serverId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] as int?,
      name: map['name'] as String,
      unit: map['unit'] as String,
      price: map['price'] as int,
      durationDays: (map['duration_days'] as int?) ?? 3,
      isActive: (map['is_active'] as int?) == 1,
      barcode: map['barcode'] as String?,
      serverId: map['server_id'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Service copyWith({
    int? id,
    String? name,
    String? unit,
    int? price,
    int? durationDays,
    bool? isActive,
    String? barcode,
    int? serverId,
    DateTime? createdAt,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      durationDays: durationDays ?? this.durationDays,
      isActive: isActive ?? this.isActive,
      barcode: barcode ?? this.barcode,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        unit,
        price,
        durationDays,
        isActive,
        barcode,
        serverId,
        createdAt,
      ];
}
