import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('RM-053 full battle capability gate', () {
    test('keeps the RM-026 MVP cutline exact and independently passing', () {
      final gate = BattleMvpCapabilityGate.canonical();
      final cutlineIds = gate.definitions
          .where((definition) => definition.isMvpCutline)
          .map((definition) => definition.capabilityId)
          .toSet();

      expect(gate.report.isPassing, isTrue, reason: gate.report.agentMarkdown);
      expect(cutlineIds, battleMvpCutlineCapabilityIds);
      expect(cutlineIds, hasLength(10));
      expect(
        gate.definitions.where((definition) => !definition.isMvpCutline).every(
              (definition) =>
                  definition.record.status ==
                  ProjectCapabilityTruthStatus.deferred,
            ),
        isTrue,
      );
    });

    test('promotes all 13 capabilities without blocking the MVP release', () {
      final gate = BattleFullCapabilityGate.canonical();

      expect(gate.report.isPassing, isTrue, reason: gate.report.agentMarkdown);
      expect(gate.isMvpReleaseBlocking, isFalse);
      expect(
        gate.definitions.map((definition) => definition.capabilityId),
        unorderedEquals(requiredBattleFullCapabilityIds),
      );
      expect(gate.definitions, hasLength(13));
      expect(
        gate.definitions.every(
          (definition) =>
              definition.record.status == ProjectCapabilityTruthStatus.promoted,
        ),
        isTrue,
      );
      expect(
        gate.definitions
            .where((definition) => !definition.isMvpCutline)
            .map((definition) => definition.capabilityId),
        unorderedEquals(const <String>{
          battleHeldItemCapabilityId,
          battleNatureIvEvCapabilityId,
          battleStruggleCapabilityId,
        }),
      );
    });

    test('fails closed when one full-gate extension loses a proof', () {
      final gate = BattleFullCapabilityGate.canonical();
      final records = gate.definitions
          .map((definition) => definition.record)
          .toList(growable: false);
      final targetIndex = records.indexWhere(
        (record) => record.capabilityId == battleStruggleCapabilityId,
      );
      final target = records[targetIndex];
      records[targetIndex] = ProjectCapabilityTruthRecord.promoted(
        capabilityId: target.capabilityId,
        authoringControl: target.authoringControl!,
        contractField: target.contractField!,
        runtimeConsumer: target.runtimeConsumer!,
        playerSurface: target.playerSurface!,
        positiveTest: target.positiveTest!,
        negativeTest: '',
      );

      final incomplete = ProjectCapabilityTruthReport.evaluate(
        records,
        requiredCapabilityIds: requiredBattleFullCapabilityIds,
      );

      expect(incomplete.isPassing, isFalse);
      expect(
        incomplete.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.missingNegativeTest),
      );
    });

    test('serializes a deterministic non-blocking full gate', () {
      final gate = BattleFullCapabilityGate.canonical();
      final first = const JsonEncoder.withIndent('  ').convert(gate.toJson());
      final second = const JsonEncoder.withIndent('  ').convert(
        BattleFullCapabilityGate.canonical().toJson(),
      );

      expect(second, first);
      expect(gate.toJson()['gateId'], battleFullCapabilityGateId);
      expect(gate.toJson()['status'], 'pass');
      expect(gate.toJson()['mvpReleaseBlocking'], isFalse);
      expect(gate.agentMarkdown, contains('Battle Full Capability Gate V0'));
      expect(gate.agentMarkdown, contains('non-blocking'));
      expect(gate.agentMarkdown, isNot(contains('`deferred`')));
    });

    test('committed generated artifacts match the canonical full gate', () {
      final repositoryRoot = Directory.current.parent.parent.path;
      final gate = BattleFullCapabilityGate.canonical();
      final expectedJson =
          '${const JsonEncoder.withIndent('  ').convert(gate.toJson())}\n';
      final expectedMarkdown = '${gate.agentMarkdown}\n';

      expect(
        File(
          '$repositoryRoot/$battleFullCapabilityJsonRelativePath',
        ).readAsStringSync(),
        expectedJson,
      );
      expect(
        File(
          '$repositoryRoot/$battleFullCapabilityMarkdownRelativePath',
        ).readAsStringSync(),
        expectedMarkdown,
      );
    });

    test('every promoted full-gate reference resolves to a proof marker', () {
      final repositoryRoot = Directory.current.parent.parent.path;
      final gate = BattleFullCapabilityGate.canonical();

      for (final definition in gate.definitions) {
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
