import 'package:flutter/material.dart';

import '../data/notes_repository.dart';
import '../models/note.dart';
import '../ui/common.dart';

class NoteDetailsPage extends StatefulWidget {
  final int id;
  final NotesRepository repo;
  const NoteDetailsPage({super.key, required this.id, required this.repo});

  @override
  State<NoteDetailsPage> createState() => _NoteDetailsPageState();
}

class _NoteDetailsPageState extends State<NoteDetailsPage> {
  late Future<Note> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.get(widget.id);
  }

  void _reload() {
    setState(() => _future = widget.repo.get(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Note>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Запись #${widget.id}')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Не удалось загрузить запись'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _reload,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final note = snap.data!;
        return Scaffold(
          appBar: AppBar(title: Text('Запись #${note.id}')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.pink.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.body,
                    style: const TextStyle(fontSize: 16, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
