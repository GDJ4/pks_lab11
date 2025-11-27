import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/notes_repository.dart';
import '../models/note.dart';
import '../ui/common.dart';
import 'note_details_page.dart';

const _baseUrl = 'https://jsonplaceholder.typicode.com';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late final NotesRepository _repo;
  final List<Note> _items = [];
  bool _loading = false;
  bool _initialLoad = true;
  bool _canLoadMore = true;
  int _page = 1;
  static const _pageSize = 15;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = NotesRepository(ApiClient(baseUrl: _baseUrl));
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _page = 1;
      _canLoadMore = true;
      _items.clear();
      _initialLoad = true;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_canLoadMore || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final batch = await _repo.list(page: _page, limit: _pageSize);
      setState(() {
        _items.addAll(batch);
        _canLoadMore = batch.isNotEmpty;
        if (_canLoadMore) _page++;
      });
    } catch (e) {
      _error = 'Не удалось загрузить данные';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialLoad = false;
        });
      }
    }
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<_CreateNoteResult>(
      context: context,
      builder: (_) => const _CreateNoteDialog(),
    );
    if (result == null || result.title.isEmpty) return;

    try {
      final created = await _repo.create(result.title, result.body);
      setState(() => _items.insert(0, created));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Создано (демо, jsonplaceholder)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Не удалось создать: $e')));
      }
    }
  }

  Future<void> _deleteNote(int index) async {
    if (index < 0 || index >= _items.length) return;
    final note = _items[index];
    setState(() => _items.removeAt(index));
    try {
      await _repo.delete(note.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Удалено (демо, jsonplaceholder)')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _items.insert(index, note));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Notes Feed')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Material(
            color: AppColors.pinkLight.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openCreateDialog,
              child: const Center(
                child: Icon(Icons.add, size: 34, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.pink,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_initialLoad && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return _ErrorState(message: _error!, onRetry: _refresh);
    }
    if (_items.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      itemCount: _items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        if (i == _items.length) {
          if (_canLoadMore) {
            _loadMore();
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }

        final note = _items[i];
        return _NoteCard(
          note: note,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteDetailsPage(id: note.id, repo: _repo),
            ),
          ),
          onDelete: () => _deleteNote(i),
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.pink.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pink, width: 2),
                  color: AppColors.pink.withOpacity(0.1),
                ),
                child: Text(
                  '#${note.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      note.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(child: NotebookIcon(size: 120, color: AppColors.pink)),
        SizedBox(height: 12),
        Center(
          child: Text(
            'Список пуст — обновите или добавьте заметку',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        Center(child: Icon(Icons.cloud_off, color: Colors.white70, size: 64)),
        const SizedBox(height: 12),
        Center(child: Text(message, style: const TextStyle(fontSize: 16))),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70, width: 1.5),
            ),
            child: const Text('Повторить'),
          ),
        ),
      ],
    );
  }
}

class _CreateNoteResult {
  final String title;
  final String body;
  const _CreateNoteResult(this.title, this.body);
}

class _CreateNoteDialog extends StatefulWidget {
  const _CreateNoteDialog();

  @override
  State<_CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<_CreateNoteDialog> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(_CreateNoteResult(title, body));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Новая запись',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Заголовок'),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Текст'),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
