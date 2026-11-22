# AGENTS.md

RepartoJusto: Flutter app (Spanish UI, Material 3) for negotiating task distribution among students. Android-first; Firebase Spark only (Auth + Firestore, no Functions/Storage/push). `plan.md` is the product/domain spec (its phase checklist is stale); `README.md` is still the default Flutter template.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # after any freezed/json model change
flutter analyze
flutter test test/widget_test.dart
flutter run -d <android-device>  # or -d chrome
```

- Generated `*.freezed.dart` / `*.g.dart` files are not committed and not gitignored. Generate them before analyzing/building.
- No Makefile, CI, or task runner; use the Flutter CLI directly.
- The only test is a smoke test. It pumps `RepartoJustoApp` without `Firebase.initializeApp`, so it needs Firebase init/mocking once the app compiles.

## Architecture

- Feature-first: `lib/features/<feature>/{application,data,domain,presentation}`. Only `auth` and `groups` currently have data/domain layers; `projects`, `tasks`, `offers`, `fairness`, and `profile` are presentation-only mock/TODO screens. `notifications`/`comments` have no feature folder yet.
- `lib/core/` holds shared `errors` (`AppError`, `Result<T>`), `router`, `theme`, `utils`, `widgets`, and Firebase config.
- Riverpod providers are hand-written `Provider`/`StreamProvider`s, not `@riverpod` codegen. Repositories are plain classes; providers wrap them.
- Repositories return `Result<T>` and map exceptions through `mapToAppError`; UI uses `fold`/`isSuccess` instead of catching Firebase exceptions.
- Models are freezed + json_serializable. Firestore timestamps are `int` epoch millis (`createdAt`), not `Timestamp`; enum JSON values are Spanish (`docente`, `estudiante`).
- Routing is centralized in `lib/core/router/app_router.dart` (nested `/groups/:groupId/projects/:projectId/...`). Auth redirects use `authStateChangesProvider` + `currentProfileProvider`.
- All user-facing strings are Spanish; locale is forced to `es_ES` in `main.dart`.

## Firebase / domain

- Firebase project `proyecto-negociacion`. Options live in root `lib/firebase_options.dart`; `lib/core/firebase/firebase_options.dart` was deleted but `firebase.json` still points to it, so don't run `flutterfire configure` blindly.
- Only Android and web options exist; iOS/macOS/Windows/Linux throw `UnsupportedError` from `DefaultFirebaseOptions.currentPlatform`.
- `firestore.rules` is the security source of truth but is not wired into `firebase.json` (no `firestore` section). Deploy manually or add the config.
- No `firestore.indexes.json`: `GroupRepository.watchMyGroups` (`memberIds array-contains` + `createdAt desc`) needs a composite index; create it in the console.
- Collections: `users`, `groups`, `joinCodes`, `projects`, `tasks` (+ `comments` subcollection), `offers`, `activity`, `notifications`. `memberIds` is denormalized on groups/projects/tasks; `users.role` is global, `groups.leaderId` is per-group.
- Offers: votes are a `{uid: approve|reject}` map; leader vote weight, quorum, and teacher override come from `groups.approvalConfig`. Fairness quota = `totalPoints / student count`; warn above +20% and require a reason.
- Rules currently deny all client writes to `activity`, yet there is no backend (Spark, no Functions); history writes from client transactions will fail. Resolve this before implementing offer resolution.
- Google Sign-In needs a real Web client ID in `lib/core/firebase/google_auth_config.dart` (`TU_WEB_CLIENT_ID_AQUI` is a placeholder); `AuthRepository.googleWebClientId` also recursively returns itself and must be fixed.

## Known state (Nov 2026)

- The working tree has an uncommitted move to the layered feature layout and does not compile. `flutter analyze` is the source of truth; expect missing generated files, missing imports in `splash_screen.dart`, and intra-feature imports one `..` too deep (from `application/` use `../data`, from `data/` use `../domain`, from `presentation/screens/` use `../../application`).
- `group_providers.dart` defines `firebaseAuthStateProvider` as a throwing stub; `myGroupsProvider` depends on it, so the groups list crashes until it is wired to `authStateChangesProvider`.
- `app_router.dart` declares its own `authStateChangesProvider` that shadows the one in `auth_providers.dart`; prefer the auth-providers version and remove the duplicate.
- Most non-auth/groups screens use mock data or TODOs; don't assume Firestore wiring exists.
