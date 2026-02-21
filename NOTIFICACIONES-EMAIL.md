# Notificaciones por correo

La app envía un correo de recordatorio cuando creas una reservación con **Correo (notificación de reunión)** rellenado. Puedes usar la **opción gratuita (Resend)** o, si prefieres tu dominio, **SMTP de Office 365**.

---

## Opción gratuita: Resend (recomendada)

Resend tiene **plan gratuito** (100 correos/día, 3.000/mes). No necesitas verificar dominio para empezar: los correos salen desde `onboarding@resend.dev` con el nombre "TACTICAL SUPPORT Agenda".

### 1. Crear cuenta y obtener API key

1. Entra en [resend.com](https://resend.com) y regístrate (gratis).
2. En el dashboard: **API Keys** → **Create API Key** → copia la key (empieza por `re_`).

### 2. Configurar el secreto en Supabase

En la terminal (en la carpeta del proyecto):

```bash
supabase secrets set RESEND_API_KEY=re_tu_api_key_aqui
```

O en el **Dashboard de Supabase**: **Project Settings** → **Edge Functions** → **Secrets** → añade `RESEND_API_KEY` con el valor de la key.

### 3. Desplegar la función

```bash
cd c:\Users\fjavi\calendario_app
supabase link --project-ref TU_PROJECT_REF   # solo la primera vez
supabase functions deploy send-reservation-email
```

### 4. Probar

Crea una reservación en la app con **Correo (notificación de reunión)** rellenado. Debería llegar el correo (revisa spam la primera vez).

**Resumen:** Solo necesitas `RESEND_API_KEY`. La función usa por defecto el remitente `onboarding@resend.dev` (válido en el plan gratuito).

---

## Usar tu dominio @tacticalsupport.com.mx con Resend (opcional)

Si quieres que los correos salgan desde `noreply@tacticalsupport.com.mx`:

1. En Resend: **Domains** → **Add Domain** → añade `tacticalsupport.com.mx` y configura los registros DNS que te indiquen.
2. En Supabase, añade el secreto opcional:
   ```bash
   supabase secrets set RESEND_FROM="TACTICAL SUPPORT <noreply@tacticalsupport.com.mx>"
   ```
   Si no pones `RESEND_FROM`, se sigue usando `onboarding@resend.dev`.

---

## Opción alternativa: SMTP Office 365

Si prefieres usar directamente tu correo de Microsoft 365 (@tacticalsupport.com.mx) por SMTP:

1. Crea una **contraseña de aplicación** en [account.microsoft.com/security](https://account.microsoft.com/security) (Seguridad avanzada → Contraseñas de aplicación).
2. Configura los secretos (y **quita** `RESEND_API_KEY` si lo tenías, para que use SMTP):
   ```bash
   supabase secrets set SMTP_USER=noreply@tacticalsupport.com.mx
   supabase secrets set SMTP_PASS=tu_contraseña_de_aplicacion
   # Opcional:
   supabase secrets set SMTP_FROM="TACTICAL SUPPORT <noreply@tacticalsupport.com.mx>"
   ```

La función usa **primero Resend** si existe `RESEND_API_KEY`; si no, usa **SMTP** si están `SMTP_USER` y `SMTP_PASS`.

---

## Prioridad de la función

1. Si está definido **RESEND_API_KEY** → envía por Resend (gratis, sin configurar SMTP).
2. Si no, y están **SMTP_USER** y **SMTP_PASS** → envía por Office 365.

Solo necesitas configurar **una** de las dos opciones.

---

## Resumen rápido (solo gratis)

| Paso | Acción |
|------|--------|
| 1 | Cuenta en [resend.com](https://resend.com) → crear API Key. |
| 2 | `supabase secrets set RESEND_API_KEY=re_xxx` |
| 3 | `supabase functions deploy send-reservation-email` |
| 4 | Probar creando una reserva con correo de notificación. |

No hace falta configurar Office 365 ni SMTP para que funcione la opción gratuita.
