import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../dev/hgss_lighting_comparison.dart';

void main() {
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
}
