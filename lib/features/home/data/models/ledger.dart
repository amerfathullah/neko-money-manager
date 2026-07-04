import 'package:flutter/material.dart';

class Ledger {
  final String id;
  final String name;
  final int colorValue; // Store color as int (ARGB)
  final bool isDefault;
  final int? iconPoint;
  final String? iconFamily;
  final String? iconPackage;
  final String? remark;

  const Ledger({
    required this.id,
    required this.name,
    required this.colorValue,
    this.isDefault = false,
    this.iconPoint,
    this.iconFamily,
    this.iconPackage,
    this.remark,
  });

  Color get color => Color(colorValue);

  factory Ledger.fromJson(Map<String, dynamic> json) {
    return Ledger(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
      isDefault: json['isDefault'] == true || json['isDefault'] == 1,
      iconPoint: json['iconPoint'] as int?,
      iconFamily: json['iconFamily'] as String?,
      iconPackage: json['iconPackage'] as String?,
      remark: json['remark'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'isDefault': isDefault ? 1 : 0,
      'iconPoint': iconPoint,
      'iconFamily': iconFamily,
      'iconPackage': iconPackage,
      'remark': remark,
    };
  }

  Ledger copyWith({
    String? id,
    String? name,
    int? colorValue,
    bool? isDefault,
    int? iconPoint,
    String? iconFamily,
    String? iconPackage,
    String? remark,
  }) {
    return Ledger(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      iconPoint: iconPoint ?? this.iconPoint,
      iconFamily: iconFamily ?? this.iconFamily,
      iconPackage: iconPackage ?? this.iconPackage,
      remark: remark ?? this.remark,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Ledger &&
        other.id == id &&
        other.name == name &&
        other.colorValue == colorValue &&
        other.isDefault == isDefault &&
        other.iconPoint == iconPoint &&
        other.iconFamily == iconFamily &&
        other.iconPackage == iconPackage &&
        other.remark == remark;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        colorValue.hashCode ^
        isDefault.hashCode ^
        iconPoint.hashCode ^
        iconFamily.hashCode ^
        iconPackage.hashCode ^
        remark.hashCode;
  }
}
