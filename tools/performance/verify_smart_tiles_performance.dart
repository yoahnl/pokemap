import 'dart:convert';
import 'dart:io';

import 'benchmark_support.dart';
import 'smart_tiles_performance_baseline.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final baseline = await _readObject(options.baselinePath);
    final receipts = <Map<String, Object?>>[
      for (final path in options.receiptPaths) await _readObject(path),
    ];
    final expectedSourceIdentity = options.allowHistorical
        ? null
        : await currentPerformanceSourceIdentity();
    final violations = verifySmartTilesPerformanceBaseline(
      baseline: baseline,
      receipts: receipts,
      enforceTimingsForTargetId: options.enforceTimeTargetId,
      expectedSourceIdentity: expectedSourceIdentity,
    );
    if (violations.isNotEmpty) {
      for (final violation in violations) {
        stderr.writeln('smart_tiles_performance: $violation');
      }
      exitCode = 1;
      return;
    }
    stdout.writeln(
      jsonEncode(<String, Object?>{
        'status': 'pass',
        'receiptCount': receipts.length,
        'timingGate': options.enforceTimeTargetId != null,
        'historicalReceipts': options.allowHistorical,
      }),
    );
  } on FormatException catch (error) {
    stderr.writeln('smart_tiles_performance: ${error.message}');
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('smart_tiles_performance: ${error.message}');
    exitCode = 66;
  }
}

Future<Map<String, Object?>> _readObject(String path) async {
  final decoded = jsonDecode(await File(path).readAsString());
  if (decoded is! Map) throw FormatException('$path must contain an object');
  return Map<String, Object?>.from(decoded);
}

final class _Options {
  const _Options({
    required this.baselinePath,
    required this.receiptPaths,
    required this.enforceTimeTargetId,
    required this.allowHistorical,
  });

  final String baselinePath;
  final List<String> receiptPaths;
  final String? enforceTimeTargetId;
  final bool allowHistorical;

  static _Options parse(List<String> arguments) {
    String? baselinePath;
    String? enforceTimeTargetId;
    var allowHistorical = false;
    final receiptPaths = <String>[];
    for (var index = 0; index < arguments.length; index += 1) {
      final option = arguments[index];
      if (option == '--allow-historical') {
        if (allowHistorical) {
          throw const FormatException(
            '--allow-historical can be supplied once',
          );
        }
        allowHistorical = true;
        continue;
      }
      if (index + 1 >= arguments.length) {
        throw FormatException('missing value for $option');
      }
      final value = arguments[++index].trim();
      if (value.isEmpty) throw FormatException('$option cannot be empty');
      switch (option) {
        case '--baseline':
          if (baselinePath != null) {
            throw const FormatException('--baseline can be supplied once');
          }
          baselinePath = value;
        case '--receipt':
          receiptPaths.add(value);
        case '--enforce-time':
          if (enforceTimeTargetId != null) {
            throw const FormatException('--enforce-time can be supplied once');
          }
          enforceTimeTargetId = value;
        default:
          throw FormatException('unknown option $option');
      }
    }
    if (baselinePath == null) {
      throw const FormatException('--baseline is required');
    }
    if (receiptPaths.isEmpty) {
      throw const FormatException('at least one --receipt is required');
    }
    return _Options(
      baselinePath: baselinePath,
      receiptPaths: List<String>.unmodifiable(receiptPaths),
      enforceTimeTargetId: enforceTimeTargetId,
      allowHistorical: allowHistorical,
    );
  }
}
