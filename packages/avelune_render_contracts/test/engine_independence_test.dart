import 'dart:io';

import 'package:test/test.dart';

const _forbiddenImports = [
  'package:flutter/',
  'package:flutter_gpu/',
  'package:flame/',
  'package:flame_3d/',
  'package:flutter_scene/',
  'package:map_render_3d/',
  'dart:ui',
];

const _forbiddenDependencies = [
  'flutter',
  'flutter_gpu',
  'flame',
  'flame_3d',
  'flutter_scene',
  'map_render_3d',
];

void main() {
  test('contract sources import no rendering engine nor Flutter', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    expect(sources, isNotEmpty);
    final violations = <String>[
      for (final file in sources)
        for (final line in file.readAsLinesSync())
          if (line.trimLeft().startsWith('import ') ||
              line.trimLeft().startsWith('export '))
            for (final forbidden in _forbiddenImports)
              if (line.contains("'$forbidden") || line.contains('"$forbidden'))
                '${file.path}: $line',
    ];
    expect(violations, isEmpty);
  });

  test('the package declares no rendering engine nor Flutter dependency', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final declared = <String>{
      for (final line in pubspec)
        if (RegExp(r'^  ([a-z_0-9]+):').firstMatch(line) case final match?)
          match.group(1)!,
    };
    expect(declared.intersection(_forbiddenDependencies.toSet()), isEmpty);
  });
}
