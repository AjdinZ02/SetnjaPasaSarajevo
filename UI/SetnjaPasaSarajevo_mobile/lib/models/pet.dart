class Pet {
  final int? id;
  final String name;
  final int age;
  final String type;
  final String? notes;

  Pet({
    this.id,
    required this.name,
    required this.age,
    required this.type,
    this.notes,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      name: json['name']?.toString() ?? json['petName']?.toString() ?? '',
      age: json['age'] is int ? json['age'] as int : int.tryParse('${json['age']}') ?? 0,
      type: json['type']?.toString() ?? json['petType']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'type': type,
      'notes': notes,
    };
  }
}
