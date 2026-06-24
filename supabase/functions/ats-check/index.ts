// Edge Function: ats-check (blueprint Part G4 ATS template)
// Scores a resume against a job description and persists the result.
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { corsHeaders, json } from '../_shared/cors.ts';
import { checkRateLimit, logUsage, requireUser } from '../_shared/auth.ts';
import { chat } from '../_shared/claude.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const ctx = await requireUser(req);
    if (!(await checkRateLimit(ctx))) return json({ error: 'rate_limit' }, 429);

    const { resumeText, jobDescription, resumeId } = await req.json();
    if (!jobDescription) return json({ error: 'jobDescription is required' }, 400);

    const prompt = `You are an ATS expert. Analyze this resume against the job description.
RESUME: ${resumeText ?? ''}
JOB DESCRIPTION: ${jobDescription}
Return a JSON object with these exact keys:
{
  "score": number (0-100),
  "matching_keywords": string[],
  "missing_keywords": string[],
  "weak_sections": string[],
  "suggestions": [{ "section": string, "issue": string, "fix": string }]
}`;

    const { content, tokens } = await chat(prompt, { json: true });
    await logUsage(ctx, 'atsCheck', tokens);

    let parsed: Record<string, unknown> = {};
    try {
      parsed = JSON.parse(content);
    } catch (_) {
      return json({ error: 'Could not parse AI response', raw: content }, 502);
    }

    // Persist the check (best-effort; ignore insert errors).
    await ctx.svc.from('ats_checks').insert({
      user_id: ctx.userId,
      resume_id: resumeId ?? null,
      job_description: jobDescription,
      ats_score: parsed.score ?? null,
      matching_keywords: parsed.matching_keywords ?? [],
      missing_keywords: parsed.missing_keywords ?? [],
      weak_sections: parsed.weak_sections ?? [],
      suggestions: parsed.suggestions ?? [],
    });

    // Client parses `result` as the JSON string.
    return json({ result: content });
  } catch (e) {
    if (e instanceof Response) return e;
    return json({ error: String(e) }, 500);
  }
});
