import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('direct color detector covers numeric and multiline constructors', () {
    for (final source in <String>[
      'Color(0xFF112233)',
      'Color.fromARGB(255, 1, 2, 3)',
      'Color.fromRGBO(1, 2, 3, 1)',
      'Color\n  .from(alpha: 1, red: 1, green: 1, blue: 1)',
      'Colors.red',
      'CupertinoColors.systemBlue',
      'MacosColors.controlAccentColor',
    ]) {
      expect(_directColorPattern.hasMatch(source), isTrue, reason: source);
    }
    expect(
        _directColorPattern.hasMatch('Color.lerp(left, right, 0.5)'), isFalse);
  });

  test('narrative design-system sources use semantic tokens and modern chrome',
      () {
    final root = Directory(
      p.join(Directory.current.path, 'lib', 'src', 'ui', 'design_system',
          'narrative'),
    );
    expect(root.existsSync(), isTrue,
        reason: 'The narrative design-system folder must exist.');

    final regressions = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relativePath =
          p.relative(entity.path, from: Directory.current.path);
      final source = entity.readAsStringSync();
      for (final match in _directColorPattern.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        regressions.add('$relativePath:$line: ${match.group(0)}');
      }
      for (final match in _legacyChromePattern.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        regressions.add('$relativePath:$line: legacy chrome import');
      }
    }

    expect(
      regressions,
      isEmpty,
      reason: <String>[
        'Narrative design-system widgets must use context.pokeMapColors.',
        'They must not import legacy editor chrome.',
        ...regressions,
      ].join('\n'),
    );
  });
}

final _directColorPattern = RegExp(
  r'\bColor\s*(?:\(|\.\s*from[A-Za-z]*\s*\()|'
  r'\b(?:Colors|CupertinoColors|MacosColors)\s*\.',
  multiLine: true,
);

final _legacyChromePattern = RegExp(r'cupertino_editor_widgets\.dart');
