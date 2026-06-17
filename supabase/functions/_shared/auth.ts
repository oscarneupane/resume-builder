// Shared auth + Supabase client helpers for Edge Functions.
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

export interface AuthContext {
  userId: string;
  email: string | null;
  // Service-role client — bypasses RLS. Use ONLY in Edge Functions.
  svc: SupabaseClient;
}

/**
 * Verifies the caller's JWT (passed in the Authorization header) and returns the
 * user plus a service-role client. Throws a Response on failure so callers can
 * `return` it directly.
 */
export async function requireUser(req: Request): Promise<AuthContext> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    throw new Response('Unauthorized', { status: 401 });
  }

  const url = Deno.env.get('SUPABASE_URL')!;
  const anonClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error } = await anonClient.auth.getUser();
  if (error || !user) {
    throw new Response('Unauthorized', { status: 401 });
  }

  const svc = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  return { userId: user.id, email: user.email ?? null, svc };
}

/**
 * Enforces the free-plan rate limit (3 AI generations / rolling week).
 * Pro users are unlimited. Returns true if allowed.
 */
export async function checkRateLimit(ctx: AuthContext): Promise<boolean> {
  const { data: sub } = await ctx.svc
    .from('subscriptions')
    .select('plan')
    .eq('user_id', ctx.userId)
    .single();

  if (sub?.plan === 'pro') return true;

  const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const { count } = await ctx.svc
    .from('ai_generation_logs')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', ctx.userId)
    .gte('created_at', weekAgo);

  return (count ?? 0) < 3;
}

export async function logUsage(ctx: AuthContext, feature: string, tokens?: number) {
  await ctx.svc.from('ai_generation_logs').insert({
    user_id: ctx.userId,
    feature,
    tokens_used: tokens ?? null,
  });
}
