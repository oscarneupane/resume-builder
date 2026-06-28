// AI chat helper + prompt templates (blueprint Part G4).
//
// Provider-agnostic: picks the provider by which secret is set, preferring FREE
// providers so a free key takes over a quota-blocked OpenAI key. All three speak
// the OpenAI chat-completions format, so callers don't change.
//   GEMINI_API_KEY     → Gemini (free tier) — model gemini-flash-latest
//   OPENROUTER_API_KEY → OpenRouter (free models)
//   OPENAI_API_KEY     → OpenAI (paid)
export interface AiProvider {
  name: string;
  baseUrl: string;
  key: string;
  model: string;
  visionModel: string;
}

export function aiProvider(): AiProvider {
  const gemini = Deno.env.get('GEMINI_API_KEY');
  if (gemini) {
    return {
      name: 'Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      key: gemini,
      model: 'gemini-flash-latest',
      visionModel: 'gemini-flash-latest',
    };
  }
  const openrouter = Deno.env.get('OPENROUTER_API_KEY');
  if (openrouter) {
    return {
      name: 'OpenRouter',
      baseUrl: 'https://openrouter.ai/api/v1',
      key: openrouter,
      model: 'google/gemini-2.0-flash-exp:free',
      visionModel: 'google/gemini-2.0-flash-exp:free',
    };
  }
  return {
    name: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    key: Deno.env.get('OPENAI_API_KEY') ?? '',
    model: 'gpt-4o',
    visionModel: 'gpt-4o',
  };
}

export async function chat(prompt: string, opts: { json?: boolean } = {}): Promise<{
  content: string;
  tokens: number;
}> {
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
      model: p.model,
      messages: [{ role: 'user', content: prompt }],
      ...(opts.json ? { response_format: { type: 'json_object' } } : {}),
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${p.name} error ${res.status}: ${text}`);
  }

  const data = await res.json();
  return {
    content: data.choices?.[0]?.message?.content ?? '',
    tokens: data.usage?.total_tokens ?? 0,
  };
}

type Ctx = Record<string, unknown>;
const s = (ctx: Ctx, k: string) => (ctx[k] ?? '').toString();

/** Builds the prompt for the `ai-generate` feature switch. */
export function buildPrompt(feature: string, ctx: Ctx): { prompt: string; json: boolean } {
  switch (feature) {
    case 'professionalSummary':
      return {
        json: false,
        prompt: `You are a professional resume writer.
Write a 3-4 sentence professional summary for a resume.
Job title: ${s(ctx, 'jobTitle')}
Years of experience: ${s(ctx, 'yearsExp')}
Top skills: ${s(ctx, 'skills')}
Career goal: ${s(ctx, 'careerGoal')}
Write in first person without using 'I'. Be specific and impactful.`,
      };

    case 'bulletImprover':
      return {
        json: false,
        prompt: `You are an expert resume writer.
Rewrite this resume bullet point to be more impactful.
Use strong action verbs. Quantify results where possible.
Original: ${s(ctx, 'bullet')}
Job title: ${s(ctx, 'jobTitle')}
Return ONLY the improved bullet point. No explanations.`,
      };

    case 'linkedinHeadline':
      return {
        json: false,
        prompt: `Write 3 punchy LinkedIn headline options (max 120 chars each) for a
${s(ctx, 'jobTitle')} with ${s(ctx, 'yearsExp')} years of experience.
Skills: ${s(ctx, 'skills')}
Return each headline on its own line, no numbering or quotes.`,
      };

    case 'linkedinAbout':
      return {
        json: false,
        prompt: `Write a compelling LinkedIn About section.
Name: ${s(ctx, 'name')} | Job Title: ${s(ctx, 'jobTitle')}
Skills: ${s(ctx, 'skills')} | Career Goal: ${s(ctx, 'goal')}
Max 300 words. Professional tone. First person.`,
      };

    case 'recruiterMessage':
      return {
        json: false,
        prompt: `Write a short, friendly cold outreach message to a recruiter (max 90 words)
from a ${s(ctx, 'jobTitle')} with ${s(ctx, 'yearsExp')} years of experience.
Skills: ${s(ctx, 'skills')}
Polite, specific, and easy to reply to. Return only the message.`,
      };

    case 'interviewQuestions':
      return {
        json: true,
        prompt: `Generate 10 realistic interview questions for a ${s(ctx, 'jobTitle')} role
${s(ctx, 'experienceLevel') ? `(${s(ctx, 'experienceLevel')} level)` : ''}.
Mix behavioral, technical, and role-specific.
Return a JSON object with a single key "questions" whose value is an array of 10 strings.`,
      };

    case 'interviewAnswer':
      return {
        json: false,
        prompt: `Generate a STAR-method interview answer.
Question: ${s(ctx, 'question')}
Job Title: ${s(ctx, 'jobTitle')}
My Experience: ${s(ctx, 'experience')}
Format as:
Situation: ...
Task: ...
Action: ...
Result: ...`,
      };

    case 'skillsSuggest':
      return {
        json: true,
        prompt: `Suggest 10 relevant resume skills for the job title: ${s(ctx, 'jobTitle')}.
Return a JSON object with a single key "skills" whose value is an array of strings.`,
      };

    case 'interviewFeedback':
      return {
        json: true,
        prompt: `You are an experienced interview coach. Score and critique the candidate's answer.
Question: ${s(ctx, 'question')}
Job title: ${s(ctx, 'jobTitle')}
Candidate's answer: ${s(ctx, 'answer')}
Return a JSON object with EXACTLY these keys: "score" (number 0-100),
"summary" (string), "strengths" (array of short strings),
"improvements" (array of short, specific, actionable strings).`,
      };

    case 'fullResume':
      return {
        json: true,
        prompt: `You are an expert resume writer. Using ONLY the candidate details below,
produce a complete, polished, ATS-friendly resume. Improve wording, write strong
action-verb bullet points with quantified impact where plausible, group technical
skills by category, and write concise one-line project descriptions. Do NOT invent
employers, schools, job titles, dates, or contact details that are not present.
Target role: ${s(ctx, 'jobTitle')}
${s(ctx, 'notes') ? `Extra notes: ${s(ctx, 'notes')}\n` : ''}Candidate details:
${s(ctx, 'details')}
Return a JSON object with EXACTLY these keys: "personal"
{"fullName","title","email","phone","location","linkedin","github","portfolio"},
"summary" (string), "skills" (array of strings, each "Category: a, b, c"),
"projects" (array of {"name","description","link"}),
"experience" (array of {"title","company","startDate","endDate","bullets":[string]}),
"education" (array of {"degree","school","startDate","endDate"}).
Use empty strings/arrays where unknown.`,
      };

    default:
      return {
        json: false,
        prompt: `You are a helpful assistant. Context: ${JSON.stringify(ctx)}`,
      };
  }
}
