class Expense {
  int? id;
  String name;
  double amount;
  String category;
  DateTime date;
  String? description; // Optional description

  Expense({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
  });

  // Convert an Expense object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(), // Store date as ISO string
      'description': description,
    };
  }

  // Extract an Expense object from a Map object
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      description: map['description'],
    );
  }
}
