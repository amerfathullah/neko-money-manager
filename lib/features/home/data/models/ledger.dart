import 'dart:ui';

class Ledger {
  final String id;
  final String name;
  final double balance;
  final int colorValue; // Store color as int (ARGB)

  const Ledger({
    required this.id,
    required this.name,
    required this.balance,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  factory Ledger.fromJson(Map<String, dynamic> json) {
    return Ledger(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      colorValue: json['colorValue'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'colorValue': colorValue,
    };
  }

  Ledger copyWith({
    String? id,
    String? name,
    double? balance,
    int? colorValue,
  }) {
    return Ledger(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Ledger &&
        other.id == id &&
        other.name == name &&
        other.balance == balance &&
        other.colorValue == colorValue;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ balance.hashCode ^ colorValue.hashCode;
  }
}
