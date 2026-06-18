import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/material_model.dart';
import '../../../services/ai_service.dart';
import '../../../services/materials_repository.dart';

class MaterialsController extends ChangeNotifier {
  MaterialsController(this._repo) {
    load();
  }

  final MaterialsRepository _repo;

  bool loading = true;
  bool busy = false; // scanning/saving an upload
  String? error;
  List<Material> materials = [];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      materials = await _repo.list();
    } catch (e) {
      error = 'Could not load materials: $e';
    }
    loading = false;
    notifyListeners();
  }

  Future<Material?> addImage(Uint8List bytes, String title) =>
      _scanAndSave(kind: MaterialKind.image, title: title, fileBytes: bytes, fileName: '$title.png',
          scan: () => AiService.instance.scanToSummary(imageBytes: bytes));

  Future<Material?> addPdf(Uint8List bytes, String title) =>
      _scanAndSave(kind: MaterialKind.pdf, title: title, fileBytes: bytes, fileName: '$title.pdf',
          scan: () => AiService.instance.scanToSummary(pdfBytes: bytes));

  /// Pasted text is already readable; store it directly as the scanned content.
  Future<Material?> addText(String title, String text) =>
      _scanAndSave(kind: MaterialKind.text, title: title, scan: () async => AiResult.ok(text.trim()));

  Future<Material?> _scanAndSave({
    required MaterialKind kind,
    required String title,
    required Future<AiResult> Function() scan,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final res = await scan();
      if (!res.isOk || res.text == null) {
        error = res.error ?? 'Could not scan the file.';
        return null;
      }
      final mat = await _repo.save(
        kind: kind,
        title: title.trim().isEmpty ? kind.label : title.trim(),
        extractedText: res.text!,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      materials = [mat, ...materials];
      return mat;
    } catch (e) {
      error = 'Could not save: $e';
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> remove(Material mat) async {
    materials = materials.where((m) => m.id != mat.id).toList();
    notifyListeners();
    try {
      await _repo.delete(mat);
    } catch (e) {
      error = 'Could not delete: $e';
      await load();
    }
  }
}

final materialsControllerProvider = ChangeNotifierProvider.autoDispose<MaterialsController>((ref) {
  ref.keepAlive(); // keep materials around while navigating between generators
  return MaterialsController(MaterialsRepository.instance);
});
