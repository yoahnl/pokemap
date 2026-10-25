import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui' show FramePhase;

import 'package:flame/game.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'studio_atmosphere_latency.dart' as studio;
import '../test/support/studio_render_performance_probe.dart';

List<Game> mountedGames() {
  final games = <Game>[];
  void visit(Element element) {
    if (element.widget case GameWidget(game: final game?)) games.add(game);
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return games;
}

Map<String, Object?> gameState(Game game) {
  return renderPerformanceGameState(game);
}

double percentile(List<double> values, double fraction) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * fraction).round()];
}

Future<void> main() async {
  await studio.main();
  var measuring = false;
  developer.registerExtension('ext.flutter.avelune.renderPerformance', (
    method,
    params,
  ) async {
    const root = String.fromEnvironment('MARIONETTE_PROJECT_PATH');
    final state = studio.readState().state;
    final runtime = state['runtime'] as Map<String, Object?>?;
    if (state['projectPath'] != root && runtime?['projectPath'] != root) {
      throw StateError('The configured copy must be active.');
    }
    final games = mountedGames();
    if (params['action'] == 'capture') {
      return developer.ServiceExtensionResponse.result(
        jsonEncode(await captureRenderPerformance(games)),
      );
    }
    if (params['coverage'] case final enabled?) {
      setRenderPerformanceCoverage(games, enabled == 'true');
    }
    if (params['action'] == 'inspect') {
      return developer.ServiceExtensionResponse.result(
        jsonEncode({'games': games.map(gameState).toList(), 'state': state}),
      );
    }
    final seconds = int.tryParse(params['seconds'] ?? '8');
    if (measuring || seconds == null || seconds < 4 || seconds > 20) {
      throw StateError('Use one bounded measurement from 4 to 20 seconds.');
    }
    final scenes = games
        .map(gameState)
        .where(
          (game) =>
              game['type'] == 'SpatialSceneGame' && game['paused'] == false,
        )
        .toList();
    if (scenes.length != 1 ||
        scenes.single['ready'] != true ||
        scenes.single['refreshing'] != false) {
      throw StateError('One stable, active 3D scene is required.');
    }
    measuring = true;
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> batch) => timings.addAll(batch);
    final before = games.map(gameState).toList();
    final clock = Stopwatch()..start();
    SchedulerBinding.instance.addTimingsCallback(collect);
    try {
      await Future<void>.delayed(Duration(seconds: seconds));
    } finally {
      SchedulerBinding.instance.removeTimingsCallback(collect);
      measuring = false;
    }
    timings.sort(
      (a, b) => a
          .timestampInMicroseconds(FramePhase.vsyncStart)
          .compareTo(b.timestampInMicroseconds(FramePhase.vsyncStart)),
    );
    final intervals = [
      for (var i = 1; i < timings.length; i++)
        (timings[i].timestampInMicroseconds(FramePhase.vsyncStart) -
                timings[i - 1].timestampInMicroseconds(FramePhase.vsyncStart)) /
            1000,
    ];
    final after = games.map(gameState).toList();
    final durations = intervals.fold<double>(0, (total, item) => total + item);
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'projectPath': root,
        'wallMs': clock.elapsedMicroseconds / 1000,
        'frames': timings.length,
        'retainedMs': durations,
        'fps': durations == 0 ? null : intervals.length * 1000 / durations,
        'intervalP50Ms': percentile(intervals, .5),
        'intervalP95Ms': percentile(intervals, .95),
        'intervalP99Ms': percentile(intervals, .99),
        'intervalMaxMs': percentile(intervals, 1),
        'over33ms': intervals.where((value) => value > 33.5).length,
        'buildP95Ms': percentile([
          for (final timing in timings)
            timing.buildDuration.inMicroseconds / 1000,
        ], .95),
        'rasterP95Ms': percentile([
          for (final timing in timings)
            timing.rasterDuration.inMicroseconds / 1000,
        ], .95),
        'before': before,
        'after': after,
        'endState': studio.readState().state,
      }),
    );
  });
}
