import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = File('.dart_tool/package_config.json').absolute;
  final packages =
      (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;
  final flame = packages.cast<Map>().singleWhere(
    (package) => package['name'] == 'flame',
  );
  final pubspec = config.uri
      .resolve('${flame['rootUri']}/')
      .resolve('pubspec.yaml');
  final version = RegExp(
    r'^version:\s*(.+)$',
    multiLine: true,
  ).firstMatch(File.fromUri(pubspec).readAsStringSync())!.group(1);
  testWidgets('measures loaded component traversal on the current engine', (
    tester,
  ) async {
    final rows = <Map<String, Object?>>[];
    for (final count in [1024, 8192]) {
      for (final depth in [1, 4]) {
        final game = FlameGame();
        final probes = <_TraversalProbe>[];
        Component tree(int level, int remaining) {
          final probe = _TraversalProbe();
          probes.add(probe);
          if (level == 1) {
            probe.addAll([
              for (var index = 1; index < remaining; index++)
                _TraversalProbe()..register(probes),
            ]);
          } else {
            final branchSize = (remaining - 1) ~/ 4;
            var assigned = 1;
            for (var branch = 0; branch < 4; branch++) {
              final size = branch == 3 ? remaining - assigned : branchSize;
              if (size > 0) probe.add(tree(level - 1, size));
              assigned += size;
            }
          }
          return probe;
        }

        game.world.add(tree(depth, count));
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: GameWidget(game: game),
          ),
        );
        await tester.runAsync(game.ready);
        game.pauseEngine();
        expect(probes, hasLength(count));
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        for (var frame = 0; frame < 200; frame++) {
          game.update(1 / 60);
          game.render(canvas);
        }
        const frames = 40;
        final updateSamples = <double>[];
        final renderSamples = <double>[];
        final initialUpdates = probes.first.updates;
        for (var sample = 0; sample < 21; sample++) {
          final stopwatch = Stopwatch()..start();
          for (var frame = 0; frame < frames; frame++) {
            game.update(1 / 60);
          }
          updateSamples.add(stopwatch.elapsedMicroseconds / frames);
          stopwatch.reset();
          for (var frame = 0; frame < frames; frame++) {
            game.render(canvas);
          }
          renderSamples.add(stopwatch.elapsedMicroseconds / frames);
        }
        updateSamples.sort();
        renderSamples.sort();
        expect(
          probes.every((probe) => probe.updates == initialUpdates + 840),
          isTrue,
        );
        recorder.endRecording().dispose();
        rows.add({
          'components': count,
          'depth': depth,
          'samples': 21,
          'framesPerSample': frames,
          'updateMedianUs': updateSamples[10],
          'renderMedianUs': renderSamples[10],
        });
        await tester.pumpWidget(const SizedBox());
        game.dispose();
      }
    }
    print(
      'FLAME_COMPONENT_BENCHMARK ${jsonEncode({'flameVersion': version, 'dartVersion': Platform.version, 'platform': Platform.operatingSystem, 'mode': 'Flutter test JIT, component traversal without GPU', 'cases': rows})}',
    );
  });
}

class _TraversalProbe extends Component {
  int updates = 0;
  double value = 0;

  void register(List<_TraversalProbe> probes) => probes.add(this);

  @override
  void update(double dt) {
    updates++;
    value = (value + dt) % 1000;
  }
}
