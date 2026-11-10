import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../../features/scenes/application/scene_action_draft.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import 'scene_actor_action_form.dart';
import 'scene_world_visual_action_form.dart';
import 'scene_npc_pose_action_form.dart';
import 'scene_pokemon_gift_moves_editor.dart';
import 'scene_image_puzzle_form.dart';

class SceneActionForm extends StatefulWidget {
  const SceneActionForm({
    super.key,
    required this.project,
    required this.current,
    required this.onApply,
    this.loadMap,
    this.loadMoves,
    this.loadItems,
    this.loadSpecies,
    this.loadVisualMedia,
    this.commandCatalog,
  });

  final ProjectManifest project;
  final SceneNodePayload? current;
  final ValueChanged<SceneNodePayload> onApply;
  final Future<MapData> Function(String)? loadMap;
  final Future<Map<String, String>> Function()? loadMoves;
  final Future<Map<String, String>> Function()? loadItems;
  final Future<List<PokemonSpeciesSummary>> Function()? loadSpecies;
  final Future<ProjectMediaCatalog> Function()? loadVisualMedia;
  @visibleForTesting
  final List<NarrativeCommandDescriptor>? commandCatalog;

  @override
  State<SceneActionForm> createState() => _SceneActionFormState();
}

class _SceneActionFormState extends State<SceneActionForm> {
  late final SceneActionDraft draft;

  @override
  void initState() {
    super.initState();
    draft = SceneActionDraft(
      project: widget.project,
      current: widget.current,
      loadMap: widget.loadMap,
      loadMoves: widget.loadMoves,
      loadItems: widget.loadItems,
      loadSpecies: widget.loadSpecies,
      commandCatalog: widget.commandCatalog,
      changed: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didUpdateWidget(SceneActionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    draft.configure(
      project: widget.project,
      current: widget.current,
      loadMap: widget.loadMap,
      loadMoves: widget.loadMoves,
      loadItems: widget.loadItems,
      loadSpecies: widget.loadSpecies,
      commandCatalog: widget.commandCatalog,
    );
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (draft.unsupported)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: StudioNotice(
            'Cette action conserve des paramètres avancés. Choisir une autre commande puis appliquer la remplacera explicitement.',
          ),
        ),
      StudioSelect(
        label: 'Commande',
        value: draft.commandId,
        options: {
          for (final command in draft.commands) command.id: command.label,
        },
        onChanged: draft.commands.isEmpty ? null : draft.choose,
      ),
      if (draft.commands.isEmpty)
        const StudioNotice('Aucune commande disponible.'),
      if (draft.itemsLoading) const StudioNotice('Chargement des objets…'),
      if (draft.itemsError != null)
        StudioNotice(draft.itemsError!, isError: true),
      if (draft.commandId == NarrativeCommandIds.claimPeriodicReward)
        const StudioNotice(
          'Une remise par jour civil. Un sac plein ne consomme pas la récompense. Sorties : Reçu, Déjà reçu aujourd’hui, Sac plein, Indisponible.',
        ),
      if (draft.commandId == NarrativeCommandIds.whiteOut)
        const StudioNotice(
          'À la fin réussie de la Scene, l’équipe est soignée, la pénalité de défaite est appliquée et le joueur revient au point de reprise. Une seule récupération par Scene.',
        ),
      if (draft.isGift && draft.speciesLoading)
        const StudioNotice('Chargement des Pokémon…'),
      if (draft.isGift && draft.speciesError != null)
        StudioNotice(draft.speciesError!, isError: true),
      if (draft.referenceLoading)
        StudioNotice(
          draft.commandId == NarrativeCommandIds.warp
              ? 'Chargement des points d’arrivée…'
              : 'Chargement des décors de la carte…',
        ),
      if (draft.referenceError != null) ...[
        StudioNotice(draft.referenceError!, isError: true),
        StudioButton(
          label: 'Recharger la carte',
          secondary: true,
          onPressed: () => setState(draft.loadReferenceMap),
        ),
      ],
      if (draft.isActorCommand(draft.commandId))
        SceneActorActionForm(
          key: ValueKey(draft.commandId),
          project: widget.project,
          commandId: draft.commandId!,
          current: widget.current is SceneActionPayload
              ? widget.current as SceneActionPayload
              : null,
          loadMap: widget.loadMap,
          onApply: widget.onApply,
        ),
      if (draft.commandId == NarrativeCommandIds.openImagePuzzle)
        SceneImagePuzzleForm(
          key: ValueKey(draft.commandId),
          current:
              widget.current is SceneActionPayload &&
                  (widget.current as SceneActionPayload).interactiveCommand
                      is SceneOpenImagePuzzleInteractiveCommand
              ? (widget.current as SceneActionPayload).interactiveCommand
                    as SceneOpenImagePuzzleInteractiveCommand
              : null,
          loadVisualMedia: widget.loadVisualMedia,
          onApply: widget.onApply,
        ),
      if (draft.commandId == NarrativeCommandIds.worldPresentation)
        SceneWorldVisualActionForm(
          key: ValueKey(draft.commandId),
          current: widget.current is SceneActionPayload
              ? widget.current as SceneActionPayload
              : null,
          loadVisualMedia: widget.loadVisualMedia,
          onApply: widget.onApply,
        ),
      if (draft.commandId == NarrativeCommandIds.setNpcPose)
        SceneNpcPoseActionForm(
          project: widget.project,
          current: widget.current is SceneActionPayload
              ? widget.current as SceneActionPayload
              : null,
          loadMap: widget.loadMap,
          onApply: widget.onApply,
        ),
      if (draft.commandId == NarrativeCommandIds.sceneMusic)
        const StudioNotice(
          'La portée Scène restaure les canaux à sa fin. La portée Carte conserve les changements jusqu’au transfert. Le combat garde la priorité musicale et suspend l’ambiance sonore. La mémorisation conserve les pistes et volumes, sans leur position.',
        ),
      if (draft.commandId != NarrativeCommandIds.openImagePuzzle &&
          !draft.isActorCommand(draft.commandId) &&
          draft.commandId != NarrativeCommandIds.setNpcPose &&
          draft.commandId != NarrativeCommandIds.worldPresentation) ...[
        for (final parameter
            in draft.command?.parameters ??
                <NarrativeCommandParameterDescriptor>[])
          if (draft.warpFieldVisible(parameter))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _field(parameter),
            ),
        if (draft.error != null) StudioNotice(draft.error!, isError: true),
        const SizedBox(height: 12),
        StudioButton(
          label: widget.current == null
              ? 'Ajouter l’action'
              : 'Appliquer l’action',
          onPressed: !draft.valid
              ? null
              : () {
                  try {
                    widget.onApply(draft.buildPayload());
                  } catch (error) {
                    setState(
                      () => draft.error = 'Paramètres incompatibles : $error',
                    );
                  }
                },
        ),
      ],
    ],
  );

  Widget _field(NarrativeCommandParameterDescriptor parameter) {
    if (draft.isGift && parameter.id == 'moveIds') {
      return ScenePokemonGiftMovesEditor(
        key: ValueKey('gift-moves-${draft.commandId}'),
        value: draft.giftMoves,
        loadMoves: widget.loadMoves,
        catalogueScope: widget.project,
        onChanged: draft.setGiftMoves,
        onValidityChanged: draft.setGiftMovesValid,
      );
    }
    void changed(String value) => draft.changeParameter(parameter.id, value);
    if (parameter.kind == NarrativeCommandParameterKind.warpPresentationMode) {
      return StudioSelect(
        label: parameter.label,
        value: draft.values[parameter.id] ?? '',
        options: draft.options(parameter.kind),
        onChanged: changed,
      );
    }
    if (draft.commandId == NarrativeCommandIds.warp &&
        parameter.id == 'arrivalFacing') {
      return StudioSelect(
        label: parameter.label,
        value: draft.values[parameter.id] ?? '',
        options: {
          '': 'Conserver la direction',
          ...draft.options(parameter.kind),
        },
        onChanged: changed,
      );
    }
    if (draft.commandId == NarrativeCommandIds.warp &&
        parameter.id == 'transition') {
      return StudioSelect(
        label: parameter.label,
        value: draft.values[parameter.id] ?? 'mapDefault',
        options: draft.options(parameter.kind),
        onChanged: changed,
      );
    }
    if (parameter.id == 'blocksMovementAfter' &&
        draft.commandId == NarrativeCommandIds.playModelAnimation) {
      return StudioSelect(
        label: parameter.label,
        value: draft.values[parameter.id] ?? '',
        options: const {
          '': 'Conserver le passage actuel',
          'false': 'Laisser passer',
          'true': 'Bloquer le passage',
        },
        onChanged: changed,
      );
    }
    if (parameter.kind == NarrativeCommandParameterKind.integerFacts) {
      final selected = <String>{};
      try {
        selected.addAll(
          (jsonDecode(draft.values[parameter.id] ?? '[]') as List)
              .cast<String>(),
        );
      } catch (_) {}
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(parameter.label),
          for (final entry in draft.options(parameter.kind).entries)
            StudioToggleRow(
              key: ValueKey('scene-integer-fact-${entry.key}'),
              label: entry.value,
              value: selected.contains(entry.key),
              onChanged: (value) {
                final next = {...selected};
                value ? next.add(entry.key) : next.remove(entry.key);
                changed(jsonEncode(next.toList()));
              },
            ),
        ],
      );
    }
    if (parameter.kind == NarrativeCommandParameterKind.movingProps) {
      final selected = <String>{};
      try {
        selected.addAll(
          (jsonDecode(draft.values['propIds'] ?? '[]') as List).cast<String>(),
        );
      } catch (_) {}
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(parameter.label),
          if (draft.referenceLoading)
            const StudioNotice('Chargement des décors mobiles…'),
          if (draft.referenceError != null) StudioNotice(draft.referenceError!),
          if (!draft.referenceLoading &&
              draft.referenceError == null &&
              draft.movingProps.isEmpty)
            const StudioNotice(
              'Configurez les décors mobiles dans les propriétés des décors de cette carte.',
            ),
          for (final missing in selected.difference(
            draft.movingProps.keys.toSet(),
          )) ...[
            const StudioNotice(
              'Un décor sélectionné n’existe plus. Retirez-le de la sélection.',
            ),
            StudioButton(
              label: 'Retirer la référence absente',
              secondary: true,
              onPressed: () =>
                  changed(jsonEncode(selected.difference({missing}).toList())),
            ),
          ],
          for (final entry in draft.movingProps.entries)
            StudioToggleRow(
              key: ValueKey('scene-prop-${entry.key}'),
              label: entry.value,
              value: selected.contains(entry.key),
              onChanged: (value) {
                final next = {...selected};
                value ? next.add(entry.key) : next.remove(entry.key);
                changed(jsonEncode(next.toList()));
              },
            ),
        ],
      );
    }
    if (parameter.kind == NarrativeCommandParameterKind.boolean) {
      return StudioToggleRow(
        label: parameter.label,
        value: draft.values[parameter.id] == 'true',
        onChanged: (value) => changed('$value'),
      );
    }
    if (parameter.kind == NarrativeCommandParameterKind.integer ||
        parameter.kind == NarrativeCommandParameterKind.number ||
        parameter.kind == NarrativeCommandParameterKind.text) {
      final presentation =
          draft.commandId == NarrativeCommandIds.wait ||
          draft.commandId == NarrativeCommandIds.worldTone ||
          draft.commandId == NarrativeCommandIds.playSoundEffect ||
          draft.commandId == NarrativeCommandIds.playMusicEffect ||
          draft.commandId == NarrativeCommandIds.sceneMusic;
      return StudioDraftField(
        key: ValueKey('action-${draft.commandId}-${parameter.id}'),
        label: parameter.label,
        value: draft.values[parameter.id] ?? '',
        onChanged: changed,
        helperText: presentation
            ? draft.presentationFieldHelp(parameter.id)
            : null,
        errorText: presentation
            ? draft.presentationFieldError(parameter.id)
            : null,
        keyboardType: parameter.kind == NarrativeCommandParameterKind.number
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : presentation &&
                  parameter.kind == NarrativeCommandParameterKind.integer
            ? TextInputType.number
            : null,
      );
    }
    final options = draft.options(parameter.kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          label: parameter.label,
          value: draft.values[parameter.id],
          options: options,
          onChanged: options.isEmpty ? null : changed,
        ),
        if (options.isEmpty)
          StudioNotice(
            'Aucune référence ${parameter.label.toLowerCase()} disponible dans ce contexte. Le contenu existant reste conservé.',
          ),
      ],
    );
  }
}
