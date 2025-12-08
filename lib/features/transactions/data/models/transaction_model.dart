import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { expense, income, transfer }

class TransactionModel {
  final String id;
  final String ledgerId;
  final String categoryId;
  final String? categoryName; // Denormalized for easier display
  final String? ledgerName; // Denormalized
  final double amount;
  final DateTime date;
  final String? note;
  final TransactionType type;

  const TransactionModel({
    required this.id,
    required this.ledgerId,
    required this.categoryId,
    this.categoryName,
    this.ledgerName,
    required this.amount,
    required this.date,
    this.note,
    required this.type,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      ledgerId: json['ledgerId'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String?,
      ledgerName: json['ledgerName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: (json['date'] as Timestamp).toDate(),
      note: json['note'] as String?,
      type: TransactionType.values.byName(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ledgerId': ledgerId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'ledgerName': ledgerName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
      'type': type.name,
    };
  }
}
