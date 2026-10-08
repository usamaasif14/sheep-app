// sheep_model.dart - Data model for individual sheep
class Sheep {
  final String id;
  String tagNumber;
  String name;
  String breed;
  String gender; // 'Male', 'Female'
  DateTime dateOfBirth;
  double weight; // kg
  String color;
  String status; // 'Active', 'Sold', 'Deceased', 'Quarantine'
  String? motherId;
  String? fatherId;
  String? photoPath;
  String? notes;
  DateTime dateAdded;
  DateTime lastUpdated;

  Sheep({
    required this.id,
    required this.tagNumber,
    required this.name,
    required this.breed,
    required this.gender,
    required this.dateOfBirth,
    required this.weight,
    required this.color,
    this.status = 'Active',
    this.motherId,
    this.fatherId,
    this.photoPath,
    this.notes,
    required this.dateAdded,
    required this.lastUpdated,
  });

  int get ageInMonths {
    final now = DateTime.now();
    return (now.difference(dateOfBirth).inDays / 30.44).floor();
  }

  String get ageDisplay {
    final months = ageInMonths;
    if (months < 12) return '$months months';
    final years = (months / 12).floor();
    final remainingMonths = months % 12;
    if (remainingMonths == 0) return '$years year${years > 1 ? 's' : ''}';
    return '$years yr $remainingMonths mo';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tagNumber': tagNumber,
      'name': name,
      'breed': breed,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'weight': weight,
      'color': color,
      'status': status,
      'motherId': motherId,
      'fatherId': fatherId,
      'photoPath': photoPath,
      'notes': notes,
      'dateAdded': dateAdded.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Sheep.fromMap(Map<String, dynamic> map) {
    return Sheep(
      id: map['id'],
      tagNumber: map['tagNumber'],
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      gender: map['gender'] ?? 'Female',
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      weight: (map['weight'] ?? 0.0).toDouble(),
      color: map['color'] ?? '',
      status: map['status'] ?? 'Active',
      motherId: map['motherId'],
      fatherId: map['fatherId'],
      photoPath: map['photoPath'],
      notes: map['notes'],
      dateAdded: DateTime.parse(map['dateAdded']),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  Sheep copyWith({
    String? tagNumber,
    String? name,
    String? breed,
    String? gender,
    DateTime? dateOfBirth,
    double? weight,
    String? color,
    String? status,
    String? motherId,
    String? fatherId,
    String? photoPath,
    String? notes,
    DateTime? lastUpdated,
  }) {
    return Sheep(
      id: id,
      tagNumber: tagNumber ?? this.tagNumber,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weight: weight ?? this.weight,
      color: color ?? this.color,
      status: status ?? this.status,
      motherId: motherId ?? this.motherId,
      fatherId: fatherId ?? this.fatherId,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      dateAdded: dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
