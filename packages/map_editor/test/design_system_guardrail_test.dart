import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('design-system guardrails', () {
    test('editor UI does not use hardcoded colors outside design tokens', () {
      final offenders = _hardcodedColorOffenders();

      expect(
        offenders,
        isEmpty,
        reason: [
          'Feature UI must use design-system/theme colors only.',
          'Move new colors to PokeMapColorTokens or a semantic design-system helper.',
          ...offenders.map((offender) => offender.describe()),
        ].join('\n'),
      );
    });
  });
}

List<_Offender> _hardcodedColorOffenders() {
  final packageRoot = Directory.current;
  final sourceRoots = <Directory>[
    Directory(p.join(packageRoot.path, 'lib', 'src', 'ui')),
    Directory(p.join(packageRoot.path, 'lib', 'src', 'features')),
  ];
  final offenders = <_Offender>[];

  for (final root in sourceRoots.where((root) => root.existsSync())) {
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final relativePath = p.relative(entity.path, from: packageRoot.path);
      if (_isDesignTokenSource(relativePath)) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index += 1) {
        if (_hardcodedColorPattern.hasMatch(lines[index])) {
          offenders.add(
            _Offender(
              path: relativePath,
              line: index + 1,
              snippet: lines[index].trim(),
            ),
          );
        }
      }
    }
  }

  return offenders;
}

bool _isDesignTokenSource(String relativePath) {
  return relativePath.startsWith('lib/src/theme/') ||
      relativePath.startsWith('lib/src/ui/design_system/');
}

final _hardcodedColorPattern = RegExp(
  r'\bColor\(0x[0-9A-Fa-f]+\)|\bColors\.',
);

class _Offender {
  const _Offender({
    required this.path,
    required this.line,
    required this.snippet,
  });

  final String path;
  final int line;
  final String snippet;

  String describe() => '$path:$line: $snippet';
}
