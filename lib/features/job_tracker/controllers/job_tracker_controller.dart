import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/job_application_model.dart';
import '../../../services/job_repository.dart';

class JobTrackerController extends ChangeNotifier {
  JobTrackerController(this._repo) {
    load();
  }

  final JobRepository _repo;

  bool loading = true;
  String? error;
  List<JobApplication> _jobs = [];

  List<JobApplication> get jobs => _jobs;
  int get total => _jobs.length;

  List<JobApplication> byStatus(JobStatus status) =>
      _jobs.where((j) => j.status == status).toList();

  int countFor(JobStatus status) => _jobs.where((j) => j.status == status).length;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _jobs = await _repo.list();
    } catch (e) {
      error = 'Could not load applications: $e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> add({
    required String companyName,
    required String jobTitle,
    required JobStatus status,
    String? notes,
  }) async {
    try {
      final job = await _repo.create(
        companyName: companyName,
        jobTitle: jobTitle,
        status: status,
        notes: notes,
      );
      _jobs = [job, ..._jobs];
      notifyListeners();
    } catch (e) {
      error = 'Could not add: $e';
      notifyListeners();
    }
  }

  Future<void> move(JobApplication job, JobStatus status) async {
    // Optimistic update.
    _jobs = _jobs.map((j) => j.id == job.id ? j.copyWith(status: status) : j).toList();
    notifyListeners();
    try {
      await _repo.updateStatus(job.id, status);
    } catch (e) {
      error = 'Could not update: $e';
      await load();
    }
  }

  Future<void> remove(JobApplication job) async {
    _jobs = _jobs.where((j) => j.id != job.id).toList();
    notifyListeners();
    try {
      await _repo.delete(job.id);
    } catch (e) {
      error = 'Could not delete: $e';
      await load();
    }
  }
}

final jobTrackerControllerProvider =
    ChangeNotifierProvider.autoDispose<JobTrackerController>((ref) => JobTrackerController(JobRepository.instance));
