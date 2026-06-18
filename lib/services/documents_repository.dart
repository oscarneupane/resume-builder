import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../models/document_model.dart';
import 'supabase_service.dart';

/// Saves/lists/opens/deletes generated documents.
///
/// Supabase mode: uploads to the `documents` storage bucket and records a row in
/// the `documents` table. Mock mode: writes the PDF under the app documents dir
/// and keeps metadata in memory for the session.
class DocumentsRepository {
  DocumentsRepository._();
  static final instance = DocumentsRepository._();

  static const _bucket = 'documents';
  static const _table = 'documents';
  final List<Document> _mock = [];

  bool get _enabled => SupabaseService.isConfigured;
  String? get _userId => SupabaseService.instance.currentUserId;

  Future<Document> save({
    required DocType docType,
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (!_enabled) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      final doc = Document(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        userId: 'local',
        docType: docType,
        fileName: fileName,
        storagePath: file.path,
        fileSize: bytes.length,
        mimeType: 'application/pdf',
        createdAt: DateTime.now(),
      );
      _mock.insert(0, doc);
      return doc;
    }

    final userId = _userId!;
    final path = '$userId/${docType.value}/$fileName';
    final client = SupabaseService.instance.client;
    await client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'application/pdf'),
        );
    final row = await client.from(_table).insert({
      'user_id': userId,
      'doc_type': docType.value,
      'file_name': fileName,
      'storage_path': path,
      'file_size': bytes.length,
      'mime_type': 'application/pdf',
    }).select().single();
    return Document.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<Document>> list() async {
    if (!_enabled) return List.unmodifiable(_mock);
    final rows = await SupabaseService.instance.client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((m) => Document.fromMap(Map<String, dynamic>.from(m as Map))).toList();
  }

  Future<Uint8List?> bytesOf(Document doc) async {
    if (!_enabled) {
      final file = File(doc.storagePath);
      return file.existsSync() ? file.readAsBytes() : null;
    }
    return SupabaseService.instance.client.storage.from(_bucket).download(doc.storagePath);
  }

  /// Opens the document via the platform share/preview sheet.
  Future<void> open(Document doc) async {
    final bytes = await bytesOf(doc);
    if (bytes == null) return;
    await Printing.sharePdf(bytes: bytes, filename: doc.fileName);
  }

  Future<void> delete(Document doc) async {
    if (!_enabled) {
      final file = File(doc.storagePath);
      if (file.existsSync()) await file.delete();
      _mock.removeWhere((d) => d.id == doc.id);
      return;
    }
    final client = SupabaseService.instance.client;
    await client.storage.from(_bucket).remove([doc.storagePath]);
    await client.from(_table).delete().eq('id', doc.id);
  }
}
