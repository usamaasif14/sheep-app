// health_model.dart - Health records for sheep
class HealthRecord {
  final String id;
  final String sheepId;
  String type; // 'Vaccination', 'Treatment', 'Checkup', 'Deworming'
  String description;
  String? medicine;
  double? dosage;
  String? dosageUnit; // 'ml', 'mg', 'g', 'tablets'
  String? veterinarian;
  double? cost;
  DateTime date;
  DateTime? nextDueDate;
  String status; // 'Completed', 'Scheduled', 'Overdue'
  String? notes;
  DateTime createdAt;

  HealthRecord({
    required this.id,
    required this.sheepId,
    required this.type,
    required this.description,
    this.medicine,
    this.dosage,
    this.dosageUnit,
    this.veterinarian,
    this.cost,
    required this.date,
    this.nextDueDate,
    this.status = 'Completed',
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sheepId': sheepId,
      'type': type,
      'description': description,
      'medicine': medicine,
      'dosage': dosage,
      'dosageUnit': dosageUnit,
      'veterinarian': veterinarian,
      'cost': cost,
      'date': date.toIso8601String(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'],
      sheepId: map['sheepId'],
      type: map['type'],
      description: map['description'],
      medicine: map['medicine'],
      dosage: map['dosage']?.toDouble(),
      dosageUnit: map['dosageUnit'],
      veterinarian: map['veterinarian'],
      cost: map['cost']?.toDouble(),
      date: DateTime.parse(map['date']),
      nextDueDate: map['nextDueDate'] != null ? DateTime.parse(map['nextDueDate']) : null,
      status: map['status'] ?? 'Completed',
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

// weight_record.dart - Weight tracking
class WeightRecord {
  final String id;
  final String sheepId;
  double weight;
  DateTime date;
  String? notes;

  WeightRecord({
    required this.id,
    required this.sheepId,
    required this.weight,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sheepId': sheepId,
      'weight': weight,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'],
      sheepId: map['sheepId'],
      weight: (map['weight'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      notes: map['notes'],
    );
  }
}
