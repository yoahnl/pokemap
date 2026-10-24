import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'marionette_main.dart' show applyStudioCaptureLifecycle;

String comparisonPlanRelativePath(String filename) => switch (filename) {
  'comparison-plan.json' ||
  'comparison-shadows-plan.json' => 'evidence/$filename',
  'comparison-day-night-plan.json' => 'evidence/day-night/$filename',
  'comparison-lamp-shadows-plan.json' => 'evidence/lamp-shadows/$filename',
  _ => throw StateError('Unsupported comparison plan.'),
};

Future<Map<String, dynamic>> loadComparisonPlan(
  String root,
  String filename,
) async {
  final relativePath = comparisonPlanRelativePath(filename);
  final evidenceRoot = await Directory('$root/evidence').resolveSymbolicLinks();
  final file = await File('$root/$relativePath').resolveSymbolicLinks();
  if (evidenceRoot != '$root/evidence' || file != '$root/$relativePath') {
    throw StateError('Comparison evidence must be local.');
  }
  final plan =
      jsonDecode(await File(file).readAsString()) as Map<String, dynamic>;
  if (plan['testProject'] != '$root/jeu' || plan['mapId'] != 'first-map') {
    throw StateError('Comparison plan does not identify this copy.');
  }
  if ((filename == 'comparison-day-night-plan.json') !=
          (plan['dayNightTest'] == true) ||
      (filename == 'comparison-lamp-shadows-plan.json') !=
          (plan['pointLightShadowTest'] == true) ||
      (plan['dayNightTest'] == true && plan['pointLightShadowTest'] == true) ||
      ((plan['dayNightTest'] == true || plan['pointLightShadowTest'] == true) &&
          plan.containsKey('shadowCasterInstanceIds'))) {
    throw StateError('Comparison plan mixes rendering modes.');
  }
  if (plan['pointLightShadowTest'] == true &&
      (((plan['hiddenMaterialsByInstance'] as Map<String, dynamic>?)
                  ?.isNotEmpty ??
              false) ||
          ((plan['hiddenInstanceIds'] as List<dynamic>?)?.isNotEmpty ??
              false))) {
    throw StateError(
      'Point light shadow comparisons require unmasked source assets.',
    );
  }
  return plan;
}

double comparisonMinuteOfDay({
  required bool after,
  required bool probeOnly,
  required int frameIndex,
  required int frameCount,
}) {
  if (!after) return 720;
  if (probeOnly) return 1320;
  if (frameCount < 2 || frameIndex < 0 || frameIndex >= frameCount) {
    throw StateError('Invalid day/night comparison frame.');
  }
  return (720 + frameIndex / (frameCount - 1) * 1440) % 1440;
}

void setComparisonLightingPhase({
  required bool dayNightTest,
  bool pointLightShadowTest = false,
  required bool after,
  required bool probeOnly,
  required int frameIndex,
  required int frameCount,
  required SpatialSceneController camera,
  required ValueNotifier<SpatialLightingProfile> lighting,
  required SpatialLightingProfile beforeProfile,
  required SpatialLightingProfile afterProfile,
}) {
  if (pointLightShadowTest) {
    camera.previewMinuteOfDay = 1320;
    camera.previewPointLightShadowsEnabled = after;
  } else if (dayNightTest) {
    camera.previewPointLightShadowsEnabled = true;
    camera.previewMinuteOfDay = comparisonMinuteOfDay(
      after: after,
      probeOnly: probeOnly,
      frameIndex: frameIndex,
      frameCount: frameCount,
    );
  } else {
    lighting.value = after ? afterProfile : beforeProfile;
  }
}

Widget comparisonLightingSurface({
  required bool dayNightTest,
  bool pointLightShadowTest = false,
  required ValueNotifier<SpatialLightingProfile> lighting,
  required Widget child,
}) => dayNightTest || pointLightShadowTest
    ? child
    : SpatialLightingPreview(controller: lighting, child: child);

MapSpatialScene prepareComparisonScene(
  MapSpatialScene source,
  Set<String> hiddenInstanceIds,
) {
  if (hiddenInstanceIds.isEmpty) return source;
  final sourceIds = source.instances.map((instance) => instance.id).toSet();
  if (!sourceIds.containsAll(hiddenInstanceIds)) {
    throw StateError('The comparison requests unknown model instances.');
  }
  return source.copyWith(
    instances: source.instances.where(
      (instance) => !hiddenInstanceIds.contains(instance.id),
    ),
  );
}

MapData prepareComparisonMap(MapData source, Set<String> hiddenInstanceIds) {
  final scene = source.spatialScene;
  if (scene == null) throw StateError('The comparison requires a spatial map.');
  final prepared = prepareComparisonScene(scene, hiddenInstanceIds);
  return identical(prepared, scene)
      ? source
      : source.copyWith(spatialScene: prepared);
}

Future<void> main() async {
  if (!kDebugMode || !Platform.isMacOS) {
    throw StateError('This comparison requires a native macOS debug build.');
  }
  MarionetteBinding.ensureInitialized();
  const configuredRoot = String.fromEnvironment('LIGHTING_COMPARISON_ROOT');
  const planFilename = String.fromEnvironment(
    'LIGHTING_COMPARISON_PLAN',
    defaultValue: 'comparison-plan.json',
  );
  comparisonPlanRelativePath(planFilename);
  final root = await Directory(configuredRoot).resolveSymbolicLinks();
  final marker = File('$root/.avelune-lighting-comparison-owner');
  if ((await marker.readAsString()).trim() != 'avelune-lighting-comparison@1') {
    throw StateError('Comparison ownership marker missing.');
  }
  final project = await Directory('$root/jeu').resolveSymbolicLinks();
  if (project != '$root/jeu') throw StateError('Project copy must be local.');
  final plan = await loadComparisonPlan(root, planFilename);
  await initializeSpatialRenderer();
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: '$project/project.json',
    mapId: plan['mapId'] as String,
  );
  if ((plan['dayNightTest'] == true || plan['pointLightShadowTest'] == true) &&
      (bundle.map.spatialScene?.dayNightCycle == null ||
          !SpatialSceneLightingCapabilities.requiresPointLights(
            bundle.manifest,
            maps: [bundle.map],
          ))) {
    throw StateError(
      'The day/night comparison requires an authored cycle and a placed light.',
    );
  }
  final session = await SpatialExplorationSession.load(
    bundle,
    characterId: bundle.manifest.settings.defaultPlayerCharacterId,
  );
  final comparison = LightingComparison(root, plan, session);
  registerMarionetteExtension(
    name: 'avelune.lightingComparison',
    description: 'Captures synchronized native GPU lighting comparisons.',
    callback: (parameters) async {
      final action = parameters['action'] ?? 'status';
      if ((action == 'start' || action == 'probe') &&
          !comparison.running &&
          !comparison.completed) {
        if (comparison.failure != null) {
          return const MarionetteExtensionResult.invalidParams(
            'A failed take requires a fresh comparison process.',
          );
        }
        unawaited(comparison.record(probeOnly: action == 'probe'));
      } else if (action != 'status' && action != 'start' && action != 'probe') {
        return const MarionetteExtensionResult.invalidParams(
          'Use start, probe or status.',
        );
      }
      return MarionetteExtensionResult.success(comparison.status);
    },
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ComparisonSurface(comparison: comparison),
    ),
  );
  applyStudioCaptureLifecycle(AppLifecycleState.resumed);
}

final class LightingComparison {
  LightingComparison(this.root, this.plan, this.session)
    : actors = session.frames(0),
      renderMap = prepareComparisonMap(
        session.bundle.map,
        ((plan['hiddenInstanceIds'] as List<dynamic>?) ?? [])
            .cast<String>()
            .toSet(),
      ),
      camera = SpatialSceneController()..setView(SpatialEditorView.game);

  final String root;
  final Map<String, dynamic> plan;
  final SpatialExplorationSession session;
  final SpatialSceneController camera;
  final MapData renderMap;
  MapSpatialScene get scene => renderMap.spatialScene!;
  final captureKey = GlobalKey();
  late final bool dayNightTest = plan['dayNightTest'] == true;
  late final bool pointLightShadowTest = plan['pointLightShadowTest'] == true;
  bool get usesAuthoredLighting => dayNightTest || pointLightShadowTest;
  int get beforeMinuteOfDay => pointLightShadowTest ? 1320 : 720;
  late final bool shadowTest = plan.containsKey('shadowCasterInstanceIds');
  late final before = shadowTest
      ? profile(shadows: false)
      : SpatialLightingProfile.disabled;
  late final after = usesAuthoredLighting
      ? SpatialLightingProfile.disabled
      : profile(shadows: shadowTest);
  late final lighting = ValueNotifier(before);
  Map<String, SpatialActorVisual> actors;
  int tick = 0;
  int captured = 0;
  bool ready = false;
  bool running = false;
  bool completed = false;
  bool probeCompleted = false;
  String? probeOutput;
  String? failure;
  String? output;
  bool? baselineRoundTripIdentical;
  Map<String, int>? lastVerifiedShadowStats;

  int get frameCount => (plan['phases'] as List<dynamic>).fold<int>(
    0,
    (total, phase) => total + (phase['ticks'] as int) ~/ 2,
  );

  void setBeforeAfter({
    required bool after,
    bool probeOnly = false,
    int frameIndex = 0,
  }) {
    setComparisonLightingPhase(
      dayNightTest: dayNightTest,
      pointLightShadowTest: pointLightShadowTest,
      after: after,
      probeOnly: probeOnly,
      frameIndex: frameIndex,
      frameCount: frameCount,
      camera: camera,
      lighting: lighting,
      beforeProfile: before,
      afterProfile: this.after,
    );
  }

  SpatialLightingProfile profile({required bool shadows}) {
    final sun = plan['sunDirection'] as Map<String, dynamic>?;
    final target = plan['shadowLightTarget'] as Map<String, dynamic>?;
    double setting(String name, double fallback) =>
        (plan[name] as num?)?.toDouble() ?? fallback;
    return SpatialLightingProfile.stylized(
      ambientColor: Color(plan['ambientColorArgb'] as int? ?? 0xffd3e1ff),
      ambientStrength: setting('ambientStrength', .82),
      sunStrength: setting('sunStrength', .4),
      surfaceStrength: setting('surfaceStrength', 1),
      groundStrength: setting('groundStrength', .7),
      actorStrength: setting('actorStrength', .25),
      sunDirection: (
        x: (sun?['x'] as num?)?.toDouble() ?? -.65,
        y: (sun?['y'] as num?)?.toDouble() ?? .8,
        z: (sun?['z'] as num?)?.toDouble() ?? .45,
      ),
      unlitMaterialNames: {'h_kage'},
      hiddenMaterialsByInstance: {
        for (final entry
            in ((plan['hiddenMaterialsByInstance'] as Map<String, dynamic>?) ??
                    {})
                .entries)
          entry.key: (entry.value as List<dynamic>).cast<String>().toSet(),
      },
      shadow: shadows
          ? SpatialShadowProfile(
              casterInstanceIds:
                  (plan['shadowCasterInstanceIds'] as List<dynamic>)
                      .cast<String>()
                      .toSet(),
              center: (
                x: (target!['x'] as num).toDouble(),
                y: (target['y'] as num).toDouble(),
                z: (target['z'] as num).toDouble(),
              ),
              extent: setting('shadowExtent', 16),
              depth: setting('shadowDepth', 32),
              resolution: plan['shadowMapResolution'] as int? ?? 1024,
              bias: setting('shadowBias', .0015),
              opacity: setting('shadowOpacity', .8),
              receiverMinY: setting('shadowReceiverMinY', .9),
              receiverMaxY: setting('shadowReceiverMaxY', 1.2),
              filterRadius: setting('shadowFilterRadius', 1),
              actorReceivers: plan['shadowActorReceivers'] as bool? ?? false,
            )
          : null,
    );
  }

  Map<String, Object?> get status => {
    'pid': pid,
    'projectPath': session.bundle.projectRootDirectory,
    'mapId': session.bundle.map.id,
    'ready': ready,
    'running': running,
    'completed': completed,
    'probeCompleted': probeCompleted,
    'probeOutput': probeOutput,
    'experimentId': plan['experimentId'],
    'authoredInstanceCount': plan['authoredInstanceCount'],
    'runtimeInstanceCount': session.bundle.map.spatialScene!.instances.length,
    'renderedRuntimeInstanceCount': scene.instances.length,
    'hiddenInstanceIds': plan['hiddenInstanceIds'] ?? [],
    'hiddenMaterialsByInstance': plan['hiddenMaterialsByInstance'] ?? {},
    'shadowCasterInstanceIds': plan['shadowCasterInstanceIds'] ?? [],
    'shadowStats': shadowStats,
    'dayNightTest': dayNightTest,
    'pointLightShadowTest': pointLightShadowTest,
    'previewPointLightShadowsEnabled': camera.previewPointLightShadowsEnabled,
    'previewMinuteOfDay': camera.previewMinuteOfDay,
    'lastVerifiedShadowStats': lastVerifiedShadowStats,
    'failure': failure,
    'tick': tick,
    'capturedPairs': captured,
    'x': session.movement.x,
    'z': session.movement.z,
    'baselineRoundTripIdentical': baselineRoundTripIdentical,
    'output': output,
    'cameraProfile': session.bundle.map.spatialScene!.camera.toJson(),
    'cameraAnchor': plan['cameraAnchor'],
    'method': plan['captureMethod'],
    'performanceBenchmark': false,
  };

  Map<String, int> get shadowStats {
    final stats = camera.shadowStats;
    return {
      'casterDrawCount': stats.casterDrawCount,
      'receiverDrawCount': stats.receiverDrawCount,
      'targetAllocations': stats.targetAllocations,
      'hiddenDrawCount': stats.hiddenDrawCount,
      'pointCasterDrawCount': stats.pointCasterDrawCount,
      'pointReceiverDrawCount': stats.pointReceiverDrawCount,
      'pointTargetAllocations': stats.pointTargetAllocations,
      'pointShadowLightCount': stats.pointShadowLightCount,
    };
  }

  SpatialModelRuntimeState? modelState(String mapId, String instanceId) {
    final explicit = session.modelRuntimeState(mapId, instanceId);
    if (explicit != null) return explicit;
    final instance = session.bundle.map.spatialScene!.instances
        .where((value) => value.id == instanceId)
        .firstOrNull;
    if (instance == null) return null;
    final model = session.bundle.manifest.models3d.firstWhere(
      (value) => value.id == instance.modelId,
    );
    final animation = model.inspection.animations
        .where((value) => value.index == instance.animationIndex)
        .firstOrNull;
    final cycles = animation == null
        ? 0.0
        : tick / 60 * instance.animationSpeed / animation.durationSeconds;
    return SpatialModelRuntimeState(
      modelId: instance.modelId,
      animationIndex: animation?.index,
      normalizedTime: animation == null
          ? 0
          : instance.animationLoop
          ? cycles % 1
          : cycles.clamp(0, 1),
      blocksMovement: instance.blocksMovement,
    );
  }

  void verifySession() {
    if (session.bundle.projectRootDirectory != '$root/jeu' ||
        session.bundle.map.id != plan['mapId'] ||
        session.transitioning.value ||
        session.nativeDoorTraversalActive ||
        session.interactionError.value != null ||
        session.movement.bumpedCell != null) {
      throw StateError(
        'Comparison left the verified exploration corridor: $status',
      );
    }
  }

  Future<void> settle() async {
    for (var count = 0; count < 3; count++) {
      applyStudioCaptureLifecycle(AppLifecycleState.resumed);
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame.timeout(
        const Duration(seconds: 15),
      );
    }
    if (failure != null) throw StateError(failure!);
  }

  Future<Uint8List> pixels() async {
    await settle();
    if (pointLightShadowTest && camera.previewPointLightShadowsEnabled) {
      final stats = camera.shadowStats;
      if (stats.pointShadowLightCount == 0 ||
          stats.pointCasterDrawCount == 0 ||
          stats.pointReceiverDrawCount == 0 ||
          stats.pointTargetAllocations == 0) {
        throw StateError(
          'The point shadow render pass is not valid: $shadowStats',
        );
      }
      lastVerifiedShadowStats = shadowStats;
    }
    if (shadowTest && identical(lighting.value, after)) {
      final stats = camera.shadowStats;
      if (stats.casterDrawCount == 0 ||
          stats.receiverDrawCount == 0 ||
          stats.hiddenDrawCount != 1 ||
          stats.targetAllocations != 1) {
        throw StateError('The shadow render pass is not valid: $shadowStats');
      }
      lastVerifiedShadowStats = shadowStats;
    }
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    if (boundary.debugNeedsPaint) throw StateError('Capture is not painted.');
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      if (image.width != 960 || image.height != 720) {
        throw StateError('Unexpected capture dimensions.');
      }
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes!.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
    } finally {
      image.dispose();
    }
  }

  Future<void> record({bool probeOnly = false}) async {
    running = true;
    captured = 0;
    final previousLifecycle = WidgetsBinding.instance.lifecycleState;
    final frames = <Map<String, Object?>>[];
    Map<String, int>? roundTripBeforeShadowStats;
    Map<String, int>? roundTripAfterShadowStats;
    try {
      if (!ready) throw StateError('Native scene is not ready.');
      verifySession();
      final take = Directory(
        '$root/evidence/${pointLightShadowTest
            ? 'lamp-shadows/native'
            : dayNightTest
            ? 'day-night/native'
            : shadowTest
            ? 'shadow-test/native'
            : 'native'}/${probeOnly ? 'probe' : 'take'}-${DateTime.now().microsecondsSinceEpoch}',
      );
      await take.create(recursive: true);
      output = take.path;
      await Directory('${take.path}/before').create();
      await Directory('${take.path}/after').create();
      setBeforeAfter(after: false, probeOnly: dayNightTest || probeOnly);
      final baseline = await pixels();
      roundTripBeforeShadowStats = shadowStats;
      setBeforeAfter(after: true, probeOnly: dayNightTest || probeOnly);
      final changed = await pixels();
      roundTripAfterShadowStats = shadowStats;
      setBeforeAfter(after: false, probeOnly: dayNightTest || probeOnly);
      baselineRoundTripIdentical = listEquals(baseline, await pixels());
      if (!baselineRoundTripIdentical!) {
        throw StateError('Lighting toggle changed the frozen baseline.');
      }
      if (listEquals(baseline, changed)) {
        throw StateError(
          'The requested rendering effect produced no pixel change.',
        );
      }
      if (probeOnly) {
        await File('${take.path}/before/00000.png').writeAsBytes(baseline);
        await File('${take.path}/after/00000.png').writeAsBytes(changed);
        captured = 1;
        if (usesAuthoredLighting) {
          frames.add({
            'frame': 0,
            'tick': tick,
            'beforeMinuteOfDay': beforeMinuteOfDay,
            'afterMinuteOfDay': 1320,
            'shadowStats': roundTripAfterShadowStats,
            'beforeShadowStats': roundTripBeforeShadowStats,
            if (pointLightShadowTest) 'beforePointLightShadowsEnabled': false,
            if (pointLightShadowTest) 'afterPointLightShadowsEnabled': true,
            'x': session.movement.x,
            'z': session.movement.z,
          });
        }
        probeCompleted = true;
        probeOutput = take.path;
        return;
      }
      for (final phase in plan['phases'] as List<dynamic>) {
        session.movement.setInput(x: phase['x'] as int, z: phase['z'] as int);
        for (var step = 0; step < (phase['ticks'] as int); step += 2) {
          for (var substep = 0; substep < 2; substep++) {
            actors = session.frames(1 / 60);
            tick++;
            verifySession();
          }
          final filename = captured.toString().padLeft(5, '0');
          setBeforeAfter(after: false, frameIndex: captured);
          await File('${take.path}/before/$filename.png')
              .writeAsBytes(await pixels());
          final beforeShadowStats = shadowStats;
          setBeforeAfter(after: true, frameIndex: captured);
          await File('${take.path}/after/$filename.png')
              .writeAsBytes(await pixels());
          frames.add({
            'frame': captured,
            'tick': tick,
            'phase': phase['name'],
            'x': session.movement.x,
            'z': session.movement.z,
            'facing': session.movement.facing.name,
            'shadowStats': shadowStats,
            if (usesAuthoredLighting) 'beforeShadowStats': beforeShadowStats,
            if (usesAuthoredLighting) 'beforeMinuteOfDay': beforeMinuteOfDay,
            if (usesAuthoredLighting)
              'afterMinuteOfDay': camera.previewMinuteOfDay,
            if (pointLightShadowTest) 'beforePointLightShadowsEnabled': false,
            if (pointLightShadowTest) 'afterPointLightShadowsEnabled': true,
            'actors': {
              for (final entry in actors.entries)
                entry.key: {
                  'x': entry.value.x,
                  'y': entry.value.y,
                  'z': entry.value.z,
                  'frame': [
                    entry.value.frame.left,
                    entry.value.frame.top,
                    entry.value.frame.width,
                    entry.value.frame.height,
                  ],
                },
            },
          });
          captured++;
        }
      }
      session.movement.setInput(x: 0, z: 0);
      final target = plan['expectedFinalPosition'] as Map<String, dynamic>;
      if ((session.movement.x - (target['x'] as num)).abs() >
              (target['tolerance'] as num) ||
          (session.movement.z - (target['z'] as num)).abs() >
              (target['tolerance'] as num)) {
        throw StateError('Exploration did not reach its final checkpoint.');
      }
      completed = true;
    } on Object catch (error, stack) {
      failure = '$error\n$stack';
    } finally {
      session.movement.setInput(x: 0, z: 0);
      running = false;
      try {
        if (output != null) {
          await File('$output/receipt.json').writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'status': status,
              'plan': plan,
              'probeOnly': probeOnly,
              if (usesAuthoredLighting) 'beforeMinuteOfDay': beforeMinuteOfDay,
              if (usesAuthoredLighting && probeOnly) 'afterMinuteOfDay': 1320,
              if (usesAuthoredLighting) 'roundTripAfterMinuteOfDay': 1320,
              if (usesAuthoredLighting)
                'roundTripBeforeShadowStats': roundTripBeforeShadowStats,
              if (usesAuthoredLighting)
                'roundTripAfterShadowStats': roundTripAfterShadowStats,
              if (pointLightShadowTest) 'beforePointLightShadowsEnabled': false,
              if (pointLightShadowTest) 'afterPointLightShadowsEnabled': true,
              'frames': frames,
            }),
          );
        }
      } finally {
        if (previousLifecycle != null) {
          applyStudioCaptureLifecycle(previousLifecycle);
        }
      }
    }
  }
}

class ComparisonSurface extends StatelessWidget {
  const ComparisonSurface({super.key, required this.comparison});
  final LightingComparison comparison;

  @override
  Widget build(BuildContext context) {
    final capture = comparison;
    final bundle = capture.session.bundle;
    final anchor = capture.plan['cameraAnchor'] as Map<String, dynamic>;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: FittedBox(
          child: SizedBox(
            width: 960,
            height: 720,
            child: RepaintBoundary(
              key: capture.captureKey,
              child: comparisonLightingSurface(
                dayNightTest: capture.dayNightTest,
                pointLightShadowTest: capture.pointLightShadowTest,
                lighting: capture.lighting,
                child: SpatialSceneView(
                  scene: capture.scene,
                  models: bundle.manifest.models3d,
                  loadModel: capture.session.modelBytes,
                  controller: capture.camera,
                  onCell: (_, _) {},
                  background: colors.shadow,
                  ground: colors.primaryContainer,
                  edge: colors.outlineVariant,
                  groundMap: capture.renderMap,
                  groundProject: bundle.manifest,
                  loadGroundImage: capture.session.groundImageBytes,
                  resourceBudget: bundle.resourceBudget,
                  resourceIdentity: bundle.projectCatalog?.identity,
                  actorFrames: (_) => capture.actors,
                  modelRuntimeState: capture.modelState,
                  presentationElapsedSeconds: () =>
                      capture.session.presentationSeconds,
                  rasterAnimationElapsedMsForCell: (map, layer, x, z, _) =>
                      capture.session.rasterAnimationElapsedMsForCell(
                        map,
                        layer,
                        x,
                        z,
                        capture.tick * 1000 ~/ 60,
                      ),
                  cameraPose: () => (
                    x: (anchor['x'] as num).toDouble(),
                    y: (anchor['y'] as num).toDouble(),
                    z: (anchor['z'] as num).toDouble(),
                    zoom: (anchor['zoom'] as num).toDouble(),
                  ),
                  cameraMagnification: () =>
                      capture.session.nativeCameraMagnification,
                  onReady: () => capture.ready = true,
                  errorBuilder: (_, error) {
                    capture.failure = error.toString();
                    return Text(error.toString());
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
