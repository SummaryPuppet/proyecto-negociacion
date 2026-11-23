# RepartoJusto

Aplicación Flutter para **negociar y repartir el trabajo de un proyecto en grupo** entre estudiantes.

Un docente crea un grupo, proyectos y tareas con un peso en puntos. Los estudiantes se postulan a las tareas mediante **ofertas** (puntos, horas y motivación); las ofertas se resuelven por **votación del grupo**, con el **jefe de grupo** y el **docente** como árbitros. Un panel de equidad avisa cuando alguien queda por encima de su cuota justa de puntos.

> Documento de diseño y reglas de negocio completas: [`plan.md`](plan.md).

## Estado del proyecto

| Módulo | Estado |
|---|---|
| Autenticación email/contraseña (registro, login, rol, recuperar contraseña) | Funcional contra Firebase Auth |
| Google Sign-In | UI lista, **sin configurar** (falta el Web client ID) |
| Grupos (crear, unirse por código, jefe, salir, regenerar código, config. de aprobación) | Funcional contra Firestore |
| Proyectos (crear, listar, estado, puntos totales, borrar) | Funcional contra Firestore |
| Tareas (crear, editar, estado, reordenar, borrar) | Funcional contra Firestore |
| Ofertas, votación y contraofertas | Solo UI de ejemplo; sin lógica ni persistencia |
| Panel de equidad, perfil, notificaciones | Pantallas mock / TODOs |
| Reglas de seguridad Firestore | Escritas, **no desplegadas** y desalineadas con las rutas que usa la app (ver [Limitaciones](#limitaciones-conocidas)) |

## Stack

- Flutter 3.x · Dart `^3.13.7` · Material 3 (tema claro/oscuro, locale forzado `es_ES`)
- Riverpod (`Provider`/`StreamProvider` escritos a mano) · go_router
- Firebase Auth + Cloud Firestore (plan Spark; sin Functions, Storage ni push)
- freezed + json_serializable · fl_chart · intl · shared_preferences · flutter_local_notifications

## Requisitos

- Flutter SDK estable y un emulador/dispositivo Android (o Chrome para web).
- Proyecto Firebase `proyecto-negociacion` con Authentication (Email/Password) y Firestore habilitados. `android/app/google-services.json` ya está incluido.
- Solo existen opciones de Firebase para **Android y web**; iOS, macOS, Windows y Linux lanzan `UnsupportedError`.

## Puesta en marcha

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <android-device>   # o: flutter run -d chrome
```

- El código generado (`*.freezed.dart`, `*.g.dart`) no se versiona completo: ejecuta `build_runner` tras cualquier cambio en los modelos freezed/json.
- La configuración de Firebase que usa la app es `lib/firebase_options.dart` (raíz). `firebase.json` todavía apunta a la ruta antigua `lib/core/firebase/firebase_options.dart`, así que **no ejecutes `flutterfire configure` sin revisar** los cambios que propone.
- Para Google Sign-In: pega el Web client ID real en `lib/core/firebase/google_auth_config.dart` y registra la SHA-1 de debug en Firebase. Además hay que corregir `AuthRepository.googleWebClientId`, que hoy se devuelve a sí mismo.

### Firestore

- Las reglas están en [`firestore.rules`](firestore.rules) pero `firebase.json` no las referencia: despliégalas a mano con `firebase deploy --only firestore:rules` (o añade la sección `firestore` al JSON) después de resolver la discrepancia de rutas.
- No hay `firestore.indexes.json`. `GroupRepository.watchMyGroups` (`memberIds array-contains` + `createdAt desc`) requiere un índice compuesto que hay que crear en la consola.

## Comandos útiles

```bash
flutter analyze                            # fuente de verdad del estado del código
flutter test test/widget_test.dart         # único test: smoke test de la pantalla de login
dart format lib test
```

No hay Makefile, CI ni task runner: se usa el CLI de Flutter directamente.

## Estructura

```
lib/
  core/                       errores (AppError, Result<T>), router, tema, utils, widgets, config Firebase
  features/<feature>/
    application/              providers de Riverpod
    data/                     repositorios (Firestore / Firebase Auth)
    domain/                   modelos freezed + lógica de dominio
    presentation/screens/     pantallas
  firebase_options.dart       configuración de Firebase para Android y web
  main.dart                   arranque, tema, localización
test/widget_test.dart         smoke test
firestore.rules               reglas de seguridad (fuente de verdad, despliegue manual)
plan.md                       especificación de producto y modelo de datos
AGENTS.md                     notas para agentes/desarrolladores sobre el estado real del repo
```

`auth`, `groups`, `projects` y `tasks` tienen las cuatro capas. `offers`, `fairness` y `profile` solo tienen presentación; `notifications` y `comments` aún no tienen carpeta propia.

## Modelo de datos (rutas reales que usa la app)

```
users/{uid}
groups/{groupId}
joinCodes/{code}
groups/{groupId}/projects/{projectId}
groups/{groupId}/projects/{projectId}/tasks/{taskId}
```

- Las fechas se guardan como enteros `epoch millis` (`createdAt`, `updatedAt`), no como `Timestamp`.
- Los valores de enum se serializan en español (`docente`, `estudiante`); los estados de proyecto/tarea en inglés en minúsculas (`draft`, `open`, `negotiating`, ...).
- `memberIds` está desnormalizado en grupos, proyectos y tareas. `users.role` es global; `groups.leaderId` es por grupo.

## Limitaciones conocidas

- **Las reglas no cubren las rutas de proyectos y tareas.** Los repositorios escriben en subcolecciones (`groups/{gid}/projects/...`), pero `firestore.rules` define `/projects`, `/tasks`, `/offers` y `/tasks/{id}/comments` en la raíz, y las reglas de Firestore no se heredan a subcolecciones. Hay que alinear una de las dos antes de probar CRUD real.
- Las reglas bloquean toda escritura de cliente en `activity` y no hay backend (Spark sin Functions), así que el historial de negociación fallará al escribirse desde una transacción.
- Ofertas, votación, contraofertas, comentarios, equidad y notificaciones no están implementados más allá de pantallas de ejemplo.
- `flutter analyze` termina con 0 errores pero decenas de warnings/infos (imports sin usar, `withOpacity` obsoleto, etc.).
