// Multi-provider AI helper for ApplyMate Edge Functions.
//
// Provider priority (first available secret wins):
//   1. Claude   (CLAUDE_API_KEY)    — best quality, vision support
//   2. DeepSeek (DEEPSEEK_API_KEY)  — free tier, OpenAI-compatible, very capable
//   3. Groq     (GROQ_API_KEY)      — free tier, fastest inference
//   4. Gemini   (GEMINI_API_KEY)    — Google free tier
//
// Set secrets via: supabase secrets set CLAUDE_API_KEY=sk-ant-...
//                  supabase secrets set DEEPSEEK_API_KEY=sk-...
//                  supabase secrets set GROQ_API_KEY=gsk_...
//                  supabase secrets set GEMINI_API_KEY=AIza...

const SYSTEM_PROMPT =
  'You are ApplyMate, a precise career-document assistant. Be practical, specific, and concise.';
const SYSTEM_PROMPT_JSON =
  'You are ApplyMate, a precise career-document assistant. Return only valid JSON. Do not wrap in markdown.';

// ── Claude (Anthropic) ────────────────────────────────────────────────────────

async function chatClaude(
  prompt: string,
  opts: { json?: boolean } = {},
): Promise<{ content: string; tokens: number }> {
  const apiKey = Deno.env.get('CLAUDE_API_KEY');
  if (!apiKey) throw new Error('CLAUDE_API_KEY not set');

  const model = Deno.env.get('CLAUDE_MODEL') ?? 'claude-haiku-4-5';
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      max_tokens: 1400,
      system: opts.json ? SYSTEM_PROMPT_JSON : SYSTEM_PROMPT,
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  if (!res.ok) throw new Error(`Claude ${res.status}: ${await res.text()}`);

  const data = await res.json();
  const content = (data.content ?? [])
    .filter((p: { type?: string }) => p.type === 'text')
    .map((p: { text?: string }) => p.text ?? '')
    .join('\n')
    .trim();

  return {
    content,
    tokens: (data.usage?.input_tokens ?? 0) + (data.usage?.output_tokens ?? 0),
  };
}

// ── DeepSeek (OpenAI-compatible, Chinese free API) ────────────────────────────

async function chatDeepSeek(
  prompt: string,
  opts: { json?: boolean } = {},
): Promise<{ content: string; tokens: number }> {
  const apiKey = Deno.env.get('DEEPSEEK_API_KEY');
  if (!apiKey) throw new Error('DEEPSEEK_API_KEY not set');

  const model = Deno.env.get('DEEPSEEK_MODEL') ?? 'deepseek-chat';
  const body: Record<string, unknown> = {
    model,
    max_tokens: 1400,
    messages: [
      { role: 'system', content: opts.json ? SYSTEM_PROMPT_JSON : SYSTEM_PROMPT },
      { role: 'user', content: prompt },
    ],
  };
  if (opts.json) body['response_format'] = { type: 'json_object' };

  const res = await fetch('https://api.deepseek.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) throw new Error(`DeepSeek ${res.status}: ${await res.text()}`);

  const data = await res.json();
  const content = (data.choices?.[0]?.message?.content ?? '').trim();
  return {
    content,
    tokens: (data.usage?.total_tokens ?? 0),
  };
}

// ── Groq (OpenAI-compatible, free tier) ───────────────────────────────────────

async function chatGroq(
  prompt: string,
  opts: { json?: boolean } = {},
): Promise<{ content: string; tokens: number }> {
  const apiKey = Deno.env.get('GROQ_API_KEY');
  if (!apiKey) throw new Error('GROQ_API_KEY not set');

  const model = Deno.env.get('GROQ_MODEL') ?? 'llama-3.1-8b-instant';
  const body: Record<string, unknown> = {
    model,
    max_tokens: 1400,
    messages: [
      { role: 'system', content: opts.json ? SYSTEM_PROMPT_JSON : SYSTEM_PROMPT },
      { role: 'user', content: prompt },
    ],
  };
  // Groq supports json_object mode
  if (opts.json) body['response_format'] = { type: 'json_object' };

  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) throw new Error(`Groq ${res.status}: ${await res.text()}`);

  const data = await res.json();
  const content = (data.choices?.[0]?.message?.content ?? '').trim();
  return {
    content,
    tokens: (data.usage?.total_tokens ?? 0),
  };
}

// ── Gemini (Google) ───────────────────────────────────────────────────────────

async function chatGemini(
  prompt: string,
  _opts: { json?: boolean } = {},
): Promise<{ content: string; tokens: number }> {
  const apiKey = Deno.env.get('GEMINI_API_KEY');
  if (!apiKey) throw new Error('GEMINI_API_KEY not set');

  const model = Deno.env.get('GEMINI_MODEL') ?? 'gemini-2.0-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { maxOutputTokens: 1400, temperature: 0.7 },
    }),
  });

  if (!res.ok) throw new Error(`Gemini ${res.status}: ${await res.text()}`);

  const data = await res.json();
  const content = (data.candidates?.[0]?.content?.parts?.[0]?.text ?? '').trim();
  const tokens = (data.usageMetadata?.totalTokenCount ?? 0);
  return { content, tokens };
}

// ── Auto-routing: tries each provider in order ────────────────────────────────

export async function chat(
  prompt: string,
  opts: { json?: boolean } = {},
): Promise<{ content: string; tokens: number; provider: string }> {
  const errors: string[] = [];

  if (Deno.env.get('CLAUDE_API_KEY')) {
    try {
      const r = await chatClaude(prompt, opts);
      return { ...r, provider: 'claude' };
    } catch (e) {
      errors.push(`Claude: ${e}`);
    }
  }

  if (Deno.env.get('DEEPSEEK_API_KEY')) {
    try {
      const r = await chatDeepSeek(prompt, opts);
      return { ...r, provider: 'deepseek' };
    } catch (e) {
      errors.push(`DeepSeek: ${e}`);
    }
  }

  if (Deno.env.get('GROQ_API_KEY')) {
    try {
      const r = await chatGroq(prompt, opts);
      return { ...r, provider: 'groq' };
    } catch (e) {
      errors.push(`Groq: ${e}`);
    }
  }

  if (Deno.env.get('GEMINI_API_KEY')) {
    try {
      const r = await chatGemini(prompt, opts);
      return { ...r, provider: 'gemini' };
    } catch (e) {
      errors.push(`Gemini: ${e}`);
    }
  }

  throw new Error(
    `All AI providers failed. Set at least one of: CLAUDE_API_KEY, DEEPSEEK_API_KEY, GROQ_API_KEY, GEMINI_API_KEY.\nErrors: ${errors.join(' | ')}`,
  );
}

// Keep named export for any existing callers that import chatClaude directly.
export { chatClaude };

// ── Prompt templates ──────────────────────────────────────────────────────────

type Ctx = Record<string, unknown>;
const s = (ctx: Ctx, k: string) => (ctx[k] ?? '').toString();

export function buildPlanningPrompt(
  feature: string,
  ctx: Ctx,
): { prompt: string; json: boolean } {
  switch (feature) {
    case 'professionalSummary':
      return {
        json: false,
        prompt: `Write a 3-4 sentence professional resume summary.
Job title: ${s(ctx, 'jobTitle')}
Years of experience: ${s(ctx, 'yearsExp')}
Top skills: ${s(ctx, 'skills')}
Career goal: ${s(ctx, 'careerGoal')}
Use only supplied facts. Do not invent employers, degrees, or numbers.
Return only the summary text.`,
      };

    case 'bulletImprover':
      return {
        json: false,
        prompt: `Rewrite this resume bullet to be stronger and ATS-friendly.
Original: ${s(ctx, 'bullet')}
Target role: ${s(ctx, 'jobTitle')}
Use a strong action verb. Quantify only if the original gives enough basis.
Return only the improved bullet.`,
      };

    case 'linkedinHeadline':
      return {
        json: false,
        prompt: `Write 3 LinkedIn headline options, each max 120 characters.
Role: ${s(ctx, 'jobTitle')}
Years: ${s(ctx, 'yearsExp')}
Skills: ${s(ctx, 'skills')}
Return each headline on its own line, no numbering.`,
      };

    case 'linkedinAbout':
      return {
        json: false,
        prompt: `Write a compelling LinkedIn About section.
Name: ${s(ctx, 'name')}
Role: ${s(ctx, 'jobTitle')}
Skills: ${s(ctx, 'skills')}
Career goal: ${s(ctx, 'goal')}
Max 300 words. First person. Specific, human, and recruiter-friendly.`,
      };

    case 'recruiterMessage':
      return {
        json: false,
        prompt: `Write a short, friendly cold outreach message to a recruiter.
Role: ${s(ctx, 'jobTitle')}
Years: ${s(ctx, 'yearsExp')}
Skills: ${s(ctx, 'skills')}
Max 90 words. Easy to reply to. Return only the message.`,
      };

    case 'interviewQuestions':
      return {
        json: true,
        prompt: `Generate 10 realistic interview questions.
Role: ${s(ctx, 'jobTitle')}
Level: ${s(ctx, 'experienceLevel')}
Mix behavioral, technical, and role-specific questions.
Return JSON only: {"questions":["..."]}`,
      };

    case 'interviewAnswer':
      return {
        json: false,
        prompt: `Draft a STAR-method interview answer.
Question: ${s(ctx, 'question')}
Role: ${s(ctx, 'jobTitle')}
Experience: ${s(ctx, 'experience')}
Format: Situation / Task / Action / Result`,
      };

    case 'skillsSuggest':
      return {
        json: true,
        prompt: `Suggest 10 relevant resume skills for: ${s(ctx, 'jobTitle')}.
Return JSON only: {"skills":["..."]}`,
      };

    default:
      return {
        json: false,
        prompt: `Help improve this career-application material:\n${JSON.stringify(ctx)}`,
      };
  }
}
