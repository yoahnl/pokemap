import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_player_pause_data.dart';

RuntimePlayerPauseDetailSnapshot? buildPlayerJournalPauseDetail({
  required ProjectManifest project,
  required GameState state,
  required String locale,
}) {
  if (!PlayerJournalCapabilities.requiresCapability(project)) return null;
  final context = ScriptEvaluationContext(
    narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts(
      project.facts,
    ),
  );
  final journal = projectPlayerJournal(
    project: project,
    gameState: state,
    locale: locale,
    isConditionTrue: (condition) => const ScriptConditionEvaluator().evaluate(
      condition,
      state,
      context: context,
    ),
  );
  if (journal.isEmpty) return null;
  final french = locale.toLowerCase().startsWith('fr');
  return RuntimePlayerPauseDetailSnapshot(
    section: RuntimePlayerPauseSection.quests,
    title: 'Journal',
    entries: [
      for (final entry in journal.entries)
        RuntimePlayerDetailEntrySnapshot(
          id: entry.id,
          title: entry.title,
          trailingLabel: _statusLabel(entry.kind, french: french),
          body: entry.text,
        ),
    ],
  );
}

String _statusLabel(PlayerJournalEntryKind kind, {required bool french}) =>
    switch (kind) {
      PlayerJournalEntryKind.inProgress => french ? 'En cours' : 'In progress',
      PlayerJournalEntryKind.completed => french ? 'Terminé' : 'Completed',
      PlayerJournalEntryKind.clue => french ? 'Indice' : 'Clue',
    };
