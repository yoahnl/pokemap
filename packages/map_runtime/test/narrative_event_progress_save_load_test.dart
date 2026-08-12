import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/domain/repositories/game_save_repository.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/infrastructure/file_game_save_repository.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000001';
const _deliveryId = 'outd_019abcde-0000-7000-8000-000000000001';
const _correlationId = 'corr_019abcde-0000-7000-8000-000000000001';

void main() {
  group('Narrative Event progress save/load', () {
    late Directory directory;
    late _TestFileGameSaveRepository repository;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('f1_progress_save_');
      repository = _TestFileGameSaveRepository(
        directory,
        NarrativeRuntimeActivityGate(),
      );
    });

    tearDown(() async {
      await directory.delete(recursive: true);
    });

    test('persists consumed IDs and pending delivery unchanged', () async {
      final delivery = _delivery();
      final state = GameState(
        saveId: 'save_f1',
        consumedEventIds: const {'legacy_event'},
        narrativeEventProgress: NarrativeEventProgress(
          consumedNarrativeEventIds: const {_eventId},
          pendingNarrativeOutcomeDeliveries: [delivery],
          activeNarrativeMapId: 'map_port',
          visitedNarrativeMapIds: const {'map_port', 'map_forest'},
          appliedNarrativeResetTokens: const [
            'map:activation-1',
            'outcome:delivery-1',
          ],
        ),
      );

      await repository.save(state);
      final loaded = await repository.load();

      expect(loaded?.consumedEventIds, {'legacy_event'});
      expect(loaded?.narrativeEventProgress.consumedNarrativeEventIds, {
        _eventId,
      });
      expect(
        loaded?.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        [delivery],
      );
      expect(loaded?.narrativeEventProgress.activeNarrativeMapId, 'map_port');
      expect(loaded?.narrativeEventProgress.visitedNarrativeMapIds,
          {'map_port', 'map_forest'});
      expect(loaded?.narrativeEventProgress.appliedNarrativeResetTokens, [
        'map:activation-1',
        'outcome:delivery-1',
      ]);
    });

    test('old GameState without strict Item schema is rejected', () async {
      final json = const GameState(saveId: 'old_save').toJson()
        ..remove('narrativeEventProgress');
      await File(repository.path).writeAsString(jsonEncode(json));

      await expectLater(
        repository.load,
        throwsA(
          isA<GameSaveException>().having(
            (error) => error.message,
            'message',
            contains('UnsupportedSaveSchema'),
          ),
        ),
      );
    });
  });
}

NarrativeOutcomeDelivery _delivery() => NarrativeOutcomeDelivery(
      deliveryId: _deliveryId,
      outcome: NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_f1',
        outcomeId: 'success',
      ),
      causationExecutionId: 'evx_019abcde-0000-7000-8000-000000000001',
      rootCorrelationId: _correlationId,
      depth: 0,
      attemptCount: 0,
    );

final class _TestFileGameSaveRepository extends FileGameSaveRepository {
  _TestFileGameSaveRepository(
    this.directory,
    NarrativeRuntimeActivityGate gate,
  ) : super(activityGate: gate);

  final Directory directory;
  String get path => '${directory.path}/game_save.json';

  @override
  Future<String> getSaveFilePath() async => path;
}
