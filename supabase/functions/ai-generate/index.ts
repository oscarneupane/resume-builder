// Edge Function: ai-generate (blueprint Part G3)
// Routes resume/summary/skills/etc. AI requests through OpenAI with JWT auth,
// free-plan rate limiting, and usage logging. The OpenAI key never leaves here.
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { corsHeaders, json } from '../_shared/cors.ts';
import { checkRateLimit, logUsage, requireUser } from '../_shared/auth.ts';
import { buildPrompt, chat } from '../_shared/openai.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const ctx = await requireUser(req);

    if (!(await checkRateLimit(ctx))) {
      return json({ error: 'rate_limit' }, 429);
    }

    const { feature, context } = await req.json();
    if (!feature) return json({ error: 'feature is required' }, 400);

    const { prompt, json: wantsJson } = buildPrompt(feature, context ?? {});
    const { content, tokens } = await chat(prompt, { json: wantsJson });

    await logUsage(ctx, feature, tokens);

    // Normalize skillsSuggest to a bare JSON array string (the client parses a List).
    let result = content;
    // List-style features return a JSON object; unwrap to a bare array string.
    if (feature === 'skillsSuggest' || feature === 'interviewQuestions') {
      const key = feature === 'skillsSuggest' ? 'skills' : 'questions';
      try {
        const parsed = JSON.parse(content);
        const list = Array.isArray(parsed) ? parsed : (parsed[key] ?? []);
        result = JSON.stringify(list);
      } catch (_) {
        result = '[]';
      }
    }

    return json({ result });
  } catch (e) {
    if (e instanceof Response) return e; // auth failures
    return json({ error: String(e) }, 500);
  }
});
