import 'package:flutter/material.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import '../../../features/dialogues/application/dialogue_working_source.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';

part 'scene_linked_cinematic.dart';

class SceneLinkedDocuments {
  DialogueWorkspaceController? dialogues;
  final _dialogues = <Object, Future<NarrativeDialogueSource>>{};
  final _compiled = <String, RuntimeDialogueDocument>{};

  Future<void> open(
    BuildContext context,
    SceneNode node,
    ProjectManifest project,
    NarrativeWorkspaceController? narrative,
  ) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(node.title ?? 'Document lié'),
      content: SizedBox(
        width: 580,
        height: 420,
        child: SingleChildScrollView(
          child: switch (node.payload) {
            SceneYarnDialoguePayload payload => dialoguePreview(
              payload,
              project,
              narrative,
              detailed: true,
            ),
            _ => _cinematic(node, project),
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour à la scène'),
        ),
      ],
    ),
  );

  Widget dialoguePreview(
    SceneYarnDialoguePayload payload,
    ProjectManifest project,
    NarrativeWorkspaceController? narrative, {
    bool detailed = false,
    ValueChanged<String>? onStartChanged,
  }) {
    if (narrative != null) {
      final working = resolveDialogueWorkingSource(
        narrative: narrative,
        dialogueId: payload.dialogueId,
        dialogues: dialogues,
      );
      if (working.problem case final problem?) {
        return StudioNotice(problem, isError: true);
      }
      if (working.source case final source?) {
        return _source(
          source,
          payload.yarnNodeName,
          working.dirty,
          detailed: detailed,
          onStartChanged: onStartChanged,
        );
      }
    }
    final entry = project.dialogues
        .where((entry) => entry.id == payload.dialogueId)
        .firstOrNull;
    if (entry == null || narrative == null) {
      return const StudioNotice(
        'Dialogue indisponible. Sa référence est conservée.',
        isError: true,
      );
    }
    final key = (narrative.workspace, project, entry);
    return FutureBuilder<NarrativeDialogueSource>(
      key: ValueKey(key),
      future: _dialogues.putIfAbsent(
        key,
        () => narrative.port.readDialogue(entry),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return StudioNotice(
            'Lecture impossible : ${snapshot.error}',
            isError: true,
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Chargement du dialogue…'),
          );
        }
        return _source(
          snapshot.data!,
          payload.yarnNodeName,
          false,
          detailed: detailed,
          onStartChanged: onStartChanged,
        );
      },
    );
  }

  Widget _source(
    NarrativeDialogueSource source,
    String? start,
    bool dirty, {
    required bool detailed,
    ValueChanged<String>? onStartChanged,
  }) {
    RuntimeDialogueDocument compiled;
    try {
      compiled = _compiled.putIfAbsent(
        source.source,
        () => const YarnDialogueCompiler().compile(source.source),
      );
    } catch (error) {
      return StudioNotice(
        'Aperçu indisponible : $error. Le document original est conservé.',
        isError: true,
      );
    }
    final selectedStart =
        start ?? source.entry.defaultStartNode ?? compiled.nodes.first.title;
    final selected = compiled.nodes
        .where((node) => node.title == selectedStart)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (detailed)
          Text(
            source.entry.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        Text(
          dirty
              ? 'Aperçu du brouillon partagé · non enregistré'
              : 'Document exact · lecture seule',
        ),
        const SizedBox(height: 12),
        if (onStartChanged != null)
          StudioSelect(
            label: 'Départ du dialogue',
            value: selectedStart,
            options: {
              for (final node in compiled.nodes) node.title: node.title,
            },
            onChanged: onStartChanged,
          )
        else
          Text('Départ : $selectedStart'),
        if (selected == null)
          const StudioNotice(
            'Le point de départ référencé est absent du dialogue.',
            isError: true,
          ),
        for (final node in detailed ? compiled.nodes : [?selected]) ...[
          const SizedBox(height: 12),
          if (detailed)
            Text(
              node.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          for (final step in detailed ? node.steps : node.steps.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: switch (step) {
                RuntimeDialogueLine(:final text) => Text(
                  text,
                  maxLines: detailed ? null : 4,
                  overflow: detailed ? null : TextOverflow.ellipsis,
                ),
                RuntimeDialogueJump(:final targetNode) => Text(
                  'Continuer vers $targetNode',
                ),
                RuntimeDialogueChoiceBlock(:final choices) => Text(
                  choices.map((choice) => '→ ${choice.text}').join('\n'),
                ),
              },
            ),
        ],
        if (detailed)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Cet aperçu ne modifie pas le dialogue. L’édition de son contenu reste dans le parcours existant.',
            ),
          ),
      ],
    );
  }
}
