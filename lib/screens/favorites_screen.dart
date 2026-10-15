import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_theme.dart';
import '../main.dart' show favoritesBoxName;

/// Route '/favorites' - READ (list), UPDATE (edit note) and DELETE.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _editNote(
      BuildContext context, Box box, Map<dynamic, dynamic> post) async {
    final title = (post['title'] ?? 'Untitled').toString();
    final initialNote = (post['note'] ?? '').toString();

    final newNote = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditNoteDialog(
        title: title,
        initialNote: initialNote,
      ),
    );

    if (newNote != null) {
      // UPDATE: write the modified map back under the same key.
      final id = post['id'];
      box.put(id, {...post, 'note': newNote});
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Note updated.')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(favoritesBoxName);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Saved Articles'),
      ),
      // Rebuilds automatically whenever the box changes.
      body: ValueListenableBuilder<Box>(
        valueListenable: box.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return _EmptyState();
          }

          // READ: all saved posts from box.values
          final posts = box.values.toList();

          return CustomScrollView(
            slivers: [
              // Section label
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Saved',
                        style: AppTheme.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${posts.length}',
                          style: AppTheme.sans(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.only(top: 4, bottom: 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = Map<dynamic, dynamic>.from(
                        posts[index] as Map,
                      );
                      return _FavoriteCard(
                        post: post,
                        box: box,
                        onEdit: () => _editNote(context, box, post),
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.accentSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 44,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nothing saved yet',
              style: AppTheme.sfPro(
                size: 20,
                weight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Open any article and tap "Save to Favorites" to store it here for later reading.',
              textAlign: TextAlign.center,
              style: AppTheme.sans(
                size: 14,
                color: AppTheme.textMuted,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Favorite card ──────────────────────────────────────────────────────────
class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.post,
    required this.box,
    required this.onEdit,
  });

  final Map<dynamic, dynamic> post;
  final Box box;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final int id = post['id'] is int
        ? post['id'] as int
        : int.tryParse('${post['id']}') ?? 0;
    final String title = (post['title'] ?? 'Untitled').toString();
    final String body = (post['body'] ?? '').toString();
    final String note = (post['note'] ?? '').toString();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
          context,
          '/details',
          arguments: {
            'id': id,
            'title': title,
            'body': body,
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: badge + actions ──────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$id',
                      style: AppTheme.sans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Edit note
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete
                  GestureDetector(
                    onTap: () {
                      // DELETE
                      box.delete(id);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Removed from favorites.'),
                          ),
                        );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Title (SF Pro) ────────────────────────────
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sfPro(
                  size: 18,
                  weight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),

              // ── Body preview ─────────────────────────────────────
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sans(
                  size: 13.5,
                  color: AppTheme.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),

              // ── Note chip ─────────────────────────────────────────
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: note.isEmpty
                        ? const Color(0xFFF8FAFC)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: note.isEmpty
                          ? AppTheme.border
                          : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        note.isEmpty
                            ? Icons.add_comment_outlined
                            : Icons.sticky_note_2_rounded,
                        size: 14,
                        color: note.isEmpty ? AppTheme.textMuted : AppTheme.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note.isEmpty
                              ? 'Tap to add a study note…'
                              : note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.sans(
                            size: 12,
                            weight: note.isEmpty
                                ? FontWeight.w400
                                : FontWeight.w500,
                            color: note.isEmpty
                                ? AppTheme.textMuted
                                : const Color(0xFF1E40AF),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Standalone edit note dialog: owns controller lifecycle & validates ─────
class _EditNoteDialog extends StatefulWidget {
  const _EditNoteDialog({
    required this.title,
    required this.initialNote,
  });

  final String title;
  final String initialNote;

  @override
  State<_EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<_EditNoteDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = 'Note cannot be empty';
      });
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Study Note'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.sfPro(
              size: 14,
              weight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: 'Your note',
              hintText: 'e.g., Review for finals exam...',
              errorText: _error,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: _submit,
            child: const Text('Save Note'),
          ),
        ),
      ],
    );
  }
}

