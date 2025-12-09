import 'package:flutter/material.dart';

class Asset {
  final String id;
  final String name;
  final int colorValue;
  final double balance;
  final double initialBalance;
  final String remark;

  const Asset({
    required this.id,
    required this.name,
    required this.colorValue,
    this.balance = 0.0,
    this.initialBalance = 0.0,
    this.remark = '',
  });

  Color get color => Color(colorValue);

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      remark: json['remark'] as String? ?? '',
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
    };
  }

  Asset copyWith({
    String? id,
    String? name,
    int? colorValue,
    double? balance,
    double? initialBalance,
    String? remark,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      balance: balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      remark: remark ?? this.remark,
    );
  }
}
