import '../../../features/scenes/application/scene_actor_action_draft.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_tool.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_panel.dart';

class SceneActorActionForm extends StatefulWidget {
  const SceneActorActionForm({
    super.key,
    required this.project,
    required this.commandId,
    required this.current,
    required this.onApply,
    this.loadMap,
  });

  final ProjectManifest project;
  final String commandId;
  final SceneActionPayload? current;
  final ValueChanged<SceneNodePayload> onApply;
  final Future<MapData> Function(String)? loadMap;

  @override
  State<SceneActorActionForm> createState() => _SceneActorActionFormState();
}

class _SceneActorActionFormState extends State<SceneActorActionForm> {
  late final SceneActorActionDraft draft;
  @override
  void initState() {
    super.initState();
    draft = SceneActorActionDraft(
      project: widget.project,
      commandId: widget.commandId,
      current: widget.current,
      loadMap: widget.loadMap,
      changed: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didUpdateWidget(SceneActorActionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    draft.configure(
      project: widget.project,
      commandId: widget.commandId,
      current: widget.current,
      loadMap: widget.loadMap,
    );
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  void _submit() {
    if (draft.payload case final payload?) widget.onApply(payload);
  }

  Widget _initialOwnerField(SceneActorStepDraft step, int index) => Column(
    key: ValueKey('actor-step-${step.id}-owner'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioSelect(
        label: 'Personnage à quitter',
        value: draft.initialOwnerValue(step, index),
        options: draft.initialOwnerOptions(step, index),
        onChanged: (value) =>
            setState(() => draft.selectInitialOwner(step, value)),
      ),
      const StudioNotice(
        'Pour quitter la case occupée par ce personnage. Les autres obstacles restent bloquants.',
      ),
      if (draft.initialOwnerError(step, index) case final String error)
        StudioNotice(error, isError: true),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Carte de l’acteur',
        value: draft.selectedMapId,
        options: draft.mapOptions,
        onChanged: (value) => setState(() {
          draft.selectedMapId = value;
          draft.selectedEntityId = null;
          draft.reloadMap();
        }),
      ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Acteur',
        value: draft.targetKind.name,
        options: const {'player': 'Joueur', 'entity': 'PNJ de la carte'},
        onChanged: (value) => setState(() {
          draft.targetKind = SceneActorTargetKind.values.byName(value);
          draft.selectedEntityId = null;
        }),
      ),
      if (draft.loading)
        const StudioNotice('Chargement des acteurs de la carte…'),
      if (draft.mapError != null) ...[
        StudioNotice(draft.mapError!, isError: true),
        StudioButton(
          label: 'Recharger la carte',
          secondary: true,
          onPressed: () => setState(draft.reloadMap),
        ),
      ],
      if (draft.targetKind == SceneActorTargetKind.entity) ...[
        const SizedBox(height: 12),
        StudioSelect(
          label: 'PNJ',
          value: draft.selectedEntityId,
          options: draft.actorOptions,
          onChanged: draft.actorOptions.isEmpty
              ? null
              : (value) => setState(() => draft.selectedEntityId = value),
        ),
        if (!draft.loading &&
            draft.stageMap != null &&
            !draft.actorOptions.containsKey(draft.selectedEntityId))
          const StudioNotice(
            'Choisir un PNJ unique avec un personnage connu dans cette carte.',
            isError: true,
          ),
      ],
      if (draft.isRoute) ...[
        StudioSelect(
          label: 'Restauration des effets temporaires',
          value: draft.transientScope.name,
          options: const {
            'route': 'À la fin du trajet',
            'scene': 'À la fin de la scène',
          },
          onChanged: (value) => setState(
            () => draft.transientScope = ActorRouteTransientScope.values.byName(
              value,
            ),
          ),
        ),
        StudioNotice(
          draft.transientScope == ActorRouteTransientScope.scene
              ? 'La traversée, le premier plan, la visibilité et le graphisme sont conservés entre les trajets, puis rétablis à la fin de la scène. Le joueur conserve ces effets entre les cartes ; un PNJ reste lié à son instance de carte.'
              : 'La traversée, le premier plan, la visibilité et le graphisme sont rétablis à la fin de ce trajet.',
        ),
        StudioToggleRow(
          label: 'Continuer si un déplacement est bloqué',
          value: draft.skippable,
          description: 'Les déplacements bloqués sont ignorés ; les autres étapes restent exécutées.',
          onChanged: (value) => setState(() => draft.skippable = value),
        ),
        for (var index = 0; index < draft.steps.length; index++)
          _step(draft.steps[index], index),
        if (draft.steps.isEmpty)
          const StudioNotice(
            'Aucune étape : la route se termine immédiatement.',
          ),
        StudioButton(
          key: const ValueKey('actor-add-step'),
          label: 'Ajouter une étape',
          secondary: true,
          onPressed: () => setState(() => draft.addStep()),
        ),
      ] else
        StudioToggleRow(
          label: 'Acteur visible',
          value: draft.visible,
          description: 'Modifie uniquement son affichage ; ses collisions restent inchangées.',
          onChanged: (value) => setState(() => draft.visible = value),
        ),
      const SizedBox(height: 12),
      StudioButton(
        label: widget.current == null
            ? 'Ajouter l’action'
            : 'Appliquer l’action',
        onPressed: draft.valid ? _submit : null,
      ),
    ],
  );

  Widget _step(SceneActorStepDraft step, int index) => Padding(
    key: ValueKey('actor-step-${step.id}'),
    padding: const EdgeInsets.only(bottom: 16),
    child: StudioPanel(
      compact: true,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Étape ${index + 1}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            StudioTool(
              key: ValueKey('actor-step-${step.id}-up'),
              label: 'Monter l’étape ${index + 1}',
              icon: Icons.arrow_upward,
              onPressed: index == 0
                  ? null
                  : () => setState(() {
                      draft.moveStep(step, -1);
                    }),
            ),
            StudioTool(
              key: ValueKey('actor-step-${step.id}-down'),
              label: 'Descendre l’étape ${index + 1}',
              icon: Icons.arrow_downward,
              onPressed: index == draft.steps.length - 1
                  ? null
                  : () => setState(() {
                      draft.moveStep(step, 1);
                    }),
            ),
            StudioTool(
              key: ValueKey('actor-step-${step.id}-delete'),
              label: 'Supprimer l’étape ${index + 1}',
              icon: Icons.delete_outline,
              onPressed: () => setState(() => draft.removeStep(step)),
            ),
          ],
        ),
        StudioSelect(
          label: 'Action de l’étape ${index + 1}',
          value: step.kind.name,
          options: const {
            'face': 'Se tourner',
            'move': 'Avancer d’une case',
            'moveDiagonal': 'Avancer en diagonale',
            'wait': 'Attendre',
            'through': 'Traverser les obstacles',
            'renderAboveMap': 'Afficher au premier plan',
            'visibility': 'Afficher ou masquer',
            'appearance': 'Changer le graphisme',
            'sound': 'Jouer un son',
          },
          onChanged: (value) => setState(
            () => step.changeKind(SceneActorRouteStepKind.values.byName(value)),
          ),
        ),
        if (step.kind == SceneActorRouteStepKind.face ||
            step.kind == SceneActorRouteStepKind.move) ...[
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Direction de l’étape ${index + 1}',
            value: step.direction.name,
            options: const {
              'north': 'Nord',
              'south': 'Sud',
              'east': 'Est',
              'west': 'Ouest',
            },
            onChanged: (value) => setState(
              () => step.direction = EntityFacing.values.byName(value),
            ),
          ),
        ],
        if (step.kind == SceneActorRouteStepKind.moveDiagonal) ...[
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Direction horizontale de l’étape ${index + 1}',
            value: step.horizontal.name,
            options: const {'west': 'Ouest', 'east': 'Est'},
            onChanged: (value) => setState(
              () => step.horizontal = EntityFacing.values.byName(value),
            ),
          ),
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Direction verticale de l’étape ${index + 1}',
            value: step.vertical.name,
            options: const {'north': 'Nord', 'south': 'Sud'},
            onChanged: (value) => setState(
              () => step.vertical = EntityFacing.values.byName(value),
            ),
          ),
        ],
        if (step.hasDuration) ...[
          const SizedBox(height: 8),
          StudioDraftField(
            key: ValueKey('actor-step-${step.id}-duration'),
            value: step.durationText,
            label: step.kind == SceneActorRouteStepKind.face
                ? 'Maintien de la direction (ms)'
                : 'Durée (ms)',
            keyboardType: TextInputType.number,
            helperText: step.isMovement
                ? 'De 1 à 2147483647 ms.'
                : 'De 0 à 2147483647 ms.',
            errorText: step.durationValid
                ? null
                : 'Saisir une durée entière dans les limites indiquées.',
            onChanged: (value) => setState(() => step.durationText = value),
          ),
        ],
        if (step.kind == SceneActorRouteStepKind.face)
          StudioToggleRow(
            key: ValueKey('actor-step-${step.id}-yield'),
            label: 'Afficher la direction avant le maintien',
            description: 'Laisser un rafraîchissement du jeu avant de commencer la durée de maintien.',
            value: step.yieldAfter,
            onChanged: (value) => setState(() => step.yieldAfter = value),
          ),
        if (draft.canSelectInitialOwner(step, index) ||
            step.initialCollisionOwnerEntityId != null) ...[
          const SizedBox(height: 8),
          _initialOwnerField(step, index),
        ],
        if (step.kind == SceneActorRouteStepKind.through)
          StudioToggleRow(
            label: 'Traversée autorisée',
            value: step.enabled,
            onChanged: (value) => setState(() => step.enabled = value),
          ),
        if (step.kind == SceneActorRouteStepKind.renderAboveMap)
          StudioToggleRow(
            label: 'Acteur au premier plan',
            value: step.enabled,
            onChanged: (value) => setState(() => step.enabled = value),
          ),
        if (step.kind == SceneActorRouteStepKind.visibility)
          StudioToggleRow(
            label: 'Personnage visible',
            value: step.enabled,
            onChanged: (value) => setState(() => step.enabled = value),
          ),
        if (step.kind == SceneActorRouteStepKind.appearance)
          StudioSelect(
            label: 'Graphisme de l’étape ${index + 1}',
            value: step.characterId,
            options: draft.characterOptions,
            onChanged: draft.characterOptions.isEmpty
                ? null
                : (value) => setState(() => step.characterId = value),
          ),
        if (step.kind == SceneActorRouteStepKind.sound) ...[
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Son de l’étape ${index + 1}',
            value: step.soundId,
            options: draft.soundOptions,
            onChanged: draft.soundOptions.isEmpty
                ? null
                : (value) => setState(() => step.soundId = value),
          ),
          if (!draft.soundOptions.containsKey(step.soundId))
            const StudioNotice(
              'Choisir un son unique sans lecture en boucle.',
              isError: true,
            ),
          const SizedBox(height: 8),
          StudioDraftField(
            key: ValueKey('actor-step-${step.id}-gain'),
            label: 'Volume (0 à 1)',
            value: step.gainText,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: step.gainValid
                ? null
                : 'Saisir un volume fini entre 0 et 1.',
            onChanged: (value) => setState(() => step.gainText = value),
          ),
        ],
      ],
    ),
  );
}
