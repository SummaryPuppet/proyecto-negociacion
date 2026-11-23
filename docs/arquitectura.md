# Arquitectura

RepartoJusto sigue un patrón **feature-first con capas** (`application` / `data` / `domain` / `presentation`), estado con **Riverpod** (providers escritos a mano, sin codegen), navegación con **go_router** y backend **Firebase** (Auth + Firestore).

- Estados de cada feature: [funcionalidades.md](funcionalidades.md).
- Rutas de Firestore y reglas: [modelo-de-datos.md](modelo-de-datos.md).
- Convenciones al escribir código nuevo: [convenciones.md](convenciones.md).

## Estructura por features y capas

| Feature | `presentation` | `domain` | `data` | `application` | Estado |
|---|---|---|---|---|---|
| `auth` | ✅ login, registro, selección de rol, splash | ✅ `AppUser`, `UserRole` | ✅ `AuthRepository`, `UserRepository` | ✅ | Funcional |
| `groups` | ✅ lista y detalle de grupo | ✅ `AppGroup`, `ApprovalConfig` | ✅ `GroupRepository` | ✅ | Funcional |
| `projects` | ✅ lista y detalle de proyecto | ✅ `Project` | ✅ `ProjectRepository` | ✅ | Funcional |
| `tasks` | ✅ detalle de tarea | ✅ `Task` | ✅ `TaskRepository` | ✅ | Parcial (ver [funcionalidades](funcionalidades.md)) |
| `offers` | ✅ `OfferFormScreen` | ❌ | ❌ | ❌ | Solo UI simulada |
| `fairness` | ✅ `FairnessScreen` | ❌ | ❌ | ❌ | Solo UI con datos mock |
| `profile` | ✅ `ProfileScreen` | ❌ | ❌ | ❌ | Solo UI con TODOs |
| `notifications` | ❌ | ❌ | ❌ | ❌ | No existe la carpeta |
| `comments` | ❌ | ❌ | ❌ | ❌ | No existe la carpeta |

Responsabilidades de cada capa (verificado en el código):

| Capa | Contenido | Ejemplo |
|---|---|---|
| `domain/` | Modelos freezed + `fromJson`/`toJson` + extensiones de negocio | `lib/features/tasks/domain/task.dart` (`TaskX.isOpen`) |
| `data/` | Clases-planas que envuelven Firestore/Firebase Auth; devuelven `Result<T>` | `TaskRepository.createTask(...)` |
| `application/` | Providers de Riverpod que exponen repositorios y streams | `tasksProvider`, `myGroupsProvider` |
| `presentation/screens/` | Pantallas (`ConsumerWidget`/`ConsumerStatefulWidget`) que leen providers y muestran `fold` | `TaskDetailScreen` |

No hay casos de uso intermedios ni capa de servicios: **la pantalla llama directamente al repositorio** a través de su provider (`ref.read(taskRepositoryProvider).deleteTask(...)`).

## `lib/core/`

| Módulo | Contenido |
|---|---|
| `core/errors/app_error.dart` | `AppError` (sealed) + subtipos, `mapToAppError`, `Result<T>` (`Success`/`Failure`), extensión `ResultX.fold`/`foldAsync` |
| `core/router/app_router.dart` | `appRouterProvider` (go_router): rutas, `redirect` de auth/perfil, `errorBuilder` |
| `core/theme/app_theme.dart` | `AppTheme.getTheme(Brightness)`: semilla `0xFF2E7D32`, claro y oscuro |
| `core/utils/utils.dart` | `AppFormatters`, `isValidEmail`, `isStrongPassword`, `generateJoinCode`, `showAppSnackBar`, `showConfirmDialog`, `colorFromString`, extensiones `ContextUtils`/`DateTimeUtils` |
| `core/widgets/common_widgets.dart` | `LoadingButton`, `AppCard`, `EmptyState`, `ErrorScreen`, `UserAvatar`, `StatusChip` (`StatusType`), `SectionDivider`, `CircularProgressWithPercent` |
| `core/firebase/google_auth_config.dart` | Constante `googleWebClientId` con placeholder `TU_WEB_CLIENT_ID_AQUI` |

## Patrón de errores: `AppError` y `Result<T>`

`lib/core/errors/app_error.dart` define una jerarquía sellada:

| Tipo | Uso |
|---|---|
| `AuthError` | Errores de Firebase Auth (`email-already-in-use`, `weak-password`, `invalid-credential`…) |
| `NetworkError` | `network-request-failed` |
| `PermissionError` | `permission-denied` de Firestore |
| `ValidationError` | Datos inválidos (email/contraseña débil, argumentos) |
| `BusinessError` | Reglas de negocio violadas por el usuario (p. ej. «Código inválido», «Ya eres miembro») |
| `UnknownError` | Fallback con el mensaje original |

Flujo obligatorio en repositorios:

1. Los métodos **asíncronos** devuelven `Future<Result<T>>` y hacen `try/catch`: `on FirebaseException` y `catch (e, st)` → `Failure(mapToAppError(e, st))`.
2. Las UI **nunca** capturan excepciones de Firebase: usan `result.fold(onSuccess: …, onError: …)` o comprueban `result.isSuccess`.
3. Los métodos **de stream** (`watch*`, `get*` una vez) devuelven `Stream<T>`/`Future<T?>` **en crudo**, sin `Result`; los errores llegan como `AsyncValue.error` de Riverpod y la UI muestra `ErrorScreen`.

## Inyección y providers

Todo se declara como `Provider` o `StreamProvider` **escritos a mano** (el paquete `riverpod_generator` está en `dev_dependencies` pero no se usa `@riverpod` en ningún archivo). No introducir codegen de providers.

### Auth (`lib/features/auth/application/auth_providers.dart`)

| Provider | Tipo | Descripción |
|---|---|---|
| `authRepositoryProvider` | `Provider<AuthRepository>` | Instancia del repositorio de auth |
| `userRepositoryProvider` | `Provider<UserRepository>` | Instancia del repositorio de perfiles |
| `authStateChangesProvider` | `StreamProvider<firebase_auth.User?>` | Sesión de Firebase Auth |
| `currentProfileProvider` | `StreamProvider<AppUser?>` | Perfil en Firestore (`users/{uid}`); `null` si no hay sesión o perfil |
| `currentProfileSyncProvider` | `Provider<AppUser?>` | Versión síncrona (`asyncValue.value`) |
| `currentUserRoleProvider` | `Provider<UserRole?>` | Rol actual para UI condicional |
| `isSignedInProvider` / `isProfileLoadingProvider` / `hasChosenRoleProvider` | `Provider<bool>` | Atajos de estado |

### Groups (`group_providers.dart`)

| Provider | Tipo | Descripción |
|---|---|---|
| `groupRepositoryProvider` | `Provider<GroupRepository>` | Repositorio |
| `myGroupsProvider` | `StreamProvider<List<AppGroup>>` | Grupos donde `uid ∈ memberIds` (depende de `authStateChangesProvider`) |
| `groupProvider` / `groupSyncProvider` | `StreamProvider.family`/`Provider.family` con `String` (groupId) | Grupo concreto |
| `isGroupTeacherProvider`, `isGroupLeaderProvider`, `groupHasLeaderProvider`, `groupApprovalConfigProvider` | familias `String` | Derivados del grupo |

### Projects y tasks

| Provider | Argumento | Descripción |
|---|---|---|
| `projectsProvider` | `String` (groupId) | Proyectos del grupo |
| `projectProvider`, `projectSyncProvider`, `isProjectTeacherProvider` | record `({String groupId, String projectId})` | Proyecto concreto y permisos |
| `tasksProvider` | record `({String groupId, String projectId})` | Tareas del proyecto |
| `taskProvider`, `taskSyncProvider`, `isTaskAssigneeProvider`, `isTaskAssignedToMeProvider` | record `({String groupId, String projectId, String taskId})` | Tarea concreta |

Los familias usan **records de Dart** como argumento (no clases `Equatable`). Ejemplo: `ref.watch(taskProvider((groupId: g, projectId: p, taskId: t)))`.

## Arranque (`lib/main.dart`)

1. `WidgetsFlutterBinding.ensureInitialized()` → `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
2. `runApp(ProviderScope(child: RepartoJustoApp()))`.
3. `MaterialApp.router` con:
   - `locale: Locale('es','ES')` forzado + delegates de `flutter_localizations`;
   - `themeMode: ThemeMode.system` con `AppTheme.getTheme(light/dark)`;
   - `builder` global que recorta el `textScaler` al rango **0.85–1.3**;
   - notificaciones locales **comentadas** (la llamada `// await _initLocalNotifications();` no tiene función asociada en `main.dart`).

## Navegación (`lib/core/router/app_router.dart`)

- `appRouterProvider` construye un `GoRouter` con `initialLocation: '/login'`.
- `refreshListenable` con un `_RouterRefresh` (ChangeNotifier que escucha `authStateChangesProvider` y `currentProfileProvider` y llama `notifyListeners()`), para reevaluar el `redirect` sin recrear el router.
- El `redirect` aplica estas reglas (líneas 47–78):

| Situación | Redirección |
|---|---|
| Sin sesión y la ruta no es `/`, `/login`, `/register` ni `/role-selection` | → `/login` |
| Sesión activa pero **sin perfil** (`users/{uid}` inexistente), y el perfil ya no está cargando | → `/role-selection` |
| Sesión + perfil y ruta de auth (`/login`, `/register`, `/role-selection`) | → `/groups` |

### Rutas

| Ruta | Nombre | Pantalla |
|---|---|---|
| `/` | `splash` | `SplashScreen` (mensajes de carga de auth/perfil) |
| `/login` | `login` | `LoginScreen` |
| `/register` | `register` | `RegisterScreen` |
| `/role-selection` | `roleSelection` | `RoleSelectionScreen` |
| `/groups` | `groups` | `GroupsListScreen` |
| `/groups/create` | `createGroup` | `GroupDetailScreen(isCreating: true)` |
| `/groups/:groupId` | `groupDetail` | `GroupDetailScreen` |
| `/groups/:groupId/projects` | `groupProjects` | `ProjectsListScreen` |
| `/groups/:groupId/projects/create` | `createProject` | `ProjectDetailScreen(isCreating: true)` |
| `/groups/:groupId/projects/:projectId` | `projectDetail` | `ProjectDetailScreen` |
| `/groups/:groupId/projects/:projectId/tasks/:taskId` | `taskDetail` | `TaskDetailScreen` |
| `/groups/:groupId/projects/:projectId/fairness` | `projectFairness` | `FairnessScreen` (datos mock) |
| `/offers/new` | `newOffer` | `OfferFormScreen` — **sin navegaciones que apunten a ella** (ver [funcionalidades](funcionalidades.md)); además exige `state.extra` con `groupId`/`projectId`/`taskId` |
| `/profile` | `profile` | `ProfileScreen` |

Cualquier ruta desconocida cae en `errorBuilder` («Página no encontrada» con botón a `/groups`).

## Flujo de datos típico

```
Pantalla (ConsumerWidget)
  → ref.watch(<provider>)            # lectura reactiva de streams
  → ref.read(xRepositoryProvider)    # escritura puntual
      → Repositorio (Firestore) → Result<T> con mapToAppError
  → result.fold(onSuccess, onError)  # UI en español vía showAppSnackBar
```

Ejemplo real: `ProjectDetailScreen._confirmStartNegotiation` → `projectRepositoryProvider.setStatus(status: 'negotiating')` → `fold` → `showAppSnackBar('Negociación iniciada')`.
