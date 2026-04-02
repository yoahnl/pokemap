import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/scenario/scenario_authoring_ux.dart';

void main() {
  group('scenario_authoring_ux', () {
    test('scenario scope labels are defined', () {
      for (final scope in ScenarioScope.values) {
        expect(scenarioScopeLabel(scope).trim(), isNotEmpty);
        expect(scenarioScopeDescription(scope).trim(), isNotEmpty);
        expect(scenarioScopePickerLabel(scope),
            contains(scenarioScopeLabel(scope)));
      }
    });

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

    test('node intent and execution labels stay defined', () {
      for (final type in ScenarioNodeType.values) {
        final node = ScenarioNode(id: 'n', type: type);
        final intent = scenarioNodeIntent(node);
        final intentLabel = scenarioNodeIntentLabel(intent);
        expect(intentLabel.trim(), isNotEmpty);

        final executionState = scenarioNodeExecutionState(
          node,
          graphRuntimeConnected: false,
        );
        expect(
            scenarioNodeExecutionStateLabel(executionState).trim(), isNotEmpty);
        expect(
          scenarioNodeExecutionStateDescription(executionState).trim(),
          isNotEmpty,
        );
      }
    });

    test('runtime-ready action is marked as runtime-capable when graph is off',
        () {
      const node = ScenarioNode(
        id: 'action_1',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: 'openDialogue'),
      );
      final preset = scenarioActionPresetById(
        node.payload.actionKind,
        referenceMode: false,
      );
      final executionState = scenarioNodeExecutionState(
        node,
        actionPreset: preset,
        graphRuntimeConnected: false,
      );
      expect(
        executionState,
        ScenarioNodeExecutionState.runtimeCapableNotConnected,
      );
    });

    test('runtime support helper reflects MVP bridge support matrix', () {
      expect(
        scenarioRuntimeMvpSupportsActionKind(
          'sourceMapEnter',
          referenceMode: true,
        ),
        isTrue,
      );
      expect(
        scenarioRuntimeMvpSupportsActionKind(
          'referenceEvent',
          referenceMode: true,
        ),
        isFalse,
      );
      expect(
        scenarioRuntimeMvpSupportsActionKind(
          'runScript',
          referenceMode: false,
        ),
        isTrue,
      );
      expect(
        scenarioRuntimeMvpSupportsActionKind(
          'emitOutcome',
          referenceMode: false,
        ),
        isTrue,
      );
      expect(
        scenarioRuntimeMvpSupportsActionKind(
          'sourceOutcome',
          referenceMode: true,
        ),
        isTrue,
      );
      expect(
        scenarioRuntimeMvpSupportsActionKind(
          'startTrainerBattle',
          referenceMode: false,
        ),
        isFalse,
      );
    });
  });
}
