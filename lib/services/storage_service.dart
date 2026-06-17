import 'dart:typed_data';

import 'supabase_service.dart';

/// Uploads/downloads from Supabase Storage `documents` bucket.
/// Stub when Supabase not configured.
class StorageService {
  StorageService._();
  static final instance = StorageService._();

  static const _bucket = 'documents';

  Future<String?> uploadResumePdf({
    required String userId,
    required String filename,
    required Uint8List bytes,
  }) async {
    if (!SupabaseService.isConfigured) return null;
    final path = '$userId/resumes/$filename';
    await SupabaseService.instance.client.storage.from(_bucket).uploadBinary(path, bytes);
    return path;
  }

  Future<Uint8List?> download(String path) async {
    if (!SupabaseService.isConfigured) return null;
    return SupabaseService.instance.client.storage.from(_bucket).download(path);
  }

  String? signedUrlSync(String path) {
    if (!SupabaseService.isConfigured) return null;
    return SupabaseService.instance.client.storage.from(_bucket).getPublicUrl(path);
  }
}
