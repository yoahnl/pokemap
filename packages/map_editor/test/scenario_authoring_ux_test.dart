import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/scenario/scenario_authoring_ux.dart';

void main() {
  group('scenario_authoring_ux', () {
    test('node labels and descriptions are defined for all types', () {
      for (final type in ScenarioNodeType.values) {
        final label = scenarioNodeTypeLabel(type);
        final description = scenarioNodeTypeDescription(type);
        final pickerLabel = scenarioNodeTypePickerLabel(type);
        expect(label.trim(), isNotEmpty);
        expect(description.trim(), isNotEmpty);
        expect(pickerLabel.contains(label), isTrue);
      }
    });

    test('action preset lookup resolves known action', () {
      final preset = scenarioActionPresetById(
        'startTrainerBattle',
        referenceMode: false,
      );
      expect(preset, isNotNull);
      expect(preset!.fields.contains(ScenarioActionField.trainer), isTrue);
    });

    test('reference preset lookup resolves map-scoped resource', () {
      final preset = scenarioActionPresetById(
        'referenceEvent',
        referenceMode: true,
      );
      expect(preset, isNotNull);
      expect(
        preset!.fields.containsAll(
          <ScenarioActionField>[
            ScenarioActionField.map,
            ScenarioActionField.event
          ],
        ),
        isTrue,
      );
    });

    test('unknown preset id returns null', () {
      final preset = scenarioActionPresetById(
        'does_not_exist',
        referenceMode: false,
      );
      expect(preset, isNull);
    });

    test('all presets expose execution hints', () {
      for (final preset in scenarioActionPresets) {
        expect(preset.executionHint.trim(), isNotEmpty);
        expect(scenarioRuntimeSupportLabel(preset.runtimeSupport), isNotEmpty);
      }
      for (final preset in scenarioReferencePresets) {
        expect(preset.executionHint.trim(), isNotEmpty);
        expect(scenarioRuntimeSupportLabel(preset.runtimeSupport), isNotEmpty);
      }
    });

    test('trigger source presets are detected', () {
      expect(scenarioPresetRepresentsTriggerSource('sourceMapEnter'), isTrue);
      expect(
          scenarioPresetRepresentsTriggerSource('sourceTriggerEnter'), isTrue);
      expect(scenarioPresetRepresentsTriggerSource('sourceEntityInteract'),
          isTrue);
      expect(scenarioPresetRepresentsTriggerSource('referenceEvent'), isFalse);
    });

    test('node human summary stays non-empty for all node types', () {
      for (final type in ScenarioNodeType.values) {
        final node = ScenarioNode(id: 'n', type: type);
        expect(scenarioNodeHumanSummary(node).trim(), isNotEmpty);
      }
    });
  });
}
