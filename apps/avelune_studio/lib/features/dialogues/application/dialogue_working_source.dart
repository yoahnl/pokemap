import '../../narrative/application/dialogue_draft_codec.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../../narrative/domain/narrative_port.dart';
import 'dialogue_workspace_controller.dart';

class DialogueWorkingSource {
  const DialogueWorkingSource({this.source, this.dirty = false, this.problem});
  final NarrativeDialogueSource? source;
  final bool dirty;
  final String? problem;
}

DialogueWorkingSource resolveDialogueWorkingSource({
  required NarrativeWorkspaceController narrative,
  required String dialogueId,
  DialogueWorkspaceController? dialogues,
}) {
  final full = identical(dialogues?.narrative, narrative)
      ? dialogues?.session(dialogueId)
      : null;
  final candidates = <DialogueWorkingSource>[
    if (full != null)
      DialogueWorkingSource(
        source: NarrativeDialogueSource(
          entry: full.entry,
          source: full.source,
          revision: full.sourceRevision,
        ),
        dirty: full.dirty,
      ),
    for (final s in narrative.sessions.values)
      if (s.current.dialogue.entry.id == dialogueId)
        DialogueWorkingSource(
          dirty: s.dirty,
          source: s.readOnlySource == null
              ? const DialogueDraftCodec().encode(s.current.dialogue)
              : NarrativeDialogueSource(
                  entry: s.current.dialogue.entry,
                  source: s.readOnlySource!,
                ),
        ),
  ];
  final modified = candidates.where((c) => c.dirty).toList();
  final relevant = modified.isEmpty ? candidates : modified;
  if (relevant.isEmpty) return const DialogueWorkingSource();
  if (modified.length > 1 &&
      modified.any(
        (c) =>
            c.source!.entry != modified[0].source!.entry ||
            c.source!.source != modified[0].source!.source,
      )) {
    return const DialogueWorkingSource(
      dirty: true,
      problem:
          'Plusieurs brouillons incompatibles de ce dialogue sont ouverts. Reprenez leur éditeur propriétaire pour enregistrer ou abandonner explicitement une version.',
    );
  }
  if (modified.isNotEmpty) return modified[0];
  if (full != null) return candidates[0];
  if (relevant.any(
    (c) =>
        c.source!.entry != relevant[0].source!.entry ||
        c.source!.source != relevant[0].source!.source,
  )) {
    return const DialogueWorkingSource(
      problem:
          'Les sessions de ce dialogue ne décrivent pas la même source. Rechargez explicitement son éditeur avant de poursuivre.',
    );
  }
  return relevant[0];
}
