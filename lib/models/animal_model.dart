// animal_model.dart - Universal animal model (sheep, goat, cow, etc.)

// Common animal types — user can also type a custom one
const List<String> kDefaultAnimalTypes = [
  'Sheep',
  'Goat',
  'Cow',
  'Buffalo',
  'Camel',
  'Horse',
  'Donkey',
  'Chicken',
  'Other',
];

class Animal {
  final String id;
  String tagNumber;
  String name;
  String animalType; // 'Sheep', 'Goat', 'Cow', etc. or custom
  String breed;
  String gender; // 'Male', 'Female'
  DateTime dateOfBirth;
  double weight; // kg
  String color;
  String status; // 'Active', 'Sold', 'Deceased', 'Quarantine'
  double? purchaseCost; // optional cost when added/bought
  String? birthLocation; // farm area / location
  String? groupOwner; // person or group managing this animal
  String? motherId; // parent tracking
  String? fatherId;
  String? photoPath;
  String? notes;
  DateTime dateAdded;
  DateTime lastUpdated;

  Animal({
    required this.id,
    required this.tagNumber,
    required this.name,
    required this.animalType,
    required this.breed,
    required this.gender,
    required this.dateOfBirth,
    required this.weight,
    required this.color,
    this.status = 'Active',
    this.purchaseCost,
    this.birthLocation,
    this.groupOwner,
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
    if (months < 1) return '< 1 month';
    if (months < 12) return '$months month${months > 1 ? 's' : ''}';
    final years = (months / 12).floor();
    final rem = months % 12;
    if (rem == 0) return '$years year${years > 1 ? 's' : ''}';
    return '$years yr $rem mo';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tagNumber': tagNumber,
      'name': name,
      'animalType': animalType,
      'breed': breed,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'weight': weight,
      'color': color,
      'status': status,
      'purchaseCost': purchaseCost,
      'birthLocation': birthLocation,
      'groupOwner': groupOwner,
      'motherId': motherId,
      'fatherId': fatherId,
      'photoPath': photoPath,
      'notes': notes,
      'dateAdded': dateAdded.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Animal.fromMap(Map<String, dynamic> map) {
    return Animal(
      id: map['id'] as String,
      tagNumber: map['tagNumber'] as String,
      name: (map['name'] as String?) ?? '',
      animalType: (map['animalType'] as String?) ?? 'Sheep',
      breed: (map['breed'] as String?) ?? '',
      gender: (map['gender'] as String?) ?? 'Female',
      dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
      weight: ((map['weight'] as num?) ?? 0.0).toDouble(),
      color: (map['color'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'Active',
      purchaseCost: (map['purchaseCost'] as num?)?.toDouble(),
      birthLocation: map['birthLocation'] as String?,
      groupOwner: map['groupOwner'] as String?,
      motherId: map['motherId'] as String?,
      fatherId: map['fatherId'] as String?,
      photoPath: map['photoPath'] as String?,
      notes: map['notes'] as String?,
      dateAdded: DateTime.parse(map['dateAdded'] as String),
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }

  Animal copyWith({
    String? tagNumber,
    String? name,
    String? animalType,
    String? breed,
    String? gender,
    DateTime? dateOfBirth,
    double? weight,
    String? color,
    String? status,
    double? purchaseCost,
    String? birthLocation,
    String? groupOwner,
    String? motherId,
    String? fatherId,
    String? photoPath,
    String? notes,
    DateTime? lastUpdated,
  }) {
    return Animal(
      id: id,
      tagNumber: tagNumber ?? this.tagNumber,
      name: name ?? this.name,
      animalType: animalType ?? this.animalType,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weight: weight ?? this.weight,
      color: color ?? this.color,
      status: status ?? this.status,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      birthLocation: birthLocation ?? this.birthLocation,
      groupOwner: groupOwner ?? this.groupOwner,
      motherId: motherId ?? this.motherId,
      fatherId: fatherId ?? this.fatherId,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      dateAdded: dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Backwards compat alias — old code used Sheep class
  static Animal fromSheepMap(Map<String, dynamic> map) => Animal.fromMap(map);
}

// ─── Group / Owner ───────────────────────────────────────────────────────────

class AnimalGroup {
  final String id;
  String name;
  String? description;
  final DateTime createdAt;

  AnimalGroup({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AnimalGroup.fromMap(Map<String, dynamic> map) => AnimalGroup(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
