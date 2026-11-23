# Estado y limitaciones

Verificación realizada sobre el árbol de trabajo el **22 de noviembre de 2026** (las cifras y `git status` de la sección 1 corresponden al momento de la medición; el árbol tenía **cambios sin confirmar en curso**, posiblemente de otras sesiones).

## 1. Estado del árbol de trabajo

### Medidas (22/11/2026, ~21:53)

| Comando | Resultado |
|---|---|
| `flutter analyze` | **61 issues: 3 errores, 28 warnings, 30 infos** |
| `flutter test` | **Falla** (`test/widget_test.dart` no compila) |

Los 3 errores son de `lib/core/router/app_router.dart` (cambio sin confirmar en revisión):

| Error | Ubicación |
|---|---|
| `directive_after_declaration` (imports después de la clase `_RouterRefresh`) | `app_router.dart:35` y `:36` |
| `argument_type_not_assignable`: se pasa un `Ref` donde se espera `WidgetRef` | `app_router.dart:41` |

> ⚠️ Durante la verificación el árbol **cambió bajo los pies** (aparecieron cambios en `login_screen.dart` y `app_router.dart` que no estaban al empezar). Si vuelves a ejecutar `flutter analyze`, usa esos resultados como fuente de verdad; estas páginas se actualizaron con la medición de las 21:53.

### `git status --short` (21:53)

```
 M AGENTS.md
 M README.md
 M lib/core/errors/app_error.dart
 M lib/core/router/app_router.dart
 M lib/features/auth/application/auth_providers.dart
 M lib/features/auth/data/auth_repository.dart
 M lib/features/auth/presentation/screens/login_screen.dart
?? lib/features/projects/domain/project.freezed.dart
?? lib/features/projects/domain/project.g.dart
?? lib/features/tasks/domain/task.freezed.dart
?? lib/features/tasks/domain/task.g.dart
```

- Cambios en `auth_repository.dart`: el getter recursivo `googleWebClientId => googleWebClientId` se corrigió con un alias de import (`as google_auth_config`).
- Cambios en `app_error.dart`: añadido el mapeo de `invalid-credential`.
- Cambios en `login_screen.dart`: navegación explícita tras login según exista perfil.
- Los `*.freezed.dart`/`*.g.dart` de `projects`/`tasks` siguen sin versionar (`.gitignore` **no** los excluye).

### Warnings habituales del analizador (sin errores de compilación)

| Cantidad aprox. | Problema | Archivos típicos |
|---|---|---|
| ~11 | `unused_import` | `group_repository.dart:2`, `group_detail_screen.dart:9`, `groups_list_screen.dart:9`, `project_repository.dart:2`, `project_detail_screen.dart:12,15`, `projects_list_screen.dart:11`, `task_repository.dart:2`, `task_detail_screen.dart:8,11`, `test/widget_test.dart:3` |
| 4+4 | `unnecessary_non_null_assertion` / `unnecessary_null_comparison` (+ info `use_null_aware_elements`) | `group_repository.dart:33,53,190,228,280,289` |
| 3 | info `unnecessary_underscores` | `group_detail_screen.dart:127`, `project_detail_screen.dart:156`, `task_detail_screen.dart:39` |
| 2 | info `deprecated_member_use` (`withOpacity` → `withValues`) | `offer_form_screen.dart:122,124` |
| 1+1 | `use_build_context_synchronously` (info) / `avoid_types_as_parameter_names` | `profile_screen.dart:246`, `task_repository.dart:162` |
| 1 | `unused_local_variable` (`brightness`) | `main.dart:32` |

No hay reglas de lint propias: `analysis_options.yaml` solo incluye `flutter_lints/flutter.yaml` y excluye `build/`, `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`.

### Tests

- **Único test**: `test/widget_test.dart` (smoke test: `pumpWidget` + busca «RepartoJusto» e «Iniciar sesión»). No inicializa Firebase ni ejerce Firestore/Auth.
- Sin tests de unitarios de repositorios, ni de widgets de features, ni de reglas de seguridad.

## 2. Divergencias: `plan.md` vs código

| `plan.md` | Realidad en el código |
|---|---|
| §2 Plataforma «Android» | Android **y web** (`lib/firebase_options.dart` solo define esos dos; el resto lanza `UnsupportedError`) |
| §5 `projects/{projectId}` y `tasks/{taskId}` en la raíz | Subcolecciones: `groups/{gid}/projects/{pid}` y `groups/{gid}/projects/{pid}/tasks/{tid}` |
| §5 `users`: `nombre`, `rol` | `name`, `role`, y añade `groupIds[]` |
| §5 `projects` con `memberIds[]`, `teacherId`, `titulo`, `deadline` | Sin `memberIds`/`teacherId`; `title`, `deliveryDeadline` + `negotiationDeadline`, `createdAt`/`updatedAt` |
| §5 `tasks` con `memberIds[]`, `titulo` | Sin `memberIds`; `title`; añade `createdAt`/`updatedAt` |
| §5 colecciones `offers`, `activity`, `notifications`, `tasks/…/comments` | **Sin ninguna implementación** (solo existen en `firestore.rules`) |
| §5 índices `tasks(groupId,status)`, `offers(…)`, etc. | Ninguna consulta de ese tipo existe; el único índice compuesto necesario hoy es `groups(memberIds + createdAt)` |
| §4/§9 reglas de arbitraje, votación y votos `{uid: approve\|reject}` | Sin código; el único residuo ejecutable es el modelo `ApprovalConfig` y las reglas de `/offers` |
| §7 pantallas 3, 4 (home docente/estudiante), 7 (hoja de oferta como bottom sheet), 8 (bandeja de arbitraje), historial | No existen (la «hoja de oferta» es una pantalla normal sin persistencia) |
| §8 estructura con `features/comments/` y `features/notifications/` | No existen esas carpetas |
| §11 checklist: «Fase 2: Proyectos y tareas» **pendiente** | La fase 2 **está implementada** (`projects`/`tasks` con las 4 capas) — el checklist está desactualizado |
| §11 checklist: Fases 0 y 1 marcadas `[x]` | Coincide con el código (auth + grupos funcionales) |

Conclusión: **el modelo de datos y el checklist de `plan.md` no sirven como referencia técnica**; sí lo son sus reglas de negocio (§3, §4, §10) para la futura fase de ofertas.

## 3. Divergencias: documentación vs código (corregidas en esta pasada)

| Dónde se afirmaba | Afirmación | Realidad | Acción |
|---|---|---|---|
| `README.md` (tabla «Estado», fila Grupos) | «…regenerar código, **config. de aprobación** \| Funcional» | `GroupRepository.updateApprovalConfig` no tiene **ninguna** UI que lo invoque | Corregido en `README.md` |
| `README.md` (tabla «Estado», fila Tareas) | «crear, **editar, estado, reordenar**, borrar \| Funcional» | Solo crear/borrar/ver; `updateTask`, `setStatus` y `reorderTasks` no se lladan desde UI | Corregido en `README.md` |
| `README.md` («Modelo de datos») | «`memberIds` está desnormalizado en grupos, **proyectos y tareas**» | `memberIds` solo existe en `AppGroup`; `Project` y `Task` no lo llevan | Corregido en `README.md` |
| `README.md` («Puesta en marcha») | «hay que corregir `AuthRepository.googleWebClientId`, que hoy se devuelve a sí mismo» | Ya está corregido en el árbol (alias `google_auth_config`) — persiste el placeholder de client ID | Corregido en `README.md` |
| `README.md` (límite de reglas) | «no desplegadas» | El repo **no permite saber** si están desplegadas (no hay sección `firestore` en `firebase.json` ni CI) | Reformulado + `TODO` explícito |
| `AGENTS.md` (intro) | «`README.md` is still the untouched Flutter template» | El README está completamente reescrito (sin confirmar) | Corregido en `AGENTS.md` |
| `AGENTS.md` (Commands) | «~57 warnings/infos but zero errors» | Medido: **61 issues = 3 errores + 28 warnings + 30 infos** (errores en curso de otra edición) | Corregido en `AGENTS.md` |
| `AGENTS.md` (Architecture) | «`memberIds` is denormalized on groups/projects/tasks» | Solo en `groups` | Corregido en `AGENTS.md` |
| `AGENTS.md` (gotchas) | «`googleWebClientId` returns itself (recursive_getters); import unused» | Getter ya no recursivo; el import **se usa** | Corregido en `AGENTS.md` |
| `AGENTS.md` (gotchas) | `firebase.json` «points to» la ruta antigua | Contiene **dos** claves `dart`: la borrada `lib/core/firebase/firebase_options.dart` **y** la actual `lib/firebase_options.dart` | Precisado |

## 4. Divergencias: reglas de seguridad vs repositorios (crítico)

| Situación | Código | `firestore.rules` |
|---|---|---|
| Proyectos | `groups/{gid}/projects` | `/projects/{id}` en la raíz |
| Tareas | `groups/{gid}/projects/{pid}/tasks` | `/tasks/{id}` en la raíz |
| Comentarios | No existe código | `/tasks/{taskId}/comments` en la raíz |
| Ofertas | No existe código | `/offers/{id}` en la raíz |
| Historial | No existe código | `/activity`: `allow create: if false` (y no hay backend) |
| Notificaciones | No existe código | `/notifications/{id}` con `notificationId == uid` |
| `users`/`groups`/`joinCodes` | Coinciden con las reglas ✅ | Coinciden ✅ |

Consecuencia práctica: **con estas reglas activas, cualquier CRUD de proyectos/tareas daría `permission-denied`**, porque las reglas de Firestore no se heredan a subcolecciones. Antes de probar la app contra un proyecto con estas reglas hay que elegir: mover el código a rutas de raíz, o reescribir las reglas para las subcolecciones.

## 5. Límites funcionales conocidos

| # | Limitación | Evidencia |
|---|---|---|
| 1 | **Borrado sin cascada**: `deleteGroup` borra solo el grupo y su `joinCodes`, pero el diálogo promete «Se eliminarán todos los proyectos, tareas y ofertas» | `group_repository.dart:245-262` vs `group_detail_screen.dart:441` |
| 2 | `deleteProject` no borra la subcolección `tasks` (diálogo promete «Se eliminarán todas las tareas y ofertas») | `project_repository.dart:119-128` vs `projects_list_screen.dart:186` |
| 3 | `deleteTask` **no recalcula** `projects.totalPoints` (sube al crear tareas, no baja al borrarlas) | `project_detail_screen.dart:764-781` |
| 4 | `users.groupIds` queda desincronizado: `UserRepository.removeGroupId` **no tiene llamadas** (no se usa al salir/expulsarse) | grep `removeGroupId`: solo definición |
| 5 | Ruta `/offers/new` sin navegaciones y con cast de `extra` que fallaría sin `extra` | `app_router.dart:173-184` |
| 6 | Ruta `/groups/create` sin navegaciones (la creación real es un diálogo) | grep `context.go`: sin coincidencias |
| 7 | Miembros y asignados se muestran como **uid truncado**, no nombre (no hay llamadas a `users` para terceros desde esas pantallas) | `group_detail_screen.dart:301`, `project_detail_screen.dart:784` |
| 8 | Google Sign-In sin client ID real | `google_auth_config.dart:6` → `'TU_WEB_CLIENT_ID_AQUI'` |
| 9 | Dependencias **instaladas y sin uso**: `shared_preferences`, `flutter_local_notifications` (en `lib/` no hay ni una importación); `riverpod_generator` (dev) sin `@riverpod` | grep en `lib/` |
| 10 | `main.dart` comenta `// await _initLocalNotifications();` pero **esa función no existe** en el archivo | `main.dart:20` |
| 11 | El selector de tema del perfil no persiste; `ThemeMode.system` es el único real | `profile_screen.dart:320` |
| 12 | El perfil no lee `users/{uid}`: usa `FirebaseAuth.instance.currentUser` y un rol hardcodeado «Estudiante» | `profile_screen.dart:13,53` |
| 13 | «Cerrar sesión» del perfil no cierra `GoogleSignIn` (no pasa por `AuthRepository.signOut`) | `profile_screen.dart:135` |
| 14 | `generateJoinCode` usa un LCG con semilla `millisecondsSinceEpoch`: los códigos no son criptográficamente aleatorios | `utils.dart:47-58` |
| 15 | Sin escritura de `activity` desde cliente (`allow create: if false`) y sin Functions: el historial de negociación es indesplegable en el plan actual | `firestore.rules` + plan Spark |
| 16 | Cobertura de tests mínima (1 smoke test) | `test/widget_test.dart` |

## 6. TODOs explícitos en el código

Marcadores `// TODO` existentes en `lib/` (líneas del 22/11/2026):

| Archivo:Línea | Texto |
|---|---|
| `features/profile/presentation/screens/profile_screen.dart:53` | `TODO: Rol real` |
| `features/profile/presentation/screens/profile_screen.dart:180` | `TODO: Actualizar perfil` |
| `features/profile/presentation/screens/profile_screen.dart:225` | `TODO: Cambiar contraseña` |
| `features/profile/presentation/screens/profile_screen.dart:245` | `TODO: Eliminar cuenta` |
| `features/profile/presentation/screens/profile_screen.dart:320` | `TODO: Guardar preferencia de tema` |
| `features/fairness/presentation/screens/fairness_screen.dart:19` | `TODO: Conectar con datos reales del proyecto` |
| `features/groups/presentation/screens/group_detail_screen.dart:301` | `TODO: Cargar nombres reales de usuarios desde users collection` |
| `features/groups/presentation/screens/group_detail_screen.dart:408` | `TODO: Implementar actualización` (editar nombre/periodo) |
| `features/projects/presentation/screens/project_detail_screen.dart:784` | `TODO: Cargar nombre real del usuario desde users collection` |
| `features/projects/presentation/screens/projects_list_screen.dart:167` | `TODO: Implementar edición` |

Además, hay acciones que **no** llevan comentario `TODO` pero anuncian fases: «Editar tarea (pendiente)», «Forzar asignación disponible en la Fase 3», «Asignar manualmente (pendiente de Fase 3)», «Comentarios disponibles en la Fase 4», «Skills (pendiente)», «Notificaciones (pendiente)», «Perfil actualizado (simulado)», «Oferta enviada (simulado)».

## 7. TODOs que requieren decisión

1. **Alinear reglas y rutas**: ¿mover proyectos/tareas a colecciones de raíz, o reescribir `firestore.rules` para `groups/{gid}/projects/…`? (bloquea cualquier prueba real de CRUD; ver sección 4)
2. **Estado de despliegue de las reglas**: ¿están activas en `proyecto-negociacion`? El repo no lo dice. `TODO` documental.
3. **Índice compuesto** `groups(memberIds array-contains, createdAt desc)`: ¿se crea en consola o se añade un `firestore.indexes.json` + sección `firestore` en `firebase.json`?
4. **`activity` vs plan Spark**: ¿cómo se escribe el historial si `allow create: if false` y no hay Functions? (¿cambio de plan, escritura delegada, o eliminar la colección del plan?)
5. **Google Sign-In**: pegar un Web client ID real y registrar la SHA-1, o quitar el botón de la UI hasta tenerlo.
6. **Código generado sin versionar** (`projects`/`tasks`): ¿se versiona o se añade a `.gitignore` y se genera siempre en CI/local?
7. **`plan.md`**: ¿actualizar su modelo de datos al árbol real y marcar la fase 2 como hecha, o mantenerlo como intención y avisar en la cabecera?
8. **Dependencias sin uso** (`shared_preferences`, `flutter_local_notifications`): ¿implementar tema persistido + avisos locales o quitarlas del `pubspec`?
9. **Fases pendientes**: ofertas/votación (fase 3) y comentarios/equidad/notificaciones reales (fase 4) siguen sin empezar más allá de la UI.
10. **Corregir los 3 errores actuales de `app_router.dart`** (edición en curso no confirmada) para volver a un árbol compilable.
