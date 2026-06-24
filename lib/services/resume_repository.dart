import '../models/resume_model.dart';
import 'supabase_service.dart';

/// Persists resumes + their sections to Supabase when configured.
///
/// In mock mode (no `.env` creds) every method is a no-op that returns null,
/// so the builder/preview flow works unchanged without a backend.
class ResumeRepository {
  ResumeRepository._();
  static final instance = ResumeRepository._();

  bool get _enabled => SupabaseService.isConfigured;

  /// Upserts the resume row and replaces its sections. Returns the persisted
  /// resume id, or null when Supabase isn't configured.
  ///
  /// Pass [existingId] to update an already-saved draft; omit it for a new one
  /// (the DB generates the id).
  Future<String?> saveResume(Resume resume, {String? existingId}) async {
    if (!_enabled) return null;
    final client = SupabaseService.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    // Upsert the resume row. Let the DB generate the id for new drafts.
    final resumeRow = <String, dynamic>{
      'user_id': userId,
      'title': resume.title,
      'template': resume.template,
      'is_primary': resume.isPrimary,
      'updated_at': DateTime.now().toIso8601String(),
      if (existingId != null) 'id': existingId,
    };

    final saved = await client.from('resumes').upsert(resumeRow).select('id').single();
    final resumeId = saved['id'] as String;

    // Replace sections (simple, correct sync for the whole draft).
    await client.from('resume_sections').delete().eq('resume_id', resumeId);
    final sectionRows = resume.sections
        .map((s) => {
              'resume_id': resumeId,
              'user_id': userId,
              'section_type': s.type.value,
              'content': s.content,
              'display_order': s.displayOrder,
            })
        .toList();
    if (sectionRows.isNotEmpty) {
      await client.from('resume_sections').insert(sectionRows);
    }

    return resumeId;
  }

  /// Loads a resume with its sections, or null if not configured / not found.
  Future<Resume?> loadResume(String id) async {
    if (!_enabled) return null;
    final client = SupabaseService.instance.client;
    final row = await client.from('resumes').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    final sectionRows = await client
        .from('resume_sections')
        .select()
        .eq('resume_id', id)
        .order('display_order');
    final sections = (sectionRows as List)
        .map((m) => ResumeSection.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
    return Resume.fromMap(Map<String, dynamic>.from(row), sections: sections);
  }
}
