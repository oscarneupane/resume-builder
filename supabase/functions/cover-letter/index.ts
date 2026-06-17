// Edge Function: cover-letter (blueprint Part G4 cover letter template)
// Generates 3 formats and persists the result.
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { corsHeaders, json } from '../_shared/cors.ts';
import { checkRateLimit, logUsage, requireUser } from '../_shared/auth.ts';
import { chat } from '../_shared/openai.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const ctx = await requireUser(req);
    if (!(await checkRateLimit(ctx))) return json({ error: 'rate_limit' }, 429);

    const { jobTitle, companyName, skills, jobDescription, tone, resumeId } = await req.json();

    const prompt = `You are a professional cover letter writer.
Write a ${tone ?? 'professional'} cover letter for:
Job Title: ${jobTitle ?? ''}
Company: ${companyName ?? ''}
Applicant skills: ${skills ?? ''}
Job Description: ${jobDescription ?? ''}
Return a JSON object with keys: full_letter, short_email, recruiter_msg`;

    const { content, tokens } = await chat(prompt, { json: true });
    await logUsage(ctx, 'coverLetter', tokens);

    let parsed: Record<string, unknown> = {};
    try {
      parsed = JSON.parse(content);
    } catch (_) {
      return json({ error: 'Could not parse AI response', raw: content }, 502);
    }

    await ctx.svc.from('cover_letters').insert({
      user_id: ctx.userId,
      resume_id: resumeId ?? null,
      job_title: jobTitle ?? null,
      company_name: companyName ?? null,
      tone: tone ?? 'professional',
      full_letter: parsed.full_letter ?? null,
      short_email: parsed.short_email ?? null,
      recruiter_msg: parsed.recruiter_msg ?? null,
    });

    return json({ result: content });
  } catch (e) {
    if (e instanceof Response) return e;
    return json({ error: String(e) }, 500);
  }
});
