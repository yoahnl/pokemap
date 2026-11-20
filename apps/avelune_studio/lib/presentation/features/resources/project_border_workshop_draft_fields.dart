import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/application/border_workshop_draft_input.dart';
import 'project_border_workshop_preview.dart';

class ProjectBorderWorkshopDraftFields extends StatelessWidget {
  const ProjectBorderWorkshopDraftFields({
    super.key,
    required this.input,
    required this.models,
    required this.enabled,
    required this.awaitingRecovery,
    required this.reopenRequired,
    required this.onChange,
    this.onSave,
    this.onPublish,
    this.onReconcile,
    this.status,
    this.problem,
  });

  final BorderWorkshopDraftInput input;
  final List<ProjectModel3dEntry> models;
  final bool enabled;
  final bool awaitingRecovery, reopenRequired;
  final void Function(VoidCallback change) onChange;
  final VoidCallback? onSave, onPublish, onReconcile;
  final String? status, problem;

  @override
  Widget build(BuildContext context) {
    final names = {for (final model in models) model.id: model.name};
    return StudioPanel(
      title: 'Réglages du brouillon',
      icon: Icons.tune,
      children: [
        Wrap(
          spacing: StudioSpacing.m,
          runSpacing: StudioSpacing.s,
          children: [
            if (awaitingRecovery) ...[
              if (!reopenRequired)
                StudioButton(
                  label: 'Relire l’enregistrement',
                  icon: Icons.refresh,
                  onPressed: onReconcile,
                ),
            ] else ...[
              StudioButton(
                label: 'Enregistrer le brouillon',
                icon: Icons.save_outlined,
                onPressed: onSave,
              ),
              StudioButton(
                label: 'Publier le brouillon',
                icon: Icons.publish_outlined,
                onPressed: onPublish,
                variant: StudioButtonVariant.secondary,
              ),
            ],
          ],
        ),
        if (status case final message?) ...[
          const SizedBox(height: StudioSpacing.s),
          Semantics(liveRegion: true, child: Text(message)),
        ],
        if (problem case final message?) ...[
          const SizedBox(height: StudioSpacing.s),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        if (input.hasChanges && enabled) ...[
          const SizedBox(height: StudioSpacing.s),
          const Text(
            'Enregistrez le brouillon pour actualiser le tracé d’essai.',
          ),
        ],
        const SizedBox(height: StudioSpacing.l),
        StudioDraftField(
          key: const ValueKey('border-draft-name'),
          value: input.name,
          onChanged: (name) => onChange(() => input.name = name),
          label: 'Nom du brouillon',
          enabled: enabled,
          errorText: input.nameError,
        ),
        const SizedBox(height: StudioSpacing.xl),
        Text(
          'Pièces du brouillon',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: StudioSpacing.s),
        const Text('Un poids de 0 désactive une variante.'),
        for (final piece in input.original.definition.primitives) ...[
          const Divider(height: StudioSpacing.xl),
          _piece(
            context,
            piece,
            names[piece.sourceModelId] ?? 'Modèle introuvable',
          ),
        ],
      ],
    );
  }

  Widget _piece(
    BuildContext context,
    BorderPrimitiveDraft piece,
    String model,
  ) {
    final role = borderWorkshopRoleLabel(piece.role);
    final info = [
      role,
      if (input.original.definition.sequenceLength > 1)
        'Étape ${piece.sequenceIndex + 1}',
      if (piece.cornerTurn case final turn?)
        turn == BorderCornerTurn.left ? 'Rentrant' : 'Sortant',
      ?_direction(piece.authoredOrientation),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(model, style: Theme.of(context).textTheme.titleSmall),
        Text(info, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: StudioSpacing.m),
        Wrap(
          spacing: StudioSpacing.l,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 160,
              child: StudioDraftField(
                key: ValueKey('border-draft-weight-${piece.id}'),
                value: input.weightText(piece),
                onChanged: (value) =>
                    onChange(() => input.weights[piece.id] = value),
                label: 'Poids de sélection',
                enabled: enabled,
                keyboardType: TextInputType.number,
                errorText: input.weight(piece) == null
                    ? 'Entre 0 et 1 000.'
                    : null,
              ),
            ),
            SizedBox(
              width: 230,
              child: StudioToggleRow(
                key: ValueKey('border-draft-collision-${piece.id}'),
                label: 'Bloque le passage',
                value: input.collision(piece),
                onChanged: enabled
                    ? (value) =>
                          onChange(() => input.collisions[piece.id] = value)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String? _direction(BorderPrimitiveOrientation orientation) =>
    switch (orientation) {
      BorderPrimitiveOrientation.legacyAxis => null,
      BorderPrimitiveOrientation.east => 'Est',
      BorderPrimitiveOrientation.south => 'Sud',
      BorderPrimitiveOrientation.west => 'Ouest',
      BorderPrimitiveOrientation.north => 'Nord',
    };
