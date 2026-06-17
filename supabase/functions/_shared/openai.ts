// OpenAI chat helper + prompt templates (blueprint Part G4).

export async function chat(prompt: string, opts: { json?: boolean } = {}): Promise<{
  content: string;
  tokens: number;
}> {
  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      messages: [{ role: 'user', content: prompt }],
      ...(opts.json ? { response_format: { type: 'json_object' } } : {}),
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OpenAI error ${res.status}: ${text}`);
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

    case 'linkedinAbout':
      return {
        json: false,
        prompt: `Write a compelling LinkedIn About section.
Name: ${s(ctx, 'name')} | Job Title: ${s(ctx, 'jobTitle')}
Skills: ${s(ctx, 'skills')} | Career Goal: ${s(ctx, 'goal')}
Max 300 words. Professional tone. First person.`,
      };

    case 'interviewAnswer':
      return {
        json: true,
        prompt: `Generate a STAR-method interview answer.
Question: ${s(ctx, 'question')}
Job Title: ${s(ctx, 'jobTitle')}
My Experience: ${s(ctx, 'experience')}
Return JSON with keys: situation, task, action, result.`,
      };

    case 'skillsSuggest':
      return {
        json: true,
        prompt: `Suggest 10 relevant resume skills for the job title: ${s(ctx, 'jobTitle')}.
Return a JSON object with a single key "skills" whose value is an array of strings.`,
      };

    default:
      return {
        json: false,
        prompt: `You are a helpful assistant. Context: ${JSON.stringify(ctx)}`,
      };
  }
}
