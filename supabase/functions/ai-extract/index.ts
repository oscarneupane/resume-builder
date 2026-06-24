// Edge Function: ai-extract
// Scans an uploaded image/PDF-page (base64) or text with GPT-4o vision and
// returns extracted content (plain text or structured JSON). Used by the
// Materials library + Smart Import. Keeps the OpenAI key server-side.
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { corsHeaders, json } from '../_shared/cors.ts';
import { checkRateLimit, logUsage, requireUser } from '../_shared/auth.ts';

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

    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [{ role: 'user', content }],
        ...(structured ? { response_format: { type: 'json_object' } } : {}),
      }),
    });

    if (!res.ok) return json({ error: `OpenAI error ${res.status}` }, 502);
    const data = await res.json();
    await logUsage(ctx, 'extract', data.usage?.total_tokens);
    return json({ result: data.choices?.[0]?.message?.content ?? '' });
  } catch (e) {
    if (e instanceof Response) return e;
    return json({ error: String(e) }, 500);
  }
});
