class AssetHistoryModel {
  final String id;
  final String assetId;
  final double balance; // The snapshot balance AFTER the change
  final DateTime date;
  final String reason; // 'transaction' or 'manual_edit' etc.
  final String? relatedTransactionId;

  const AssetHistoryModel({
    required this.id,
    required this.assetId,
    required this.balance,
    required this.date,
    this.reason = 'unknown',
    this.relatedTransactionId,
  });

  factory AssetHistoryModel.fromJson(Map<String, dynamic> json) {
    return AssetHistoryModel(
      id: json['id'] as String,
      assetId: json['assetId'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      reason: json['reason'] as String? ?? 'unknown',
      relatedTransactionId: json['relatedTransactionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetId': assetId,
      'balance': balance,
      'date': date.millisecondsSinceEpoch,
      'reason': reason,
      'relatedTransactionId': relatedTransactionId,
    };
  }
}
