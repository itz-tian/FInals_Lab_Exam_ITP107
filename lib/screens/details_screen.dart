import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_theme.dart';
import '../main.dart' show favoritesBoxName;

/// Route '/details' - shows the post passed via route arguments and lets the
/// user save it to Hive (CREATE).
class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the arguments passed by Navigator.pushNamed().
    final rawArgs = ModalRoute.of(context)!.settings.arguments;

    if (rawArgs == null || rawArgs is! Map) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to Articles',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          title: const Text('Article Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.pad * 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.article_outlined,
                  size: 48,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Article Selected',
                  style: AppTheme.sfPro(
                    size: 18,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please select an article from the reader to view details.',
                  textAlign: TextAlign.center,
                  style: AppTheme.sans(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/'),
                    child: const Text('Back to Articles'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final args = Map<String, dynamic>.from(rawArgs);
    final int id = (args['id'] as int?) ?? 1;
    final String title = (args['title'] as String?) ?? 'Untitled';
    final String body = (args['body'] as String?) ?? '';

    final box = Hive.box(favoritesBoxName);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'View Saved',
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta chips row
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            'Mobile Dev',
                            style: AppTheme.sans(
                              size: 11,
                              weight: FontWeight.w600,
                              color: AppTheme.accent,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#$id  ·  3 min read',
                          style: AppTheme.sans(
                            size: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Title — SF Pro
                    Text(
                      title,
                      style: AppTheme.sfPro(
                        size: 24,
                        weight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider with accent line
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppTheme.border,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Body — Inter, generous line height
                    Text(
                      body,
                      style: AppTheme.sans(
                        size: 16,
                        color: const Color(0xFF334155),
                        height: 1.75,
                        weight: FontWeight.w400,
                        letterSpacing: 0.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Sticky bottom action dock ────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                  top: BorderSide(color: AppTheme.border),
                ),
              ),
              child: ValueListenableBuilder<Box>(
                valueListenable: box.listenable(keys: [id]),
                builder: (context, _, __) {
                  final bool saved = box.containsKey(id);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Save button — state-reactive
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                saved ? const Color(0xFF1E293B) : AppTheme.accent,
                          ),
                          icon: Icon(
                            saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 18,
                            color: saved
                                ? const Color(0xFFFBBF24)
                                : Colors.white,
                          ),
                          label: Text(
                            saved ? 'Saved to Favorites' : 'Save to Favorites',
                          ),
                          onPressed: () {
                            // The post id is the key, so the same post is never
                            // stored twice. Existing notes are preserved.
                            final existing = box.get(id);
                            final String existingNote = existing is Map
                                ? (existing['note']?.toString() ?? '')
                                : '';

                            box.put(id, {
                              'id': id,
                              'title': title,
                              'body': body,
                              'note': existingNote,
                            });

                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    saved
                                        ? 'Favorite updated.'
                                        : 'Added to favorites!',
                                  ),
                                ),
                              );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back to Articles'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
