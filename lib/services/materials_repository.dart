import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../models/material_model.dart';
import 'supabase_service.dart';

/// Stores scanned materials (metadata + extracted text) and their original
/// files. Supabase mode: `materials` table + `materials` storage bucket. Mock
/// mode: in-memory list + local file copy.
class MaterialsRepository {
  MaterialsRepository._();
  static final instance = MaterialsRepository._();

  static const _bucket = 'materials';
  static const _table = 'materials';
  final List<Material> _mock = [];

  bool get _enabled => SupabaseService.isConfigured;
  String? get _userId => SupabaseService.instance.currentUserId;

  Future<List<Material>> list() async {
    if (!_enabled) return List.unmodifiable(_mock);
    final rows = await SupabaseService.instance.client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((m) => Material.fromMap(Map<String, dynamic>.from(m as Map))).toList();
  }

  Future<Material> save({
    required MaterialKind kind,
    required String title,
    required String extractedText,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    if (!_enabled) {
      String path = '';
      if (fileBytes != null && fileName != null) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/materials_${DateTime.now().microsecondsSinceEpoch}_$fileName');
        await file.writeAsBytes(fileBytes, flush: true);
        path = file.path;
      }
      final mat = Material(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        userId: 'local',
        kind: kind,
        title: title,
        storagePath: path,
        extractedText: extractedText,
        createdAt: DateTime.now(),
      );
      _mock.insert(0, mat);
      return mat;
    }

    final userId = _userId!;
    String storagePath = '';
    if (fileBytes != null && fileName != null) {
      storagePath = '$userId/${kind.value}/${DateTime.now().microsecondsSinceEpoch}_$fileName';
      await SupabaseService.instance.client.storage.from(_bucket).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
    }
    final row = await SupabaseService.instance.client.from(_table).insert({
      'user_id': userId,
      'kind': kind.value,
      'title': title,
      if (storagePath.isNotEmpty) 'storage_path': storagePath,
      'extracted_text': extractedText,
    }).select().single();
    return Material.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> delete(Material mat) async {
    if (!_enabled) {
      if (mat.storagePath.isNotEmpty) {
        final f = File(mat.storagePath);
        if (f.existsSync()) await f.delete();
      }
      _mock.removeWhere((m) => m.id == mat.id);
      return;
    }
    final client = SupabaseService.instance.client;
    if (mat.storagePath.isNotEmpty) {
      await client.storage.from(_bucket).remove([mat.storagePath]);
    }
    await client.from(_table).delete().eq('id', mat.id);
  }
}
