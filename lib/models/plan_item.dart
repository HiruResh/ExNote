// lib/models/plan_item.dart

class PlanItem {
  int? id;
  int planId; // Foreign key linking to the Plan
  String name;
  double amount;
  String? description;
  bool isCompleted;
  int displayOrder; // To allow changing the order

  PlanItem({
    this.id,
    required this.planId,
    required this.name,
    required this.amount,
    this.description,
    this.isCompleted = false,
    required this.displayOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'name': name,
      'amount': amount,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'displayOrder': displayOrder,
    };
  }

  factory PlanItem.fromMap(Map<String, dynamic> map) {
    return PlanItem(
      id: map['id'],
      planId: map['planId'],
      name: map['name'],
      amount: map['amount'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      displayOrder: map['displayOrder'],
    );
  }

  PlanItem copyWith({
    int? id,
    int? planId,
    String? name,
    double? amount,
    String? description,
    bool? isCompleted,
    int? displayOrder,
  }) {
    return PlanItem(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
