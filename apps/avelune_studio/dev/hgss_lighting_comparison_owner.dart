import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

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
