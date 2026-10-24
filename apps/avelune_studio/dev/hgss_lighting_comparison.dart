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
  if (!{
    'comparison-plan.json',
    'comparison-shadows-plan.json',
  }.contains(planFilename)) {
    throw StateError('Unsupported comparison plan.');
  }
  final root = await Directory(configuredRoot).resolveSymbolicLinks();
  final marker = File('$root/.avelune-lighting-comparison-owner');
  if ((await marker.readAsString()).trim() != 'avelune-lighting-comparison@1') {
    throw StateError('Comparison ownership marker missing.');
  }
  final project = await Directory('$root/jeu').resolveSymbolicLinks();
  if (project != '$root/jeu') throw StateError('Project copy must be local.');
  final plan = jsonDecode(
    await File('$root/evidence/$planFilename').readAsString(),
  ) as Map<String, dynamic>;
  if (plan['testProject'] != project || plan['mapId'] != 'first-map') {
    throw StateError('Comparison plan does not identify this copy.');
  }
  await initializeSpatialRenderer();
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: '$project/project.json',
    mapId: plan['mapId'] as String,
  );
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
      scene = prepareComparisonScene(
        session.bundle.map.spatialScene!,
        ((plan['hiddenInstanceIds'] as List<dynamic>?) ?? [])
            .cast<String>()
            .toSet(),
      ),
      camera = SpatialSceneController()..setView(SpatialEditorView.game);

  final String root;
  final Map<String, dynamic> plan;
  final SpatialExplorationSession session;
  final SpatialSceneController camera;
  final MapSpatialScene scene;
  final captureKey = GlobalKey();
  late final bool shadowTest = plan.containsKey('shadowCasterInstanceIds');
  late final before = shadowTest
      ? profile(shadows: false)
      : SpatialLightingProfile.disabled;
  late final after = profile(shadows: shadowTest);
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

  SpatialLightingProfile profile({required bool shadows}) {
    final sun = plan['sunDirection'] as Map<String, dynamic>?;
    return SpatialLightingProfile.stylized(
      ambientStrength: shadowTest ? .72 : .82,
      sunStrength: shadowTest ? .6 : .4,
      groundStrength: shadowTest ? 1 : .7,
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
              center: (x: 26.5, y: 2.5, z: 13),
              extent: 16,
              depth: 32,
              resolution: 1024,
              bias: .0015,
              opacity: .8,
              receiverMinY: .9,
              receiverMaxY: 1.2,
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
    'sourceInstanceCount': session.bundle.map.spatialScene!.instances.length,
    'renderedInstanceCount': scene.instances.length,
    'hiddenInstanceIds': plan['hiddenInstanceIds'] ?? [],
    'hiddenMaterialsByInstance': plan['hiddenMaterialsByInstance'] ?? {},
    'shadowCasterInstanceIds': plan['shadowCasterInstanceIds'] ?? [],
    'shadowStats': shadowStats,
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
    if (shadowTest && identical(lighting.value, after)) {
      final stats = camera.shadowStats;
      if (stats.casterDrawCount == 0 ||
          stats.receiverDrawCount == 0 ||
          stats.hiddenDrawCount != 1 ||
          stats.targetAllocations != 1) {
        throw StateError('The shadow render pass is not valid: $shadowStats');
      }
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
    try {
      if (!ready) throw StateError('Native scene is not ready.');
      verifySession();
      final take = Directory(
        '$root/evidence/${shadowTest ? 'shadow-test/native' : 'native'}/${probeOnly ? 'probe' : 'take'}-${DateTime.now().microsecondsSinceEpoch}',
      );
      await take.create(recursive: true);
      output = take.path;
      await Directory('${take.path}/before').create();
      await Directory('${take.path}/after').create();
      lighting.value = before;
      final baseline = await pixels();
      lighting.value = after;
      final changed = await pixels();
      lighting.value = before;
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
          lighting.value = before;
          await File('${take.path}/before/$filename.png')
              .writeAsBytes(await pixels());
          lighting.value = after;
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
              child: SpatialLightingPreview(
                controller: capture.lighting,
                child: SpatialSceneView(
                  scene: capture.scene,
                  models: bundle.manifest.models3d,
                  loadModel: capture.session.modelBytes,
                  controller: capture.camera,
                  onCell: (_, _) {},
                  background: colors.shadow,
                  ground: colors.primaryContainer,
                  edge: colors.outlineVariant,
                  groundMap: bundle.map,
                  groundProject: bundle.manifest,
                  loadGroundImage: capture.session.groundImageBytes,
                  resourceBudget: bundle.resourceBudget,
                  resourceIdentity: bundle.projectCatalog?.identity,
                  actorFrames: (_) => capture.actors,
                  modelRuntimeState: capture.modelState,
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
