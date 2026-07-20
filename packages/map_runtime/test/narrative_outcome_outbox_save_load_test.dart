import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/infrastructure/file_game_save_repository.dart';

const _deliveryId = 'outd_019abcde-0000-7000-8000-000000000010';

void main() {
  test('pending and terminal outbox states survive separate reloads', () async {
    final directory = await Directory.systemTemp.createTemp('f1_outbox_save_');
    addTearDown(() => directory.delete(recursive: true));
    final repository = _TestFileGameSaveRepository(
      directory,
      NarrativeRuntimeActivityGate(),
    );
    final delivery = NarrativeOutcomeDelivery(
      deliveryId: _deliveryId,
      outcome: NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: 'battle_f1',
        outcomeId: 'victory',
      ),
      rootCorrelationId: 'corr_019abcde-0000-7000-8000-000000000010',
      depth: 2,
      attemptCount: 1,
    );

    await repository.save(
      GameState(
        saveId: 'save_f1',
        narrativeEventProgress: NarrativeEventProgress(
          pendingNarrativeOutcomeDeliveries: [delivery],
        ),
      ),
    );
    final pendingReload = await repository.load();
    expect(
      pendingReload?.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
      [delivery],
    );

    await repository.save(
      GameState(
        saveId: 'save_f1',
        narrativeEventProgress: NarrativeEventProgress(
          deliveredNarrativeOutcomeDeliveryIds: const {_deliveryId},
        ),
      ),
    );
    final terminalReload = await repository.load();
    expect(
      terminalReload?.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
      isEmpty,
    );
    expect(
      terminalReload
          ?.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
      {_deliveryId},
    );

    var replayCalls = 0;
    final processor = NarrativeOutcomeOutboxProcessor(
      stateTransactions: NarrativeEventStateTransactions(terminalReload!),
      activityPort: NoopNarrativeEventActivityPort(),
      dispatcher: (_) async {
        replayCalls++;
        return NarrativeOutcomeDispatchResult.delivered(
          updatedGameState: terminalReload,
        );
      },
      deliveryIdFactory: () => 'outd_unused',
    );

    expect(await processor.processNext(), isA<NarrativeOutcomeOutboxEmpty>());
    expect(replayCalls, 0);
  });
}

final class _TestFileGameSaveRepository extends FileGameSaveRepository {
  _TestFileGameSaveRepository(
    this.directory,
    NarrativeRuntimeActivityGate gate,
  ) : super(activityGate: gate);

  final Directory directory;

  @override
  Future<String> getSaveFilePath() async => '${directory.path}/game_save.json';
}
