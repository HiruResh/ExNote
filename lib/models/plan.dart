// lib/models/plan.dart

enum PlanType { daily, weekly, monthly, custom }

class Plan {
  int? id;
  String name;
  PlanType type;
  double maxAmount;
  DateTime startDate;
  DateTime endDate;
  String? description;
  bool isActive; // To determine if it's an "Ongoing" plan

  Plan({
    this.id,
    required this.name,
    required this.type,
    required this.maxAmount,
    required this.startDate,
    required this.endDate,
    this.description,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'maxAmount': maxAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'description': description,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'],
      name: map['name'],
      type: PlanType.values.firstWhere((e) => e.name == map['type']),
      maxAmount: map['maxAmount'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      description: map['description'],
      isActive: map['isActive'] == 1,
    );
  }

  Plan copyWith({
    int? id,
    String? name,
    PlanType? type,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    bool? isActive,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      maxAmount: maxAmount ?? this.maxAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
