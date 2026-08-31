import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_authoring_controller.dart';
import '../../application/smart_tile_form_projection.dart';

class SmartTileVariantsStage extends StatelessWidget {
  const SmartTileVariantsStage({
    super.key,
    required this.usage,
    required this.transformPolicy,
    required this.currentTransformPolicy,
    required this.allowedTransforms,
    required this.topology,
    required this.transformProposal,
    required this.animations,
    required this.selectedAnimationFrames,
    required this.animationNameController,
    required this.animationDurationController,
    required this.atlasPreview,
    required this.onTransformPolicyChanged,
    required this.onAcceptTransformProposal,
    required this.onDiscardTransformProposal,
    required this.onAnimationNameChanged,
    required this.onAnimationDurationChanged,
    required this.onRemoveAnimationFrame,
    required this.onClearAnimationFrames,
    required this.onCreateAnimation,
    required this.onContinue,
    required this.showAdvancedSettings,
    required this.onToggleAdvancedSettings,
  });

  final SmartTileUsage usage;

  final SmartTileTransformPolicy transformPolicy;
  final SmartTileTransformPolicy currentTransformPolicy;
  final List<SmartTileSpriteTransform> allowedTransforms;
  final SmartTileTopology topology;
  final SmartTileTransformProposal? transformProposal;
  final List<ProjectSmartTileAnimation> animations;
  final List<SmartTileFrameRef> selectedAnimationFrames;
  final TextEditingController animationNameController;
  final TextEditingController animationDurationController;
  final Widget atlasPreview;
  final ValueChanged<SmartTileTransformPolicy> onTransformPolicyChanged;
  final VoidCallback onAcceptTransformProposal;
  final VoidCallback onDiscardTransformProposal;
  final ValueChanged<String> onAnimationNameChanged;
  final ValueChanged<String> onAnimationDurationChanged;
  final ValueChanged<int> onRemoveAnimationFrame;
  final VoidCallback onClearAnimationFrames;
  final VoidCallback? onCreateAnimation;
  final VoidCallback? onContinue;
  final bool showAdvancedSettings;
  final VoidCallback onToggleAdvancedSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: usage == SmartTileUsage.path
              ? 'Options facultatives du chemin'
              : 'Options d’affichage',
          description: usage == SmartTileUsage.path
              ? 'Pour un chemin simple, gardez les réglages proposés et continuez. Activez une rotation ou un miroir seulement si vos tuiles restent correctes une fois retournées.'
              : 'Autorisez uniquement les rotations et miroirs qui respectent le dessin.',
        ),
        if (usage == SmartTileUsage.path) ...[
          const SizedBox(height: 12),
          PokeMapPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Réglages conseillés prêts',
          description:
                      'Aucune rotation, aucun miroir et aucune animation ne sont nécessaires pour commencer.',
        ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PokeMapButton(
                    key: const Key('smart-tiles-toggle-variants-advanced'),
                    onPressed: onToggleAdvancedSettings,
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    leading: Icon(
                      showAdvancedSettings
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.slider_horizontal_3,
                      size: 14,
                    ),
                    child: Text(
                      showAdvancedSettings
                          ? 'Masquer les options avancées'
                          : 'Afficher les rotations et animations',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (usage != SmartTileUsage.path || showAdvancedSettings) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            SizedBox(
              width: 270,
              child: PokeMapToggleTile(
                key: const Key('smart-tiles-transform-quarter-turns'),
                label: 'Rotations par quart de tour',
                description: 'Autoriser 90°, 180° et 270°.',
                value: transformPolicy.allowQuarterTurns,
                onChanged: (value) => onTransformPolicyChanged(
                  transformPolicy.copyWith(allowQuarterTurns: value),
                ),
              ),
            ),
            SizedBox(
              width: 270,
              child: PokeMapToggleTile(
                key: const Key('smart-tiles-transform-horizontal-flip'),
                label: 'Miroir horizontal',
                description: 'Retourner la source de gauche à droite.',
                value: transformPolicy.allowHFlip,
                onChanged: (value) => onTransformPolicyChanged(
                  transformPolicy.copyWith(allowHFlip: value),
                ),
              ),
            ),
            SizedBox(
              width: 270,
              child: PokeMapToggleTile(
                key: const Key('smart-tiles-transform-vertical-flip'),
                label: 'Miroir vertical',
                description: 'Retourner la source de haut en bas.',
                value: transformPolicy.allowVFlip,
                onChanged: (value) => onTransformPolicyChanged(
                  transformPolicy.copyWith(allowVFlip: value),
                ),
              ),
            ),
            SizedBox(
              width: 270,
              child: PokeMapToggleTile(
                key: const Key('smart-tiles-transform-prefer-original'),
                label: 'Préférer l’original',
                description: 'Choisir la source non transformée si possible.',
                value: transformPolicy.preferUntransformed,
                onChanged: (value) => onTransformPolicyChanged(
                  transformPolicy.copyWith(preferUntransformed: value),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PokeMapPanel(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${allowedTransforms.length} orientation(s) réellement autorisée(s)',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final transform in allowedTransforms)
                    PokeMapBadge(
                        label: smartTileTransformHumanLabel(transform),),
                ],
              ),
            ],
          ),
        ),
        if (transformProposal case final proposal?) ...[
          const SizedBox(height: 12),
          PokeMapPanel(
            key: const Key('smart-tiles-transform-proposal'),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const PokeMapSectionHeader(
                  title: 'Proposition à vérifier',
                  description:
                      'Le réglage actif reste intact tant que vous n’acceptez pas cette proposition.',
                ),
                const SizedBox(height: 10),
                Text(
                  '${smartTileAllowedTransforms(currentTransformPolicy).length} orientation(s) actives → ${allowedTransforms.length} proposées',
                ),
                const SizedBox(height: 10),
                _TransformImpactGroup(
                  title: 'Formes gagnées',
                  emptyLabel: 'Aucune forme supplémentaire',
                  impacts: proposal.gainedForms,
                  topology: topology,
                  badgeVariant: PokeMapBadgeVariant.success,
                ),
                const SizedBox(height: 8),
                _TransformImpactGroup(
                  title: 'Formes perdues',
                  emptyLabel: 'Aucune forme perdue',
                  impacts: proposal.lostForms,
                  topology: topology,
                  badgeVariant: PokeMapBadgeVariant.warning,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: <Widget>[
                    PokeMapButton(
                      key: const Key('smart-tiles-transform-discard'),
                      onPressed: onDiscardTransformProposal,
                      variant: PokeMapButtonVariant.ghost,
                      child: const Text('Annuler la proposition'),
                    ),
                    PokeMapButton(
                      key: const Key('smart-tiles-transform-accept'),
                      onPressed: proposal.hasChanges
                          ? onAcceptTransformProposal
                          : null,
                      child: const Text('Accepter les transformations'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        const PokeMapSectionHeader(
          title: 'Animation facultative',
          description:
                'Ignorez cette section si votre chemin est fixe. Sinon, choisissez au moins deux images dans l’ordre.',
        ),
        const SizedBox(height: 10),
        atlasPreview,
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (var index = 0;
                index < selectedAnimationFrames.length;
                index += 1)
              PokeMapButton(
                key: Key('smart-tiles-animation-frame-$index'),
                onPressed: () => onRemoveAnimationFrame(index),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                trailing: const Icon(CupertinoIcons.xmark, size: 12),
                child: Text('Image ${index + 1}'),
              ),
            if (selectedAnimationFrames.isNotEmpty)
              PokeMapButton(
                key: const Key('smart-tiles-animation-clear-frames'),
                onPressed: onClearAnimationFrames,
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                child: const Text('Effacer la sélection'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        PokeMapPanel(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: <Widget>[
              SizedBox(
                width: 260,
                child: PokeMapTextField(
                  label: 'Nom de l’animation',
                  fieldKey: const Key('smart-tiles-animation-name'),
                  controller: animationNameController,
                  hintText: 'Ex. Herbe au vent',
                  onChanged: onAnimationNameChanged,
                ),
              ),
              SizedBox(
                width: 190,
                child: PokeMapTextField(
                  label: 'Durée par image (ms)',
                  fieldKey: const Key('smart-tiles-animation-duration'),
                  controller: animationDurationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: onAnimationDurationChanged,
                ),
              ),
              PokeMapButton(
                key: const Key('smart-tiles-create-animation'),
                onPressed: onCreateAnimation,
                leading: const Icon(CupertinoIcons.play_circle, size: 15),
                child: const Text('Créer la boucle'),
              ),
            ],
          ),
        ),
        if (animations.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final animation in animations) ...[
            PokeMapAssetCard(
              key: Key('smart-tiles-animation-${animation.id}'),
              thumbnail: const Icon(CupertinoIcons.play_circle, size: 20),
              label: animation.name,
              description:
                  '${animation.frames.length} images · ${animation.frames.fold<int>(0, (sum, frame) => sum + frame.durationMs)} ms',
              selected: false,
              onPressed: null,
            ),
            const SizedBox(height: 8),
          ],
        ],
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-variants-next-step'),
            onPressed: onContinue,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: Text(
              usage == SmartTileUsage.path
                  ? 'Associer les images du chemin'
                  : 'Associer les images',),
          ),
        ),
      ],
    );
  }
}

class _TransformImpactGroup extends StatelessWidget {
  const _TransformImpactGroup({
    required this.title,
    required this.emptyLabel,
    required this.impacts,
    required this.topology,
    required this.badgeVariant,
  });

  final String title;
  final String emptyLabel;
  final List<SmartTileTransformImpact> impacts;
  final SmartTileTopology topology;
  final PokeMapBadgeVariant badgeVariant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$title (${impacts.length})'),
        const SizedBox(height: 6),
        if (impacts.isEmpty)
          Text(emptyLabel)
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final impact in impacts) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    PokeMapBadge(
                      label: smartTileFormHumanLabel(impact.mask, topology),
                      variant: badgeVariant,
                    ),
                    Text(
                      'Depuis ${smartTileFormHumanLabel(impact.sourceMask, topology)} · '
                      '${smartTileTransformHumanLabel(impact.transform)}',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ],
          ),
      ],
    );
  }
}

String smartTileTransformHumanLabel(SmartTileSpriteTransform transform) {
  if (transform.quarterTurns == 0 && !transform.flipX) return 'Original';
  final rotation = switch (transform.quarterTurns) {
    0 => '',
    1 => 'rotation 90°',
    2 => 'rotation 180°',
    3 => 'rotation 270°',
    _ => throw StateError('Transformation D4 invalide.'),
  };
  if (!transform.flipX) return rotation;
  return rotation.isEmpty ? 'miroir horizontal' : '$rotation + miroir';
}
