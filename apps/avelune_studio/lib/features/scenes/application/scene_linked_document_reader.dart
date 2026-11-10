import 'package:map_core/map_core_domain.dart';

import '../../dialogues/application/dialogue_workspace_controller.dart';
import '../../dialogues/application/dialogue_working_source.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../../narrative/domain/narrative_port.dart';

class SceneLinkedDocumentReader {
  DialogueWorkspaceController? dialogues;
  final _dialogues = <Object, Future<NarrativeDialogueSource>>{};
  final _compiled = <String, RuntimeDialogueDocument>{};

  Future<RuntimeDialogueDocument> readDialogueDocument(
    String dialogueId,
    ProjectManifest project,
    NarrativeWorkspaceController? narrative,
  ) async {
    if (narrative == null) {
      throw StateError('La source du dialogue est indisponible.');
    }
    final workspace = narrative.workspace;
    final working = resolveDialogueWorkingSource(
      narrative: narrative,
      dialogueId: dialogueId,
      dialogues: dialogues,
    );
    if (working.problem case final problem?) throw StateError(problem);
    var source = working.source;
    if (source == null) {
      final entry = project.dialogues
          .where((entry) => entry.id == dialogueId)
          .firstOrNull;
      if (entry == null) throw StateError('Le document est introuvable.');
      final key = (narrative.workspace, project, entry);
      source = await _dialogues.putIfAbsent(
        key,
        () => narrative.port.readDialogue(entry),
      );
      if (narrative.workspace != workspace) {
        throw StateError('Le projet a changé pendant la lecture du dialogue.');
      }
      final latest = resolveDialogueWorkingSource(
        narrative: narrative,
        dialogueId: dialogueId,
        dialogues: dialogues,
      );
      if (latest.problem case final problem?) throw StateError(problem);
      source = latest.source ?? source;
    }
    final text = source.source;
    return _compiled.putIfAbsent(
      text,
      () => const YarnDialogueCompiler().compile(text),
    );
  }

  Future<NarrativeDialogueSource> readSource(
    Object identity,
    Future<NarrativeDialogueSource> Function() load,
  ) => _dialogues.putIfAbsent(identity, load);

  RuntimeDialogueDocument compileSource(String source) => _compiled.putIfAbsent(
    source,
    () => const YarnDialogueCompiler().compile(source),
  );
}

({String start, RuntimeDialogueNode? node}) selectLinkedDialogueStart(
  NarrativeDialogueSource source,
  RuntimeDialogueDocument document,
  String? requested,
) {
  final start =
      requested ?? source.entry.defaultStartNode ?? document.nodes.first.title;
  return (
    start: start,
    node: document.nodes.where((node) => node.title == start).firstOrNull,
  );
}
