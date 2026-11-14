import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/player/runtime_player_journal_pause.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  group('journal pause detail', () {
    test('a project without journal data publishes no journal', () {
      final project = _project(withJournal: false);

      expect(
        buildPlayerJournalPauseDetail(
          project: project,
          state: _state(),
          locale: 'fr',
        ),
        isNull,
      );
    });

    test('milestone status follows the facts stored in the save', () {
      final opening = buildPlayerJournalPauseDetail(
        project: _project(),
        state: _state(),
        locale: 'fr',
      )!;

      expect(opening.section, RuntimePlayerPauseSection.quests);
      expect([for (final entry in opening.entries) entry.title], ['Le rival']);
      expect(opening.entries.single.trailingLabel, 'En cours');
      expect(opening.entries.single.body, 'Il attend au labo.');

      final later = buildPlayerJournalPauseDetail(
        project: _project(),
        state: _state(trueFacts: {'met_rival', 'saw_tracks'}),
        locale: 'en',
      )!;

      expect(
        [
          for (final entry in later.entries)
            '${entry.title}|${entry.trailingLabel}',
        ],
        ['The rival|Completed', 'Des traces au nord.|Clue'],
      );
    });

    test('a milestone recorded in the save is completed', () {
      final detail = buildPlayerJournalPauseDetail(
        project: _project(),
        state: _state(completedStepIds: ['m1']),
        locale: 'fr',
      )!;

      expect(detail.entries.single.trailingLabel, 'Terminé');
    });

    test('nothing to show yet keeps the journal unpublished', () {
      final cluesOnly = _project(withJournal: false).copyWith(
        storylines: [
          _project(withJournal: false).storylines.single.copyWith(
            journalClues: _project().storylines.single.journalClues,
          ),
        ],
      );

      expect(PlayerJournalCapabilities.requiresCapability(cluesOnly), isTrue);
      expect(
        buildPlayerJournalPauseDetail(
          project: cluesOnly,
          state: _state(),
          locale: 'fr',
        ),
        isNull,
      );
    });
  });

  group('pause menu journal entry', () {
    test('opens once a journal detail is published', () async {
      final harness = RuntimePlayerTestHarness();
      addTearDown(harness.dispose);
      await launchHarnessToPlaying(harness);
      harness.adapter.pauseDetails = {
        RuntimePlayerPauseSection.quests: buildPlayerJournalPauseDetail(
          project: _project(),
          state: _state(),
          locale: 'fr',
        )!,
      };
      await _openMenu(harness);

      expect(
        harness.coordinator.snapshot.isActionEnabled(
          RuntimePlayerAction.openQuests,
        ),
        isTrue,
      );
      final opened = await harness.coordinator.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.openQuests,
          snapshotRevision: harness.coordinator.snapshot.revision,
        ),
      );

      expect(opened.status, RuntimePlayerCommandStatus.accepted);
      expect(
        harness.coordinator.snapshot.pauseSection,
        RuntimePlayerPauseSection.quests,
      );
      expect(
        harness.coordinator.snapshot
            .pauseDetailFor(RuntimePlayerPauseSection.quests)
            ?.entries
            .single
            .title,
        'Le rival',
      );
    });
  });
}

Future<void> _openMenu(RuntimePlayerTestHarness harness) async {
  final result = await harness.coordinator.dispatch(
    RuntimePlayerCommand(
      action: RuntimePlayerAction.openMenu,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ),
  );
  expect(result.status, RuntimePlayerCommandStatus.accepted);
}

GameState _state({
  Set<String> trueFacts = const {},
  List<String> completedStepIds = const [],
}) {
  final writer = NarrativeFactRuntimeWriter(
    NarrativeFactRuntimeResolver.fromFacts(_project().facts),
  );
  var state = GameState(
    saveId: 'save',
    progression: PlayerProgression(completedStepIds: completedStepIds),
  );
  for (final fact in trueFacts) {
    state = writer
        .setFact(gameState: state, factId: fact, value: true)
        .gameState;
  }
  return state;
}

ProjectManifest _project({bool withJournal = true}) => ProjectManifest(
  name: 'Journal',
  maps: [],
  tilesets: [],
  facts: [
    NarrativeFactDefinition(id: 'met_rival', label: 'Rival'),
    NarrativeFactDefinition(id: 'saw_tracks', label: 'Traces'),
  ],
  storylines: [
    StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Trame',
      chapters: [
        StorylineChapter(
          id: 'c1',
          title: 'Un',
          order: 0,
          steps: [
            StorylineStep(
              id: 'm1',
              title: 'Rival',
              order: 0,
              completionCondition: ScriptConditionFactory.factEquals(
                'met_rival',
                const NarrativeValue.boolean(true),
              ),
              journal: withJournal
                  ? StorylineMilestoneJournal(
                      title: SceneLocalizedText(
                        fallback: 'Le rival',
                        translations: {'en': 'The rival'},
                      ),
                      text: SceneLocalizedText(fallback: 'Il attend au labo.'),
                    )
                  : null,
            ),
          ],
        ),
      ],
      journalClues: [
        if (withJournal)
          StorylineJournalClue(
            id: 'tracks',
            factId: 'saw_tracks',
            text: SceneLocalizedText(fallback: 'Des traces au nord.'),
          ),
      ],
    ),
  ],
);
