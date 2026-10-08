// breeding_model.dart - Breeding and lambing records
class BreedingRecord {
  final String id;
  final String eweId;    // Female sheep
  final String? ramId;   // Male sheep
  DateTime matingDate;
  DateTime? expectedLambingDate;
  DateTime? actualLambingDate;
  String status; // 'Mated', 'Pregnant', 'Lambed', 'Failed'
  int? lambsBorn;
  int? lambsSurvived;
  String? notes;
  DateTime createdAt;

  BreedingRecord({
    required this.id,
    required this.eweId,
    this.ramId,
    required this.matingDate,
    this.expectedLambingDate,
    this.actualLambingDate,
    this.status = 'Mated',
    this.lambsBorn,
    this.lambsSurvived,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eweId': eweId,
      'ramId': ramId,
      'matingDate': matingDate.toIso8601String(),
      'expectedLambingDate': expectedLambingDate?.toIso8601String(),
      'actualLambingDate': actualLambingDate?.toIso8601String(),
      'status': status,
      'lambsBorn': lambsBorn,
      'lambsSurvived': lambsSurvived,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BreedingRecord.fromMap(Map<String, dynamic> map) {
    return BreedingRecord(
      id: map['id'],
      eweId: map['eweId'],
      ramId: map['ramId'],
      matingDate: DateTime.parse(map['matingDate']),
      expectedLambingDate: map['expectedLambingDate'] != null
          ? DateTime.parse(map['expectedLambingDate'])
          : null,
      actualLambingDate: map['actualLambingDate'] != null
          ? DateTime.parse(map['actualLambingDate'])
          : null,
      status: map['status'] ?? 'Mated',
      lambsBorn: map['lambsBorn'],
      lambsSurvived: map['lambsSurvived'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

// Expense/Income model for finance tracking
class FinancialRecord {
  final String id;
  String type; // 'Income' or 'Expense'
  String category; // 'Sale', 'Purchase', 'Veterinary', 'Feed', 'Medication', 'Shearing', 'Other'
  String description;
  double amount;
  DateTime date;
  String? sheepId; // optional link to specific sheep
  String? notes;
  DateTime createdAt;

  FinancialRecord({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.sheepId,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'sheepId': sheepId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FinancialRecord.fromMap(Map<String, dynamic> map) {
    return FinancialRecord(
      id: map['id'],
      type: map['type'],
      category: map['category'],
      description: map['description'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      sheepId: map['sheepId'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

// Feed Record model
class FeedRecord {
  final String id;
  String feedType; // 'Hay', 'Grain', 'Silage', 'Pasture', 'Supplement'
  double quantity; // kg
  double? costPerKg;
  DateTime date;
  String? notes;
  DateTime createdAt;

  FeedRecord({
    required this.id,
    required this.feedType,
    required this.quantity,
    this.costPerKg,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feedType': feedType,
      'quantity': quantity,
      'costPerKg': costPerKg,
      'date': date.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FeedRecord.fromMap(Map<String, dynamic> map) {
    return FeedRecord(
      id: map['id'],
      feedType: map['feedType'],
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      costPerKg: map['costPerKg']?.toDouble(),
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
