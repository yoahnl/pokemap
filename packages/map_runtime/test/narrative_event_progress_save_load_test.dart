import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
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
    });

    test('old GameState without progress loads an empty V2 namespace',
        () async {
      final json = const GameState(saveId: 'old_save').toJson()
        ..remove('narrativeEventProgress');
      await File(repository.path).writeAsString(jsonEncode(json));

      final loaded = await repository.load();

      expect(
          loaded?.narrativeEventProgress, const NarrativeEventProgress.empty());
      expect(loaded?.consumedEventIds, isEmpty);
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
