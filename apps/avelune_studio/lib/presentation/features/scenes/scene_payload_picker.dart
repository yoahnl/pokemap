import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';

Future<SceneNodePayload?> chooseScenePayload(
  BuildContext context,
  SceneNodeKind kind,
  ProjectManifest project,
) => showDialog<SceneNodePayload>(
  context: context,
  builder: (context) {
    final choices = <String, (String, SceneNodePayload)>{
      if (kind == SceneNodeKind.yarnDialogue)
        for (final d in project.dialogues)
          d.id: (
            d.name,
            SceneYarnDialoguePayload(
              dialogueId: d.id,
              yarnNodeName: d.defaultStartNode,
              expectedOutcomes: d.declaredOutcomes.map((o) => o.id).toList(),
            ),
          ),
      if (kind == SceneNodeKind.cinematic)
        for (final c in project.cinematics)
          c.id: (c.title, SceneCinematicPayload(cinematicId: c.id)),
      if (kind == SceneNodeKind.presentationCinematic)
        for (final c in project.presentationCinematics)
          c.id: (
            c.title,
            ScenePresentationCinematicPayload(presentationCinematicId: c.id),
          ),
      if (kind == SceneNodeKind.battle)
        for (final t in project.trainers)
          t.id: (
            t.name,
            SceneBattlePayload(trainerId: t.id, battleKind: 'trainer'),
          ),
    };
    return AlertDialog(
      title: Text(
        kind == SceneNodeKind.action
            ? 'Configurer une action'
            : 'Choisir le document',
      ),
      content: SizedBox(
        width: 440,
        height: 400,
        child: SingleChildScrollView(
          child: kind == SceneNodeKind.action
              ? SceneActionForm(
                  project: project,
                  current: null,
                  onApply: (payload) => Navigator.pop(context, payload),
                )
              : Column(
                  children: [
                    if (choices.isEmpty)
                      const Text(
                        'Aucun document disponible dans ce catalogue. Créez-le depuis son parcours existant.',
                      ),
                    for (final choice in choices.entries)
                      StudioChoice(
                        label: choice.value.$1,
                        subtitle: choice.key,
                        onTap: () => Navigator.pop(context, choice.value.$2),
                      ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  },
);
