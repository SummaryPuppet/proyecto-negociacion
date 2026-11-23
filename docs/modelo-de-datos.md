# Modelo de datos

Este documento describe **las rutas y campos que el código escribe de verdad** en Cloud Firestore, y cómo se relacionan con `firestore.rules`. El modelo de `plan.md` (§5) difiere: ver [Divergencias](#divergencias-respecto-a-planmd).

> Colecciones verificadas buscando todas las llamadas a `collection(...)` en `lib/` (22/11/2026): `users`, `groups`, `joinCodes` y las subcolecciones `groups/…/projects/…/tasks`. **Ningún código del cliente toca `offers`, `activity`, `notifications` ni `comments`.**

## Árbol real usado por la app

```
users/{uid}
groups/{groupId}
groups/{groupId}/projects/{projectId}
groups/{groupId}/projects/{projectId}/tasks/{taskId}
joinCodes/{code}
```

| Ruta | Escritura desde | Lectura desde |
|---|---|---|
| `users/{uid}` | `UserRepository` (`lib/features/auth/data/user_repository.dart`) | `currentProfileProvider` (stream) |
| `groups/{groupId}` | `GroupRepository` | `myGroupsProvider`, `groupProvider` |
| `joinCodes/{code}` | `GroupRepository` (transacción crear/regenerar/borrar) | `GroupRepository.joinByCode` |
| `groups/{gid}/projects/{pid}` | `ProjectRepository` (`projects` es subcolección de `groups`, línea 10) | `projectsProvider`, `projectProvider` |
| `…/projects/{pid}/tasks/{tid}` | `TaskRepository` (subcolección anidada, línea 10) | `tasksProvider`, `taskProvider` |

## Modelos (freezed + json_serializable)

Todos los modelos son `@freezed` con `fromJson`/`toJson` y generan `*.freezed.dart` / `*.g.dart` con build_runner.

### `users/{uid}` → `AppUser` (`lib/features/auth/domain/app_user.dart`)

| Campo | Tipo | Default | Notas |
|---|---|---|---|
| `uid` | `String` | — | id del documento = uid de Auth |
| `name` | `String` | — | |
| `email` | `String` | — | |
| `photoUrl` | `String?` | `null` | |
| `role` | `UserRole` (enum) | — | JSON en español: `'docente'` / `'estudiante'` |
| `skills` | `List<String>` | `[]` | Hoy sin UI de edición (TODO en `profile_screen.dart:82`) |
| `groupIds` | `List<String>` | `[]` | Escrito con `FieldValue.arrayUnion` al crear/unirse a grupo; **ver advertencia en [Denormalización](#denormalización-y-campos-derivados)** |
| `createdAt` | `int` | `0` | epoch millis |

### `groups/{groupId}` → `AppGroup` (`lib/features/groups/domain/app_group.dart`)

| Campo | Tipo | Default | Notas |
|---|---|---|---|
| `id` | `String` | — | id del documento |
| `name` | `String` | — | |
| `period` | `String` | — | p. ej. «2025-2026 Q1» |
| `teacherId` | `String` | — | docente dueño del grupo (global) |
| `leaderId` | `String` | `''` | jefe **del grupo**; vacío = sin jefe |
| `memberIds` | `List<String>` | `[]` | **única** `memberIds` del modelo (ver nota) |
| `joinCode` | `String` | — | 6 caracteres (`generateJoinCode`, sin I/O/0/1) |
| `approvalConfig` | `ApprovalConfig` | `{50, 2, true}` | ver abajo |
| `createdAt` | `int` | `0` | epoch millis |

### `groups/{gid}.approvalConfig` → `ApprovalConfig`

| Campo | Tipo | Default |
|---|---|---|
| `quorumPercent` | `int` | `50` |
| `leaderVoteWeight` | `int` | `2` |
| `teacherCanOverride` | `bool` | `true` |

Extensión `ApprovalConfigX.votesNeeded(totalMembers)` = `ceil(totalMembers * quorumPercent / 100)`. Hoy **no hay ninguna pantalla que lo modifique**: `GroupRepository.updateApprovalConfig` existe pero ningún widget lo llama.

### `joinCodes/{code}` → documento plano (**sin modelo freezed**)

Escrito en `GroupRepository.createGroup` (líneas 53–57) y `regenerateJoinCode` (289–293):

| Campo | Tipo |
|---|---|
| `groupId` | `String` |
| `groupName` | `String` |
| `teacherId` | `String` |

El código se genera en mayúsculas; `joinByCode` consulta `doc(code.toUpperCase())`.

### `groups/{gid}/projects/{pid}` → `Project` (`lib/features/projects/domain/project.dart`)

| Campo | Tipo | Default | Notas |
|---|---|---|---|
| `id` | `String` | — | |
| `groupId` | `String` | — | **no** hay `memberIds` ni `teacherId` en este modelo |
| `title` | `String` | — | |
| `description` | `String` | — | |
| `totalPoints` | `int` | `0` en creación | suma de `weight` de las tareas; se recalcula **al crear** tarea (`project_detail_screen.dart:567`) pero **no al borrarla** |
| `negotiationDeadline` | `int` | — | epoch millis |
| `deliveryDeadline` | `int` | — | epoch millis |
| `status` | `String` | `'draft'` | `draft`, `negotiating`, `assigned`, `closed` |
| `createdAt` / `updatedAt` | `int` | `0` | epoch millis |

### `…/tasks/{taskId}` → `Task` (`lib/features/tasks/domain/task.dart`)

| Campo | Tipo | Default | Notas |
|---|---|---|---|
| `id` | `String` | — | |
| `projectId` | `String` | — | |
| `groupId` | `String` | — | **no** hay `memberIds` en este modelo |
| `title` | `String` | — | |
| `description` | `String` | — | |
| `weight` | `int` | — | puntos de la tarea |
| `estHours` | `int` | — | horas estimadas |
| `skills` | `List<String>` | `[]` | se introduce como texto separado por comas |
| `status` | `String` | `'open'` | `open`, `negotiating`, `assigned`, `done` |
| `assigneeId` | `String?` | `null` | uid del asignado; `FieldValue.delete()` al volver a `open` |
| `order` | `int` | nº de tareas existentes al crear | se ordena con `orderBy('order')`; **sin UI de reorden** |
| `createdAt` / `updatedAt` | `int` | `0` | epoch millis |

## Enums y estados

| Enum/estado | Valores (JSON) | Idioma del valor |
|---|---|---|
| `UserRole` | `'docente'`, `'estudiante'` | español (fijado con `@JsonValue`) |
| `Project.status` | `'draft'`, `'negotiating'`, `'assigned'`, `'closed'` | inglés minúsculas |
| `Task.status` | `'open'`, `'negotiating'`, `'assigned'`, `'done'` | inglés minúsculas |
| `Offer.status` | `pending`, `accepted`… | **solo existe en `plan.md` y en `firestore.rules`; no hay modelo Dart** |
| `StatusType` (UI, no persiste) | `success`, `warning`, `error`, `info`, `neutral` | colores de `StatusChip` |

Transiciones que la UI dispara hoy:

- Proyecto: `draft → negotiating` («Iniciar negociación») y `→ closed` («Cerrar») desde `projects_list_screen.dart` y `project_detail_screen.dart`. **Nada escribe `'assigned'`** en proyectos.
- Tarea: `TaskRepository.setStatus` existe, pero **ninguna pantalla lo invoca**; en la práctica las tareas se quedan en `'open'` salvo manipulación manual.

## Fechas

- Todas las fechas son **enteros epoch millis** (`DateTime.now().millisecondsSinceEpoch`), nunca `Timestamp` de Firestore (grep confirmado: no hay usos de `Timestamp` ni `serverTimestamp` en `lib/`).
- Helpers de presentación en `AppFormatters` (`formatDate`, `parseDate`, `timeAgo`, …) con locale `'es'`.

## Denormalización y campos derivados

| Campo | Propósito | Estado |
|---|---|---|
| `groups.memberIds` | Listas baratas sin `collectionGroup` y condición de las reglas | **Único `memberIds` real**. Proyectos y tareas no lo llevan (los `README`/`AGENTS` que lo afirman estaban corregidos en esta pasada) |
| `users.groupIds` | Espejo de los grupos del usuario | Se rellena al crear/unirse, pero **no hay ninguna llamada a `removeGroupId`**: al salir/expulsarse queda desincronizado. Hoy nada lee `groupIds` para consultar (las listas van por `groups.where(memberIds array-contains)`) |
| `projects.totalPoints` | Puntos totales del proyecto (cuota de equidad) | Se actualiza al **crear** tarea; **no** se recalcula al borrar (`deleteTask` no lo toca). `TaskRepository.calculateTotalPoints` existe pero no se usa |
| `tasks.order` | Orden de tareas | Se asigna = nº de tareas al crear; `reorderTasks` (batch) existe pero **no tiene UI** |
| `joinCodes` | Desnormalización de `groupId`/`teacherId` para validar permisos baratos | OK; se borra en transacción al regenerar/eliminar grupo |

## Reglas de seguridad (`firestore.rules`)

Resumen de lo que declara el archivo (fuente de verdad de permisos):

| Ruta en las reglas | Lectura | Escritura |
|---|---|---|
| `/users/{userId}` | autenticado | `create` con `userId == uid` y `role ∈ {docente, estudiante}`; `update` solo dueño y sin cambiar `role`; `delete: false` |
| `/joinCodes/{code}` | autenticado | `create/update/delete` solo con `teacherId == uid` |
| `/groups/{groupId}` | miembro o docente | `create` solo docente que se autoincluye en `memberIds` con `leaderId == ''`; `update`: docente, auto-unirse (`isSelfJoin`, solo `memberIds`, +1) o auto-salir (`isSelfLeave`, `memberIds`/`leaderId`, −1); `delete`: docente |
| `/projects/{projectId}` (raíz) | miembro del `groupId` del doc | CRUD solo docente del grupo |
| `/tasks/{taskId}` (raíz) | miembro del grupo vía `projectId` | CRUD docente; miembros solo pueden cambiar `status`/`assigneeId` con la tarea en `'open'` |
| `/offers/{offerId}` (raíz) | miembros | `create` solo con tarea `open` y `studentId == uid` y no docente; voto: solo tu clave de `votes` (`approve`/`reject`); resolución: jefe/docente sobre `status/resolvedAt/resolvedBy/resolution/votes`; `delete`: docente |
| `/tasks/{taskId}/comments/{commentId}` | miembros | `create` con `authorId == uid`; editar/borrar solo autor |
| `/activity/{activityId}` | miembros | **`allow create: if false`** (solo backend) |
| `/notifications/{notificationId}` | `notificationId == uid` | lectura/escritura solo con `notificationId == uid` (doc-id = uid) |

### Discrepancia crítica: rutas de las reglas vs rutas del código

Las reglas de Firestore **no se heredan a subcolecciones**. El código escribe en:

- `groups/{gid}/projects/{pid}`
- `groups/{gid}/projects/{pid}/tasks/{tid}`

…mientras que `firestore.rules` protege `/projects/{id}` y `/tasks/{id}` **en la raíz**. Resultado: con estas reglas desplegadas, cualquier CRUD de proyectos/tareas sería `permission-denied` (grupos, usuarios y joinCodes sí encajan). Hay que alinear un lado (rutas del código) o el otro (reglas). Detalle y decisiones pendientes: [estado-y-limitaciones](estado-y-limitaciones.md).

Otras observaciones verificadas:

- `joinCodes` y `groups` **sí coinciden** entre reglas y código (incluido el patrón de auto-unión/salida).
- Las reglas de `/offers` y `/tasks/…/comments` **asumen los documentos top-level de `plan.md`**, que el código no crea.
- `/activity` no admite escritura de cliente y no hay backend (Spark sin Functions): el historial de negociación no puede escribirse hasta resolverlo.
- **El estado de despliegue de las reglas no está registrado en el repo**: `firebase.json` no tiene sección `firestore`. Ver [puesta-en-marcha](puesta-en-marcha.md) (`TODO`).

## Índices

- **No existe `firestore.indexes.json`.**
- `GroupRepository.watchMyGroups` combina `where('memberIds', arrayContains: userId)` + `orderBy('createdAt', descending: true)`: requiere un **índice compuesto** creado a mano en la consola de Firebase.
- Las demás consultas usan un solo campo (`orderBy('createdAt')`, `orderBy('order')`), cubiertas por los índices automáticos.
- `plan.md` §5 lista además previstos: `tasks(groupId,status)`, `tasks(assigneeId)`, `offers(projectId,status)`, `offers(studentId,status)` — **ninguno aplicable hoy** porque esas colecciones no se consultan.

## Divergencias respecto a `plan.md`

| `plan.md` (§5) | Código real |
|---|---|
| `projects/{projectId}` y `tasks/{taskId}` en la raíz | Subcolecciones anidadas bajo `groups` |
| `users` con `nombre`, `rol` | `name`, `role`, y añade `groupIds` |
| `projects` con `memberIds[]`, `teacherId`, `titulo`, `deadline` | Sin `memberIds`/`teacherId`; `title`, `deliveryDeadline` + `negotiationDeadline`; añade `createdAt`/`updatedAt` |
| `tasks` con `memberIds[]`, `titulo` | Sin `memberIds`; `title`; añade `createdAt`/`updatedAt` |
| `offers`, `activity`, `notifications`, `tasks/…/comments` | Sin implementar (solo reglas/plan) |
| Índices compuestos (`tasks(groupId,status)`, etc.) | No aplicables aún; solo haría falta el de `groups(memberIds, createdAt)` |
| Plataforma «Android» (§2) | Android y web (`firebase_options.dart` solo define esos dos) |
