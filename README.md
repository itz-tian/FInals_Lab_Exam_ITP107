# Post Reader & Favorites

Flutter app (ITP107 Finals Lab Exam): fetches posts from JSONPlaceholder, opens a post, and saves favorites locally with Hive.

## Setup
```bash
bash setup_platforms.sh   # one time: flutter create + native config
flutter run
```
(Windows: run the commands inside the script manually, or use Git Bash.)

## Native dependency configuration
| Dependency | Native requirement | Where |
|---|---|---|
| `http` | `INTERNET` permission (required for release builds on Android) | `android/app/src/main/AndroidManifest.xml` |
| `http` | `com.apple.security.network.client` entitlement (macOS only) | `macos/Runner/*.entitlements` |
| `hive_flutter` | `path_provider` native plugin (auto-registered by `flutter pub get`); needs `WidgetsFlutterBinding.ensureInitialized()` before `Hive.initFlutter()` | `lib/main.dart` |

## Structure
- `lib/main.dart` – Hive init, named routes (`/`, `/details`, `/favorites`)
- `lib/app_theme.dart` – ThemeData
- `lib/screens/posts_screen.dart` – GET list, POST dialog, error display
- `lib/screens/details_screen.dart` – route arguments, Save to Favorites (put)
- `lib/screens/favorites_screen.dart` – read, edit note (update), delete

## Exam checklist
Part 1 routes ✔ · Part 2 GET/POST + error handling ✔ · Part 3 Hive CRUD + persistence ✔
# FInals_Lab_Exam_ITP107
