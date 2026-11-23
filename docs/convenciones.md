# Convenciones

Reglas extraídas del código existente. Si vas a añadir algo nuevo, **sigue el patrón que ya usan las features `auth`/`groups`/`projects`/`tasks`** (las otras solo tienen UI de ejemplo).

## Idioma y localización

- **Toda la UI en español.** `main.dart` fuerza `locale: Locale('es','ES')` y añade los delegates de `flutter_localizations`.
- Mensajes de error ya traducidos en `mapToAppError`; los `BusinessError` se crean con texto español en el repositorio (p. ej. «Código inválido», «Ya eres miembro»).
- Fechas con `AppFormatters` (locale `'es'`), nunca `DateFormat` con locale por defecto.
- `pubspec.yaml` → `description` sigue siendo el de la plantilla («A new Flutter project.») — `TODO` menor si algún día publicas algo.

## Estructura y naming

```
lib/features/<feature>/{application,data,domain,presentation/screens}/
```

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivos | `snake_case.dart` | `group_repository.dart` |
| Modelos | Sustantivo en PascalCase, a veces prefijo `App` | `AppUser`, `AppGroup`, `Project`, `Task` |
| Extensiones de modelo | `<Modelo>X` | `AppGroupX.isMember`, `TaskX.isOpen` |
| Repositorios | `<Feature>Repository` | `GroupRepository` |
| Providers | `<cosa>Provider` | `myGroupsProvider`, `taskSyncProvider` |
| Pantallas | `<Cosa>Screen` | `ProjectDetailScreen` |
| Enums | PascalCase; valores JSON en español si son de dominio | `UserRole.docente` → `'docente'` |

## Modelos (domain)

- `@freezed` + `part '*.freezed.dart'` + `part '*.g.dart'` + `factory fromJson`.
- Tras tocar campos: `dart run build_runner build --delete-conflicting-outputs`.
- **Fechas como `int` epoch millis** (`createdAt`, `updatedAt`), jamás `Timestamp`.
- Defaults explícitos con `@Default(...)` para sobrevivir a documentos antiguos.
- Extensiones `copyWithTimestamp()` para actualizar marcas de tiempo.
- Estados como `String` con constantes implícitas (`'draft'`, `'open'`…) + getters de conveniencia (`isNegotiating`); **no** hay enum para los estados de proyecto/tarea.

## Repositorios (data)

Patrón obligatorio (extraído de los 4 repositorios reales):

```dart
class XRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _xCollection => _firestore.collection('…');

  Future<Result<T>> metodo(...) async {
    try {
      // …Firestore…
      return Success(valor);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  Stream<T> watchX(...) => ...snapshots().map(...);   // en crudo, sin Result
}
```

- Las operaciones con varios pasos (código de invitación, alta/baja de miembros) van en **`_firestore.runTransaction`**; los reordenados en `batch()`.
- Excepciones de negocio se lanzan como `Exception('mensaje en español')` y en el `catch` se mapean a `BusinessError` si el mensaje coincide (ver `GroupRepository.joinByCode`).
- Cada repositorio se expone con un `final xRepositoryProvider = Provider<XRepository>((ref) => XRepository())`.
- **No** se usa ningún repositorio de `mockito`/fake: la UI de ejemplo simplemente no tiene repositorio.

## Providers (application)

- Escritos a mano: `Provider`, `StreamProvider` y sus `.family`. **`riverpod_generator` está instalado pero no se usa `@riverpod`; no lo introduzcas.**
- Familias con **records**: `StreamProvider.family<Project?, ({String groupId, String projectId})>`.
- Combinar auth con datos: `authState.when(data: (user) => user == null ? Stream.value([]) : repo.watch…, loading: …, error: …)` (patrón de `myGroupsProvider`).
- Derivados síncronos: `xSyncProvider = Provider.family< X?, ... >` leyendo `asyncX.value`.
- Para reintentos en UI: `ref.invalidate(provider)` dentro de `ErrorScreen.onRetry`.

## Errores y UI

- Las pantallas **nunca** hacen `try/catch` sobre Firebase: usan `result.fold(onSuccess:, onError:)` o `AsyncValue.when`.
- Feedback con `showAppSnackBar(context, msg, isError: true/false)` y confirmaciones destructivas con `showConfirmDialog(..., isDestructive: true)`.
- Estados vacíos/carga/error con `EmptyState`, `CircularProgressIndicator`, `ErrorScreen` (de `core/widgets/common_widgets.dart`).
- Navegación con `context.go('/ruta')` (go_router), no `Navigator.push`, salvo diálogos (`showDialog`).

## Helpers reutilizables (`core/utils/utils.dart`)

| Helper | Para qué |
|---|---|
| `AppFormatters.formatDate/formatDateTime/formatTime/formatRelative/parseDate/timeAgo` | Fechas en español |
| `isValidEmail`, `isStrongPassword` | Validación de formularios de auth |
| `generateJoinCode` | Códigos de 6 caracteres sin `I/O/0/1` (LCG con semilla de tiempo) |
| `showAppSnackBar`, `showConfirmDialog` | Feedback y confirmaciones |
| `truncate`, `capitalizeWords`, `colorFromString`, `clampProgress` | Utilidades de presentación |
| `ContextUtils` (`hideKeyboard`, `screenWidth`, `isMobile`…) y `DateTimeUtils` (`startOfDay`, `isToday`…) | Extensiones de contexto/fecha |

No reimplementes estos helpers: ya están probados en toda la app.

## Widgets compartidos (`core/widgets/common_widgets.dart`)

`LoadingButton` (con `isLoading`), `AppCard` (opcional `onTap`), `EmptyState`, `ErrorScreen`, `UserAvatar` (color determinista con `colorFromString`), `StatusChip` + `StatusType`, `SectionDivider`, `CircularProgressWithPercent`.

## Tema

- Semilla `0xFF2E7D32` (verde) en `AppTheme`; usar `colorScheme` en lugar de colores hardcodeados cuando exista el equivalente.
- La app sigue el tema del sistema (`ThemeMode.system`). **No** persiste preferencia (TODO en `profile_screen.dart:320`); `shared_preferences` está instalado sin usar.

## Qué NO hacer

1. **No edites `lib/firebase_options.dart` ni ejecutes `flutterfire configure` sin revisar** (ver [puesta-en-marcha](puesta-en-marcha.md)).
2. **No cambies las rutas de Firestore a la ligera**: las reglas y los repositorios ya están desalineados; ver [modelo-de-datos](modelo-de-datos.md).
3. **No uses `Timestamp` de Firestore**: todo es `int` epoch millis.
4. **No introduzcas codegen de Riverpod** ni `StateNotifier`: el repo usa providers manuales.
5. **No documentes como funcional** una pantalla con `TODO`, `Future.delayed` o snackbar «(simulado)».
6. **No trates los warnings del analizador como errores** (no hay `flutter analyze --fatal-warnings`), pero tampoco hagas limpiezas masivas ajenas a tu cambio.
7. **No borres `plan.md` ni sus reglas de negocio**: son la única especificación de ofertas/votación/equidad, aunque su modelo de datos esté obsoleto.
