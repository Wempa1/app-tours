# Avanti — Guía de Onboarding para Colaboradores

Bienvenido/a al proyecto **Avanti** (autoguías de turismo por audio). Este README te guía para arrancar el entorno desde cero, entender la arquitectura (Front/Back), ejecutar la app, correr tests y contribuir con buenas prácticas.

---

## Índice

1. [Requisitos de sistema](#requisitos-de-sistema)
2. [Instalación de herramientas](#instalación-de-herramientas)
3. [Clonado y configuración inicial](#clonado-y-configuración-inicial)
4. [Variables de entorno y secretos](#variables-de-entorno-y-secretos)
5. [Dependencias del proyecto](#dependencias-del-proyecto)
6. [Ejecución en emulador/dispositivo](#ejecución-en-emuladordispositivo)
7. [Scripts y comandos útiles](#scripts-y-comandos-útiles)
8. [Arquitectura del proyecto](#arquitectura-del-proyecto)
9. [Front-End vs Back-End (responsabilidades)](#front-end-vs-back-end-responsabilidades)
10. [Estructura de carpetas](#estructura-de-carpetas)
11. [Estándares de código y CI](#estándares-de-código-y-ci)
12. [Flujo de ramas (Git)](#flujo-de-ramas-git)
13. [Cómo contribuir (PRs)](#cómo-contribuir-prs)
14. [Tests / QA](#tests--qa)
15. [Problemas comunes (Troubleshooting)](#problemas-comunes-troubleshooting)
16. [Contacto y soporte interno](#contacto-y-soporte-interno)

---

## Requisitos de sistema

* **SO**: Windows 10/11, macOS 12+ (Monterey) o Linux reciente.
* **RAM**: 8 GB mínimo (recomendado 16 GB para emuladores).
* **Almacenamiento**: 10–20 GB libres (SDKs + emuladores + dependencias).

---

## Instalación de herramientas

### 1) Git

* Windows: [https://git-scm.com/download/win](https://git-scm.com/download/win)
* macOS: `brew install git` (o instalar Xcode que incluye Git)

### 2) Flutter SDK (canal estable)

* Guía oficial: [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
* Tras instalar, valida:

  ```bash
  flutter --version
  flutter doctor
  ```

### 3) VS Code (recomendado)

* Extensiones: **Flutter**, **Dart**, *Error Lens*, *Riverpod Snippets* (opcional).

### 4) Android Studio (emuladores Android)

* Instalar **Android SDK**, **Android SDK Platform-Tools**, **Android SDK Build-Tools**.
* Aceptar licencias:

  ```bash
  flutter doctor --android-licenses
  ```

### 5) Xcode + CocoaPods (solo macOS/iOS)

* Xcode desde App Store.
* `sudo gem install cocoapods`

### 6) Supabase CLI (opcional para tareas de BD)

* macOS: `brew install supabase/tap/supabase`
* Windows: usar Scoop o binarios desde releases de Supabase CLI.

---

## Clonado y configuración inicial

```bash
# elige tu carpeta de trabajo
cd ~/dev    # (macOS/Linux)  |  cd C:\dev  (Windows)

git clone https://github.com/Wempa1/app-tours.git
cd app-tours

flutter pub get
flutter doctor
```

---

## Variables de entorno y secretos

Crea un archivo `.env` en la **raíz** del proyecto (NO lo subas al repo):

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

> Las claves se gestionan en el proyecto de Supabase (Admin). Guarda el `.env` en un gestor de contraseñas.

Para ejecutar ciertos **tests** que leen estas variables en CI/local, expórtalas en shell (ejemplo PowerShell):

```powershell
$env:SUPABASE_URL="https://<tu-ref>.supabase.co"
$env:SUPABASE_ANON_KEY="<tu-anon>"
flutter test
```

> **Nunca** subas al repo `.env`, keystores, `key.properties` o keys de servicio.

---

## Dependencias del proyecto

**Stack principal:** Flutter + Supabase + Riverpod + just\_audio + Isar.

Dependencias directas más relevantes:

* **supabase\_flutter** — SDK Supabase (auth, DB, storage)
* **flutter\_dotenv** — carga de `.env`
* **flutter\_riverpod** — estado
* **go\_router** — navegación
* **cached\_network\_image** — imágenes con caché
* **just\_audio** / **audio\_session** — audio y audio focus
* **geolocator** — ubicación del dispositivo
* **flutter\_map** (Leaflet) — mapas
* **isar** — almacenamiento local/offline
* **intl**, **uuid**, **flutter\_svg**, **google\_fonts**, etc.

Instalar dependencias:

```bash
flutter pub get
```

Actualizar (si cambiamos pubspec):

```bash
flutter pub upgrade --major-versions
```

---

## Ejecución en emulador/dispositivo

### Configuración del emulador Android

* Abrir **Android Studio → Device Manager**.
* Crear AVD recomendado: **Pixel 6a**, API **34** (Android 14), imagen **x86\_64**.
* Configurar:

  * RAM: 2–4 GB
  * Internal Storage: 2–4 GB
  * Habilitar hardware acceleration (Intel HAXM/Hypervisor o AMD Hyper-V).

### iOS (macOS)

* Usa un **iPhone 15** (iOS 17+) en el Simulator.
* Para *release* se requiere cuenta de Apple Developer y firma; para *debug*, no.

### Ejecutar la app

```bash
flutter run            # selecciona el dispositivo/emulador
# o:
flutter run -d chrome  # para pruebas rápidas web (limitado)
```

---

## Scripts y comandos útiles

```bash
# Formatear y analizar
dart format .
flutter analyze

# Ejecutar pruebas
flutter test

# Limpiar caches y artefactos
flutter clean && flutter pub get

# Android: aceptar licencias
flutter doctor --android-licenses

# Generar APK debug
flutter build apk --debug

# (iOS) instalar pods si hace falta
cd ios && pod install && cd ..
```

---

## Arquitectura del proyecto

* **Capa de UI (presentation)**: pantallas, widgets, navegación.
* **Capa de dominio/datos (features/.../data)**: modelos, repositorios, caché local, integración Supabase.
* **Core**: router, tema, utilidades (logger, retry, file cache), widgets compartidos.
* **Backend**: Supabase (Postgres + RLS + Storage + RPC). Desde la app **nunca** escribimos tours/stops; ese flujo está protegido por RLS. La app solo lee contenido publicado y escribe **progreso**/completions del usuario.

Diagrama simplificado:

```
UI (Screens) → Repos (TourRepo, ProgressRepo) → Supabase (DB, RPC, Storage)
                 ↘ Isar (cache offline) ↙ Retry/Backoff
```

---

## Front-End vs Back-End (responsabilidades)

### Front-End (Flutter)

* Pantallas: Home, Catálogo, Detalle de Tour (player de audio y progreso).
* Estado: Riverpod (`Provider`, `ConsumerWidget`/`ConsumerStatefulWidget`).
* Navegación: `go_router` (rutas estables `/`, `/catalog`, `/tour/:id`).
* **NO** hace llamadas directas a Supabase: usa **Repos**.
* Audio: `just_audio` + `audio_session` (pausa ante interrupciones/background y recuerda posición).

### Back-End (Supabase)

* **DB**: tablas `tours`, `stops`, `tour_i18n`, `stop_i18n`, `progress`, etc.
* **RLS**: lectura pública de tours publicados; escrituras limitadas (progreso y RPC completions con auth).
* **RPC**: `record_tour_completion(p_tour_id, p_duration_minutes)`.
* **Storage**:

  * Bucket público `avanti-public` (imágenes).
  * Bucket privado `avanti-audio` (audios). Las URLs se **firman** desde el Repo.

> Para detalles precisos de integración UI ↔ datos, ver **Contrato Front-End** (documento incluido en el repo/canvas).

---

## Estructura de carpetas

```
lib/
  core/
    router.dart
    theme.dart
    config/app_keys.dart
    logging/app_logger.dart
    services/
      file_cache_service.dart
      retry.dart
    ui/app_snack.dart
    widgets/error_retry.dart
  features/
    home/
      presentation/home_screen.dart
    tours/
      data/
        models.dart
        tour_repo.dart
        caching_tour_repo.dart
        progress_repo.dart
      presentation/
        catalog_screen.dart
        tour_detail_screen.dart

supabase/
  schema.sql
  seed.sql
.github/
  workflows/flutter-ci.yml
```

---

## Estándares de código y CI

* **Linter**: `flutter_lints` (mantener `flutter analyze` sin errores).
* **Commits**: estilo *Conventional Commits* (sugerido):

  * `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`
* **PRs**: code review obligatorio, tests en verde.
* **CI (GitHub Actions)**: `flutter-ci.yml` ejecuta analyze y tests. Secrets:

  ```yaml
  ```

env:
SUPABASE\_URL: \${{ secrets.SUPABASE\_URL }}
SUPABASE\_ANON\_KEY: \${{ secrets.SUPABASE\_ANON\_KEY }}

````

---

## Flujo de ramas (Git)
- **main** → rama estable (producción/QA). Solo se mergea desde PRs revisados.
- **develop** → integración continua de features (opcional si el equipo lo prefiere).
- **feature/*** → nuevas funcionalidades (desde `develop` o `main` según estrategia).
- **fix/*** → hotfixes/bugs.
- **chore/***, **docs/*** → tareas de mantenimiento/documentación.

> Recomendado: PRs dirigidos a `develop`; se liberan a `main` con *release PR*.

---

## Cómo contribuir (PRs)
1. Crear rama: `git checkout -b feature/nombre-corto`.
2. Hacer cambios + agregar tests si aplica.
3. `dart format . && flutter analyze && flutter test`.
4. Commit (convencional) y push.
5. Abrir PR con descripción, screenshots (si UI) y checklist:
 - [ ] Sin errores de `analyze`
 - [ ] Tests en verde
 - [ ] No se rompieron rutas ni contratos de Repos
 - [ ] Cumple RLS/seguridad (nada de llamadas directas a DB desde UI)

---

## Tests / QA
- **Unit tests** estándar: `flutter test`
- **Tests de seguridad RLS** (requieren env):
```bash
# PowerShell (Windows)
$env:SUPABASE_URL="https://<ref>.supabase.co"
$env:SUPABASE_ANON_KEY="<anon>"
flutter test test/security/rls_client_test.dart
````

* **E2E manual**: catálogo online/offline, detalle de tour (audio y progreso), RLS (sin escrituras indebidas), player pausa en background/interrupciones.

---

## Problemas comunes (Troubleshooting)

* **Android licenses**: `flutter doctor --android-licenses` y acepta todo.
* **Gradle fallas**: `flutter clean && flutter pub get` y reintentar.
* **iOS pods**: `cd ios && pod install && cd ..`.
* **RLS errores**: mensajes como *"row-level security policy"* u *"permission denied"* indican que intentaste una operación no permitida (ver Repos/Policies).
* **Env no cargado**: comprueba `.env` y el uso de `flutter_dotenv` en `main`.

---

## Contacto y soporte interno

* Incidencias: abrir **Issue** en GitHub con template (bug/feature).
* Dudas de datos/seguridad: mencionar al responsable de Back-End en el PR/Issue.
* Diseño UI/UX: coordinar con el responsable de Front-End y revisar el **Contrato Front-End**.

---

¡Gracias por contribuir a Avanti! Mantengamos la estabilidad (RLS), escalabilidad y DX con estos lineamientos. 🙌
