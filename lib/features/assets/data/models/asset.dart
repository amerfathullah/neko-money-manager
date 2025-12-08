import 'package:flutter/material.dart';

enum AssetType { investment, property, savings, vehicle, other }

class Asset {
  final String id;
  final String name;
  final double currentValue;
  final AssetType type;
  final int colorValue;

  const Asset({
    required this.id,
    required this.name,
    required this.currentValue,
    required this.type,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      currentValue: (json['currentValue'] as num).toDouble(),
      type: AssetType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AssetType.other,
      ),
      colorValue: json['colorValue'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currentValue': currentValue,
      'type': type.toString(),
      'colorValue': colorValue,
    };
  }

  Asset copyWith({
    String? id,
    String? name,
    double? currentValue,
    AssetType? type,
    int? colorValue,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      currentValue: currentValue ?? this.currentValue,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
