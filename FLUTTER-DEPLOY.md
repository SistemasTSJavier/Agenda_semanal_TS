# Flutter: que todo funcione (build + GitHub Pages)

Sigue estos pasos en orden para que la app Flutter se compile y se vea en la web.

---

## 1. Clave de Supabase (obligatorio)

Sin la clave anon, la app no puede conectar con el backend.

1. Entra en [Supabase](https://supabase.com/dashboard) → tu proyecto → **Settings** → **API**.
2. Copia la clave **anon public** (la larga que empieza por `eyJ...`).
3. Abre **`lib/config/supabase_config.dart`** y sustituye `TU_ANON_KEY_AQUI` por esa clave:

```dart
static const String supabaseAnonKey = 'eyJ...tu_clave_completa...';
```

4. Guarda y haz commit (si el repo es privado no hay problema en subirla):

```powershell
git add lib/config/supabase_config.dart
git commit -m "Configurar clave Supabase"
git push origin main
```

---

## 2. GitHub Pages con GitHub Actions

Para que lo que compila Flutter sea lo que se publica:

1. Repo en GitHub → **Settings** → **Pages**.
2. En **Build and deployment**, en **Source** elige **GitHub Actions** (no "Deploy from a branch").
3. Guarda.

Si aquí tienes "Deploy from a branch", la web no se actualizará con el build de Flutter.

---

## 3. Que el workflow pase (Actions)

Cada vez que haces **push a `main`**, se ejecuta el workflow que:

- Instala Flutter
- Ejecuta `flutter pub get` y `flutter build web --base-href "/Agenda_semanal_TS/"`
- Sube el resultado a GitHub Pages

1. Repo → pestaña **Actions**.
2. Abre el último **"Build and deploy to GitHub Pages"**.
3. Debe terminar en **verde** (todos los pasos ✓).

Si falla:

- **"version solving failed"** → ya está corregido con `intl: ^0.19.0` en `pubspec.yaml`. Haz push de ese cambio.
- **"repository not found"** → el workflow ya usa `actions/configure-pages` (no `configure-pagedeploy`).
- Otro error → abre el paso en rojo y lee el mensaje; si lo pegas aquí te ayudo.

---

## 4. Ver la app en la web

- URL: **https://sistemastsjavier.github.io/Agenda_semanal_TS/**
- Espera 2–3 minutos después del push para que termine el deploy.
- Si sigue viéndose la versión antigua: **Ctrl+Shift+R** (recarga forzada) o abre la URL en **modo incógnito** (caché del navegador).

---

## 5. Probar en local (opcional)

```powershell
cd c:\Users\fjavi\calendario_app
flutter pub get
flutter run -d chrome
```

O compilar web y abrir la carpeta generada:

```powershell
flutter build web --base-href "/"
# Abre build/web/index.html o sirve la carpeta con: npx serve build/web
```

---

## Resumen

| Paso | Qué hacer |
|------|-----------|
| 1 | Poner la anon key en `lib/config/supabase_config.dart` y hacer push. |
| 2 | Settings → Pages → Source = **GitHub Actions**. |
| 3 | Revisar que el workflow en Actions termine en verde. |
| 4 | Abrir https://sistemastsjavier.github.io/Agenda_semanal_TS/ (recarga forzada o incógnito si no se actualiza). |

Con eso, Flutter debería quedar funcionando de punta a punta.
