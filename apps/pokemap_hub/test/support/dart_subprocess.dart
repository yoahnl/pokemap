import 'dart:io';

import 'package:path/path.dart' as p;

/// Returns the Dart VM even when the parent test runs inside `flutter_tester`.
String dartSubprocessExecutable() {
  final resolved = File(Platform.resolvedExecutable);
  final executableName = p.basenameWithoutExtension(resolved.path);
  if (executableName != 'flutter_tester') return resolved.path;

  final cacheDirectory = resolved.parent.parent.parent.parent;
  final candidate = File(
    p.join(
      cacheDirectory.path,
      'dart-sdk',
      'bin',
      Platform.isWindows ? 'dart.exe' : 'dart',
    ),
  );
  if (!candidate.existsSync()) {
    throw StateError('Dart VM not found beside flutter_tester.');
  }
  return candidate.path;
}
