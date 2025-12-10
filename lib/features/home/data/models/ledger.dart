import 'dart:ui';

class Ledger {
  final String id;
  final String name;
  final double balance;
  final int colorValue; // Store color as int (ARGB)
  final bool isDefault;

  const Ledger({
    required this.id,
    required this.name,
    required this.balance,
    required this.colorValue,
    this.isDefault = false,
  });

  Color get color => Color(colorValue);

  factory Ledger.fromJson(Map<String, dynamic> json) {
    return Ledger(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      colorValue: json['colorValue'] as int,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'colorValue': colorValue,
      'isDefault': isDefault,
    };
  }

  Ledger copyWith({
    String? id,
    String? name,
    double? balance,
    int? colorValue,
    bool? isDefault,
  }) {
    return Ledger(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Ledger &&
        other.id == id &&
        other.name == name &&
        other.balance == balance &&
        other.colorValue == colorValue &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        balance.hashCode ^
        colorValue.hashCode ^
        isDefault.hashCode;
  }
}
