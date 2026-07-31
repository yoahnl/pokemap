import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectCapabilityTruthAdapter', () {
    test('preserves an explicit promoted attestation', () {
      final truth = ProjectCapabilityTruthAdapter.evaluate(
        records: const [
          ProjectCapabilityTruthRecord.promoted(
            capabilityId: 'narrative.command.dialogue',
            authoringControl: 'Dialogue picker',
            contractField: 'DialogueCommand.dialogueId',
            runtimeConsumer: 'DialogueCommandRunner',
            playerSurface: 'Dialogue overlay',
            positiveTest: 'dialogue_positive_test.dart',
            negativeTest: 'dialogue_missing_test.dart',
          ),
        ],
        requiredCapabilityIds: const {'narrative.command.dialogue'},
      );

      expect(truth.isPassing, isTrue);
      expect(truth.capabilities.single.toJson(), {
        'capabilityId': 'narrative.command.dialogue',
        'authoringControl': 'Dialogue picker',
        'contractField': 'DialogueCommand.dialogueId',
        'runtimeConsumer': 'DialogueCommandRunner',
        'playerSurface': 'Dialogue overlay',
        'positiveTest': 'dialogue_positive_test.dart',
        'negativeTest': 'dialogue_missing_test.dart',
        'status': 'promoted',
        'reason': null,
      });
      expect(truth.issues, isEmpty);
    });

    test('preserves deferred reasons without pretending support', () {
      final truth = ProjectCapabilityTruthAdapter.evaluate(
        records: const [
          ProjectCapabilityTruthRecord.deferred(
            capabilityId: 'battle.held-items',
            reason: 'Runtime bridge not delivered.',
          ),
        ],
        requiredCapabilityIds: const {'battle.held-items'},
      );

      expect(truth.isPassing, isFalse);
      expect(truth.capabilities.single.status, 'deferred');
      expect(
        truth.capabilities.single.reason,
        'Runtime bridge not delivered.',
      );
      expect(
        truth.issues.map((issue) => issue.code),
        contains('noPromotedCapabilities'),
      );
    });

    test('keeps missing attestations as coded issues', () {
      final truth = ProjectCapabilityTruthAdapter.evaluate(
        records: const [],
        requiredCapabilityIds: const {
          'narrative.command.dialogue',
          'narrative.command.setFact',
        },
      );

      expect(
        truth.issues
            .where((issue) => issue.code == 'missingExpectedCapability')
            .map((issue) => issue.capabilityId),
        [
          'narrative.command.dialogue',
          'narrative.command.setFact',
        ],
      );
      expect(
        truth.issues.map((issue) => issue.code),
        contains('noPromotedCapabilities'),
      );
    });

    test('is deterministic independently of record and requirement order', () {
      const promoted = ProjectCapabilityTruthRecord.promoted(
        capabilityId: 'capability.a',
        authoringControl: 'control',
        contractField: 'contract',
        runtimeConsumer: 'runtime',
        playerSurface: 'surface',
        positiveTest: 'positive',
        negativeTest: 'negative',
      );
      const deferred = ProjectCapabilityTruthRecord.deferred(
        capabilityId: 'capability.b',
        reason: 'Deferred.',
      );

      final forward = ProjectCapabilityTruthAdapter.evaluate(
        records: const [promoted, deferred],
        requiredCapabilityIds: const {'capability.a', 'capability.b'},
      );
      final reverse = ProjectCapabilityTruthAdapter.evaluate(
        records: const [deferred, promoted],
        requiredCapabilityIds: {'capability.b', 'capability.a'},
      );

      expect(forward.toJson(), reverse.toJson());
    });

    test('does not promote capabilities from populated project models', () {
      final manifest = ProjectManifest(
        name: 'Populated project',
        maps: const [],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(
            id: 'fact.ready',
            label: 'Ready',
          ),
        ],
      );
      expect(manifest.facts, isNotEmpty);

      final truth = ProjectCapabilityTruthAdapter.evaluate(
        records: const [],
        requiredCapabilityIds: const {'narrative.fact'},
      );

      expect(truth.capabilities, isEmpty);
      expect(truth.isPassing, isFalse);
      expect(
        truth.issues.map((issue) => issue.code),
        containsAll([
          'missingExpectedCapability',
          'noPromotedCapabilities',
        ]),
      );
    });
  });
}
