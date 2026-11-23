# Funcionalidades: estado real

Estado de cada módulo **verificado en el código** (22/11/2026). «Funcional» significa que hay pantalla + repositorio + escritura/lectura real en Firestore o Firebase Auth. «Solo UI» significa que la pantalla existe pero no hay persistencia (datos locales, `Future.delayed`, snackbars de mentira o TODO).

Leyenda: ✅ Funcional · ⚠️ Parcial · 🖼️ Solo UI (mock/TODO) · ❌ Inexistente

## Resumen

| Módulo | Estado | Pantallas (archivos) | Datos / providers | Notas |
|---|---|---|---|---|
| Registro e inicio de sesión email/contraseña | ✅ | `auth/presentation/screens/login_screen.dart`, `register_screen.dart` | `AuthRepository` (`signUpWithEmail`, `signInWithEmail`, `sendPasswordReset`) + `auth_providers.dart` | Incluye recuperar contraseña por email |
| Selección de rol inicial | ✅ | `role_selection_screen.dart` | `UserRepository.createProfile` → `users/{uid}` | Sin perfil no se pasa de `/role-selection` (redirect del router) |
| Splash / carga | ✅ (UI) | `splash_screen.dart` | `currentProfileProvider`, `authStateChangesProvider` | Solo muestra estados de carga |
| Google Sign-In | ⚠️ | botón en login y registro | `AuthRepository.signInWithGoogle` | **No funcionará**: `google_auth_config.dart` tiene `TU_WEB_CLIENT_ID_AQUI`; ver [puesta-en-marcha](puesta-en-marcha.md) |
| Grupos: crear, unirse por código, listar, detalle | ✅ | `groups_list_screen.dart`, `group_detail_screen.dart` | `GroupRepository` + `group_providers.dart` | Todo con transacciones en Firestore |
| Grupos: nombrar jefe, expulsar, salir, regenerar código, eliminar | ✅ | `group_detail_screen.dart` | `GroupRepository.setLeader/removeMember/leaveGroup/regenerateJoinCode/deleteGroup` | |
| Grupos: editar nombre/periodo | 🖼️ | `group_detail_screen.dart:408` (`// TODO: Implementar actualización`) | — | El diálogo guarda y muestra «Editar grupo (pendiente)» |
| Grupos: configuración de aprobación | ⚠️ | **sin pantalla** | `GroupRepository.updateApprovalConfig` y `groupApprovalConfigProvider` existen, **sin llamadas desde UI** | El modelo y los defaults (`50/2/true`) están listos |
| Grupos: nombres de miembros | 🖼️ | `group_detail_screen.dart:301` | — | Muestra el **uid truncado**, no el nombre (`TODO: Cargar nombres reales…`) |
| Proyectos: crear, listar, detalle, eliminar | ✅ | `projects_list_screen.dart`, `project_detail_screen.dart` | `ProjectRepository` + `project_providers.dart` | |
| Proyectos: estado (`negotiating`, `closed`) y `totalPoints` | ✅ | ambas pantallas de proyecto | `ProjectRepository.setStatus/updateTotalPoints` | `totalPoints` solo al crear tareas (no al borrarlas) |
| Proyectos: editar | 🖼️ | `project_detail_screen.dart:371` («Editar proyecto (pendiente)») | — | |
| Tareas: crear, listar, detalle, eliminar | ✅ | `project_detail_screen.dart` (lista y diálogo de creación), `task_detail_screen.dart` | `TaskRepository.createTask/watchTasks/deleteTask` | |
| Tareas: editar | 🖼️ | `task_detail_screen.dart:230` y `project_detail_screen.dart:753` («Editar tarea (pendiente)») | `TaskRepository.updateTask` **sin invocar** | |
| Tareas: cambiar estado / asignar / reordenar | ⚠️ repo, ❌ UI | «Forzar asignación» y «Asignar manualmente» muestran snackbar de Fase 3 | `TaskRepository.setStatus/reorderTasks` **sin invocar** | Las tareas se quedan en `'open'` en la práctica |
| Ofertas (crear, votar, contraofertar) | 🖼️ | `offers/presentation/screens/offer_form_screen.dart` + sección en `task_detail_screen.dart` | Ninguno (sin modelo ni repositorio) | Envío simulado: `Future.delayed(1 s)` + «Oferta enviada (simulado)»; el botón de `task_detail` dice «Ofertas disponibles en la Fase 3» |
| Votación / arbitraje de ofertas | ❌ | — | — | Reglas de dominio solo en `plan.md` §4 y en `firestore.rules` |
| Comentarios por tarea | 🖼️ placeholder | sección en `task_detail_screen.dart` («Fase 4») | — | Sin carpeta `features/comments` ni repositorio |
| Panel de equidad | 🖼️ | `fairness/presentation/screens/fairness_screen.dart` | — | `// TODO: Conectar con datos reales del proyecto` con 5 miembros hardcodeados; gráfico `fl_chart` |
| Perfil | 🖼️ | `profile/presentation/screens/profile_screen.dart` | Ninguno (lee `FirebaseAuth.instance.currentUser`) | Rol hardcodeado «Estudiante» (`TODO: Rol real`); editar perfil/contraseña/eliminar cuenta/tema = snackbars simulados; «Cerrar sesión» llama `FirebaseAuth.instance.signOut()` directamente |
| Notificaciones | ❌ | — | — | Sin carpeta `features/notifications`; solo existe la ruta `/notifications` en `firestore.rules`; `shared_preferences` y `flutter_local_notifications` están en `pubspec.yaml` **sin usar** |
| Historial de actividad (`activity`) | ❌ | — | — | Sin código; las reglas prohíben la escritura de cliente |
| Tema claro/oscuro | ✅ | `main.dart` + `core/theme/app_theme.dart` | — | `ThemeMode.system`; el selector del perfil **no persiste** la preferencia (`TODO`) |

## Detalle por feature

### auth ✅

- **Login** (`login_screen.dart`): email/contraseña contra Firebase Auth; botón «Continuar con Google» (ver ⚠️); «¿Olvidaste la contraseña?» abre diálogo → `AuthRepository.sendPasswordReset`. Tras éxito navega a `/role-selection` o `/groups` según exista perfil.
- **Registro** (`register_screen.dart`): `signUpWithEmail` con validaciones `isValidEmail` / `isStrongPassword` (mín. 8, una mayúscula, un número) y `updateDisplayName`.
- **Rol** (`role_selection_screen.dart`): crea `users/{uid}` con `role` (`docente`/`estudiante`) → `/groups`.
- **Redirects**: el router exige auth + perfil para el área principal (ver [arquitectura](arquitectura.md#navegacion-libcorerouterapp_routerdart)).

### groups ✅ con huecos

Operaciones con UI **y** repositorio: crear (transacción con código único, hasta 5 reintentos), unirse por código, listar (`watchMyGroups`), detalle, nombrar/quitar jefe (`clearLeader` existe pero sin UI), expulsar, salir (el docente no puede salir), regenerar código (borra y recrea `joinCodes`), eliminar grupo y `updateApprovalConfig`.

Huecos: edición de nombre/periodo simulada; sin pantalla de `approvalConfig`; miembros mostrados por uid; `deleteGroup` **no borra** las subcolecciones de proyectos/tareas (el diálogo de confirmación sí promete «Se eliminarán todos los proyectos, tareas y ofertas» → ver [estado-y-limitaciones](estado-y-limitaciones.md)).

### projects ✅ con huecos

Crear (estado inicial `'draft'`, `totalPoints: 0`), listar con menú de acciones (iniciar negociación → `'negotiating'`, cerrar → `'closed'`, eliminar), detalle con creación de tareas y acceso al panel de equidad. Edición de campos pendiente.

### tasks ⚠️

Crear (con `order` correlativo y recálculo de `totalPoints`), ver detalle, eliminar. **No hay UI** para editar, cambiar estado, asignar o reordenar, aunque `TaskRepository` ya tiene los métodos (`updateTask`, `setStatus`, `reorderTasks`).

### offers 🖼️

`OfferFormScreen` (puntos, horas, motivación, aviso de equidad decorativo) recibe `groupId`/`projectId`/`taskId` y **no escribe nada**: `_submit` espera 1 s y muestra «Oferta enviada (simulado). El grupo votará ahora». La ruta `/offers/new` **no tiene ningún `context.go/push` que la llame**. No hay modelo `Offer`, ni colección `offers`, ni votación.

### fairness 🖼️

`FairnessScreen(groupId, projectId)` recibe los parámetros pero los ignora: lista de 5 miembros ficticia (`fairness_screen.dart:19-26`), cuota justa calculada sobre esos datos y gráficos de barras con `fl_chart`. Es el único consumidor de la dependencia `fl_chart`.

### profile 🖼️

Muestra `displayName`/`email`/`photoURL` de Firebase Auth (no de `users/{uid}`). Editar perfil, skills, notificaciones, tema, contraseña y eliminar cuenta son UI sin persistencia (`TODO`s en `profile_screen.dart:53,180,225,245,320`). La sesión se cierra con `FirebaseAuth.instance.signOut()` en lugar de `AuthRepository.signOut` (que además cierra `GoogleSignIn`).

### notifications / comments / activity ❌

No existen como features. Sus contrapartes son solo: las rutas `/notifications`, `/tasks/{id}/comments` y `/activity` de `firestore.rules`, y las descripciones de `plan.md` §7. Los marcadores en la UI son los snackbars «…disponible en la Fase 4» de `task_detail_screen.dart`.

## Rutas sin uso

| Ruta | Situación |
|---|---|
| `/offers/new` | Declarada en el router; **ninguna pantalla navega a ella** (grep de `context.go/push` en `lib/`). Además, su builder hace `extra?['groupId'] as String`: sin `extra` lanza un error de casteo en tiempo de ejecución |
| `/groups/create` | Declarada (`GroupDetailScreen(isCreating: true)` con formulario), pero **sin navegaciones** que apunten a ella; la creación real de grupos se hace con diálogo en `groups_list_screen.dart` |
| `/groups/:groupId/projects/create` | ✅ Sí se usa: `group_detail_screen.dart:550` y `projects_list_screen.dart:30,55` |
