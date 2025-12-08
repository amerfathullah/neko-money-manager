import 'package:flutter/material.dart';

class Asset {
  final String id;
  final String name;
  final int colorValue;

  const Asset({required this.id, required this.name, required this.colorValue});

  Color get color => Color(colorValue);

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'colorValue': colorValue};
  }

  Asset copyWith({String? id, String? name, int? colorValue}) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
