import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/golden_item_system_journey.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test(
    'runs executable L0-L6 evidence without synthetic certification',
    () async {
      final repositoryRoot = p.normalize(
        p.join(Directory.current.path, '../..'),
      );
      final projectRoot = Directory(
        p.join(
          repositoryRoot,
          'examples/playable_runtime_host/golden_item_system',
        ),
      );
      final mcpRoot = Directory(p.join(repositoryRoot, 'tools/pokemap_mcp'));
      final sourceRevision = await _sourceRevision(repositoryRoot);
      final build = await Process.run('npm', const <String>[
        'run',
        'build',
      ], workingDirectory: mcpRoot.path);
      expect(build.exitCode, 0, reason: build.stderr.toString());
      const runner = ItemSystemV1CertificationRunner();

      final first = await runner.run(
        repositoryRootDirectory: Directory(repositoryRoot),
        projectRootDirectory: projectRoot,
        mcpPackageRootDirectory: mcpRoot,
        sourceRevision: sourceRevision,
        recordedAtUtc: DateTime.utc(2026, 8, 12, 8),
      );
      final second = await runner.run(
        repositoryRootDirectory: Directory(repositoryRoot),
        projectRootDirectory: projectRoot,
        mcpPackageRootDirectory: mcpRoot,
        sourceRevision: sourceRevision,
        recordedAtUtc: DateTime.utc(2026, 8, 12, 9),
      );

      for (final level in const <ItemSystemProofLevel>[
        ItemSystemProofLevel.schemaL0,
        ItemSystemProofLevel.authoringL1,
        ItemSystemProofLevel.persistenceL2,
        ItemSystemProofLevel.runtimeL3,
        ItemSystemProofLevel.playerUxL4,
        ItemSystemProofLevel.mcpParityL5,
        ItemSystemProofLevel.goldenFlowL6,
      ]) {
        expect(first.statusFor(level), ItemSystemCertificationStatus.certified);
        expect(
          first.executionReceipts[level]?.evidenceSha256,
          matches(RegExp(r'^[0-9a-f]{64}$')),
        );
      }
      expect(first.overallStatus, ItemSystemCertificationStatus.certified);
      expect(
        first.goldenFixtureStatus,
        ItemSystemGoldenFixtureStatus.certified,
      );
      expect(
        first.productCapabilityStatus,
        ItemSystemProductCapabilityStatus.closed,
      );
      expect(
        first.toJson(),
        containsPair('goldenFixtureStatus', 'GOLDEN_FIXTURE_CERTIFIED'),
      );
      expect(first.toJson(), containsPair('schemaVersion', 2));
      expect(
        first.toJson(),
        containsPair('productCapabilityStatus', 'PRODUCT_CAPABILITY_CLOSED'),
      );
      expect(first.executionReceipts, hasLength(7));
      expect(
        _withoutInformationalTimestamps(first.toJson()),
        _withoutInformationalTimestamps(second.toJson()),
      );
      final receiptDirectory = await Directory.systemTemp.createTemp(
        'item-system-pmcp-receipts-',
      );
      addTearDown(() => receiptDirectory.delete(recursive: true));
      final receiptFile = File(p.join(receiptDirectory.path, 'receipts.json'));
      final l5 = first.executionReceipts[ItemSystemProofLevel.mcpParityL5]!;
      final bundle = const ItemSystemTransportEvidenceCollector()
          .buildParityReceiptBundle(l5);
      await receiptFile.writeAsString(jsonEncode(bundle));
      final pmcp = await Process.run('dart', <String>[
        'run',
        'tool/pmcp085_conformance.dart',
        '--transport-receipts',
        receiptFile.path,
      ], workingDirectory: p.join(repositoryRoot, 'packages/map_authoring'));
      final pmcpOutput =
          jsonDecode(pmcp.stdout.toString()) as Map<String, dynamic>;
      expect(pmcp.exitCode, 0, reason: pmcp.stderr.toString());
      expect(
        pmcpOutput['summary'],
        containsPair('itemTransportCertificationComplete', true),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test('missing executable receipts never become certified', () {
    final result = const ItemSystemCertificationEvaluator().evaluate(
      const ItemSystemCertificationRequest(
        sourceRevision: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        fixtureSha256:
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      ),
    );

    for (final level in ItemSystemProofLevel.values) {
      expect(result.statusFor(level), ItemSystemCertificationStatus.missing);
    }
    expect(result.overallStatus, ItemSystemCertificationStatus.missing);
    expect(
      result.goldenFixtureStatus,
      ItemSystemGoldenFixtureStatus.notCertified,
    );
    expect(
      result.productCapabilityStatus,
      ItemSystemProductCapabilityStatus.open,
    );
  });

  test('golden fixture certification does not close product capabilities', () {
    const sourceRevision = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const fixtureSha256 =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    final required = ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
      ItemSystemProofLevel.goldenFlowL6,
    );
    final receipt = ItemSystemExecutionReceipt.record(
      level: ItemSystemProofLevel.goldenFlowL6,
      sourceRevision: sourceRevision,
      fixtureSha256: fixtureSha256,
      payload: const <String, Object?>{'probe': 'golden'},
      attemptedCapabilities: required,
      succeededCapabilities: required,
      failedCapabilities: const <String>{},
      producer: 'test',
      runnerVersion: '1.0.0',
      recordedAtUtc: DateTime.utc(2026, 8, 12),
    );

    final result = const ItemSystemCertificationEvaluator().evaluate(
      ItemSystemCertificationRequest(
        sourceRevision: sourceRevision,
        fixtureSha256: fixtureSha256,
        executionReceipts: <ItemSystemProofLevel, ItemSystemExecutionReceipt>{
          ItemSystemProofLevel.goldenFlowL6: receipt,
        },
      ),
    );

    expect(result.goldenFixtureStatus, ItemSystemGoldenFixtureStatus.certified);
    expect(
      result.productCapabilityStatus,
      ItemSystemProductCapabilityStatus.open,
    );
    expect(result.overallStatus, ItemSystemCertificationStatus.missing);
  });

  test(
    'passed receipts missing required capabilities cannot certify a level',
    () {
      const sourceRevision = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const fixtureSha256 =
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
      final receipt = ItemSystemExecutionReceipt.record(
        level: ItemSystemProofLevel.schemaL0,
        sourceRevision: sourceRevision,
        fixtureSha256: fixtureSha256,
        payload: const <String, Object?>{'probe': 'incomplete'},
        attemptedCapabilities: const <String>{'catalog_schema'},
        succeededCapabilities: const <String>{'catalog_schema'},
        failedCapabilities: const <String>{},
        producer: 'test',
        runnerVersion: '1.0.0',
        recordedAtUtc: DateTime.utc(2026, 8, 12),
      );

      final result = const ItemSystemCertificationEvaluator().evaluate(
        ItemSystemCertificationRequest(
          sourceRevision: sourceRevision,
          fixtureSha256: fixtureSha256,
          executionReceipts: <ItemSystemProofLevel, ItemSystemExecutionReceipt>{
            ItemSystemProofLevel.schemaL0: receipt,
          },
        ),
      );

      expect(
        result.statusFor(ItemSystemProofLevel.schemaL0),
        ItemSystemCertificationStatus.partial,
      );
      expect(
        result.productCapabilityStatus,
        ItemSystemProductCapabilityStatus.open,
      );
    },
  );

  test(
    'golden receipt rejects missing observations and forged final state',
    () async {
      final repositoryRoot = p.normalize(
        p.join(Directory.current.path, '../..'),
      );
      final sourceRevision = await _sourceRevision(repositoryRoot);
      final saveRoot = await Directory.systemTemp.createTemp(
        'item-system-invalid-receipt-',
      );
      addTearDown(() => saveRoot.delete(recursive: true));
      final journey = await GoldenItemSystemJourney.run(
        projectRootDirectory: p.join(
          repositoryRoot,
          'examples/playable_runtime_host/golden_item_system',
        ),
        saveRootDirectory: saveRoot.path,
        sourceRevision: sourceRevision,
        rngSeed: 47,
      );
      final missing = journey.toJson()
        ..['observations'] = <String>['new_game_from_project'];
      final forged = journey.toJson()..['finalMoney'] = 0;

      expect(
        () => ItemSystemGoldenFlowReceipt.fromJson(missing),
        throwsFormatException,
      );
      expect(
        () => ItemSystemGoldenFlowReceipt.fromJson(forged),
        throwsFormatException,
      );
    },
  );
}

Object? _withoutInformationalTimestamps(Object? value) {
  if (value is List) {
    return value.map(_withoutInformationalTimestamps).toList(growable: false);
  }
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries)
        if (entry.key != 'recordedAtUtc')
          entry.key.toString(): _withoutInformationalTimestamps(entry.value),
    };
  }
  return value;
}

Future<String> _sourceRevision(String repositoryRoot) async {
  final result = await Process.run('git', const <String>[
    'rev-parse',
    'HEAD',
  ], workingDirectory: repositoryRoot);
  if (result.exitCode != 0) throw StateError(result.stderr.toString());
  return result.stdout.toString().trim();
}
