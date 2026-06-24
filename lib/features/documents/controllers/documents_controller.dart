import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/document_model.dart';
import '../../../services/documents_repository.dart';

class DocumentsController extends ChangeNotifier {
  DocumentsController(this._repo) {
    load();
  }

  final DocumentsRepository _repo;

  bool loading = true;
  String? error;
  List<Document> documents = [];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      documents = await _repo.list();
    } catch (e) {
      error = 'Could not load documents: $e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> open(Document doc) async {
    try {
      await _repo.open(doc);
    } catch (e) {
      error = 'Could not open: $e';
      notifyListeners();
    }
  }

  Future<void> remove(Document doc) async {
    documents = documents.where((d) => d.id != doc.id).toList();
    notifyListeners();
    try {
      await _repo.delete(doc);
    } catch (e) {
      error = 'Could not delete: $e';
      await load();
    }
  }
}

final documentsControllerProvider =
    ChangeNotifierProvider.autoDispose<DocumentsController>((ref) => DocumentsController(DocumentsRepository.instance));
