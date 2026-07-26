import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Battle MVP capability gate', () {
    test('canonical matrix passes with the exact fail-closed capability set',
        () {
      final gate = BattleMvpCapabilityGate.canonical();

      expect(gate.report.isPassing, isTrue, reason: gate.report.agentMarkdown);
      expect(
        gate.definitions.map((definition) => definition.capabilityId),
        unorderedEquals(requiredBattleMvpCapabilityIds),
      );
      expect(
        gate.definitions.where((definition) => definition.isMvpCutline).every(
            (definition) =>
                definition.record.status ==
                ProjectCapabilityTruthStatus.promoted),
        isTrue,
      );
    });

    test('keeps full-gate extensions explicitly deferred from the MVP cutline',
        () {
      final gate = BattleMvpCapabilityGate.canonical();
      final extensions = gate.definitions
          .where((definition) => !definition.isMvpCutline)
          .toList(growable: false);

      expect(
        extensions.map((definition) => definition.capabilityId),
        unorderedEquals(const <String>{
          battleHeldItemCapabilityId,
          battleNatureIvEvCapabilityId,
          battleStruggleCapabilityId,
        }),
      );
      expect(
        extensions.every(
          (definition) =>
              definition.record.status ==
                  ProjectCapabilityTruthStatus.deferred &&
              definition.record.reason!.contains('RM-053'),
        ),
        isTrue,
      );
    });

    test('fails closed when one canonical capability disappears', () {
      final gate = BattleMvpCapabilityGate.canonical();
      final incomplete = ProjectCapabilityTruthReport.evaluate(
        gate.definitions.skip(1).map((definition) => definition.record),
        requiredCapabilityIds: requiredBattleMvpCapabilityIds,
      );

      expect(incomplete.isPassing, isFalse);
      expect(
        incomplete.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.missingExpectedCapability),
      );
    });

    test('fails closed when a promoted capability loses a layer proof', () {
      final gate = BattleMvpCapabilityGate.canonical();
      final records = gate.definitions
          .map((definition) => definition.record)
          .toList(growable: false);
      final targetIndex = records.indexWhere(
        (record) => record.capabilityId == battleTrainerDifficultyCapabilityId,
      );
      records[targetIndex] = const ProjectCapabilityTruthRecord.promoted(
        capabilityId: battleTrainerDifficultyCapabilityId,
        authoringControl: 'editor',
        contractField: 'contract',
        runtimeConsumer: '',
        playerSurface: 'player',
        positiveTest: 'positive',
        negativeTest: 'negative',
      );

      final incomplete = ProjectCapabilityTruthReport.evaluate(
        records,
        requiredCapabilityIds: requiredBattleMvpCapabilityIds,
      );

      expect(incomplete.isPassing, isFalse);
      expect(
        incomplete.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.missingRuntimeConsumer),
      );
    });

    test('serializes a deterministic machine-readable cutline', () {
      final gate = BattleMvpCapabilityGate.canonical();
      final first = const JsonEncoder.withIndent('  ').convert(gate.toJson());
      final second = const JsonEncoder.withIndent('  ').convert(
        BattleMvpCapabilityGate.canonical().toJson(),
      );

      expect(second, first);
      expect(gate.toJson()['gateId'], battleMvpCapabilityGateId);
      expect(gate.toJson()['status'], 'pass');
      expect(gate.agentMarkdown, contains('Battle MVP Capability Gate V0'));
      expect(gate.agentMarkdown, contains('`deferred`'));
    });

    test('committed generated artifacts match the canonical gate', () {
      final repositoryRoot = Directory.current.parent.parent.path;
      final gate = BattleMvpCapabilityGate.canonical();
      final expectedJson =
          '${const JsonEncoder.withIndent('  ').convert(gate.toJson())}\n';
      final expectedMarkdown = '${gate.agentMarkdown}\n';

      expect(
        File(
          '$repositoryRoot/$battleMvpCapabilityJsonRelativePath',
        ).readAsStringSync(),
        expectedJson,
      );
      expect(
        File(
          '$repositoryRoot/$battleMvpCapabilityMarkdownRelativePath',
        ).readAsStringSync(),
        expectedMarkdown,
      );
    });

    test('every promoted reference resolves to a repository proof marker', () {
      final repositoryRoot = Directory.current.parent.parent.path;
      final gate = BattleMvpCapabilityGate.canonical();

      for (final definition in gate.definitions.where(
        (definition) =>
            definition.record.status == ProjectCapabilityTruthStatus.promoted,
      )) {
        for (final reference in definition.promotedReferences) {
          final parts = reference.split('#');
          expect(
            parts,
            hasLength(2),
            reason:
                '${definition.capabilityId} must reference path#proof-marker',
          );
          final relativePath = parts.first;
          final file = File('$repositoryRoot/$relativePath');
          expect(
            file.existsSync(),
            isTrue,
            reason:
                '${definition.capabilityId} references missing file $relativePath',
          );
          final normalizedContent = _normalizeProofMarker(
            file.readAsStringSync(),
          );
          for (final marker in parts.last.split(',')) {
            expect(
              normalizedContent,
              contains(_normalizeProofMarker(marker)),
              reason:
                  '${definition.capabilityId} references missing marker $marker '
                  'in $relativePath',
            );
          }
        }
      }
    });
  });
}

String _normalizeProofMarker(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
