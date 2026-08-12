import 'dart:io';

import 'item_system_certification.dart';
import 'item_system_execution_receipt.dart';
import 'item_system_fixture_digest.dart';

final class ItemSystemPlayerEvidenceCollector {
  const ItemSystemPlayerEvidenceCollector();

  Future<ItemSystemExecutionReceipt> collect({
    required Directory repositoryRootDirectory,
    required Directory projectRootDirectory,
    required String sourceRevision,
    required DateTime recordedAtUtc,
  }) async {
    final fixtureSha256 = await computeItemSystemFixtureSha256(
      projectRootDirectory,
    );
    final probes = <String, _PlayerEvidenceProbe>{
      'bag_menu': const _PlayerEvidenceProbe(
        packagePath: 'packages/map_player_ui',
        testPath: 'test/player/runtime_player_detail_router_test.dart',
        plainName: 'bag selects a party target and keeps key items unavailable',
      ),
      'target_picker': const _PlayerEvidenceProbe(
        packagePath: 'packages/map_player_ui',
        testPath: 'test/player/runtime_player_detail_router_test.dart',
        plainName: 'HM target picker emits a compatible replacement command',
      ),
      'shop_controls': const _PlayerEvidenceProbe(
        packagePath: 'packages/map_player_ui',
        testPath: 'test/player/player_shop_overlay_test.dart',
        plainName: 'shop renders runtime prices and emits versioned commands',
      ),
      'capture_controls': const _PlayerEvidenceProbe(
        packagePath: 'packages/map_runtime',
        testPath: 'test/battle_mobile_command_overlay_test.dart',
        plainName: 'capture item control emits the selected Poke Ball entry',
      ),
      'move_machine_controls': const _PlayerEvidenceProbe(
        packagePath: 'packages/map_player_ui',
        testPath: 'test/player/runtime_player_detail_router_test.dart',
        plainName:
            'TM target picker teaches directly or chooses a move to forget',
      ),
      'held_item_controls': const _PlayerEvidenceProbe(
        packagePath: 'packages/map_player_ui',
        testPath: 'test/player/runtime_player_detail_router_test.dart',
        plainName: 'party gives, swaps and takes held items with guided labels',
      ),
      'hidden_pickup_rendering': const _PlayerEvidenceProbe(
        packagePath: 'packages/map_runtime',
        testPath: 'test/item_pickup_give_item_readiness_test.dart',
        plainName:
            'playable hidden item interaction remains available without rendering',
      ),
    };
    final succeeded = <String>{};
    final failed = <String>{};
    final probePayloads = <Object?>[];
    for (final entry in probes.entries) {
      final result = await _runProbe(repositoryRootDirectory, entry.value);
      if (result.exitCode == 0) {
        succeeded.add(entry.key);
      } else {
        failed.add(entry.key);
      }
      probePayloads.add(<String, Object?>{
        'capability': entry.key,
        'command': result.command,
        'exitCode': result.exitCode,
        'packagePath': entry.value.packagePath,
        'plainName': entry.value.plainName,
        'testPath': entry.value.testPath,
      });
    }
    return ItemSystemExecutionReceipt.record(
      level: ItemSystemProofLevel.playerUxL4,
      sourceRevision: sourceRevision,
      fixtureSha256: fixtureSha256,
      payload: <String, Object?>{'probes': probePayloads},
      attemptedCapabilities: probes.keys,
      succeededCapabilities: succeeded,
      failedCapabilities: failed,
      producer: 'item-system-player-evidence-collector',
      runnerVersion: '1.0.0',
      recordedAtUtc: recordedAtUtc,
    );
  }

  Future<_PlayerEvidenceProbeResult> _runProbe(
    Directory repositoryRootDirectory,
    _PlayerEvidenceProbe probe,
  ) async {
    final command = <String>[
      'flutter',
      'test',
      probe.testPath,
      '--plain-name',
      probe.plainName,
      '--reporter',
      'compact',
    ];
    final result = await Process.run(
      command.first,
      command.skip(1).toList(growable: false),
      workingDirectory: '${repositoryRootDirectory.path}/${probe.packagePath}',
    );
    return _PlayerEvidenceProbeResult(
      command: command,
      exitCode: result.exitCode,
    );
  }
}

final class _PlayerEvidenceProbe {
  const _PlayerEvidenceProbe({
    required this.packagePath,
    required this.testPath,
    required this.plainName,
  });

  final String packagePath;
  final String testPath;
  final String plainName;
}

final class _PlayerEvidenceProbeResult {
  const _PlayerEvidenceProbeResult({
    required this.command,
    required this.exitCode,
  });

  final List<String> command;
  final int exitCode;
}
