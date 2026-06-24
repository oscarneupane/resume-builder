import '../models/job_application_model.dart';
import 'supabase_service.dart';

/// CRUD for `job_applications`. Uses Supabase when configured; otherwise keeps an
/// in-memory list for the session so the tracker is usable in mock mode.
class JobRepository {
  JobRepository._();
  static final instance = JobRepository._();

  static const _table = 'job_applications';
  final List<JobApplication> _mock = [];

  bool get _enabled => SupabaseService.isConfigured;
  String? get _userId => SupabaseService.instance.currentUserId;

  Future<List<JobApplication>> list() async {
    if (!_enabled) return List.unmodifiable(_mock);
    final rows = await SupabaseService.instance.client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((m) => JobApplication.fromMap(Map<String, dynamic>.from(m as Map))).toList();
  }

  Future<JobApplication> create({
    required String companyName,
    required String jobTitle,
    required JobStatus status,
    String? notes,
  }) async {
    if (!_enabled) {
      final job = JobApplication(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        userId: 'local',
        companyName: companyName,
        jobTitle: jobTitle,
        applicationDate: DateTime.now(),
        status: status,
        notes: notes,
        createdAt: DateTime.now(),
      );
      _mock.insert(0, job);
      return job;
    }
    final row = await SupabaseService.instance.client
        .from(_table)
        .insert({
          'user_id': _userId,
          'company_name': companyName,
          'job_title': jobTitle,
          'status': status.value,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        })
        .select()
        .single();
    return JobApplication.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> updateStatus(String id, JobStatus status) async {
    if (!_enabled) {
      final i = _mock.indexWhere((j) => j.id == id);
      if (i != -1) _mock[i] = _mock[i].copyWith(status: status);
      return;
    }
    await SupabaseService.instance.client.from(_table).update({'status': status.value}).eq('id', id);
  }

  Future<void> delete(String id) async {
    if (!_enabled) {
      _mock.removeWhere((j) => j.id == id);
      return;
    }
    await SupabaseService.instance.client.from(_table).delete().eq('id', id);
  }
}
