import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('Player host code never imports editor or developer host', () async {
    final violations = <String>[];
    await for (final entity
        in Directory('lib').list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = await entity.readAsString();
      for (final forbidden in <String>[
        'package:map_editor/',
        'tools/pokemap_render_host',
        'package:pokemap_render_host/',
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
        'package:avelune_player_host/',
        'tools/pokemap_render_host',
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
    final source = await File('lib/avelune_player_host.dart').readAsString();

    expect(source, isNot(contains('presentation/')));
    expect(source, isNot(contains('avelune_player_session.dart')));
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
      "import 'package:avelune_player_host/avelune_player_host.dart';\n"
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
        reason: 'avelune_player_host.dart must compile as plain Dart.\n'
            '${result.stdout}\n${result.stderr}',
      );
    } finally {
      if (probe.existsSync()) await probe.delete();
      if (output.existsSync()) await output.delete();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
