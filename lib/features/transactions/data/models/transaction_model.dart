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
  final String? destinationLedgerId;
  final String? destinationLedgerName; // Denormalized
  final bool isBookmarked;
  final String? assetId;
  final String? assetName; // Denormalized
  final String? destinationAssetId;
  final String? destinationAssetName; // Denormalized
  final String? remarks;
  final bool isReimbursement;
  final double? reimbursedAmount;
  final String? reimbursedAssetId;

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
    this.destinationLedgerId,
    this.destinationLedgerName,
    this.isBookmarked = false,
    this.assetId,
    this.assetName,
    this.destinationAssetId,
    this.destinationAssetName,
    this.remarks,
    this.isReimbursement = false,
    this.reimbursedAmount,
    this.reimbursedAssetId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      ledgerId: json['ledgerId'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String?,
      ledgerName: json['ledgerName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      note: json['note'] as String?,
      type: TransactionType.values.byName(json['type'] as String),
      destinationLedgerId: json['destinationLedgerId'] as String?,
      destinationLedgerName: json['destinationLedgerName'] as String?,
      isBookmarked: json['isBookmarked'] == true || json['isBookmarked'] == 1,
      assetId: json['assetId'] as String?,
      assetName: json['assetName'] as String?,
      destinationAssetId: json['destinationAssetId'] as String?,
      destinationAssetName: json['destinationAssetName'] as String?,
      remarks: json['remarks'] as String?,
      isReimbursement: json['isReimbursement'] == true || json['isReimbursement'] == 1,
      reimbursedAmount: (json['reimbursedAmount'] as num?)?.toDouble(),
      reimbursedAssetId: json['reimbursedAssetId'] as String?,
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
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'type': type.name,
      'destinationLedgerId': destinationLedgerId,
      'destinationLedgerName': destinationLedgerName,
      'isBookmarked': isBookmarked ? 1 : 0,
      'assetId': assetId,
      'assetName': assetName,
      'destinationAssetId': destinationAssetId,
      'destinationAssetName': destinationAssetName,
      'remarks': remarks,
      'isReimbursement': isReimbursement ? 1 : 0,
      'reimbursedAmount': reimbursedAmount,
      'reimbursedAssetId': reimbursedAssetId,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? ledgerId,
    String? categoryId,
    String? categoryName,
    String? ledgerName,
    double? amount,
    DateTime? date,
    String? note,
    TransactionType? type,
    String? destinationLedgerId,
    String? destinationLedgerName,
    bool? isBookmarked,
    String? assetId,
    String? assetName,
    String? destinationAssetId,
    String? destinationAssetName,
    String? remarks,
    bool? isReimbursement,
    double? reimbursedAmount,
    String? reimbursedAssetId,
    bool clearReimbursement = false,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      ledgerName: ledgerName ?? this.ledgerName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      type: type ?? this.type,
      destinationLedgerId: destinationLedgerId ?? this.destinationLedgerId,
      destinationLedgerName:
          destinationLedgerName ?? this.destinationLedgerName,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      destinationAssetId: destinationAssetId ?? this.destinationAssetId,
      destinationAssetName: destinationAssetName ?? this.destinationAssetName,
      remarks: remarks ?? this.remarks,
      isReimbursement: isReimbursement ?? this.isReimbursement,
      reimbursedAmount: clearReimbursement
          ? null
          : (reimbursedAmount ?? this.reimbursedAmount),
      reimbursedAssetId: clearReimbursement
          ? null
          : (reimbursedAssetId ?? this.reimbursedAssetId),
    );
  }
}
