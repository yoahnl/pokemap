import 'dart:convert';
import 'dart:io';

/// Appends import failures to a durable log and formats their technical detail.
///
/// Extracted from the dashboard controller so the notifier keeps orchestration
/// only. Every write is best-effort: diagnostics must never mask the original
/// failure they describe.
final class HubDiagnosticLogWriter {
  const HubDiagnosticLogWriter({this.logFile});

  final File? logFile;

  /// Returns the log path when the entry was persisted, `null` otherwise.
  Future<String?> append({
    required String code,
    required String operation,
    required String packagePath,
    required Object cause,
    required StackTrace stackTrace,
  }) async {
    final file = logFile;
    if (file == null) return null;
    try {
      await file.parent.create(recursive: true);
      final sink = file.openWrite(mode: FileMode.append);
      sink.writeln(
        jsonEncode(<String, Object?>{
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'feature': 'hub-package-import',
          'operation': operation,
          'code': code,
          'packagePath': packagePath,
          'cause': cause.toString(),
          'stackTrace': stackTrace.toString(),
        }),
      );
      await sink.flush();
      await sink.close();
      return file.path;
    } on Object {
      return null;
    }
  }

  static String technicalDetails({
    required String code,
    required String operation,
    required String packagePath,
    required Object cause,
    required StackTrace stackTrace,
  }) {
    final stackLines = stackTrace
        .toString()
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .take(12)
        .join('\n');
    return <String>[
      'Code : $code',
      'Opération : $operation',
      'Package : $packagePath',
      'Cause système : $cause',
      if (stackLines.isNotEmpty) 'Pile :\n$stackLines',
    ].join('\n');
  }
}
