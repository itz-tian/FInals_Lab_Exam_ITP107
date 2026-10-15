import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_theme.dart';
import 'screens/details_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/posts_screen.dart';

/// Name of the Hive box that stores favorite posts.
const String favoritesBoxName = 'favoritesBox';

/// Name of the Hive box that stores cached posts and user-created posts.
const String postsBoxName = 'postsBox';

Future<void> main() async {
  // Required before using any platform channel (Hive's path_provider) in main().
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes Hive in the app's documents directory.
  await Hive.initFlutter();

  // Open the boxes BEFORE runApp so screens can use them synchronously.
  await Hive.openBox(favoritesBoxName);
  await Hive.openBox(postsBoxName);

  runApp(const PostReaderApp());
}

class PostReaderApp extends StatelessWidget {
  const PostReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Reader & Favorites',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const PostsScreen(),
        '/details': (context) => const PostDetailsScreen(),
        '/favorites': (context) => const FavoritesScreen(),
      },
    );
  }
}
