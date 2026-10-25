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

import 'package:avelune_studio/presentation/features/map_workspace/map_atmosphere_preview_controls.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';

import 'atmosphere_comparison_support.dart';
import 'presentation_comparison_controls.dart';
import 'save_disk_trace.dart';
import 'marionette_main.dart' show applyStudioCaptureLifecycle;
import '../test/support/studio_depth_of_field_probe.dart';

String comparisonPlanRelativePath(String filename) => switch (filename) {
  'comparison-plan.json' ||
  'comparison-shadows-plan.json' => 'evidence/$filename',
  'comparison-contact-shadows-plan.json' =>
    'evidence/actor-contact-shadows/$filename',
  'comparison-day-night-plan.json' => 'evidence/day-night/$filename',
  'comparison-atmosphere-plan.json' => 'evidence/atmosphere/$filename',
  'comparison-presentation-plan.json' => 'evidence/presentation/$filename',
  'comparison-depth-of-field-plan.json' => 'evidence/depth-of-field/$filename',
  'comparison-lamp-shadows-plan.json' => 'evidence/lamp-shadows/$filename',
  _ => throw StateError('Unsupported comparison plan.'),
};

void verifyComparisonContactActors({
  required Set<String> authoredContactActorIds,
  required Set<String> expectedActorIds,
  required bool after,
  required int renderedCount,
}) {
  if (!authoredContactActorIds.containsAll(expectedActorIds) ||
      renderedCount != (after ? authoredContactActorIds.length : 0)) {
    throw StateError('The contact shadow comparison actors are not ready.');
  }
}

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
  final mode = switch (filename) {
    'comparison-day-night-plan.json' => 'dayNightTest',
    'comparison-atmosphere-plan.json' => 'atmosphereTest',
    'comparison-presentation-plan.json' => 'presentationTest',
    'comparison-depth-of-field-plan.json' => 'depthOfFieldTest',
    'comparison-lamp-shadows-plan.json' => 'pointLightShadowTest',
    'comparison-contact-shadows-plan.json' => 'actorContactShadowTest',
    _ => null,
  };
  final modes = [
    'depthOfFieldTest',
    'presentationTest',
    'atmosphereTest',
    'dayNightTest',
    'pointLightShadowTest',
    'actorContactShadowTest',
  ];
  if ((mode != null && plan[mode] != true) ||
      modes.any((key) => key != mode && plan[key] == true) ||
      (mode != null && plan.containsKey('shadowCasterInstanceIds'))) {
    throw StateError('Comparison plan mixes rendering modes.');
  }
  if ((plan['depthOfFieldTest'] == true ||
          plan['presentationTest'] == true ||
          plan['atmosphereTest'] == true ||
          plan['pointLightShadowTest'] == true ||
          plan['dayNightTest'] == true ||
          plan['actorContactShadowTest'] == true) &&
      (((plan['hiddenMaterialsByInstance'] as Map<String, dynamic>?)
                  ?.isNotEmpty ??
              false) ||
          ((plan['hiddenInstanceIds'] as List<dynamic>?)?.isNotEmpty ??
              false))) {
    throw StateError(
      'Authored lighting comparisons require unmasked source assets.',
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
  bool depthOfFieldTest = false,
  bool atmosphereTest = false,
  bool pointLightShadowTest = false,
  bool actorContactShadowTest = false,
  required bool after,
  required bool probeOnly,
  required int frameIndex,
  required int frameCount,
  required SpatialSceneController camera,
  required ValueNotifier<SpatialLightingProfile> lighting,
  required SpatialLightingProfile beforeProfile,
  required SpatialLightingProfile afterProfile,
}) {
  if (depthOfFieldTest) {
    camera.depthOfFieldEnabled = after;
  } else if (atmosphereTest) {
    camera.previewMinuteOfDay = probeOnly
        ? 1320
        : 720 + frameIndex / (frameCount - 1) * 600;
    camera.waterAnimated = after;
    camera.windowsLit = after;
    camera.fireflies = after;
  } else if (actorContactShadowTest) {
    camera.previewMinuteOfDay = probeOnly || frameIndex >= frameCount ~/ 2
        ? 1320
        : 720;
    camera.previewPointLightShadowsEnabled = true;
  } else if (pointLightShadowTest) {
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
  bool depthOfFieldTest = false,
  bool presentationTest = false,
  bool atmosphereTest = false,
  bool pointLightShadowTest = false,
  bool actorContactShadowTest = false,
  required ValueNotifier<SpatialLightingProfile> lighting,
  required Widget child,
}) =>
    depthOfFieldTest ||
        presentationTest ||
        atmosphereTest ||
        dayNightTest ||
        pointLightShadowTest ||
        actorContactShadowTest
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
  if (kReleaseMode || !Platform.isMacOS) {
    throw StateError(
      'This comparison requires a native macOS development build.',
    );
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
  if ((plan['atmosphereTest'] == true ||
          plan['dayNightTest'] == true ||
          plan['pointLightShadowTest'] == true ||
          plan['actorContactShadowTest'] == true) &&
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
  if (comparison.depthOfFieldTest) {
    comparison.camera.applyAtmosphereSettings(bundle.spatialAtmosphereSettings);
    comparison.camera.previewMinuteOfDay = (plan['previewMinuteOfDay'] as num)
        .toDouble();
    comparison.camera.depthOfFieldProfile = SpatialDepthOfFieldProfile(
      strength: (plan['depthOfFieldStrength'] as num).toDouble(),
      focusRange: (plan['depthOfFieldFocusRange'] as num).toDouble(),
    );
  }
  if (comparison.presentationTest) {
    comparison.camera.applyAtmosphereSettings(bundle.spatialAtmosphereSettings);
    final raw = plan['presentationProfile'] as Map<String, dynamic>;
    comparison.camera.presentationProfile = SpatialPresentationProfile(
      fogStart: (raw['fogStart'] as num).toDouble(),
      fogEnd: (raw['fogEnd'] as num).toDouble(),
      fogOpacity: (raw['fogOpacity'] as num).toDouble(),
      halos: [
        for (final source in raw['halos'] as List<dynamic>)
          SpatialHaloSource(
            position: Model3dVector3.fromJson(
              Map<String, dynamic>.from(source['position'] as Map),
            ),
            radiusX: (source['radiusX'] as num).toDouble(),
            radiusY: (source['radiusY'] as num).toDouble(),
            opacity: (source['opacity'] as num).toDouble(),
            window: source['window'] == true,
          ),
      ],
    );
    comparison.camera.previewMinuteOfDay = (plan['previewMinuteOfDay'] as num)
        .toDouble();
  }
  final trace = SaveDiskTrace(project);
  final toggleProbe = AtmosphereToggleProbe(
    comparison.camera,
    trace,
    counters: () => comparison.loadCounters,
  );
  if (comparison.atmosphereTest || comparison.presentationTest) {
    if (comparison.atmosphereTest) {
      comparison.camera.atmosphereProfile = comparisonAtmosphereProfile(
        plan['atmosphereProfile'] as Map<String, dynamic>,
      );
      comparison.camera.previewMinuteOfDay = 1320;
    }
    registerMarionetteExtension(
      name: 'avelune.atmospherePreview',
      description: 'Inspects the test copy and times real atmosphere controls.',
      callback: (parameters) async {
        if (parameters['action'] == 'arm') toggleProbe.arm();
        return MarionetteExtensionResult.success({
          'projectPath': project,
          'state': toggleProbe.state,
          'measurement': toggleProbe.result,
          'loads': comparison.loadCounters,
          'halos': comparison.camera.halosEnabled,
          'fog': comparison.camera.depthFogEnabled,
          'haloCount': comparison.camera.haloCount,
          'haloAllocations': comparison.camera.haloAllocations,
        });
      },
    );
  }
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
  await trace.run(() async {
    runApp(
      MaterialApp(
        theme: studioTheme(),
        debugShowCheckedModeBanner: false,
        home: ComparisonSurface(comparison: comparison),
      ),
    );
    applyStudioCaptureLifecycle(AppLifecycleState.resumed);
  });
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
  final idleClock = Stopwatch()..start();
  int modelLoads = 0, groundImageLoads = 0, readyCalls = 0;
  ({int generation, Map<String, Object?> state})? get renderFrame =>
      readDepthOfFieldFrame(captureKey);

  Map<String, int> get loadCounters => {
    'modelLoads': modelLoads,
    'groundImageLoads': groundImageLoads,
    'readyCalls': readyCalls,
  };
  double get presentationSeconds => running || !atmosphereTest
      ? session.presentationSeconds
      : idleClock.elapsedMicroseconds / 1000000;
  late final bool atmosphereTest = plan['atmosphereTest'] == true;
  late final bool depthOfFieldTest = plan['depthOfFieldTest'] == true;
  late final bool presentationTest = plan['presentationTest'] == true;
  late final bool dayNightTest = plan['dayNightTest'] == true;
  late final bool pointLightShadowTest = plan['pointLightShadowTest'] == true;
  late final bool actorContactShadowTest =
      plan['actorContactShadowTest'] == true;
  bool contactShadowsAfter = false;
  bool get usesAuthoredLighting =>
      depthOfFieldTest ||
      presentationTest ||
      atmosphereTest ||
      dayNightTest ||
      pointLightShadowTest ||
      actorContactShadowTest;
  int get beforeMinuteOfDay =>
      atmosphereTest || pointLightShadowTest || actorContactShadowTest
      ? 1320
      : 720;
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

  int get tickStride => (plan['captureTickStride'] as int?) ?? 2;

  int get frameCount => (plan['phases'] as List<dynamic>).fold<int>(
    0,
    (total, phase) => total + (phase['ticks'] as int) ~/ tickStride,
  );

  void setBeforeAfter({
    required bool after,
    bool probeOnly = false,
    int frameIndex = 0,
  }) {
    if (presentationTest) {
      camera.halosEnabled = after;
      camera.depthFogEnabled = after;
      camera.previewMinuteOfDay = (plan['previewMinuteOfDay'] as num)
          .toDouble();
      return;
    }
    contactShadowsAfter = after;
    setComparisonLightingPhase(
      depthOfFieldTest: depthOfFieldTest,
      atmosphereTest: atmosphereTest,
      actorContactShadowTest: actorContactShadowTest,
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

  Map<String, SpatialActorVisual> get renderedActors =>
      !actorContactShadowTest || contactShadowsAfter
      ? actors
      : {
          for (final entry in actors.entries)
            entry.key: SpatialActorVisual(
              x: entry.value.x,
              y: entry.value.y,
              z: entry.value.z,
              groundY: entry.value.groundY,
              texture: entry.value.texture,
              frame: entry.value.frame,
              width: entry.value.width,
              height: entry.value.height,
              billboardVerticalOffset: entry.value.billboardVerticalOffset,
            ),
        };

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
    'atmosphereTest': atmosphereTest,
    'depthOfFieldTest': depthOfFieldTest,
    'depthOfFieldEnabled': camera.depthOfFieldEnabled,
    'depthOfFieldFrame': renderFrame?.state,
    'loads': loadCounters,
    'presentationTest': presentationTest,
    'halosEnabled': camera.halosEnabled,
    'depthFogEnabled': camera.depthFogEnabled,
    'haloCount': camera.haloCount,
    'haloAllocations': camera.haloAllocations,
    'dayNightTest': dayNightTest,
    'pointLightShadowTest': pointLightShadowTest,
    'actorContactShadowTest': actorContactShadowTest,
    'actorContactShadowCount': camera.actorContactShadowCount,
    'authoredActorContactShadowIds': [
      for (final actor in actors.entries)
        if (actor.value.contactShadow) actor.key,
    ],
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
    final before = renderFrame?.generation;
    void invalidate(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(invalidate);
    }

    for (var count = 0; count < 3; count++) {
      applyStudioCaptureLifecycle(AppLifecycleState.resumed);
      if (depthOfFieldTest) updateSpatialCapture(captureKey);
      if (captureKey.currentContext?.findRenderObject() case final object?) {
        invalidate(object);
      }
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame.timeout(
        const Duration(seconds: 15),
      );
    }
    if (failure != null) throw StateError(failure!);
    if (depthOfFieldTest &&
        (before == null ||
            renderFrame!.generation <= before ||
            renderFrame!.state['enabled'] != camera.depthOfFieldEnabled)) {
      throw StateError(
        'Capture did not paint the requested depth of field state.',
      );
    }
  }

  Future<Uint8List> pixels() async {
    await settle();
    if (actorContactShadowTest) {
      verifyComparisonContactActors(
        authoredContactActorIds: {
          for (final entry in actors.entries)
            if (entry.value.contactShadow) entry.key,
        },
        expectedActorIds:
            ((plan['expectedActorContactShadowIds'] as List<dynamic>?) ?? [])
                .cast<String>()
                .toSet(),
        after: contactShadowsAfter,
        renderedCount: camera.actorContactShadowCount,
      );
    }
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
    final resumeRendering = depthOfFieldTest
        ? freezeSpatialCapture(captureKey)
        : null;
    final frames = <Map<String, Object?>>[];
    Map<String, int>? roundTripBeforeShadowStats;
    Map<String, int>? roundTripAfterShadowStats;
    int? roundTripBeforeContactShadowCount;
    int? roundTripAfterContactShadowCount;
    try {
      if (!ready) throw StateError('Native scene is not ready.');
      verifySession();
      final take = Directory(
        '$root/evidence/${depthOfFieldTest
            ? 'depth-of-field/native'
            : presentationTest
            ? 'presentation/native'
            : atmosphereTest
            ? 'atmosphere/native'
            : actorContactShadowTest
            ? 'actor-contact-shadows/native'
            : pointLightShadowTest
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
      setBeforeAfter(
        after: false,
        probeOnly: usesAuthoredLighting || probeOnly,
      );
      if (depthOfFieldTest) await pixels();
      final baseline = await pixels();
      roundTripBeforeShadowStats = shadowStats;
      roundTripBeforeContactShadowCount = camera.actorContactShadowCount;
      setBeforeAfter(after: true, probeOnly: usesAuthoredLighting || probeOnly);
      final changed = await pixels();
      roundTripAfterShadowStats = shadowStats;
      roundTripAfterContactShadowCount = camera.actorContactShadowCount;
      setBeforeAfter(
        after: false,
        probeOnly: usesAuthoredLighting || probeOnly,
      );
      final reverted = await pixels();
      if (depthOfFieldTest) {
        await File('${take.path}/baseline.png').writeAsBytes(baseline);
        await File('${take.path}/enabled.png').writeAsBytes(changed);
        await File('${take.path}/reverted.png').writeAsBytes(reverted);
      }
      baselineRoundTripIdentical = listEquals(baseline, reverted);
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
            'beforeMinuteOfDay': presentationTest
                ? camera.previewMinuteOfDay
                : beforeMinuteOfDay,
            'afterMinuteOfDay': presentationTest
                ? camera.previewMinuteOfDay
                : 1320,
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
        for (var step = 0; step < (phase['ticks'] as int); step += tickStride) {
          for (var substep = 0; substep < tickStride; substep++) {
            actors = session.frames(1 / 60);
            tick++;
            verifySession();
          }
          final filename = captured.toString().padLeft(5, '0');
          setBeforeAfter(after: false, frameIndex: captured);
          await File('${take.path}/before/$filename.png')
              .writeAsBytes(await pixels());
          final beforeShadowStats = shadowStats;
          final beforeDepthOfFieldFrame = renderFrame?.state;
          final beforeContactShadowCount = camera.actorContactShadowCount;
          final beforeCapturedMinute = camera.previewMinuteOfDay;
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
            if (depthOfFieldTest)
              'beforeDepthOfFieldFrame': beforeDepthOfFieldFrame,
            if (depthOfFieldTest) 'afterDepthOfFieldFrame': renderFrame?.state,
            if (actorContactShadowTest)
              'beforeContactShadowCount': beforeContactShadowCount,
            if (actorContactShadowTest)
              'afterContactShadowCount': camera.actorContactShadowCount,
            if (usesAuthoredLighting) 'beforeShadowStats': beforeShadowStats,
            if (usesAuthoredLighting) 'beforeMinuteOfDay': beforeCapturedMinute,
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
              if (actorContactShadowTest)
                'roundTripBeforeContactShadowCount':
                    roundTripBeforeContactShadowCount,
              if (actorContactShadowTest)
                'roundTripAfterContactShadowCount':
                    roundTripAfterContactShadowCount,
              if (usesAuthoredLighting)
                'beforeMinuteOfDay': presentationTest
                    ? camera.previewMinuteOfDay
                    : beforeMinuteOfDay,
              if (usesAuthoredLighting && probeOnly)
                'afterMinuteOfDay': presentationTest
                    ? camera.previewMinuteOfDay
                    : 1320,
              if (usesAuthoredLighting)
                'roundTripAfterMinuteOfDay': presentationTest
                    ? camera.previewMinuteOfDay
                    : 1320,
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
        resumeRendering?.call();
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
      body: Column(
        children: [
          if (capture.presentationTest)
            PresentationComparisonControls(controller: capture.camera),
          if (capture.atmosphereTest)
            SizedBox(
              width: 960,
              child: MapAtmospherePreviewControls(controller: capture.camera),
            ),
          Expanded(
            child: Center(
              child: FittedBox(
                child: SizedBox(
                  width: 960,
                  height: 720,
                  child: RepaintBoundary(
                    key: capture.captureKey,
                    child: comparisonLightingSurface(
                      depthOfFieldTest: capture.depthOfFieldTest,
                      atmosphereTest: capture.atmosphereTest,
                      dayNightTest: capture.dayNightTest,
                      pointLightShadowTest: capture.pointLightShadowTest,
                      actorContactShadowTest: capture.actorContactShadowTest,
                      presentationTest: capture.presentationTest,
                      lighting: capture.lighting,
                      child: SpatialSceneView(
                        scene: capture.scene,
                        models: bundle.manifest.models3d,
                        loadModel: (id) {
                          capture.modelLoads++;
                          return capture.session.modelBytes(id);
                        },
                        controller: capture.camera,
                        onCell: (_, _) {},
                        background: colors.shadow,
                        ground: colors.primaryContainer,
                        edge: colors.outlineVariant,
                        groundMap: capture.renderMap,
                        groundProject: bundle.manifest,
                        loadGroundImage: (id) {
                          capture.groundImageLoads++;
                          return capture.session.groundImageBytes(id);
                        },
                        resourceBudget: bundle.resourceBudget,
                        resourceIdentity: bundle.projectCatalog?.identity,
                        actorFrames: (_) => capture.renderedActors,
                        modelRuntimeState: capture.modelState,
                        presentationElapsedSeconds: () =>
                            capture.presentationSeconds,
                        rasterAnimationElapsedMsForCell:
                            (map, layer, x, z, _) =>
                                capture.session.rasterAnimationElapsedMsForCell(
                                  map,
                                  layer,
                                  x,
                                  z,
                                  capture.tick * 1000 ~/ 60,
                                ),
                        cameraPose: () => (
                          x: capture.depthOfFieldTest
                              ? capture.session.movement.x
                              : (anchor['x'] as num).toDouble(),
                          y: (anchor['y'] as num).toDouble(),
                          z: capture.depthOfFieldTest
                              ? capture.session.movement.z
                              : (anchor['z'] as num).toDouble(),
                          zoom: (anchor['zoom'] as num).toDouble(),
                        ),
                        cameraMagnification: () =>
                            capture.session.nativeCameraMagnification,
                        onReady: () {
                          capture.readyCalls++;
                          capture.ready = true;
                        },
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
          ),
        ],
      ),
    );
  }
}
