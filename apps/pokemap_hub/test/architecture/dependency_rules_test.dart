import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Documented exceptions. Every entry needs a written reason, and the reason
/// has to survive being read out loud by whoever adds the next one.
const _allowlist = <String, String>{
  // `File` is the real input type of a local package install. Hiding it behind
  // a bytes port would change the behaviour the installer's tests pin down.
  'lib/features/installation/domain/repositories/game_installation_repository_interface.dart':
      'dart:io',
  // A migration snapshot IS a set of files on disk; abstracting it would change
  // what a rollback restores.
  'lib/features/saves/domain/entities/save_migration.dart': 'dart:io',
  // The port exists precisely to hand resolved files to the runtime.
  'lib/features/session/domain/repositories/package_asset_port.dart': 'dart:io',
  // The single presentation bridge from artwork paths to ImageProvider.
  'lib/presentation/shared/artwork/local_artwork_image.dart': 'dart:io',
  // supportRoot and diagnosticLogFile are values passed THROUGH this widget to
  // the session layer, not I/O the UI performs.
  'lib/presentation/features/player/pages/hub_installed_game_player.dart':
      'dart:io',
};

/// UI edges that cross feature boundaries on purpose.
const _uiCouplingAllowlist = <String>{};

Future<List<({String path, String source})>> _dartFiles(String root) async {
  final files = <({String path, String source})>[];
  final directory = Directory(root);
  if (!directory.existsSync()) return files;
  await for (final entity
      in directory.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    files.add((
      path: p.relative(entity.path),
      source: await entity.readAsString(),
    ));
  }
  return files;
}

bool _allowed(String path, String needle) => _allowlist[path] == needle;

void main() {
  test('rule 1 — domain layers stay pure', () async {
    final violations = <String>[];
    for (final file in await _dartFiles('lib/features')) {
      if (!file.path.contains('/domain/')) continue;
      for (final forbidden in <String>[
        "package:flutter/material.dart",
        "package:flutter/widgets.dart",
        "package:flutter/cupertino.dart",
        "package:flutter_riverpod/",
        "package:riverpod",
        "dart:io",
        "pokemap_hub/presentation/",
      ]) {
        if (file.source.contains(forbidden) && !_allowed(file.path, forbidden)) {
          violations.add('${file.path} imports $forbidden');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('rule 2 — presentation never reaches into data', () async {
    final violations = <String>[
      for (final file in await _dartFiles('lib/presentation'))
        if (RegExp(r'features/[a-z_]+/data/').hasMatch(file.source))
          '${file.path} imports a data layer',
    ];
    expect(violations, isEmpty);
  });

  test('rule 3 — application names no implementation', () async {
    final violations = <String>[];
    for (final file in await _dartFiles('lib/features')) {
      if (!file.path.contains('/application/')) continue;
      for (final forbidden in <String>['RepositoryImpl', '/data/']) {
        if (file.source.contains(forbidden)) {
          violations.add('${file.path} references $forbidden');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('rule 4 — data never reaches into presentation', () async {
    final violations = <String>[];
    for (final file in await _dartFiles('lib/features')) {
      if (!file.path.contains('/data/')) continue;
      if (file.source.contains('pokemap_hub/presentation/')) {
        violations.add('${file.path} imports presentation');
      }
    }
    expect(violations, isEmpty);
  });

  test('rule 5 — the design system is feature agnostic', () async {
    final violations = <String>[
      for (final file in await _dartFiles('lib/presentation/design_system'))
        if (file.source.contains('pokemap_hub/features/') ||
            file.source.contains('pokemap_hub/presentation/features/'))
          '${file.path} depends on a feature',
    ];
    expect(violations, isEmpty);
  });

  test('rule 6 — implementations are built only in the di layer', () async {
    final violations = <String>[];
    for (final file in await _dartFiles('lib')) {
      if (file.path.startsWith('lib/app/di/')) continue;
      if (file.path.contains('/data/')) continue;
      if (RegExp(r'\b[A-Za-z]*RepositoryImpl\(').hasMatch(file.source)) {
        violations.add('${file.path} instantiates an implementation');
      }
    }
    expect(violations, isEmpty);
  });

  test('rule 7 — the di barrel only re-exports', () async {
    final source = await File('lib/app/di/providers.dart').readAsString();
    final offending = source
        .split('\n')
        .where(
          (line) => RegExp(r'^\s*(final|const|class|abstract)').hasMatch(line),
        )
        .toList();
    expect(offending, isEmpty);
  });

  test('rule 8 — presentation stays filesystem free', () async {
    final violations = <String>[
      for (final file in await _dartFiles('lib/presentation'))
        if (file.source.contains('dart:io') && !_allowed(file.path, 'dart:io'))
          '${file.path} imports dart:io',
    ];
    expect(violations, isEmpty);
  });

  test('the allowlist has no stale entries', () async {
    final stale = <String>[
      for (final entry in _allowlist.entries)
        if (!File(entry.key).existsSync())
          '${entry.key} no longer exists'
        else if (!File(entry.key).readAsStringSync().contains(entry.value))
          '${entry.key} no longer needs its ${entry.value} exception',
      ..._uiCouplingAllowlist.where((path) => !File(path).existsSync()),
    ];
    expect(
      stale,
      isEmpty,
      reason: 'An exception that is no longer needed must be deleted, not kept '
          'as cover for the next one.',
    );
  });
}
