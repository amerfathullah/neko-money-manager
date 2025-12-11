import 'package:flutter/material.dart';

class Asset {
  final String id;
  final String name;
  final int colorValue;
  final double balance;
  final double initialBalance;
  final String remark;
  final int? iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;

  const Asset({
    required this.id,
    required this.name,
    required this.colorValue,
    this.balance = 0.0,
    this.initialBalance = 0.0,
    this.remark = '',
    this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
  });

  Color get color => Color(colorValue);

  IconData get icon {
    if (iconCodePoint != null) {
      return IconData(
        iconCodePoint!,
        fontFamily: iconFontFamily,
        fontPackage: iconFontPackage,
      );
    }
    // Default fallback if no icon set
    return Icons.account_balance_wallet;
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      remark: json['remark'] as String? ?? '',
      iconCodePoint: json['iconCodePoint'] as int?,
      iconFontFamily: json['iconFontFamily'] as String?,
      iconFontPackage: json['iconFontPackage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'balance': balance,
      'initialBalance': initialBalance,
      'remark': remark,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
    };
  }

  Asset copyWith({
    String? id,
    String? name,
    int? colorValue,
    double? balance,
    double? initialBalance,
    String? remark,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      balance: balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      remark: remark ?? this.remark,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: iconFontPackage ?? this.iconFontPackage,
    );
  }
}
