// animal_model.dart - Universal animal model
const List<String> kDefaultAnimalTypes = [
  'Sheep', 'Goat', 'Cow', 'Buffalo', 'Camel',
  'Horse', 'Donkey', 'Chicken', 'Other',
];

// Life stage labels based on age
String lifeStage(String animalType, String gender, int ageMonths) {
  final type = animalType.toLowerCase();
  if (type == 'sheep' || type == 'goat') {
    if (ageMonths <= 6) return gender == 'Female' ? 'Ewe Lamb' : 'Ram Lamb';
    if (ageMonths <= 12) return gender == 'Female' ? 'Gimmer' : 'Ram Lamb';
    return gender == 'Female' ? 'Ewe' : 'Ram';
  }
  if (type == 'cow' || type == 'buffalo') {
    if (ageMonths <= 12) return gender == 'Female' ? 'Heifer Calf' : 'Bull Calf';
    if (ageMonths <= 36) return gender == 'Female' ? 'Heifer' : 'Bull';
    return gender == 'Female' ? 'Cow' : 'Bull';
  }
  if (ageMonths <= 6) return 'Young';
  if (ageMonths <= 12) return 'Juvenile';
  return gender == 'Female' ? 'Female' : 'Male';
}

class Animal {
  final String id;
  String tagNumber;
  String name;
  String animalType;
  String breed;
  String gender;
  DateTime dateOfBirth;
  double weight;
  String color;

  // Status: 'Active' | 'Pregnant' | 'Gave Birth' | 'Sold' | 'Deceased' | 'Quarantine'
  String status;

  double? purchaseCost;
  String? birthLocation;
  String? groupOwner;
  String? motherId;
  String? motherName; // denormalized for fast display
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
    this.motherName,
    this.fatherId,
    this.photoPath,
    this.notes,
    required this.dateAdded,
    required this.lastUpdated,
  });

  int get ageInMonths =>
      (DateTime.now().difference(dateOfBirth).inDays / 30.44).floor();

  String get ageDisplay {
    final m = ageInMonths;
    if (m < 1) return '< 1 month';
    if (m < 12) return '$m month${m > 1 ? 's' : ''}';
    final y = (m / 12).floor();
    final rem = m % 12;
    if (rem == 0) return '$y year${y > 1 ? 's' : ''}';
    return '$y yr $rem mo';
  }

  String get stage => lifeStage(animalType, gender, ageInMonths);

  bool get isPregnant => status == 'Pregnant';
  bool get isActive => status == 'Active';

  Map<String, dynamic> toMap() => {
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
        'motherName': motherName,
        'fatherId': fatherId,
        'photoPath': photoPath,
        'notes': notes,
        'dateAdded': dateAdded.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory Animal.fromMap(Map<String, dynamic> map) => Animal(
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
        motherName: map['motherName'] as String?,
        fatherId: map['fatherId'] as String?,
        photoPath: map['photoPath'] as String?,
        notes: map['notes'] as String?,
        dateAdded: DateTime.parse(map['dateAdded'] as String),
        lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      );

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
    String? motherName,
    String? fatherId,
    String? photoPath,
    String? notes,
    DateTime? lastUpdated,
  }) =>
      Animal(
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
        motherName: motherName ?? this.motherName,
        fatherId: fatherId ?? this.fatherId,
        photoPath: photoPath ?? this.photoPath,
        notes: notes ?? this.notes,
        dateAdded: dateAdded,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

// ─── Animal Event ────────────────────────────────────────────────────────────
class AnimalEvent {
  final String id;
  final String animalId;
  String eventType; // 'Note', 'Weight Check', 'Shearing', 'Sale Attempt', 'Medication', 'Other'
  String title;
  String? description;
  DateTime date;
  double? cost;
  final DateTime createdAt;

  AnimalEvent({
    required this.id,
    required this.animalId,
    required this.eventType,
    required this.title,
    this.description,
    required this.date,
    this.cost,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'animalId': animalId,
        'eventType': eventType,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'cost': cost,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AnimalEvent.fromMap(Map<String, dynamic> map) => AnimalEvent(
        id: map['id'] as String,
        animalId: map['animalId'] as String,
        eventType: (map['eventType'] as String?) ?? 'Note',
        title: map['title'] as String,
        description: map['description'] as String?,
        date: DateTime.parse(map['date'] as String),
        cost: (map['cost'] as num?)?.toDouble(),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
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
