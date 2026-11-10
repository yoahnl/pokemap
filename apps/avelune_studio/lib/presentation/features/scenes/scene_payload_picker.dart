import 'package:flutter/material.dart';

import '../../../features/scenes/application/scene_edit_session.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';

import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';

Future<SceneNodePayload?> chooseScenePayload(
  BuildContext context,
  SceneNodeKind kind,
  ProjectManifest project, {
  Future<MapData> Function(String)? loadMap,
  Future<Map<String, String>> Function()? loadMoves,
  Future<Map<String, String>> Function()? loadItems,
  Future<List<PokemonSpeciesSummary>> Function()? loadSpecies,
  Future<ProjectMediaCatalog> Function()? loadVisualMedia,
}) => showDialog<SceneNodePayload>(
  context: context,
  builder: (context) {
    final choices = scenePayloadChoices(project, kind);
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
                  loadMap: loadMap,
                  loadMoves: loadMoves,
                  loadItems: loadItems,
                  loadSpecies: loadSpecies,
                  loadVisualMedia: loadVisualMedia,
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
