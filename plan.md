# Plan: RepartoJusto

Aplicación Flutter para negociar y distribuir trabajos entre estudiantes.

---

## 1. Resumen ejecutivo

**RepartoJusto** permite a un docente crear un trabajo en grupo dividido en tareas con peso/puntos. Los estudiantes se postulan a las tareas mediante ofertas (puntos + horas + motivación). Las ofertas se cierran por **votación del grupo**, con **jefe de grupo** (voto doble) y **docente** (veto/asignación forzada) como árbitros. Un **panel de equidad** garantiza que nadie acabe con más carga de la que le toca (cuota justa = puntos totales / nº alumnos; aviso al superar +20 % con motivo obligatorio).

---

## 2. Decisiones finales

| Decisión | Elección |
|---|---|
| Nombre / paquete | **RepartoJusto** · `com.tunombre.repartojusto` |
| Plataforma | Android |
| Backend | **Firebase Spark** (sin facturación, sin Functions, sin Storage) |
| Auth | Email/contraseña + Google Sign-In |
| Estado | Riverpod |
| Navegación | go_router |
| Negociación | Oferta → contraoferta → votación del grupo |
| Árbitros | Jefe de grupo (voto doble, desempata) y docente (veto y asignación forzada) |
| Jefe de grupo | Lo designa el docente |
| Equidad | Cuota = puntos totales / nº alumnos; aviso al superar +20 % con motivo obligatorio |
| Notificaciones | Feed in-app + avisos locales (sin push) |
| Extras v1 | Comentarios por tarea |
| Fuera de v1 | Push, subida de archivos, calendario, calificaciones |

---

## 3. Roles

| Rol | Ámbito | Permisos |
|---|---|---|
| **Docente** | Global | Crea grupos, proyectos y tareas; designa jefe; ve todo; puede forzar asignaciones con motivo; cierra la negociación |
| **Jefe de grupo** | Por grupo | Arbitra ofertas, desempata votaciones, propone cierres; no puede asignarse tareas a sí mismo sin aprobación del docente |
| **Estudiante** | Por grupo | Se une con código, oferta, contraoferta, vota ofertas ajenas, comenta |

Un usuario tiene rol global (`docente` / `estudiante`); ser jefe es un atributo **del grupo** (`leaderId`), no del usuario.

---

## 4. Regla de arbitraje (configurable por grupo)

```json
approvalConfig {
  quorumPercent: 50,        // votos necesarios sobre los miembros con derecho a voto
  leaderVoteWeight: 2,      // el voto del jefe desempata
  teacherCanOverride: true  // el docente siempre puede aceptar/anular/forzar
}
```

1. Oferta enviada → estado `pending`, visible para el grupo.
2. Votan todos los miembros **excepto el ofertante** (el jefe vale doble).
3. Se cierra a favor si: **mayoría de votos emitidos** con quórum alcanzado **o** el jefe acepta tras el plazo **o** el docente acepta.
4. Se cierra en contra si la mayoría vota no.
5. Al aceptar: **transacción** que asigna la tarea, marca la oferta `accepted`, rechaza el resto y escribe el evento de historial.
6. Docente puede **reabrir** una tarea y forzar asignación dejando motivo registrado.
7. Contraoferta: cualquiera de los árbitros propone nuevos puntos/horas → se crea oferta hija (`parentOfferId`) y el estudiante acepta o rechaza.

---

## 5. Modelo de datos (Firestore)

```
users/{uid}            nombre, email, rol, photoUrl, skills[], createdAt
groups/{groupId}       nombre, teacherId, leaderId, memberIds[], joinCode, periodo, approvalConfig
joinCodes/{code}       groupId
projects/{projectId}   groupId, memberIds[], teacherId, titulo, descripcion,
                       deadline, negotiationDeadline, totalPoints, status
tasks/{taskId}         projectId, groupId, memberIds[], titulo, descripcion,
                       weight, estHours, skills[], status, assigneeId, order
tasks/{taskId}/comments/{commentId}   authorId, texto, createdAt
offers/{offerId}       taskId, projectId, groupId, studentId, points, hours,
                       mensaje, status, parentOfferId, votes{uid: approve|reject},
                       resolvedAt, resolvedBy, resolution
activity/{id}          groupId, projectId, tipo, actorId, payload, createdAt
notifications/{id}     userId, tipo, leido, payload
```

- `memberIds[]` desnormalizado → reglas de seguridad baratas y listas sin `collectionGroup`.
- Votos como mapa: la regla solo permite tocar la clave del propio `uid`.
- Índices compuestos: `tasks(groupId,status)`, `tasks(assigneeId)`, `offers(projectId,status)`, `offers(studentId,status)`.

---

## 6. Stack final

Riverpod · go_router · freezed + json_serializable · Firebase Auth (email + Google) · Cloud Firestore · fl_chart · intl · shared_preferences · flutter_local_notifications. Material 3, español, claro/oscuro.

---

## 7. Pantallas

1. Login / Registro (email y Google)
2. Home docente — grupos, proyectos activos, aprobaciones pendientes
3. Home estudiante — mis tareas, tareas abiertas, mis ofertas
4. Detalle de grupo — miembros, código de invitación, jefe, proyectos
5. Detalle de proyecto — tareas con peso, progreso, plazo, equilibrio por alumno
6. Detalle de tarea — info, ofertas, votos, comentarios, contraoferta, historial
7. Hoja de oferta — puntos, horas, motivación, compromiso
8. Bandeja de arbitraje (jefe/docente) — pendientes, votos, forzar con motivo
9. Panel de equidad — puntos y horas por estudiante, avisos de desbalance
10. Perfil — nombre, foto, skills

---

## 8. Estructura del código

```
lib/
  core/        firebase/, router/, theme/, errors/, widgets/, utils/
  features/
    auth/  groups/  projects/  tasks/  offers/  comments/
    fairness/  notifications/  profile/
```

---

## 9. Seguridad (borrador de reglas)

- `groups`: lectura si `uid in memberIds`; escritura solo `teacherId`.
- `projects`/`tasks`: lectura si `uid in memberIds`; CRUD solo docente del grupo.
- `offers`: crear solo si `studentId == uid` y la tarea está `open`; el voto solo modifica `votes[uid]`; aprobar/rechazar solo jefe o docente; campos `studentId/points/taskId` inmutables.
- `comments`: lectura/creación si miembro; edición/borrado solo autor.
- `notifications`: solo el dueño.

---

## 10. Equidad

- Cuota justa = `totalPoints / nº estudiantes`.
- Aviso si la asignación deja al alumno por encima de cuota + 20 % → el árbitro debe escribir motivo.
- Gráfico de barras por estudiante con puntos y horas; badge verde/ámbar/rojo.

---

## 11. Fases

| Fase | Contenido | Est. |
|---|---|---|
| 0 | `flutter create`, deps, Firebase, tema, router, lint | 0,5–1 d |
| 1 | Auth (email + Google), grupos, código de invitación, jefe | 1,5–2 d |
| 2 | Proyectos y tareas con pesos | 2 d |
| 3 | Ofertas, contraofertas, votación, transacción, reglas Firestore | 3 d |
| 4 | Comentarios, panel de equidad, historial, notificaciones | 2 d |
| 5 | Pulido, estados vacíos/error, tests, datos demo, README y manual | 2 d |

**~2 semanas** a tiempo parcial. Entregables: APK, README, manual de uso, diagrama de arquitectura y modelo de datos.

---

## 12. Preparación previa (15 min)

1. Crear proyecto en Firebase Console → plan **Spark** (sin tarjeta).
2. Añadir app Android con el `applicationId` que elijas.
3. Descargar `google-services.json` → `android/app/`.
4. Activar Authentication → Email/Password y Google.
5. Registrar la SHA-1 de debug:
   ```bash
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
6. Tener emulador Android o móvil con depuración USB.

---

## 13. Próximos pasos

- [x] Plan creado (`plan.md`)
- [x] **Fase 0**: Setup del proyecto Flutter + dependencias + Firebase + tema + router
- [ ] Fase 1: Auth + grupos + código de invitación + jefe
- [ ] Fase 2: Proyectos y tareas
- [ ] Fase 3: Ofertas + votación + transacción
- [ ] Fase 4: Comentarios + equidad + notificaciones
- [ ] Fase 5: Pulido + tests + documentación