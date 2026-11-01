import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show FramePhase;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:flame/components.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart' as qa;

const _fixtureFiles = [
  'data/pokemon/media/totodile.json',
  'data/pokemon/media/rattata.json',
  'assets/pokemon/johto/bourg-geon/totodile/back.png',
  'assets/pokemon/johto/route-29/rattata/front.png',
  'assets/battle/backgrounds/clairiere-johto-v1.png',
];

final _doubles =
    const bool.fromEnvironment('QA_DOUBLES') ||
    Platform.environment['QA_DOUBLES'] == 'true';

Future<void> main() async {
  final binding = MarionetteBinding.ensureInitialized();
  if (!Platform.isIOS || !kProfileMode) {
    throw StateError('This QA entrypoint requires a physical iOS profile run.');
  }
  final support = await getApplicationSupportDirectory();
  final root = Directory('${support.path}/battle-camera-consolidation');
  final fixture = Directory('${root.path}/fixture');
  for (final relative in _fixtureFiles) {
    final bytes = await rootBundle.load('assets/fixture/$relative');
    final output = File('${fixture.path}/$relative');
    await output.parent.create(recursive: true);
    await output.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
  }
  qa.qaRoot = root.path;
  qa.projectRoot = fixture.path;
  if (_doubles) {
    qa.qaOverlayFactory = _doublesOverlay;
  }
  final metrics = _QaFrameMetrics(
    () => qa.appKey.currentState?.game.isPaused == false,
  );
  binding.addTimingsCallback(metrics.record);
  developer.registerExtension('ext.flutter.battle.qaOrientation', (
    _,
    parameters,
  ) async {
    final requested = parameters['orientation'];
    final orientation = switch (requested) {
      'portraitUp' => DeviceOrientation.portraitUp,
      'landscapeLeft' => DeviceOrientation.landscapeLeft,
      _ => null,
    };
    if (orientation == null) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.invalidParams,
        'orientation must be portraitUp or landscapeLeft.',
      );
    }
    await SystemChrome.setPreferredOrientations([orientation]);
    final wait = Stopwatch()..start();
    bool matches() {
      final size = binding.platformDispatcher.views.first.physicalSize;
      return requested == 'portraitUp'
          ? size.height > size.width
          : size.width > size.height;
    }

    while (!matches() && wait.elapsedMilliseconds < 5000) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final view = binding.platformDispatcher.views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    await qa.appKey.currentState?.applyQaViewport(logicalSize);
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'requested': requested,
        'matched': matches(),
        'waitMs': wait.elapsedMilliseconds,
        'views': [
          for (final current in binding.platformDispatcher.views)
            {
              'viewId': current.viewId,
              'physicalWidth': current.physicalSize.width,
              'physicalHeight': current.physicalSize.height,
              'devicePixelRatio': current.devicePixelRatio,
              'logicalWidth':
                  current.physicalSize.width / current.devicePixelRatio,
              'logicalHeight':
                  current.physicalSize.height / current.devicePixelRatio,
            },
        ],
        'viewport': {'width': logicalSize.width, 'height': logicalSize.height},
      }),
    );
  });
  developer.registerExtension('ext.flutter.battle.qaPerformance', (
    _,
    parameters,
  ) async {
    final state = qa.appKey.currentState;
    final operation = parameters['operation'] ?? 'read';
    if (operation == 'reset') {
      if (state == null || !state.game.loadedCompleter.isCompleted) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          'Battle scene is not ready.',
        );
      }
      final warmup = int.tryParse(parameters['warmupFrames'] ?? '120');
      if (warmup == null || warmup < 0 || warmup > 3600) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.invalidParams,
          'warmupFrames must be 0..3600.',
        );
      }
      metrics.reset(warmup);
      state.game.resumeEngine();
    } else if (operation == 'stop') {
      metrics.stop();
    } else if (operation != 'read') {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.invalidParams,
        'operation must be read, reset or stop.',
      );
    }
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        ...metrics.snapshot(),
        'enginePaused': state?.game.isPaused,
        'profileMode': kProfileMode,
        'platform': Platform.operatingSystem,
        'fixture': _doubles ? 'doubles_readonly' : 'singles',
      }),
    );
  });
  qa.main();
}

BattleOverlayComponent _doublesOverlay(
  Vector2 size,
  void Function(BattleCommandOverlaySnapshot?) onSnapshot,
) {
  PsdkBattleCombatantSetup combatant(String id, String species) =>
      PsdkBattleCombatantSetup(
        id: id,
        speciesId: species,
        displayName: id,
        level: 7,
        maxHp: 50,
        currentHp: 50,
        types: const PsdkBattleTypes(primary: 'normal'),
        stats: const PsdkBattleStats(
          attack: 20,
          defense: 20,
          specialAttack: 20,
          specialDefense: 20,
          speed: 20,
        ),
        moves: [
          PsdkBattleMoveData(
            id: 'tackle',
            dbSymbol: 'tackle',
            name: 'Charge',
            type: 'normal',
            category: PsdkBattleMoveCategory.physical,
            power: 40,
            accuracy: 100,
            pp: 35,
            currentPp: 35,
            priority: 0,
            battleEngineMethod: 's_basic',
            target: PsdkBattleMoveTarget.adjacentFoe,
          ),
        ],
      );
  final adapter = RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.doubles(
      ruleset: PokemonRulesetProfile.standardV1,
      player: [
        combatant('player_0', 'totodile'),
        combatant('player_1', 'totodile'),
      ],
      opponent: [
        combatant('opponent_0', 'rattata'),
        combatant('opponent_1', 'rattata'),
      ],
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
  return BattleOverlayComponent(
    session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
    presentation: adapter.presentation,
    viewportSize: size,
    onPlayerChoice: (_) {},
    onPlayerDecision: (_, _) {},
    onCommandOverlaySnapshotChanged: onSnapshot,
    resolveSpeciesDisplayName: (id) =>
        id == 'totodile' ? 'Kaiminus' : 'Rattata',
    backgroundSpec: BattleBackgroundSpec.explicitImage(
      fallbackKey: BattleBackgroundKey.wildOutdoor,
      absolutePath:
          '${qa.projectRoot}/assets/battle/backgrounds/clairiere-johto-v1.png',
    ),
    spriteResolver: BattlePokemonSpriteResolver(
      manifest: ProjectManifest(name: 'QA doubles', maps: [], tilesets: []),
      projectRootDirectory: qa.projectRoot,
    ),
  );
}

final class _QaFrameMetrics {
  _QaFrameMetrics(this._engineRunning);

  static const _maximumSamples = 18000;
  final bool Function() _engineRunning;
  final _uiMicros = <int>[];
  final _rasterMicros = <int>[];
  final _clock = Stopwatch();
  bool _recording = false;
  int _warmupRemaining = 0;
  int _warmupSkipped = 0;
  int _droppedSamples = 0;
  int _nonLiveTimings = 0;
  int _minimumVsyncMicros = 0;

  void reset(int warmupFrames) {
    _uiMicros.clear();
    _rasterMicros.clear();
    _warmupRemaining = warmupFrames;
    _warmupSkipped = 0;
    _droppedSamples = 0;
    _nonLiveTimings = 0;
    _minimumVsyncMicros =
        SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    _recording = true;
    _clock
      ..reset()
      ..start();
  }

  void stop() {
    _recording = false;
    _clock.stop();
  }

  void record(List<FrameTiming> timings) {
    if (!_recording) return;
    for (final timing in timings) {
      if (timing.timestampInMicroseconds(FramePhase.vsyncStart) <=
          _minimumVsyncMicros)
        continue;
      if (!_engineRunning()) {
        _nonLiveTimings++;
        continue;
      }
      if (_warmupRemaining > 0) {
        _warmupRemaining--;
        _warmupSkipped++;
        continue;
      }
      if (_uiMicros.length >= _maximumSamples) {
        _droppedSamples++;
        continue;
      }
      _uiMicros.add(timing.buildDuration.inMicroseconds);
      _rasterMicros.add(timing.rasterDuration.inMicroseconds);
    }
  }

  Map<String, Object?> snapshot() => {
    'source': 'SchedulerBinding.addTimingsCallback',
    'clock': 'live_engine',
    'recording': _recording,
    'elapsedWallMs': _clock.elapsedMilliseconds,
    'samples': _uiMicros.length,
    'warmupRemaining': _warmupRemaining,
    'warmupSkipped': _warmupSkipped,
    'maximumSamples': _maximumSamples,
    'droppedSamples': _droppedSamples,
    'nonLiveTimings': _nonLiveTimings,
    'uiMs': _percentiles(_uiMicros),
    'rasterMs': _percentiles(_rasterMicros),
  };

  Map<String, double?> _percentiles(List<int> samples) {
    if (samples.isEmpty) return {'p50': null, 'p95': null};
    final sorted = List<int>.of(samples)..sort();
    double percentile(double quantile) =>
        sorted[math.max(0, (sorted.length * quantile).ceil() - 1)] / 1000;
    return {'p50': percentile(.5), 'p95': percentile(.95)};
  }
}
