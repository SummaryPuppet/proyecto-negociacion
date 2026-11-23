# Puesta en marcha

Guía para compilar y ejecutar RepartoJusto. Todo aquí está contrastado con `pubspec.yaml`, `firebase.json`, `lib/firebase_options.dart` y el árbol del repo (22/11/2026).

## Requisitos

| Requisito | Detalle verificado |
|---|---|
| Flutter SDK estable | `pubspec.yaml` → `environment: sdk: ^3.13.7` (Dart) |
| Dispositivo o emulador Android, o Chrome | `flutter run -d <android-device>` / `flutter run -d chrome` |
| Proyecto Firebase | `proyecto-negociacion` (`lib/firebase_options.dart` y `firebase.json`) |
| Proveedores de Auth | Email/Password obligatorio; Google solo si quieres probar Google Sign-In |
| Credenciales Android | `android/app/google-services.json` **ya está en el repo** |
| Firebase CLI (solo para desplegar reglas) | `firebase deploy --only firestore:rules`, ver [Firestore](#firestore-reglas-e-índices) |

**Plataformas soportadas:** solo **Android** y **web**. `DefaultFirebaseOptions.currentPlatform` lanza `UnsupportedError` en iOS, macOS, Windows y Linux (`lib/firebase_options.dart:26-48`).

## Primer arranque

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <android-device>   # o: flutter run -d chrome
```

- `build_runner` genera `*.freezed.dart` y `*.g.dart`. Hazlo **tras cualquier cambio de campos** en los modelos (`lib/features/*/domain/*.dart`).
- Estado del generado (22/11/2026): los de `auth` y `groups` están versionados en git; los de `projects` y `tasks` están **sin versionar** (pero `.gitignore` no los excluye). Si el analizador se queja de símbolos faltantes (`_$Task`, `_$Project`), vuelve a ejecutar build_runner.

## Comandos de verificación

```bash
flutter analyze                        # fuente de verdad del estado del código
flutter test test/widget_test.dart     # único test (smoke test del login)
dart format lib test
```

No hay Makefile, CI ni task runner: solo CLI de Flutter. Resultado de la última verificación: [estado-y-limitaciones](estado-y-limitaciones.md).

## Configuración de Firebase

### Rutas de `firebase_options.dart` (ojo con FlutterFire)

- La app importa **`lib/firebase_options.dart`** (raíz), generado por FlutterFire CLI.
- `firebase.json` contiene **dos** entradas en `flutter.dart`: la actual (`lib/firebase_options.dart`) **y una antigua** (`lib/core/firebase/firebase_options.dart`), cuyo archivo **ya no existe** (solo queda `lib/core/firebase/google_auth_config.dart` en esa carpeta).
- Por eso **no ejecutes `flutterfire configure` a ciegas**: puede regenerar/ mover archivos y pisar estas rutas.

### Firestore: reglas e índices

- Las reglas viven en [`firestore.rules`](../firestore.rules) y `firebase.json` **no tiene sección `firestore`**: el despliegue queda fuera de la configuración del repo.

  ```bash
  firebase deploy --only firestore:rules
  ```

  `TODO`: el estado real de despliegue (si estas reglas están activas en el proyecto o no) **no se puede determinar desde el repo**.
- Antes de desplegar, resuelve la discrepancia de rutas: el código escribe en subcolecciones `groups/{gid}/projects/…` y las reglas protegen `/projects`, `/tasks` en la raíz → [modelo-de-datos](modelo-de-datos.md#discrepancia-crítica-rutas-de-las-reglas-vs-rutas-del-código).
- No hay `firestore.indexes.json`. Crea en la consola el índice compuesto que pide `watchMyGroups`: colección `groups`, campo `memberIds` (array contains) + `createdAt` descendente.
- **Sin reglas desplegadas (o con las actuales), el CRUD de proyectos/tareas fallará con `permission-denied`.**

### Google Sign-In (no configurado hoy)

Pasos que constan en el repo (`lib/core/firebase/google_auth_config.dart` y `plan.md` §12):

1. Firebase Console → Authentication → Sign-in method → **Google** → activar.
2. Copiar el **Web client ID** de la app Android (formato `…apps.googleusercontent.com`) y pegarlo en `lib/core/firebase/google_auth_config.dart`, sustituyendo `'TU_WEB_CLIENT_ID_AQUI'` (hoy el placeholder).
3. Registrar la SHA-1 de debug:

   ```bash
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```

4. En web, la ruta usa `signInWithPopup`: hay que permitir ventanas emergentes y tener el proveedor OAuth configurado en la consola.

`TODO` (decisión pendiente): validar con la app real — el código de `signInWithGoogle` (Android con `serverClientId` y web con popup) está escrito pero **nunca ha funcionado con un client ID real**. Nota: en el árbol sin confirmar, `AuthRepository.googleWebClientId` ya apunta a la constante del config (se corrigió el getter recursivo que documentaban `README`/`AGENTS`).

## Ejecución y flujo esperado

1. Arranque → `/login` (initialLocation).
2. Registrarse → `/role-selection` → se crea `users/{uid}` con rol → `/groups`.
3. Crear grupo (como docente) o unirse con código de 6 caracteres → detalle → proyectos → tareas.

## Recursos de ejecución

| Comando | Nota |
|---|---|
| `flutter run -d chrome` | Web (una de las dos plataformas con opciones de Firebase) |
| `flutter run -d <device>` | Android (requiere `google-services.json`, ya incluido) |
| `flutter test` | Solo `test/widget_test.dart`; no inicializa Firebase |

> El smoke test **no** llama `Firebase.initializeApp`; comprueba solo que se pintan «RepartoJusto» e «Iniciar sesión». Pasa cuando el árbol compila: consulta el resultado exacto en [estado-y-limitaciones](estado-y-limitaciones.md).
