-- ApplyMate initial schema
-- Source: blueprint Part D (tables), Part L1/L3/L4 (security).
-- All user-owned tables enable RLS with an owner policy keyed on auth.uid().

-- ─────────────────────────────────────────────────────────────────────────────
-- profiles
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name    TEXT,
  avatar_url   TEXT,
  career_goal  TEXT,
  job_title    TEXT,
  country      TEXT,
  experience   TEXT CHECK (experience IN ('entry','junior','mid','senior','executive')),
  resume_style TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage their own profile"
  ON profiles FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Auto-create a profile row when a new auth user signs up. full_name is taken
-- from the signUp metadata the Flutter app sends.
CREATE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─────────────────────────────────────────────────────────────────────────────
-- resumes
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE resumes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL DEFAULT 'My Resume',
  template    TEXT DEFAULT 'classic',
  is_primary  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE resumes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their resumes"
  ON resumes FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX resumes_user_id_idx ON resumes(user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- resume_sections
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE resume_sections (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resume_id     UUID NOT NULL REFERENCES resumes(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  section_type  TEXT NOT NULL CHECK (section_type IN (
                  'personal','summary','experience','education',
                  'skills','projects','certifications','languages','references')),
  content       JSONB NOT NULL DEFAULT '{}',
  display_order INT DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE resume_sections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their sections"
  ON resume_sections FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX resume_sections_resume_id_idx ON resume_sections(resume_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- cover_letters
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE cover_letters (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  resume_id     UUID REFERENCES resumes(id) ON DELETE SET NULL,
  job_title     TEXT,
  company_name  TEXT,
  tone          TEXT DEFAULT 'professional',
  full_letter   TEXT,
  short_email   TEXT,
  recruiter_msg TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE cover_letters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their cover letters"
  ON cover_letters FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- ats_checks
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE ats_checks (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  resume_id         UUID REFERENCES resumes(id) ON DELETE SET NULL,
  job_description   TEXT NOT NULL,
  ats_score         INT CHECK (ats_score BETWEEN 0 AND 100),
  matching_keywords TEXT[],
  missing_keywords  TEXT[],
  weak_sections     TEXT[],
  suggestions       JSONB DEFAULT '[]',
  created_at        TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE ats_checks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their ATS checks"
  ON ats_checks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- job_applications
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE job_applications (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_name     TEXT NOT NULL,
  job_title        TEXT NOT NULL,
  application_date DATE DEFAULT CURRENT_DATE,
  status           TEXT DEFAULT 'saved' CHECK (status IN (
                     'saved','applied','interview','offer','rejected')),
  notes            TEXT,
  resume_id        UUID REFERENCES resumes(id) ON DELETE SET NULL,
  cover_letter_id  UUID REFERENCES cover_letters(id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their job applications"
  ON job_applications FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- interview_answers  (named in Part D1)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE interview_answers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question    TEXT NOT NULL,
  category    TEXT,
  job_title   TEXT,
  star_answer JSONB DEFAULT '{}',   -- { situation, task, action, result }
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE interview_answers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their interview answers"
  ON interview_answers FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- documents  (metadata for files in Supabase Storage; named in Part D1)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE documents (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  doc_type     TEXT NOT NULL CHECK (doc_type IN ('resume','cover_letter','upload','export')),
  file_name    TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  file_size    BIGINT,
  mime_type    TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their documents"
  ON documents FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- subscriptions  (users READ only; Edge Functions write via service role)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE subscriptions (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_customer_id     TEXT UNIQUE,
  stripe_subscription_id TEXT UNIQUE,
  plan                   TEXT DEFAULT 'free' CHECK (plan IN ('free','pro')),
  status                 TEXT DEFAULT 'inactive' CHECK (status IN (
                           'inactive','trialing','active','past_due','canceled','unpaid')),
  trial_end              TIMESTAMPTZ,
  current_period_end     TIMESTAMPTZ,
  created_at             TIMESTAMPTZ DEFAULT NOW(),
  updated_at             TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own subscription"
  ON subscriptions FOR SELECT USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- ai_generation_logs  (rate limiting; users READ only)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE ai_generation_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature     TEXT NOT NULL,
  tokens_used INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE ai_generation_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own logs"
  ON ai_generation_logs FOR SELECT USING (auth.uid() = user_id);
CREATE INDEX ai_generation_logs_user_created_idx ON ai_generation_logs(user_id, created_at);

-- ─────────────────────────────────────────────────────────────────────────────
-- payment_events  (raw Stripe webhook audit; no user-facing RLS policy)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE payment_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_event_id TEXT UNIQUE NOT NULL,
  event_type      TEXT NOT NULL,
  data            JSONB,
  processed       BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
-- RLS on, but no policy: only the service role (Edge Functions) can access.
ALTER TABLE payment_events ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- Storage: documents bucket + per-user folder policies (Part L3)
-- File path structure: {user_id}/{doc_type}/{filename}
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', FALSE)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "User uploads own files"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "User reads own files"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "User updates own files"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "User deletes own files"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ─────────────────────────────────────────────────────────────────────────────
-- Account deletion (GDPR, Part L4). ON DELETE CASCADE removes all related rows.
-- Storage files must be deleted from the client first.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE FUNCTION public.delete_user()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;
