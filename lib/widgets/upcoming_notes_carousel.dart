// lib/widgets/upcoming_notes_carousel.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:exnote/models/note.dart';
import 'package:exnote/providers/note_provider.dart';

class UpcomingNotesCarousel extends StatelessWidget {
  const UpcomingNotesCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final upcomingNotes = Provider.of<NoteProvider>(context).upcomingNotes;

    if (upcomingNotes.isEmpty) {
      return Container(); // Hide if no upcoming notes
    }

    // Only show notes for the next few days/notes
    final notesToShow = upcomingNotes.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Text(
            'Upcoming Plans & Notes',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: notesToShow.length,
            itemBuilder: (context, index) {
              final note = notesToShow[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16.0 : 8.0,
                  right: 8.0,
                ),
                child: _NoteCard(note: note),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final isToday =
        DateFormat.yMd().format(note.date) ==
        DateFormat.yMd().format(DateTime.now());

    return Card(
      color: isToday
          ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
          : Theme.of(context).cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isToday
                  ? 'TODAY'
                  : DateFormat.E().format(note.date).toUpperCase(),
              style: TextStyle(
                color: isToday
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.white : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              note.content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isToday ? Colors.white70 : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
