import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../app_theme.dart';
import '../main.dart' show postsBoxName;

/// Route '/' - fetches posts with GET and lets the user create one with POST.
class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  static const String _url = 'https://jsonplaceholder.typicode.com/posts';

  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _error;
  int _nextId = 101;

  @override
  void initState() {
    super.initState();
    _loadPersistedPosts();
    _fetchPosts(); // async method called from initState()
  }

  /// Loads cached articles and user-created posts from Hive immediately.
  void _loadPersistedPosts() {
    try {
      final box = Hive.box(postsBoxName);
      final rawUserPosts = box.get('user_posts');
      final rawCachedPosts = box.get('cached_posts');

      final userPosts = (rawUserPosts is List ? rawUserPosts : [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final cachedPosts = (rawCachedPosts is List ? rawCachedPosts : [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (userPosts.isNotEmpty || cachedPosts.isNotEmpty) {
        _posts = [...userPosts, ...cachedPosts];
        _loading = false;
        _computeNextId();
      }
    } catch (_) {
      // Fallback silently if cache is invalid
    }
  }

  void _computeNextId() {
    int maxId = 100;
    for (final p in _posts) {
      final id = p['id'] is int
          ? p['id'] as int
          : int.tryParse('${p['id']}') ?? 0;
      if (id > maxId) maxId = id;
    }
    _nextId = maxId + 1;
  }

  // ---------------------------------------------------------------- GET
  Future<void> _fetchPosts() async {
    if (_posts.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await http.get(Uri.parse(_url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        final fetched = data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList()
            .reversed
            .toList();

        // Persist cached posts to Hive for offline availability
        try {
          final box = Hive.box(postsBoxName);
          await box.put('cached_posts', fetched);

          final rawUser = box.get('user_posts');
          final userPosts = (rawUser is List ? rawUser : [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          if (!mounted) return;
          setState(() {
            _posts = [...userPosts, ...fetched];
            _loading = false;
            _error = null;
            _computeNextId();
          });
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _posts = fetched;
            _loading = false;
            _error = null;
            _computeNextId();
          });
        }
      } else {
        if (!mounted) return;
        if (_posts.isEmpty) {
          setState(() {
            _error =
                'Unable to load articles right now (Error ${response.statusCode}).';
            _loading = false;
          });
        } else {
          _showMessage(
            'Unable to refresh (Status ${response.statusCode}). Showing cached articles.',
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      if (_posts.isEmpty) {
        setState(() {
          _error =
              'Could not connect to the network. Please check your internet connection and try again.';
          _loading = false;
        });
      } else {
        _showMessage(
          'Offline mode: showing previously saved articles.',
        );
      }
    }
  }

  // --------------------------------------------------------------- POST
  Future<void> _createPost(String title, String body) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final newId = _nextId++;
        final newPost = <String, dynamic>{
          'id': newId,
          'title': title,
          'body': body,
          'userId': 1,
        };

        // Persist user-created post to Hive so it survives app restarts!
        try {
          final box = Hive.box(postsBoxName);
          final rawUser = box.get('user_posts');
          final userPosts = (rawUser is List ? rawUser : [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          userPosts.insert(0, newPost);
          await box.put('user_posts', userPosts);
        } catch (_) {}

        if (!mounted) return;
        setState(() {
          _posts.insert(0, newPost);
        });

        _showMessage(
          'Post created successfully (#$newId, status 201)',
        );
      } else {
        _showMessage(
          'Unable to publish article (Error ${response.statusCode}).',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Could not publish article. Please check your internet connection.',
        isError: true,
      );
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor:
              isError ? AppTheme.danger : AppTheme.primary,
        ),
      );
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _CreateArticleDialog(),
    );

    if (result != null && mounted) {
      await _createPost(result['title']!, result['body']!);
    }
  }

  // ----------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Reader'),
        actions: [
          IconButton(
            tooltip: 'Saved Favorites',
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Write Article',
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.edit_outlined, size: 20),
        label: const Text('Write'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading articles…',
              style: AppTheme.sans(
                size: 14,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 36,
                  color: AppTheme.danger,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Connection Failed',
                style: AppTheme.sfPro(
                  size: 18,
                  weight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTheme.sans(
                  size: 14,
                  color: AppTheme.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                child: ElevatedButton.icon(
                  onPressed: _fetchPosts,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  size: 40,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Articles Available',
                style: AppTheme.sfPro(size: 18, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh or write a new article using the button below.',
                textAlign: TextAlign.center,
                style: AppTheme.sans(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchPosts,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 44),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _fetchPosts,
      child: CustomScrollView(
        slivers: [
          // ── Section header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Articles',
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
                      '${_posts.length}',
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

          // ── Article list ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.only(top: 4, bottom: 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _posts[index];
                  return _ArticleCard(post: post);
                },
                childCount: _posts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Extracted card widget for cleanliness ──────────────────────────────────
class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.post});
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final int id = post['id'] is int
        ? post['id'] as int
        : int.tryParse('${post['id']}') ?? 0;
    final String title = (post['title'] ?? 'Untitled').toString();
    final String body = (post['body'] ?? '').toString();

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
              // ── Meta row ──────────────────────────────────────────
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
                  const SizedBox(width: 8),
                  Text(
                    '3 min read',
                    style: AppTheme.sans(
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: AppTheme.textMuted,
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
              // ── Preview body (Inter muted) ────────────────────────
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
            ],
          ),
        ),
      ),
    );
  }
}

// ── Standalone dialog widget: owns its controllers & lifecycle cleanly ─────
class _CreateArticleDialog extends StatefulWidget {
  const _CreateArticleDialog();

  @override
  State<_CreateArticleDialog> createState() => _CreateArticleDialogState();
}

class _CreateArticleDialogState extends State<_CreateArticleDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  String? _titleError;
  String? _bodyError;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    setState(() {
      _titleError = title.isEmpty ? 'Title cannot be empty' : null;
      _bodyError = body.isEmpty ? 'Body cannot be empty' : null;
    });

    if (title.isNotEmpty && body.isNotEmpty) {
      Navigator.pop(context, {'title': title, 'body': body});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write an Article'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share your thoughts with the community.',
            style: AppTheme.sans(
              size: 13,
              color: AppTheme.textMuted,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Article Title',
              hintText: 'e.g., Why Mobile UX Matters',
              errorText: _titleError,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Content',
              hintText: 'Write a brief description or summary...',
              errorText: _bodyError,
            ),
          ),
          const SizedBox(height: 4),
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
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
            ),
            onPressed: _submit,
            child: const Text('Publish'),
          ),
        ),
      ],
    );
  }
}


