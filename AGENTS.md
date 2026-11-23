# AGENTS.md

RepartoJusto: Flutter app (Spanish UI, Material 3, `es_ES` forced in `main.dart`) for negotiating task distribution among students. Android + web only. Firebase Spark plan (Auth + Firestore; no Functions/Storage/push). `plan.md` is the product/domain spec, but its data model and phase checklist do not match the code — verify against source. `README.md` is still the untouched Flutter template.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # after any freezed/json model change
flutter analyze
flutter test test/widget_test.dart
flutter run -d <android-device>  # or -d chrome
```

- No Makefile, CI, or task runner; use the Flutter CLI directly.
- `flutter analyze` currently reports ~57 warnings/infos but **zero errors**. Don't treat the warning count as a broken tree, and don't mass-fix unrelated lints.
- Generated `*.freezed.dart` / `*.g.dart` are not gitignored. `auth`/`groups` ones are committed; `projects`/`tasks` ones are untracked. Regenerate after editing a model's fields.
- `riverpod_generator` is in dev_dependencies but no `@riverpod` is used. Providers are hand-written `Provider`/`StreamProvider`, some with record-typed families (e.g. `({String groupId, String projectId})`). Don't introduce codegen for them.
- The only test is a smoke test: pumps `RepartoJustoApp` without `Firebase.initializeApp` and only checks that the login screen renders. It passes today and exercises no Firestore/Auth logic.

## Architecture

- Feature-first: `lib/features/<feature>/{application,data,domain,presentation}`. `auth`, `groups`, `projects`, `tasks` have real data/domain layers. `offers`, `fairness`, `profile` are presentation-only with mock data/TODOs; `notifications` and `comments` have no feature folder.
- `lib/core/` holds `errors` (`AppError`, `Result<T>`), `router`, `theme`, `utils` (validators, formatters, join-code generator), `widgets`, and Firebase config.
- Repositories are plain classes wrapping Firestore; a `*RepositoryProvider` wraps each. Async methods return `Result<T>` and map exceptions via `mapToAppError`; UI uses `fold`/`isSuccess` instead of catching Firebase exceptions. Watch methods return raw streams, not `Result`.
- Routing is centralized in `lib/core/router/app_router.dart`; redirects depend on `authStateChangesProvider` + `currentProfileProvider` from `auth_providers.dart`.
- Models are freezed + json_serializable. Firestore timestamps are `int` epoch millis (`createdAt`, `updatedAt`), not `Timestamp`; enum JSON values are Spanish (`docente`, `estudiante`); status values are lowercase English (`open`, `draft`, `negotiating`, ...).
- `memberIds` is denormalized on groups/projects/tasks. `users.role` is global; `groups.leaderId` is per-group; teacher rights derive from `groups.teacherId`.

## Firebase / data-path gotchas

- **Rules and repositories disagree on paths.** Repositories use subcollections `groups/{groupId}/projects/{projectId}/tasks`, but `firestore.rules` matches top-level `/projects/{id}`, `/tasks/{id}`, `/offers/{id}`, `/tasks/{taskId}/comments/{id}`. Firestore rules don't cascade into subcollections, so nested project/task access is denied. Fix one side before expecting any project/task CRUD to work.
- `firestore.rules` is the security source of truth but is not referenced in `firebase.json` (which has no `firestore` section). Deploy manually (`firebase deploy --only firestore:rules`) or add the config.
- Rules deny all client writes to `activity` (`allow create: if false`) and there is no backend, so writing negotiation history from a client transaction will fail. Resolve before implementing offer resolution.
- `firebase.json` points to `lib/core/firebase/firebase_options.dart`, which was deleted; `main.dart` imports the root `lib/firebase_options.dart`. Dart config exists only for Android and web; other platforms throw `UnsupportedError`. Don't run `flutterfire configure` blindly — it will overwrite these paths.
- No `firestore.indexes.json`. `GroupRepository.watchMyGroups` (`memberIds array-contains` + `createdAt desc`) needs a composite index created in the console. `plan.md` lists further planned indexes.
- Google Sign-In is not functional: `lib/core/firebase/google_auth_config.dart` still has `TU_WEB_CLIENT_ID_AQUI`, and `AuthRepository.googleWebClientId` returns itself (analyzer flags `recursive_getters`). The import of the config is currently unused.
- Domain rules for offers live only in `plan.md` + `firestore.rules` (no code yet): votes are a `{uid: approve|reject}` map, leader/teacher resolution comes from `groups.approvalConfig`, fairness quota = `totalPoints / student count`, warn above +20% and require a reason.

## Conventions

- All user-facing strings are Spanish; keep new UI text Spanish. `lib/core/utils/utils.dart` holds `AppFormatters` plus top-level helpers `isValidEmail`, `isStrongPassword`, and `generateJoinCode` (reuse them instead of re-implementing).
- `main.dart` also clamps `textScaler` to 0.85–1.3 and follows system light/dark theme; local notifications are stubbed out (the init call is commented).
- Most non-auth/groups/projects/tasks screens are mock/TODO UIs — don't assume Firestore wiring exists there.
