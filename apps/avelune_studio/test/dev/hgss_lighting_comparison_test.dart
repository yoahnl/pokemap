import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../dev/hgss_lighting_comparison.dart';

void main() {
  test(
    'depth of field pairs preserve lighting and restore the source image',
    () {
      final camera = SpatialSceneController();
      final lighting = ValueNotifier(SpatialLightingProfile.disabled);
      addTearDown(camera.dispose);
      addTearDown(lighting.dispose);
      camera.previewMinuteOfDay = 840;
      camera.halosEnabled = true;
      camera.depthFogEnabled = true;
      for (final enabled in [false, true, false]) {
        setComparisonLightingPhase(
          dayNightTest: false,
          depthOfFieldTest: true,
          after: enabled,
          probeOnly: false,
          frameIndex: 0,
          frameCount: 60,
          camera: camera,
          lighting: lighting,
          beforeProfile: SpatialLightingProfile.disabled,
          afterProfile: SpatialLightingProfile.stylized(),
        );
        expect(camera.depthOfFieldEnabled, enabled);
        expect(camera.previewMinuteOfDay, 840);
        expect(camera.halosEnabled, isTrue);
        expect(camera.depthFogEnabled, isTrue);
        expect(lighting.value, same(SpatialLightingProfile.disabled));
      }
      const child = SizedBox();
      expect(
        comparisonLightingSurface(
          dayNightTest: false,
          depthOfFieldTest: true,
          lighting: lighting,
          child: child,
        ),
        same(child),
      );
    },
  );

  test(
    'atmosphere pairs share the clock and independently restore all flags',
    () {
      final camera = SpatialSceneController();
      final lighting = ValueNotifier(SpatialLightingProfile.disabled);
      addTearDown(camera.dispose);
      addTearDown(lighting.dispose);
      for (final frame in [0, 120, 239]) {
        double? beforeMinute;
        for (final enabled in [false, true, false]) {
          setComparisonLightingPhase(
            dayNightTest: false,
            atmosphereTest: true,
            after: enabled,
            probeOnly: false,
            frameIndex: frame,
            frameCount: 240,
            camera: camera,
            lighting: lighting,
            beforeProfile: SpatialLightingProfile.disabled,
            afterProfile: SpatialLightingProfile.disabled,
          );
          beforeMinute ??= camera.previewMinuteOfDay;
          expect(camera.previewMinuteOfDay, beforeMinute);
          expect(camera.waterAnimated, enabled);
          expect(camera.windowsLit, enabled);
          expect(camera.fireflies, enabled);
        }
      }
      expect(camera.previewMinuteOfDay, 1320);
      const child = SizedBox();
      expect(
        comparisonLightingSurface(
          dayNightTest: false,
          atmosphereTest: true,
          lighting: lighting,
          child: child,
        ),
        same(child),
      );
    },
  );

  test(
    'contact capture requires every named actor to have the authored flag',
    () {
      expect(
        () => verifyComparisonContactActors(
          authoredContactActorIds: {'hero'},
          expectedActorIds: {'hero', 'npc'},
          after: true,
          renderedCount: 1,
        ),
        throwsStateError,
      );
      verifyComparisonContactActors(
        authoredContactActorIds: {'hero', 'npc'},
        expectedActorIds: {'hero', 'npc'},
        after: false,
        renderedCount: 0,
      );
      verifyComparisonContactActors(
        authoredContactActorIds: {'hero', 'npc'},
        expectedActorIds: {'hero', 'npc'},
        after: true,
        renderedCount: 2,
      );
      expect(
        () => verifyComparisonContactActors(
          authoredContactActorIds: {'hero', 'npc'},
          expectedActorIds: {'hero', 'npc'},
          after: false,
          renderedCount: 1,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'contact shadow comparison keeps the same hour and scenery in each pair',
    () {
      final camera = SpatialSceneController();
      final before = SpatialLightingProfile.disabled;
      final lighting = ValueNotifier(before);
      addTearDown(camera.dispose);
      addTearDown(lighting.dispose);
      for (final index in [0, 59, 60, 119]) {
        for (final after in [false, true]) {
          setComparisonLightingPhase(
            dayNightTest: false,
            actorContactShadowTest: true,
            after: after,
            probeOnly: false,
            frameIndex: index,
            frameCount: 120,
            camera: camera,
            lighting: lighting,
            beforeProfile: before,
            afterProfile: SpatialLightingProfile.stylized(),
          );
          expect(camera.previewMinuteOfDay, index < 60 ? 720 : 1320);
          expect(camera.previewPointLightShadowsEnabled, isTrue);
          expect(lighting.value, same(before));
        }
      }
      const child = SizedBox();
      expect(
        comparisonLightingSurface(
          dayNightTest: false,
          actorContactShadowTest: true,
          lighting: lighting,
          child: child,
        ),
        same(child),
      );
    },
  );

  test('contact plans reject mixed lighting, masked props and unowned paths', () async {
    final root = await Directory.systemTemp.createTemp('avelune-contact-plan-');
    addTearDown(() => root.delete(recursive: true));
    final path = await root.resolveSymbolicLinks();
    await Directory('$path/evidence/actor-contact-shadows')
        .create(recursive: true);
    final file = File(
      '$path/evidence/actor-contact-shadows/comparison-contact-shadows-plan.json',
    );
    final plan = {
      'testProject': '$path/jeu',
      'mapId': 'first-map',
      'actorContactShadowTest': true,
    };
    await file.writeAsString(jsonEncode(plan));
    expect(
      await loadComparisonPlan(path, 'comparison-contact-shadows-plan.json'),
      plan,
    );
    for (final extra in [
      {'dayNightTest': true},
      {'pointLightShadowTest': true},
      {
        'shadowCasterInstanceIds': ['house'],
      },
      {
        'hiddenInstanceIds': ['tree'],
      },
      {'testProject': '/other/jeu'},
    ]) {
      await file.writeAsString(jsonEncode({...plan, ...extra}));
      await expectLater(
        loadComparisonPlan(path, 'comparison-contact-shadows-plan.json'),
        throwsStateError,
      );
    }
  });

  test(
    'depth of field plans preserve unmasked assets and exclude other modes',
    () async {
      final root = await Directory.systemTemp.createTemp('avelune-dof-plan-');
      addTearDown(() => root.delete(recursive: true));
      final path = await root.resolveSymbolicLinks();
      await Directory('$path/evidence/depth-of-field').create(recursive: true);
      final file = File(
        '$path/evidence/depth-of-field/comparison-depth-of-field-plan.json',
      );
      final plan = {
        'testProject': '$path/jeu',
        'mapId': 'first-map',
        'depthOfFieldTest': true,
      };
      await file.writeAsString(jsonEncode(plan));
      expect(
        await loadComparisonPlan(path, 'comparison-depth-of-field-plan.json'),
        plan,
      );
      for (final extra in [
        {'presentationTest': true},
        {'dayNightTest': true},
        {'depthOfFieldTest': false},
        {
          'shadowCasterInstanceIds': ['house'],
        },
        {
          'hiddenInstanceIds': ['tree'],
        },
        {'testProject': '/other/jeu'},
      ]) {
        await file.writeAsString(jsonEncode({...plan, ...extra}));
        await expectLater(
          loadComparisonPlan(path, 'comparison-depth-of-field-plan.json'),
          throwsStateError,
        );
      }
    },
  );

  test('comparison plans retain both modes and bound the day/night folder', () {
    expect(
      comparisonPlanRelativePath('comparison-plan.json'),
      'evidence/comparison-plan.json',
    );
    expect(
      comparisonPlanRelativePath('comparison-shadows-plan.json'),
      'evidence/comparison-shadows-plan.json',
    );
    expect(
      comparisonPlanRelativePath('comparison-day-night-plan.json'),
      'evidence/day-night/comparison-day-night-plan.json',
    );
    expect(
      comparisonPlanRelativePath('comparison-lamp-shadows-plan.json'),
      'evidence/lamp-shadows/comparison-lamp-shadows-plan.json',
    );
    expect(
      () => comparisonPlanRelativePath('../comparison-day-night-plan.json'),
      throwsStateError,
    );
    expect(() => comparisonPlanRelativePath('other.json'), throwsStateError);
  });

  test(
    'loads the owned day/night plan and rejects a foreign copy or mixed mode',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'avelune-comparison-plan-',
      );
      addTearDown(() => root.delete(recursive: true));
      final path = await root.resolveSymbolicLinks();
      await Directory('$path/evidence/day-night').create(recursive: true);
      final file = File(
        '$path/evidence/day-night/comparison-day-night-plan.json',
      );
      final plan = {
        'testProject': '$path/jeu',
        'mapId': 'first-map',
        'dayNightTest': true,
      };
      await file.writeAsString(jsonEncode(plan));
      expect(
        await loadComparisonPlan(path, 'comparison-day-night-plan.json'),
        plan,
      );
      await file.writeAsString(
        jsonEncode({...plan, 'testProject': '/other/jeu'}),
      );
      await expectLater(
        loadComparisonPlan(path, 'comparison-day-night-plan.json'),
        throwsStateError,
      );
      await file.writeAsString(
        jsonEncode({
          ...plan,
          'shadowCasterInstanceIds': ['house'],
        }),
      );
      await expectLater(
        loadComparisonPlan(path, 'comparison-day-night-plan.json'),
        throwsStateError,
      );
      await file.writeAsString(jsonEncode({...plan, 'dayNightTest': false}));
      await expectLater(
        loadComparisonPlan(path, 'comparison-day-night-plan.json'),
        throwsStateError,
      );
    },
  );

  test(
    'lamp shadow plans stay in their folder and reject other lighting modes',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'avelune-lamp-shadow-plan-',
      );
      addTearDown(() => root.delete(recursive: true));
      final path = await root.resolveSymbolicLinks();
      await Directory('$path/evidence/lamp-shadows').create(recursive: true);
      final file = File(
        '$path/evidence/lamp-shadows/comparison-lamp-shadows-plan.json',
      );
      final plan = {
        'testProject': '$path/jeu',
        'mapId': 'first-map',
        'pointLightShadowTest': true,
      };
      await file.writeAsString(jsonEncode(plan));
      expect(
        await loadComparisonPlan(path, 'comparison-lamp-shadows-plan.json'),
        plan,
      );
      for (final extra in [
        {'dayNightTest': true},
        {
          'shadowCasterInstanceIds': ['house'],
        },
        {'pointLightShadowTest': false},
      ]) {
        await file.writeAsString(jsonEncode({...plan, ...extra}));
        await expectLater(
          loadComparisonPlan(path, 'comparison-lamp-shadows-plan.json'),
          throwsStateError,
        );
      }
      expect(
        () =>
            comparisonPlanRelativePath('../comparison-lamp-shadows-plan.json'),
        throwsStateError,
      );
    },
  );

  test(
    'lamp shadow comparison rejects masking without changing older modes',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'avelune-unmasked-lamp-plan-',
      );
      addTearDown(() => root.delete(recursive: true));
      final path = await root.resolveSymbolicLinks();
      await Directory('$path/evidence/lamp-shadows').create(recursive: true);
      final file = File(
        '$path/evidence/lamp-shadows/comparison-lamp-shadows-plan.json',
      );
      final plan = {
        'testProject': '$path/jeu',
        'mapId': 'first-map',
        'pointLightShadowTest': true,
        'hiddenMaterialsByInstance': <String, dynamic>{},
        'hiddenInstanceIds': <String>[],
      };
      await file.writeAsString(jsonEncode(plan));
      expect(
        await loadComparisonPlan(path, 'comparison-lamp-shadows-plan.json'),
        plan,
      );
      for (final masking in [
        {
          'hiddenMaterialsByInstance': {
            'house': ['h_kage'],
          },
        },
        {
          'hiddenInstanceIds': ['turbine'],
        },
      ]) {
        await file.writeAsString(jsonEncode({...plan, ...masking}));
        await expectLater(
          loadComparisonPlan(path, 'comparison-lamp-shadows-plan.json'),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('unmasked'),
            ),
          ),
        );
      }
      final olderPlan = {
        'testProject': '$path/jeu',
        'mapId': 'first-map',
        'shadowCasterInstanceIds': ['house'],
        'hiddenMaterialsByInstance': {
          'house': ['h_kage'],
        },
        'hiddenInstanceIds': ['turbine'],
      };
      await File('$path/evidence/comparison-shadows-plan.json')
          .writeAsString(jsonEncode(olderPlan));
      expect(
        await loadComparisonPlan(path, 'comparison-shadows-plan.json'),
        olderPlan,
      );
    },
  );

  test('day night comparisons require the actual unmasked assets', () async {
    final root = await Directory.systemTemp.createTemp('avelune-clean-cycle-');
    addTearDown(() => root.delete(recursive: true));
    final path = await root.resolveSymbolicLinks();
    await Directory('$path/evidence/day-night').create(recursive: true);
    final file = File(
      '$path/evidence/day-night/comparison-day-night-plan.json',
    );
    final plan = {
      'testProject': '$path/jeu',
      'mapId': 'first-map',
      'dayNightTest': true,
      'hiddenMaterialsByInstance': <String, dynamic>{},
      'hiddenInstanceIds': <String>[],
    };
    await file.writeAsString(jsonEncode(plan));
    expect(
      await loadComparisonPlan(path, 'comparison-day-night-plan.json'),
      plan,
    );
    for (final masking in [
      {
        'hiddenMaterialsByInstance': {
          'house': ['h_kage'],
        },
      },
      {
        'hiddenInstanceIds': ['turbine'],
      },
    ]) {
      await file.writeAsString(jsonEncode({...plan, ...masking}));
      await expectLater(
        loadComparisonPlan(path, 'comparison-day-night-plan.json'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('unmasked'),
          ),
        ),
      );
    }
  });

  test('lamp shadow comparison changes only occlusion at a fixed 22h', () {
    final camera = SpatialSceneController();
    final before = SpatialLightingProfile.disabled;
    final after = SpatialLightingProfile.stylized();
    final lighting = ValueNotifier(before);
    addTearDown(camera.dispose);
    addTearDown(lighting.dispose);
    expect(camera.previewPointLightShadowsEnabled, isTrue);
    void phase(bool enabled, int frame) => setComparisonLightingPhase(
      dayNightTest: false,
      pointLightShadowTest: true,
      after: enabled,
      probeOnly: false,
      frameIndex: frame,
      frameCount: 240,
      camera: camera,
      lighting: lighting,
      beforeProfile: before,
      afterProfile: after,
    );
    phase(false, 0);
    expect(camera.previewMinuteOfDay, 1320);
    expect(camera.previewPointLightShadowsEnabled, isFalse);
    phase(true, 120);
    expect(camera.previewMinuteOfDay, 1320);
    expect(camera.previewPointLightShadowsEnabled, isTrue);
    phase(false, 239);
    expect(camera.previewMinuteOfDay, 1320);
    expect(camera.previewPointLightShadowsEnabled, isFalse);
    expect(lighting.value, same(before));
    const child = SizedBox();
    expect(
      comparisonLightingSurface(
        dayNightTest: false,
        pointLightShadowTest: true,
        lighting: lighting,
        child: child,
      ),
      same(child),
    );
  });

  test(
    'day/night samples noon before, a full day after, and 22h for the probe',
    () {
      double minute({
        required bool after,
        bool probe = false,
        int index = 0,
        int count = 240,
      }) => comparisonMinuteOfDay(
        after: after,
        probeOnly: probe,
        frameIndex: index,
        frameCount: count,
      );
      expect(minute(after: false, index: 100), 720);
      expect(minute(after: true, probe: true), 1320);
      expect(minute(after: true), 720);
      expect(minute(after: true, index: 239), 720);
      expect(minute(after: true, index: 1, count: 5), 1080);
      expect(minute(after: true, index: 2, count: 5), 0);
      expect(minute(after: true, index: 3, count: 5), 360);
      expect(() => minute(after: true, count: 1), throwsStateError);
      expect(() => minute(after: true, index: 240), throwsStateError);
    },
  );

  test('day/night uses authored lighting and restores noon without changing the profile', () {
    final camera = SpatialSceneController();
    final before = SpatialLightingProfile.disabled;
    final after = SpatialLightingProfile.stylized();
    final lighting = ValueNotifier(before);
    addTearDown(camera.dispose);
    addTearDown(lighting.dispose);
    void phase(bool enabled, {bool dayNight = true}) =>
        setComparisonLightingPhase(
          dayNightTest: dayNight,
          after: enabled,
          probeOnly: true,
          frameIndex: 0,
          frameCount: 240,
          camera: camera,
          lighting: lighting,
          beforeProfile: before,
          afterProfile: after,
        );
    phase(false);
    expect(camera.previewMinuteOfDay, 720);
    phase(true);
    expect(camera.previewMinuteOfDay, 1320);
    expect(lighting.value, same(before));
    phase(false);
    expect(camera.previewMinuteOfDay, 720);
    const child = SizedBox();
    expect(
      comparisonLightingSurface(
        dayNightTest: true,
        lighting: lighting,
        child: child,
      ),
      same(child),
    );
    expect(
      comparisonLightingSurface(
        dayNightTest: false,
        lighting: lighting,
        child: child,
      ),
      isA<SpatialLightingPreview>(),
    );
    phase(true, dayNight: false);
    expect(lighting.value, same(after));
    phase(false, dayNight: false);
    expect(lighting.value, same(before));
  });

  final house = SpatialModelInstance(
    id: 'house',
    modelId: 'house-model',
    position: Model3dVector3.zero,
  );
  final door = SpatialModelInstance(
    id: 'door',
    modelId: 'door-model',
    position: Model3dVector3.zero,
  );
  final turbine = SpatialModelInstance(
    id: 'turbine',
    modelId: 'turbine-model',
    position: Model3dVector3.zero,
  );
  final source = MapSpatialScene(
    width: 4,
    depth: 4,
    heightLevels: List.filled(16, 1),
    instances: [house, door, turbine],
  );

  test(
    'comparison hides only requested instances without mutating its source',
    () {
      final prepared = prepareComparisonScene(source, {'turbine'});
      expect(prepared.instances, [house, door]);
      expect(source.instances, [house, door, turbine]);
      expect(prepared.camera, same(source.camera));
      expect(prepared.navigation, same(source.navigation));
      expect(prepared.heightLevels, source.heightLevels);
      expect(prepared.terrainSurfaces, same(source.terrainSurfaces));
    },
  );

  test(
    'an unknown removal fails instead of producing a misleading comparison',
    () {
      expect(
        () => prepareComparisonScene(source, {'unknown'}),
        throwsStateError,
      );
    },
  );

  test('an unfiltered comparison preserves the original scene identity', () {
    expect(prepareComparisonScene(source, {}), same(source));
  });

  test(
    'the renderer map carries the same filtered scene as its scene argument',
    () {
      final map = MapData(
        id: 'comparison',
        name: 'Comparison',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: source,
      );
      final prepared = prepareComparisonMap(map, {'turbine'});
      expect(prepared.spatialScene!.instances, [house, door]);
      expect(map.spatialScene!.instances, [house, door, turbine]);
      expect(prepared.spatialScene!.camera, same(source.camera));
      expect(prepared.entities, map.entities);
      expect(prepared.layers, map.layers);
    },
  );
}
