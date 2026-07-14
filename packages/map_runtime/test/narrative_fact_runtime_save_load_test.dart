import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Narrative Fact runtime save load', () {
    late Directory directory;
    late _FactSaveRepository repository;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('fact_save_test_');
      repository = _FactSaveRepository(directory);
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('preserves explicit false true and orphan overrides', () async {
      final original = GameState(
        saveId: 'fact_runtime',
        storyFlags: const StoryFlags(activeFlags: {'legacy_flag'}),
        consumedEventIds: const {'legacy_event'},
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {
            'fact_default_true': false,
            'fact_orphan': true,
          },
        ),
      );

      await repository.save(original);
      final loaded = await repository.load();

      expect(loaded, isNotNull);
      expect(loaded!.narrativeFactRuntimeState,
          original.narrativeFactRuntimeState);
      expect(loaded.storyFlags, original.storyFlags);
      expect(loaded.consumedEventIds, original.consumedEventIds);

      final file = File(await repository.filePath());
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final runtimeState =
          json['narrativeFactRuntimeState'] as Map<String, dynamic>;
      final overrides =
          runtimeState['overridesByFactId'] as Map<String, dynamic>;
      expect(overrides['fact_default_true'], isFalse);
      expect(overrides['fact_orphan'], isTrue);
    });

    test('loads old disk JSON with an empty Fact runtime state', () async {
      final file = File(await repository.filePath());
      await file.writeAsString(jsonEncode({
        'saveId': 'legacy_runtime',
        'storyFlags': {
          'activeFlags': ['legacy_flag'],
        },
      }));

      final loaded = await repository.load();

      expect(loaded, isNotNull);
      expect(loaded!.narrativeFactRuntimeState.overridesByFactId, isEmpty);
      expect(loaded.storyFlags.activeFlags, {'legacy_flag'});
    });

    test('keeps explicit false after canonical write save and reload',
        () async {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          defaultValue: true,
          legacyFlagName: 'legacy_gate',
        ),
      ]);
      final written = NarrativeFactRuntimeWriter(resolver).setFact(
        gameState: const GameState(
          saveId: 'fact_false_disk',
          storyFlags: StoryFlags(activeFlags: {'legacy_gate'}),
          progression: PlayerProgression(storyFlags: ['legacy_gate']),
        ),
        factId: 'fact_gate',
        value: false,
      );

      await repository.save(written.gameState);
      final loaded = await repository.load();
      final resolved = resolver.resolve(
        factId: 'fact_gate',
        runtimeState: loaded!.narrativeFactRuntimeState,
        storyFlags: loaded.storyFlags,
      ) as NarrativeFactRuntimeResolved;

      expect(resolved.value, isFalse);
      expect(
        resolved.source,
        NarrativeFactRuntimeValueSource.explicitOverride,
      );
      expect(loaded.storyFlags.activeFlags, isNot(contains('legacy_gate')));
      expect(
        loaded.progression.storyFlags,
        isNot(contains('legacy_gate')),
      );
    });
  });
}

final class _FactSaveRepository extends FileGameSaveRepository {
  _FactSaveRepository(this.directory);

  final Directory directory;

  Future<String> filePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final saveDirectory = Directory('${directory.path}/pokemonProject');
    if (!await saveDirectory.exists()) {
      await saveDirectory.create(recursive: true);
    }
    return '${saveDirectory.path}/game_save.json';
  }
}
