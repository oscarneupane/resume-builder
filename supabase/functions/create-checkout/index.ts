// Edge Function: create-checkout (blueprint Part H3)
// Creates (or reuses) a Stripe customer and returns a Checkout Session URL.
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import Stripe from 'https://esm.sh/stripe@14.0.0?target=deno';
import { corsHeaders, json } from '../_shared/cors.ts';
import { requireUser } from '../_shared/auth.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const ctx = await requireUser(req);
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
      apiVersion: '2023-10-16',
      httpClient: Stripe.createFetchHttpClient(),
    });

    // Reuse an existing Stripe customer for this user if we have one.
    const { data: sub } = await ctx.svc
      .from('subscriptions')
      .select('stripe_customer_id')
      .eq('user_id', ctx.userId)
      .single();

    let customerId = sub?.stripe_customer_id ?? undefined;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: ctx.email ?? undefined,
        metadata: { supabase_user_id: ctx.userId },
      });
      customerId = customer.id;
      // Seed a subscriptions row so the webhook can upsert by customer id later.
      await ctx.svc.from('subscriptions').upsert(
        { user_id: ctx.userId, stripe_customer_id: customerId },
        { onConflict: 'user_id' },
      );
    }

    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      payment_method_types: ['card'],
      line_items: [{ price: Deno.env.get('STRIPE_PRICE_ID')!, quantity: 1 }],
      mode: 'subscription',
      subscription_data: { trial_period_days: 7 },
      success_url: 'applymate://payment-success',
      cancel_url: 'applymate://payment-cancelled',
    });

    return json({ url: session.url });
  } catch (e) {
    if (e instanceof Response) return e;
    return json({ error: String(e) }, 500);
  }
});
