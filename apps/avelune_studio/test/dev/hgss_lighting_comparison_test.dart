import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
