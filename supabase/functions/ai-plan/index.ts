// Edge Function: ai-plan
// Claude-backed planning/writing function for resume summaries, bullets,
// LinkedIn, interview prep, skills, and similar high-level career content.
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { corsHeaders, json } from '../_shared/cors.ts';
import { checkRateLimit, logUsage, requireUser } from '../_shared/auth.ts';
import { buildPlanningPrompt, chat } from '../_shared/claude.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const ctx = await requireUser(req);
    if (!(await checkRateLimit(ctx))) return json({ error: 'rate_limit' }, 429);

    const { feature, context } = await req.json();
    if (!feature) return json({ error: 'feature is required' }, 400);

    const { prompt, json: wantsJson } = buildPlanningPrompt(feature, context ?? {});
    // auto-routes: Claude → DeepSeek → Groq based on which secrets are set
    const { content, tokens, provider } = await chat(prompt, { json: wantsJson });
    console.log(`[ai-plan] feature=${feature} provider=${provider} tokens=${tokens}`);
    await logUsage(ctx, feature, tokens);

    let result = content;
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
    if (e instanceof Response) return e;
    return json({ error: String(e) }, 500);
  }
});
