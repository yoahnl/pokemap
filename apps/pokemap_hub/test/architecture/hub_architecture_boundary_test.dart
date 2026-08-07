import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('Hub production code never imports editor or developer host', () async {
    final violations = <String>[];
    await for (final entity
        in Directory('lib').list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = await entity.readAsString();
      for (final forbidden in <String>[
        'package:map_editor/',
        'examples/playable_runtime_host',
        'package:playable_runtime_host/',
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${p.relative(entity.path)} imports $forbidden');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('distribution handoff stays pure and editor never depends on Hub',
      () async {
    final repositoryRoot = Directory.current.parent.parent;
    final distributionPubspec = await File(
      p.join(
        repositoryRoot.path,
        'packages',
        'map_distribution',
        'pubspec.yaml',
      ),
    ).readAsString();
    final editorPubspec = await File(
      p.join(repositoryRoot.path, 'packages', 'map_editor', 'pubspec.yaml'),
    ).readAsString();
    final violations = <String>[
      for (final forbidden in <String>[
        'flutter:',
        'map_editor:',
        'pokemap_hub:',
        'playable_runtime_host:',
      ])
        if (distributionPubspec.contains(forbidden))
          'map_distribution depends on $forbidden',
      for (final forbidden in <String>[
        'pokemap_hub:',
        'playable_runtime_host:',
      ])
        if (editorPubspec.contains(forbidden))
          'map_editor depends on $forbidden',
      if (!editorPubspec.contains('map_distribution:'))
        'map_editor does not use the pure distribution contract',
    ];
    final editorLib = Directory(
      p.join(repositoryRoot.path, 'packages', 'map_editor', 'lib'),
    );
    await for (final entity
        in editorLib.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = await entity.readAsString();
      for (final forbidden in <String>[
        'package:pokemap_hub/',
        'package:playable_runtime_host/',
        'examples/playable_runtime_host',
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${p.relative(entity.path)} imports $forbidden');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('player UI is reusable and runtime never depends on it', () async {
    final repositoryRoot = Directory.current.parent.parent;
    final playerUi = Directory(
      p.join(repositoryRoot.path, 'packages', 'map_player_ui', 'lib'),
    );
    final violations = <String>[];
    await for (final entity
        in playerUi.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = await entity.readAsString();
      for (final forbidden in <String>[
        'package:map_editor/',
        'package:pokemap_hub/',
        'examples/playable_runtime_host',
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${p.relative(entity.path)} imports $forbidden');
        }
      }
    }
    final runtimePubspec = await File(
      p.join(repositoryRoot.path, 'packages', 'map_runtime', 'pubspec.yaml'),
    ).readAsString();
    if (runtimePubspec.contains('map_player_ui:')) {
      violations.add('map_runtime depends on map_player_ui');
    }

    expect(violations, isEmpty);
  });

  test('pure recovery barrel does not export Flutter player UI', () async {
    final source = await File('lib/pokemap_hub.dart').readAsString();

    expect(source, isNot(contains('presentation/')));
    expect(source, isNot(contains('pokemap_hub_player.dart')));
    expect(source, isNot(contains('map_player_ui')));
  });

  test('pure recovery barrel compiles without Flutter', () async {
    // The text assertions above only inspect this file's own directives. They
    // cannot see a Flutter package pulled in transitively by something the
    // barrel exports — which is exactly how map_player_ui slipped in through
    // hub_preferences_read.dart. Compiling as plain Dart is the real guard:
    // recovery workers run in a Dart subprocess with no Flutter engine.
    final probe = File('test/.pure_barrel_probe.dart');
    final output = File('test/.pure_barrel_probe.dill');
    await probe.writeAsString(
      "import 'package:pokemap_hub/pokemap_hub.dart';\n"
      'void main() => print(GameLibrary.empty().games.length);\n',
    );
    try {
      final result = await Process.run(
        'dart',
        <String>['compile', 'kernel', probe.path, '-o', output.path],
      );
      expect(
        result.exitCode,
        0,
        reason: 'pokemap_hub.dart must compile as plain Dart.\n'
            '${result.stdout}\n${result.stderr}',
      );
    } finally {
      if (probe.existsSync()) await probe.delete();
      if (output.existsSync()) await output.delete();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
