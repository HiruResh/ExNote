// lib/models/note.dart

class Note {
  int? id;
  String title;
  String content;
  DateTime date; // The date the note/list is scheduled for

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.date,
  });

  // Convert an Note object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(), // Store date as ISO string
    };
  }

  // Extract an Note object from a Map object
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.parse(map['date']),
    );
  }

  Note copyWith({int? id, String? title, String? content, DateTime? date}) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
    );
  }
}
