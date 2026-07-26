import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project capability truth gate', () {
    test('rejects a promoted capability without a runtime consumer', () {
      final report = ProjectCapabilityTruthReport.evaluate(
        [
          const ProjectCapabilityTruthRecord.promoted(
            capabilityId: 'trainer.difficulty',
            authoringControl: 'Trainer difficulty selector',
            contractField: 'TrainerDefinition.battleDifficulty',
            runtimeConsumer: '',
            playerSurface: 'Trainer battle',
            positiveTest: 'trainer_difficulty_runtime_test.dart',
            negativeTest: 'trainer_difficulty_unsupported_test.dart',
          ),
        ],
        requiredCapabilityIds: const {'trainer.difficulty'},
      );

      expect(report.isPassing, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.missingRuntimeConsumer),
      );
    });

    test('rejects a promoted capability without positive or negative proof',
        () {
      final report = ProjectCapabilityTruthReport.evaluate(
        [
          const ProjectCapabilityTruthRecord.promoted(
            capabilityId: 'trainer.difficulty',
            authoringControl: 'Trainer difficulty selector',
            contractField: 'TrainerDefinition.battleDifficulty',
            runtimeConsumer: 'TrainerBattleCoordinator',
            playerSurface: 'Trainer battle',
            positiveTest: '',
            negativeTest: '',
          ),
        ],
        requiredCapabilityIds: const {'trainer.difficulty'},
      );

      expect(report.isPassing, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        containsAll(<ProjectCapabilityTruthIssueCode>[
          ProjectCapabilityTruthIssueCode.missingPositiveTest,
          ProjectCapabilityTruthIssueCode.missingNegativeTest,
        ]),
      );
    });

    test('rejects duplicate capability ids', () {
      const record = ProjectCapabilityTruthRecord.deferred(
        capabilityId: 'battle.held-items',
        reason: 'Runtime bridge not delivered.',
      );

      final report = ProjectCapabilityTruthReport.evaluate(
        const [record, record],
        requiredCapabilityIds: const {'battle.held-items'},
      );

      expect(report.isPassing, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.duplicateCapabilityId),
      );
    });

    test('serializes deferred capabilities without pretending support', () {
      final report = ProjectCapabilityTruthReport.evaluate(
        const [
          ProjectCapabilityTruthRecord.deferred(
            capabilityId: 'battle.held-items',
            reason: 'Runtime bridge not delivered.',
          ),
        ],
        requiredCapabilityIds: const {'battle.held-items'},
      );

      expect(report.isPassing, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.noPromotedCapabilities),
      );
      expect(
        report.toJson()['capabilities'],
        [
          {
            'capabilityId': 'battle.held-items',
            'authoringControl': null,
            'contractField': null,
            'runtimeConsumer': null,
            'playerSurface': null,
            'positiveTest': null,
            'negativeTest': null,
            'status': 'deferred',
            'reason': 'Runtime bridge not delivered.',
          },
        ],
      );
    });

    test('rejects empty and partial matrices against the required set', () {
      final empty = ProjectCapabilityTruthReport.evaluate(
        const [],
        requiredCapabilityIds: const {
          'narrative.command.setFact',
          'narrative.command.dialogue',
        },
      );
      final partial = ProjectCapabilityTruthReport.evaluate(
        const [
          ProjectCapabilityTruthRecord.promoted(
            capabilityId: 'narrative.command.setFact',
            authoringControl: 'authoring.dart#builder',
            contractField: 'setFact',
            runtimeConsumer: 'runtime.dart#writer',
            playerSurface: 'runtime.dart#surface',
            positiveTest: 'positive_test.dart#case',
            negativeTest: 'negative_test.dart#case',
          ),
        ],
        requiredCapabilityIds: const {
          'narrative.command.setFact',
          'narrative.command.dialogue',
        },
      );

      expect(empty.isPassing, isFalse);
      expect(
        empty.issues
            .where(
              (issue) =>
                  issue.code ==
                  ProjectCapabilityTruthIssueCode.missingExpectedCapability,
            )
            .map((issue) => issue.capabilityId),
        unorderedEquals(
          const {
            'narrative.command.setFact',
            'narrative.command.dialogue',
          },
        ),
      );
      expect(partial.isPassing, isFalse);
      expect(
        partial.issues.map((issue) => issue.capabilityId),
        contains('narrative.command.dialogue'),
      );
    });

    test('canonical narrative command matrix is complete and fail-closed', () {
      final catalog = NarrativeCommandCatalog.canonical();
      final attestation = _attestation(catalog);
      final matrix = buildNarrativeCommandCapabilityTruthMatrix(
        catalog: catalog,
        authoring: attestation,
        runtime: attestation,
        playerSurface: attestation,
        positiveTests: attestation,
        negativeTests: attestation,
      );
      final report = ProjectCapabilityTruthReport.evaluate(
        matrix,
        requiredCapabilityIds: requiredNarrativeCommandCapabilityIds(
          catalog: catalog,
        ),
      );

      expect(report.isPassing, isTrue, reason: report.agentMarkdown);
      expect(
        matrix
            .where(
              (record) =>
                  record.status == ProjectCapabilityTruthStatus.promoted,
            )
            .map((record) => record.capabilityId),
        unorderedEquals(
          catalog.publishable.map(
            (command) => 'narrative.command.${command.id}',
          ),
        ),
      );
      expect(
        matrix
            .singleWhere(
              (record) =>
                  record.capabilityId ==
                  'narrative.command.${NarrativeCommandIds.setNpcPresence}',
            )
            .status,
        ProjectCapabilityTruthStatus.deferred,
      );
    });
  });
}

ProjectCapabilityTruthAttestation _attestation(
  NarrativeCommandCatalog catalog,
) =>
    ProjectCapabilityTruthAttestation(
      referencesByCapabilityId: {
        for (final command in catalog.publishable)
          command.id: 'proof.dart#${command.id}',
      },
    );
