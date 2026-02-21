// Edge Function: envía correo de notificación al crear una reservación.
// Opción gratuita: Resend (RESEND_API_KEY) — solo configurar la API key.
// Opción con tu dominio: SMTP Office 365 (SMTP_USER, SMTP_PASS).

import { SMTPClient } from "https://deno.land/x/denomailer@v1.6.0/mod.ts";

const RESEND_API_URL = "https://api.resend.com/emails";
const SMTP_HOST = "smtp.office365.com";
const SMTP_PORT = 587;

// Remitente por defecto en plan gratuito de Resend (no requiere verificar dominio)
const RESEND_DEFAULT_FROM = "TACTICAL SUPPORT Agenda <onboarding@resend.dev>";

interface ReservationRecord {
  id?: string;
  fecha?: string;
  hora?: string;
  responsable?: string;
  asunto?: string;
  participantes?: string;
  reservado_por?: string;
  nombre_contacto?: string;
  correo_notificacion?: string;
}

function getRecordFromPayload(body: unknown): ReservationRecord | null {
  if (!body || typeof body !== "object") return null;
  const b = body as Record<string, unknown>;
  if (b.record && typeof b.record === "object") return b.record as ReservationRecord;
  if (b.fecha != null || b.correo_notificacion != null) return b as ReservationRecord;
  return null;
}

function buildEmailHtml(record: ReservationRecord): string {
  const fecha = record.fecha ?? "";
  const hora = record.hora ?? "";
  const organizador = record.responsable ?? "";
  const asunto = record.asunto ?? "";
  const participantes = record.participantes ?? "—";
  return `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: sans-serif; max-width: 560px;">
  <h2 style="color: #2563eb;">Recordatorio de reunión - TACTICAL SUPPORT</h2>
  <p>Se ha programado una reservación de sala.</p>
  <table style="border-collapse: collapse;">
    <tr><td style="padding: 6px 12px 6px 0; font-weight: bold;">Fecha:</td><td>${fecha}</td></tr>
    <tr><td style="padding: 6px 12px 6px 0; font-weight: bold;">Hora:</td><td>${hora}</td></tr>
    <tr><td style="padding: 6px 12px 6px 0; font-weight: bold;">Organizador:</td><td>${organizador}</td></tr>
    <tr><td style="padding: 6px 12px 6px 0; font-weight: bold;">Asunto:</td><td>${asunto}</td></tr>
    <tr><td style="padding: 6px 12px 6px 0; font-weight: bold;">Participantes:</td><td>${participantes}</td></tr>
  </table>
  <p style="margin-top: 24px; color: #666; font-size: 14px;">Este correo es un recordatorio automático de la agenda.</p>
</body>
</html>
`.trim();
}

async function sendViaResend(to: string, subject: string, html: string): Promise<void> {
  const apiKey = Deno.env.get("RESEND_API_KEY");
  if (!apiKey) throw new Error("RESEND_API_KEY no configurado");

  const from = Deno.env.get("RESEND_FROM") ?? RESEND_DEFAULT_FROM;

  const res = await fetch(RESEND_API_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ from, to: [to], subject, html }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Resend API: ${res.status} ${err}`);
  }
}

async function sendViaSmtp(to: string, subject: string, html: string): Promise<void> {
  const smtpUser = Deno.env.get("SMTP_USER");
  const smtpPass = Deno.env.get("SMTP_PASS");
  const fromEmail = Deno.env.get("SMTP_FROM") ?? smtpUser ?? "noreply@tacticalsupport.com.mx";

  if (!smtpUser || !smtpPass) throw new Error("SMTP_USER o SMTP_PASS no configurados");

  const client = new SMTPClient({
    connection: {
      hostname: SMTP_HOST,
      port: SMTP_PORT,
      tls: true,
      auth: { username: smtpUser, password: smtpPass },
    },
  });

  await client.send({
    from: fromEmail,
    to,
    subject,
    content: "Ver contenido en HTML.",
    html,
  });
  await client.close();
}

Deno.serve(async (req: Request): Promise<Response> => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Método no permitido" }), {
      status: 405,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Body JSON inválido" }), {
      status: 400,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }

  const record = getRecordFromPayload(body);
  if (!record) {
    return new Response(JSON.stringify({ error: "Falta el registro de reservación" }), {
      status: 400,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }

  const to = (record.correo_notificacion ?? "").trim();
  if (!to) {
    return new Response(JSON.stringify({ ok: true, skipped: "Sin correo de notificación" }), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }

  const subject = `Reservación: ${record.asunto ?? "Sala"} - ${record.fecha ?? ""} ${record.hora ?? ""}`;
  const html = buildEmailHtml(record);

  const useResend = !!Deno.env.get("RESEND_API_KEY");
  const useSmtp = !!Deno.env.get("SMTP_USER") && !!Deno.env.get("SMTP_PASS");

  try {
    if (useResend) {
      await sendViaResend(to, subject, html);
      return new Response(JSON.stringify({ ok: true, sent: to, provider: "resend" }), {
        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }
    if (useSmtp) {
      await sendViaSmtp(to, subject, html);
      return new Response(JSON.stringify({ ok: true, sent: to, provider: "smtp" }), {
        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }
    return new Response(
      JSON.stringify({
        error: "Configura RESEND_API_KEY (gratis) o SMTP_USER + SMTP_PASS. Ver NOTIFICACIONES-EMAIL.md",
      }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } },
    );
  } catch (err) {
    console.error("Error enviando correo:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
});
