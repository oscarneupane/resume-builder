// Edge Function: ai-extract
// Scans an uploaded image/PDF-page (base64) or text with a vision model and
// returns extracted content (plain text or structured JSON). Used by the
// Materials library + Smart Import. Keeps the AI key server-side.
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { corsHeaders, json } from '../_shared/cors.ts';
import { checkRateLimit, logUsage, requireUser } from '../_shared/auth.ts';
import { aiProvider } from '../_shared/openai.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const ctx = await requireUser(req);
    if (!(await checkRateLimit(ctx))) return json({ error: 'rate_limit' }, 429);

    const { prompt, structured, image, text } = await req.json();
    if (!prompt) return json({ error: 'prompt is required' }, 400);

    const content: unknown[] = [
      { type: 'text', text: text ? `${prompt}\n\nSOURCE:\n${text}` : prompt },
    ];
    if (image) {
      content.push({ type: 'image_url', image_url: { url: `data:image/png;base64,${image}` } });
    }

    const p = aiProvider();
    const res = await fetch(`${p.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${p.key}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://applymate.app',
        'X-Title': 'ApplyMate',
      },
      body: JSON.stringify({
        model: p.visionModel,
        messages: [{ role: 'user', content }],
        ...(structured ? { response_format: { type: 'json_object' } } : {}),
      }),
    });

    if (!res.ok) return json({ error: `${p.name} error ${res.status}` }, 502);
    const data = await res.json();
    await logUsage(ctx, 'extract', data.usage?.total_tokens);
    return json({ result: data.choices?.[0]?.message?.content ?? '' });
  } catch (e) {
    if (e instanceof Response) return e;
    return json({ error: String(e) }, 500);
  }
});
