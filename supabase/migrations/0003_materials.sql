-- User-uploaded materials (pics/PDFs/notes) that the AI scans into reusable text.

CREATE TABLE materials (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kind           TEXT NOT NULL CHECK (kind IN ('image','pdf','text')),
  title          TEXT NOT NULL DEFAULT 'Untitled',
  storage_path   TEXT,             -- path in the `materials` bucket (null for pasted text)
  extracted_text TEXT,             -- AI-scanned content, reused as generation context
  created_at     TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their materials"
  ON materials FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX materials_user_id_idx ON materials(user_id);

-- Storage bucket for the original uploaded files, with per-user folder policies.
INSERT INTO storage.buckets (id, name, public)
VALUES ('materials', 'materials', FALSE)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "User uploads own materials"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'materials' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "User reads own materials"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'materials' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "User deletes own materials"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'materials' AND auth.uid()::text = (storage.foldername(name))[1]);
