enum MaterialKind { image, pdf, text;
  String get value => name;
  static MaterialKind parse(String v) =>
      MaterialKind.values.firstWhere((e) => e.value == v, orElse: () => MaterialKind.text);
  String get label => switch (this) {
        MaterialKind.image => 'Photo',
        MaterialKind.pdf => 'PDF',
        MaterialKind.text => 'Text',
      };
}

/// A user-uploaded resource that the AI has scanned. [extractedText] is the
/// scanned content reused as context across the app. [storagePath] points to the
/// original file (Supabase storage path or local file path; empty for pasted text).
class Material {
  final String id;
  final String userId;
  final MaterialKind kind;
  final String title;
  final String storagePath;
  final String extractedText;
  final DateTime createdAt;

  const Material({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    this.storagePath = '',
    required this.extractedText,
    required this.createdAt,
  });

  factory Material.fromMap(Map<String, dynamic> m) => Material(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        kind: MaterialKind.parse(m['kind'] as String),
        title: (m['title'] as String?) ?? 'Untitled',
        storagePath: (m['storage_path'] as String?) ?? '',
        extractedText: (m['extracted_text'] as String?) ?? '',
        createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now(),
      );

  /// A short preview of the scanned content for list rows.
  String get preview {
    final t = extractedText.replaceAll('\n', ' ').trim();
    return t.length <= 120 ? t : '${t.substring(0, 120)}…';
  }
}
