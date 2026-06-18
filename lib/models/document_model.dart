enum DocType { resume, coverLetter, upload, export;
  String get value => switch (this) {
        DocType.coverLetter => 'cover_letter',
        _ => name,
      };
  static DocType parse(String v) => switch (v) {
        'resume' => DocType.resume,
        'cover_letter' => DocType.coverLetter,
        'upload' => DocType.upload,
        _ => DocType.export,
      };
  String get label => switch (this) {
        DocType.resume => 'Resume',
        DocType.coverLetter => 'Cover letter',
        DocType.upload => 'Upload',
        DocType.export => 'Export',
      };
}

/// Maps to the `documents` table (metadata for a file in Supabase Storage or,
/// in mock mode, a local file). [localBytes] is only set in mock mode.
class Document {
  final String id;
  final String userId;
  final DocType docType;
  final String fileName;
  final String storagePath;
  final int? fileSize;
  final String? mimeType;
  final DateTime createdAt;

  const Document({
    required this.id,
    required this.userId,
    required this.docType,
    required this.fileName,
    required this.storagePath,
    this.fileSize,
    this.mimeType,
    required this.createdAt,
  });

  factory Document.fromMap(Map<String, dynamic> m) => Document(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        docType: DocType.parse(m['doc_type'] as String),
        fileName: m['file_name'] as String,
        storagePath: m['storage_path'] as String,
        fileSize: m['file_size'] as int?,
        mimeType: m['mime_type'] as String?,
        createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now(),
      );

  /// Human-readable size, e.g. "12.3 KB".
  String get prettySize {
    final b = fileSize ?? 0;
    if (b <= 0) return '—';
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
