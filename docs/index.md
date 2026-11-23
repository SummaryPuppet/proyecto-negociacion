# Documentación de RepartoJusto

RepartoJusto es una aplicación Flutter (interfaz en español, Material 3, Material You) para **negociar y repartir el trabajo de un proyecto en grupo** entre estudiantes. Backend: Firebase plan Spark (Authentication + Cloud Firestore; sin Functions, Storage ni notificaciones push).

Toda la documentación de este directorio está verificada contra el código fuente. Cuando un documento y el código discrepan, **manda el código** y la discrepancia queda anotada en [estado-y-limitaciones](estado-y-limitaciones.md).

## Cómo usar esta documentación

| Documento | Contenido | Léelo cuando necesites… |
|---|---|---|
| [index.md](index.md) | Índice, mapa del repo, jerarquía de fuentes | Orientarte por primera vez |
| [arquitectura.md](arquitectura.md) | Capas por feature, `Result`/`AppError`, providers, router | Entender cómo fluye un cambio por el código |
| [modelo-de-datos.md](modelo-de-datos.md) | Colecciones reales, campos, estados, reglas, índices | Saber qué se guarda en Firestore y qué protegen las reglas |
| [funcionalidades.md](funcionalidades.md) | Estado real de cada módulo (funcional / solo UI / inexistente) | Saber qué funciona hoy antes de tocar una pantalla |
| [puesta-en-marcha.md](puesta-en-marcha.md) | Requisitos, comandos, Firebase, build_runner | Montar el proyecto y ejecutarlo |
| [convenciones.md](convenciones.md) | Estilo, patrones de repositorio, helpers, qué NO hacer | Escribir código nuevo coherente con el resto |
| [estado-y-limitaciones.md](estado-y-limitaciones.md) | Divergencias, TODOs, warnings del analizador | Conocer los huecos y las decisiones pendientes |

Documentos relacionados fuera de `docs/`:

- [`../README.md`](../README.md) — resumen en español del proyecto y su estado (para humanos).
- [`../AGENTS.md`](../AGENTS.md) — notas rápidas en inglés para agentes/programadores.
- [`../plan.md`](../plan.md) — especificación de producto **intencionada**: sus reglas de negocio siguen siendo la referencia de dominio, pero su modelo de datos y su checklist de fases **no coinciden con el código** (ver [estado-y-limitaciones](estado-y-limitaciones.md)).
- [`../firestore.rules`](../firestore.rules) — reglas de seguridad de Firestore (fuente de verdad de permisos; su despliegue no está registrado en el repo).

## Mapa del repo

```
proyecto-negociacion/
├── README.md                    resumen del proyecto (en español)
├── AGENTS.md                    notas para agentes (en inglés)
├── plan.md                      especificación de producto (intención, no realidad)
├── docs/                        ← esta documentación
├── pubspec.yaml                 deps: riverpod, go_router, firebase, freezed, fl_chart…
├── analysis_options.yaml        flutter_lints por defecto, sin reglas extra
├── firebase.json                config FlutterFire; NO referencia firestore.rules
├── firestore.rules              reglas de seguridad (despliegue manual)
├── android/app/google-services.json   credenciales Android (incluido)
├── lib/
│   ├── main.dart                arranque: Firebase, tema, locale es_ES, textScaler
│   ├── firebase_options.dart    opciones Firebase (solo Android y web)
│   ├── core/
│   │   ├── errors/              AppError, Result<T>, mapToAppError
│   │   ├── router/              app_router.dart (go_router + redirects)
│   │   ├── theme/               AppTheme (semilla verde, claro/oscuro)
│   │   ├── utils/               AppFormatters + helpers de formulario/fecha
│   │   ├── widgets/             widgets compartidos (AppCard, StatusChip…)
│   │   └── firebase/            google_auth_config.dart (placeholder)
│   └── features/
│       ├── auth/                4 capas — funcional
│       ├── groups/              4 capas — funcional
│       ├── projects/            4 capas — funcional
│       ├── tasks/               4 capas — parcial (falta edición/estado/reorden)
│       ├── offers/              solo presentation — UI de ejemplo
│       ├── fairness/            solo presentation — datos mock
│       └── profile/             solo presentation — UI con TODOs
│                                (no existen carpetas notifications/ ni comments/)
└── test/widget_test.dart        único test: smoke test del login
```

## Jerarquía de fuentes de verdad

1. **El código**: `lib/`, `test/`, `firestore.rules`, `pubspec.yaml`, `firebase.json`.
2. **Esta documentación** (`docs/`), siempre subordinada al código.
3. **`README.md` / `AGENTS.md`**: resúmenes; se corrigen cuando el código cambia.
4. **`plan.md`**: intención de producto. Útil para las reglas de negocio de ofertas/votación/equidad (aún sin implementar), pero su modelo de datos y su checklist de fases están desactualizados.

## Última verificación

Campaña de verificación completa (lectura de todo `lib/`, `firestore.rules`, `pubspec.yaml`, ejecución de `flutter analyze` y `flutter test`) realizada el **22 de noviembre de 2026**. Los resultados exactos, incluido el estado del árbol de trabajo, están en [estado-y-limitaciones](estado-y-limitaciones.md).

> Nota: el árbol de trabajo tenía cambios sin confirmar en `lib/` durante la verificación; si el analizador se pone en rojo, consulta primero [estado-y-limitaciones](estado-y-limitaciones.md).
