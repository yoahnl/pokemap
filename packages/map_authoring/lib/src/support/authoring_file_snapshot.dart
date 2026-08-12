import 'dart:io';

final class AuthoringFileSnapshot {
  const AuthoringFileSnapshot({
    required this.size,
    required this.modified,
    required this.changed,
  });

  static Future<AuthoringFileSnapshot?> capture(File file) async {
    final stat = await file.stat();
    if (stat.type == FileSystemEntityType.notFound) return null;
    return AuthoringFileSnapshot(
      size: stat.size,
      modified: stat.modified,
      changed: stat.changed,
    );
  }

  final int size;
  final DateTime modified;
  final DateTime changed;

  @override
  bool operator ==(Object other) =>
      other is AuthoringFileSnapshot &&
      other.size == size &&
      other.modified == modified &&
      other.changed == changed;

  @override
  int get hashCode => Object.hash(size, modified, changed);
}
