import 'package:path/path.dart' as p;

String? normalizeProjectLocalBattleBackgroundPath({
  required String projectRootPath,
  required String pickedAbsolutePath,
}) {
  final normalizedProjectRoot = p.normalize(projectRootPath);
  final normalizedAbsolutePath = p.normalize(pickedAbsolutePath);
  final relativePath = p.posix.normalize(
    p.relative(normalizedAbsolutePath, from: normalizedProjectRoot),
  );

  if (relativePath == '.' ||
      relativePath.startsWith('..') ||
      p.isAbsolute(relativePath)) {
    return null;
  }

  return relativePath;
}

String? normalizeOptionalBattleBackgroundRelativePath(String? rawValue) {
  final trimmed = rawValue?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  return p.posix.normalize(trimmed.replaceAll(r'\', '/'));
}
