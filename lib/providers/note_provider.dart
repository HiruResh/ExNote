import 'package:flutter/material.dart';
import 'package:exnote/models/note.dart';
import 'package:exnote/services/database_service.dart';
import 'package:exnote/services/note_service.dart';

class NoteProvider with ChangeNotifier {
  // FIX: Service is now initialized with the injected DatabaseService
  final NoteService _noteService;
  List<Note> _allNotes = [];
  List<Note> _upcomingNotes = []; // Notes scheduled for today or later

  List<Note> get allNotes => _allNotes;
  List<Note> get upcomingNotes => _upcomingNotes;

  // FIX: Constructor now requires DatabaseService instance
  NoteProvider(DatabaseService dbService)
    : _noteService = NoteService(dbService) {
    // Assume NoteService accepts dbService
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    _allNotes = await _noteService.readAllNotes();
    _upcomingNotes = _allNotes.where((note) {
      final noteDate = DateTime(note.date.year, note.date.month, note.date.day);
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);
      return noteDate.isAfter(todayNormalized) ||
          noteDate.isAtSameMomentAs(todayNormalized);
    }).toList();
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    await _noteService.create(note);
    await _loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await _noteService.update(note);
    await _loadNotes();
  }

  Future<void> deleteNote(int id) async {
    await _noteService.delete(id);
    await _loadNotes();
  }
}
