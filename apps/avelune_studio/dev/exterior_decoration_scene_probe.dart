import 'dart:async';
import 'dart:ui' show FramePhase;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';

final class ExteriorDecorationSceneProbe {
  final sourceKey = GlobalKey();
  final presentedKey = GlobalKey();
  final presentation = ValueNotifier<Widget?>(null);
  final _paused = <Game, bool>{};
  SpatialSceneView? presentedScene;

  ({SpatialMapEditor? editor, SpatialSceneView? scene}) sourceView() {
    SpatialMapEditor? editor;
    SpatialSceneView? scene;
    void findScene(Element element) {
      if (scene == null && element.widget is SpatialSceneView) {
        scene = element.widget as SpatialSceneView;
      }
      element.visitChildren(findScene);
    }

    void findEditor(Element element) {
      if (editor == null && element.widget is SpatialMapEditor) {
        editor = element.widget as SpatialMapEditor;
        element.visitChildren(findScene);
        return;
      }
      element.visitChildren(findEditor);
    }

    (sourceKey.currentContext as Element?)?.visitChildren(findEditor);
    return (editor: editor, scene: scene);
  }

  SpatialSceneView? get displayedScene => presentedScene ?? sourceView().scene;

  List<Game> _games(GlobalKey key) {
    final games = <Game>[];
    void visit(Element element) {
      if (element is StatefulElement) {
        final state = element.state;
        if (state is GameWidgetState) games.add(state.currentGame);
      }
      element.visitChildren(visit);
    }

    (key.currentContext as Element?)?.visitChildren(visit);
    return games;
  }

  Future<void> show(SpatialSceneView scene, double aspectRatio) async {
    if (!aspectRatio.isFinite || aspectRatio <= 0) {
      throw StateError('Positive finite presentation aspect required');
    }
    for (final game in _games(sourceKey)) {
      _paused.putIfAbsent(game, () => game.isPaused);
      game.pauseEngine();
    }
    for (final game in _games(presentedKey)) {
      game.pauseEngine();
    }
    final previous = presentedScene?.controller;
    presentedScene = scene;
    presentation.value = ColoredBox(
      key: presentedKey,
      color: const Color(0xff000000),
      child: Center(
        child: AspectRatio(aspectRatio: aspectRatio, child: scene),
      ),
    );
    await WidgetsBinding.instance.endOfFrame;
    previous?.dispose();
  }

  Future<void> restoreEditor() async {
    for (final game in _games(presentedKey)) {
      game.pauseEngine();
    }
    final previous = presentedScene?.controller;
    presentedScene = null;
    presentation.value = null;
    await WidgetsBinding.instance.endOfFrame;
    for (final entry in _paused.entries) {
      if (entry.value) {
        entry.key.pauseEngine();
      } else {
        entry.key.resumeEngine();
      }
    }
    _paused.clear();
    previous?.dispose();
  }

  Map<String, Object?> snapshot() {
    final displayed = _games(presentedScene == null ? sourceKey : presentedKey)
        .where(_isSpatial)
        .map((game) => game as dynamic)
        .toList();
    final stats = displayedScene?.controller.decorationStats;
    return {
      'presented': presentedScene != null,
      'compositionReady':
          displayed.isNotEmpty &&
          displayed.every(
            (game) =>
                game.sceneReady &&
                !game.refreshing &&
                !game.closed &&
                game.decorationStats.ready,
          ),
      'displayedGames': displayed
          .map((game) => _gameState(game as Game))
          .toList(),
      'originalGames': _games(sourceKey)
          .map(
            (game) => {
              'identity': identityHashCode(game),
              'paused': game.isPaused,
              if (_isSpatial(game)) ..._gameState(game),
            },
          )
          .toList(),
      'decorationDefinitions': displayedScene?.decorations.length,
      'nativeDecoration': stats == null
          ? null
          : {
              'requestRevision': stats.requestRevision,
              'committedRevision': stats.committedRevision,
              'ready': stats.ready,
              'sectorBuilds': stats.sectorBuilds,
              'visibleSectors': stats.visibleSectors,
            },
    };
  }

  Future<Map<String, Object?>> measureFrames() async {
    final beforeState = snapshot();
    if (presentedScene != null &&
        _games(sourceKey).any((game) => !game.isPaused)) {
      throw StateError(
        'Original games must be paused before presentation measurement',
      );
    }
    if (beforeState['compositionReady'] != true) {
      throw StateError(
        'Composition must be ready before frame measurement: $beforeState',
      );
    }
    final games = {
      ..._games(sourceKey),
      ..._games(presentedKey),
    }.where(_isSpatial).map((game) => game as dynamic).toList();
    final before = {for (final game in games) game: game.renderedFrameCount};
    final timings = <FrameTiming>[];
    final done = Completer<void>();
    int? cutoff;
    void receive(List<FrameTiming> batch) {
      for (final frame in batch) {
        if (cutoff != null &&
            frame.timestampInMicroseconds(FramePhase.vsyncStart) >= cutoff! &&
            timings.length < 90) {
          timings.add(frame);
        }
      }
      if (timings.length >= 90 && !done.isCompleted) done.complete();
    }

    final timer = Timer(const Duration(seconds: 5), () {
      if (!done.isCompleted) done.complete();
    });
    SchedulerBinding.instance.addTimingsCallback(receive);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cutoff =
          SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    });
    final watch = Stopwatch()..start();
    try {
      WidgetsBinding.instance.scheduleFrame();
      await done.future;
    } finally {
      timer.cancel();
      SchedulerBinding.instance.removeTimingsCallback(receive);
      watch.stop();
    }
    timings.sort(
      (a, b) => a
          .timestampInMicroseconds(FramePhase.vsyncStart)
          .compareTo(b.timestampInMicroseconds(FramePhase.vsyncStart)),
    );
    final interval = timings.length < 2
        ? 0
        : timings.last.timestampInMicroseconds(FramePhase.vsyncStart) -
              timings.first.timestampInMicroseconds(FramePhase.vsyncStart);
    return {
      'evidence': 'Flutter FrameTiming and scene counters; GPU acceptance requires the captured composition.',
      'requestedFrames': 90,
      'samples': timings.length,
      'maximumSeconds': 5,
      'wallMicroseconds': watch.elapsedMicroseconds,
      'complete': timings.length == 90,
      'fpsFromVsyncDelta': interval <= 0
          ? null
          : (timings.length - 1) * 1000000 / interval,
      'buildMilliseconds': _distribution(
        timings.map((frame) => frame.buildDuration.inMicroseconds),
      ),
      'rasterMilliseconds': _distribution(
        timings.map((frame) => frame.rasterDuration.inMicroseconds),
      ),
      'totalMilliseconds': _distribution(
        timings.map((frame) => frame.totalSpan.inMicroseconds),
      ),
      'displayedFramesAdvanced': games.any(
        (game) =>
            !_paused.containsKey(game) &&
            game.renderedFrameCount > before[game]!,
      ),
      'originalFramesStayedIdle': presentedScene == null
          ? null
          : games
                .where(_paused.containsKey)
                .every((game) => game.renderedFrameCount == before[game]),
      'gameCounters': [
        for (final game in games)
          {
            ..._gameState(game),
            'renderDelta': game.renderedFrameCount - before[game]!,
            'source': _paused.containsKey(game) || presentedScene == null,
          },
      ],
      'beforeComposition': beforeState,
      'afterComposition': snapshot(),
    };
  }
}

bool _isSpatial(Game game) {
  try {
    return (game as dynamic).configuration is SpatialSceneView;
  } catch (_) {
    return false;
  }
}

Map<String, Object?> _gameState(Game source) {
  final dynamic game = source;
  return {
    'identity': identityHashCode(game),
    'paused': game.isPaused,
    'sceneReady': game.sceneReady,
    'refreshing': game.refreshing,
    'renderedFrames': game.renderedFrameCount,
    'decorationUpdates': game.decorationUpdates,
    'sectorBuilds': game.decorationStats.sectorBuilds,
    'visibleSectors': game.decorationStats.visibleSectors,
    'depthOfField': game.depthOfFieldFrame,
  };
}

Map<String, double>? _distribution(Iterable<int> values) {
  final sorted = values.toList()..sort();
  if (sorted.isEmpty) return null;
  return {
    'mean': sorted.reduce((a, b) => a + b) / sorted.length / 1000,
    'p50': sorted[((sorted.length - 1) * .5).round()] / 1000,
    'p95': sorted[((sorted.length - 1) * .95).round()] / 1000,
    'maximum': sorted.last / 1000,
  };
}
