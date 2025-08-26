# Avanti – Guía de ejecución (App + Back End)

Este README explica **requisitos** y **pasos para correr la app** usando lo definido en la conversación **“Back End”** de este proyecto (Supabase como BaaS, RLS, buckets de Storage, slugs, roles, etc.). Está pensado para que **cualquier colaborador** pueda levantar el proyecto rápido, sin conocer los detalles previos.

> **Asume** que ya configuraste Supabase como en “Back End”: RLS activado, buckets de Storage, función `slugify`, y convención de rutas para assets. Si cambiaste algún nombre en tu proyecto real, **ajústalo en `.env` y en la sección de Storage**.

---

## 1) Stack y arquitectura (resumen)

* **Frontend**: Flutter (Dart).
* **Backend as a Service**: **Supabase** (Postgres + Auth + Storage + Edge Functions opcional).
* **Auth**: Supabase Auth (usuario anónimo y/o email+password; opcional OAuth).
* **Datos**: Tablas Postgres con **RLS** (Row Level Security) activado.
* **Media** (audios/imágenes): **Supabase Storage** con rutas y permisos definidos.
* **Convenciones** clave del Back End:

  * **Slugs** human-friendly (ciudad, tour, parada) generados con función `slugify` en BD.
  * **RLS**: lectura pública controlada (o sólo autenticados), escritura restringida.
  * **Storage**: bucket principal `tours` (ajustable), con estructura de carpetas por **ciudad/tour/versión**.

---

## 2) Requisitos previos

### a) Herramientas

* **Flutter SDK** `3.22+` (o la que uses en el proyecto).
* **Dart** (incluido en Flutter).
* **Android Studio** con SDK / emulador **o** Xcode (para iOS) en macOS.
* **Git** y cuenta en GitHub (el repo ya existe).
* **Supabase Project** (en la nube) con URL y llaves (anon y service\_role).

> En Windows, instala Flutter y Android Studio; configura un emulador Android. En macOS con Xcode, usa simulador iOS.

### b) Variables de entorno

La app usa un archivo **`.env`** en la raíz (no se versiona).

**`.env`:**

```env
# Claves públicas (seguras para cliente):
SUPABASE_URL=
SUPABASE_ANON_KEY=

```

**No** subas valores reales. Cada dev debe copiar:

```bash
cp .env
# Luego completar valores reales
```

> Si compilas para Web, puedes usar `.env` o `--dart-define` según tu setup.

---

## 3) Supabase (según “Back End”)

> Si tu proyecto ya está en producción en Supabase, **sólo necesitas las claves**. Si estás replicando el entorno desde cero:

### a) Crear proyecto y obtener claves

1. Crea un **project** en [Supabase](https://supabase.com/).
2. En **Project Settings → API**: copia **`Project URL`** y **`anon public key`** → colócalas en tu `.env`.

### b) Esquema de base de datos (tablas mínimas sugeridas)

> **No versionamos tu esquema exacto** aquí: esta lista es orientativa según la conversación “Back End”. Adáptalo a tu SQL real.

* `cities` (id, name, slug, ...)
* `tours` (id, city\_id, title, slug, version, ...)
* `stops` (id, tour\_id, title, slug, order\_index, ...)
* `assets` (id, stop\_id, type, url, duration, language, ...)
* `users` (perfil extendido si se requiere)

### c) Función `slugify` (ejemplo genérico)

```sql
create or replace function public.slugify(txt text)
returns text language plpgsql as $$
begin
  return lower(regexp_replace(trim(txt), '[^a-zA-Z0-9]+', '-', 'g'));
end; $$;
```

> Si ya tienes una versión propia, no la dupliques.

### d) RLS (Row Level Security)

* **Activa RLS** en tablas públicas de lectura: por ejemplo `tours`, `stops`, `assets`.
* Políticas típicas (ejemplos):

  * **Read (anon)**: permitir `SELECT` a `anon`/`authenticated` si el recurso es público.
  * **Write (authenticated)**: restringir `INSERT/UPDATE/DELETE` a usuarios del equipo o con un `role` (mediante claims/`auth.jwt()` o columnas owner).

**Ejemplo lectura pública controlada:**

```sql
alter table public.tours enable row level security;
create policy "read_public_tours"
  on public.tours for select
  to anon, authenticated
  using (true);  -- Ajusta condición si usas flags de visibilidad
```

> Repite para `stops` y `assets`. Para escritura, crea políticas más estrictas (por equipo/admin).

### e) Storage (bucket y estructura)

* Crea bucket, p.ej. **`tours`**.
* **Estructura de carpetas** (recomendada):

```
/tours/
  <city-slug>/
    <tour-slug>/
      v1/
        cover/                # imágenes portada
        audio/<lang>/         # aac/mp3 por idioma
        images/               # fotos paradas
```

* **Políticas de Storage**:

  * **Lectura**: pública o autenticada según tu modelo.
  * **Escritura**: restringida a tu equipo.

**Ejemplo lectura pública en bucket `tours`:**

```sql
create policy "storage_read_tours"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'tours');
```

> Ajusta las políticas a tu nivel de privacidad. Para escritura, usa `authenticated` con verificación adicional.

---

## 4) Configuración local de la app

1. **Clonar el repo**

```bash
git clone <URL-DEL-REPO>
cd avanti-app
```

2. **Flutter deps**

```bash
flutter --version
flutter pub get
```

3. **Variables de entorno**

```bash
cp .env
# Completa SUPABASE_URL y SUPABASE_ANON_KEY
```

4. **Plataformas**

* **Android**: abre Android Studio → instala SDKs → crea/emulador → `flutter devices`.
* **iOS (macOS)**: `cd ios && pod install && cd ..` (si usas pods). Requiere Xcode.
* **Web** (opcional): asegúrate de tener Chrome y `flutter config --enable-web` si aplica.

---

## 5) Ejecutar en desarrollo

### Opción A – Terminal

```bash
# Android/iOS (selecciona dispositivo)
flutter run

# Web (si lo habilitaste)
flutter run -d chrome
```

### Opción B – VS Code

* Instala extensiones **Flutter** y **Dart**.
* `F5` o menú **Run → Start Debugging**.
* Selecciona el dispositivo (barra inferior).

> La app leerá `.env` en tiempo de compilación/arranque (según tu implementación). Verifica que las claves sean válidas.

---

## 6) Datos y assets (cómo “engancha” la app)

* La app **consulta Supabase** para:

  * Listar **ciudades/tours** y sus **paradas**.
  * Cargar **assets** (imágenes, audios) de **Storage** siguiendo la estructura indicada.
* Si los **slugs** y rutas de Storage no coinciden, **actualiza**:

  * En BD los slugs (`cities.slug`, `tours.slug`, `stops.slug`).
  * En Storage, las carpetas.
  * En la app, cualquier **path base** o **prefix** configurable.

> Si incluyes archivos locales en `assets/`, declara en `pubspec.yaml`. Para producción, preferimos **Storage** y URLs públicas/firmadas.

---

## 7) Variables y flags útiles

* `FEATURE_FLAGS` (opcional): habilitar/deshabilitar módulos (p.ej., idiomas, descarga offline).
* `SENTRY_DSN` (opcional): monitoreo de errores.

Expón estas variables con `--dart-define` si prefieres no usar `.env` en ciertos targets.

---

## 8) Comandos recomendados

```bash
# Verificación rápida
flutter analyze

# Limpiar y reconstruir
flutter clean && flutter pub get

# Formateo
dart format .
```

---

## 9) Problemas comunes (y soluciones)

* **Pantalla en blanco / datos vacíos** → revisa `SUPABASE_URL` y `SUPABASE_ANON_KEY`; comprueba CORS en Supabase (Project Settings → API → Additional Settings → **CORS** para Web).
* **403 en Storage** → políticas RLS de Storage no permiten lectura pública; ajusta políticas o usa URLs firmadas.
* **Slugs duplicados** → asegura `unique` en `slug` y usa `slugify` al insertar/actualizar.
* **“Missing plugin”** en iOS/Android → asegura `pod install` en iOS; en Android, sincroniza Gradle abriendo `/android` en Android Studio; corre `flutter clean`.
* **Conflictos de schema** entre entornos → agrega tu SQL a `/supabase/migrations` y coordina cambios con PRs.

---

## 10) Estructura de carpetas (orientativa)

```
root/
  lib/
    core/            # tema, utils, env loader
    screen/          # pantallas (home, catalog, tour, etc.)
    data/            # servicios y repositorios (Supabase)
    widgets/         # UI reutilizable
  assets/            # (si usas recursos locales)
  supabase/
    migrations/      # SQL versionado
    seed.sql         # (opcional) datos de ejemplo
  .env
  pubspec.yaml
```

---

## 11) Flujo de colaboración (resumen)

1. `git pull` en `main` → crea **rama feature**.
2. Commits pequeños → **push** → **Pull Request**.
3. Revisiones → merge → borrar rama.

> Los cambios de **Back End** (SQL, políticas, buckets) deben ir versionados en `/supabase/migrations` o documentados en PR.

---

## 12) Producción (muy breve)

* Genera builds firmados (Android **.aab/.apk**, iOS **.ipa**).
* Usa variables de entorno de **producción** (nuevo `.env` o `--dart-define`).
* Verifica políticas de Storage y RLS para evitar filtraciones.

---

## 13) Créditos y mantenimiento

* Contacto del proyecto: **Dr. Hugo Otero Gambetta** (owner).
* Tech lead Front/Back: asignar en **CODEOWNERS** (si corresponde).
* Issues y Roadmap: usar GitHub Projects/Issues.

---

> **¿Deseas que agregue tu SQL real de tablas/políticas de “Back End” como migraciones en `/supabase/migrations`?** Pásame el script actual o dame acceso al repo para parsearlo y lo integro al README con referencias exactas.
