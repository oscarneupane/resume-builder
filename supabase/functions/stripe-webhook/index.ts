// Edge Function: stripe-webhook (blueprint Part H4)
// Verifies the Stripe signature and syncs subscription status. No JWT — Stripe
// calls this directly, so we trust the signing secret instead.
//
// IMPORTANT: deploy with --no-verify-jwt so Supabase doesn't reject Stripe's
// unauthenticated requests (see supabase/README.md).
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import Stripe from 'https://esm.sh/stripe@14.0.0?target=deno';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const svc = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const STATUS_MAP: Record<string, (sub: Stripe.Subscription) => string> = {
  'customer.subscription.created': (s) => s.status,
  'customer.subscription.updated': (s) => s.status,
  'customer.subscription.deleted': () => 'canceled',
  'invoice.payment_failed': () => 'past_due',
};

serve(async (req) => {
  const body = await req.text();
  const sig = req.headers.get('stripe-signature');
  if (!sig) return new Response('Missing signature', { status: 400 });

  let event: Stripe.Event;
  try {
    // Async variant is required on Deno (SubtleCrypto is async).
    event = await stripe.webhooks.constructEventAsync(
      body,
      sig,
      Deno.env.get('STRIPE_WEBHOOK_SECRET')!,
    );
  } catch (err) {
    return new Response(`Invalid signature: ${err}`, { status: 400 });
  }

  const mapper = STATUS_MAP[event.type];
  if (mapper) {
    const sub = event.data.object as Stripe.Subscription & {
      customer: string;
      current_period_end: number;
    };
    const newStatus = mapper(sub);
    const isPro = ['active', 'trialing'].includes(newStatus);

    await svc.from('subscriptions').upsert(
      {
        stripe_customer_id: sub.customer,
        stripe_subscription_id: sub.id,
        plan: isPro ? 'pro' : 'free',
        status: newStatus,
        current_period_end: sub.current_period_end
          ? new Date(sub.current_period_end * 1000).toISOString()
          : null,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'stripe_customer_id' },
    );
  }

  // Audit trail (idempotent on stripe_event_id).
  await svc.from('payment_events').upsert(
    {
      stripe_event_id: event.id,
      event_type: event.type,
      data: event.data,
      processed: true,
    },
    { onConflict: 'stripe_event_id' },
  );

  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
