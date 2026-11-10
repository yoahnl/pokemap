import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_decor_animation_commands.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';

class MapDecorAnimationPanel extends StatefulWidget {
  const MapDecorAnimationPanel({
    super.key,
    required this.document,
    required this.project,
    required this.visuals,
    required this.onChanged,
  });

  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final VoidCallback onChanged;

  @override
  State<MapDecorAnimationPanel> createState() => _MapDecorAnimationPanelState();
}

class _MapDecorAnimationPanelState extends State<MapDecorAnimationPanel> {
  MapPlacedElementTriggerType _trigger = MapPlacedElementTriggerType.onAction;
  String _effect = 'once';

  MapDecorAnimationCommands get commands =>
      MapDecorAnimationCommands(widget.document, widget.project);

  void _updateAnimation(MapPlacedElementAnimation animation) {
    if (commands.animation(animation)) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.document.selected;
    if (selected == null) return const SizedBox();
    final definition = commands.definition;
    final frames = definition?.frames.length ?? 0;
    final animation = selected.animation ?? const MapPlacedElementAnimation();
    final idleFrame = commands.idleFrame;
    final behaviors = commands.behaviors;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Animation du décor', style: text.titleMedium),
        const SizedBox(height: 6),
        Text(
          frames > 1
              ? '$frames images disponibles pour ce décor.'
              : 'Cette ressource ne contient pas plusieurs images à animer.',
          style: text.bodySmall,
        ),
        if (definition != null && frames > 1) ...[
          const SizedBox(height: 12),
          StudioChoice(
            label: 'Animation active',
            subtitle: 'Autoriser la lecture de cette animation dans le jeu.',
            selected: animation.enabled,
            onTap: () => _updateAnimation(
              animation.copyWith(
                enabled: !animation.enabled,
                mode: animation.mode == MapPlacedElementAnimationMode.none
                    ? MapPlacedElementAnimationMode.loop
                    : animation.mode,
              ),
            ),
          ),
          Text('Lecture', style: text.titleSmall),
          for (final mode in const [
            MapPlacedElementAnimationMode.loop,
            MapPlacedElementAnimationMode.pingPong,
          ])
            StudioChoice(
              label: mode == MapPlacedElementAnimationMode.loop
                  ? 'En boucle'
                  : 'Aller-retour',
              selected: animation.mode == mode,
              onTap: () => _updateAnimation(
                animation.copyWith(enabled: true, mode: mode),
              ),
            ),
          const SizedBox(height: 8),
          StudioChoice(
            label: 'Démarrer automatiquement',
            subtitle:
                'Sinon, lancer l’animation avec un déclencheur ci-dessous.',
            selected: animation.autoplay,
            onTap: () => _updateAnimation(
              animation.copyWith(autoplay: !animation.autoplay),
            ),
          ),
          StudioChoice(
            label: 'Départ aléatoire',
            subtitle: 'Décale le départ des exemplaires de cette ressource.',
            selected: animation.randomStart,
            onTap: () => _updateAnimation(
              animation.copyWith(
                randomStart: !animation.randomStart,
                startOffsetMs: animation.randomStart
                    ? animation.startOffsetMs
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          StudioSelect(
            key: const ValueKey('decor-idle-frame'),
            label: 'Image d’attente',
            value: '$idleFrame',
            options: {
              for (var index = 0; index < frames; index++)
                '$index': 'Image ${index + 1}',
            },
            onChanged: (value) {
              if (commands.idleImage(int.parse(value))) widget.onChanged();
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Choisir une image désactive le départ automatique. « Jouer une fois » repart de la première image.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 8),
          StudioAssetPreview(
            key: const ValueKey('decor-idle-frame-preview'),
            height: 112,
            child: Semantics(
              label: 'Aperçu de l’image d’attente ${idleFrame + 1} sur $frames',
              child: widget.visuals.thumbnail(
                definition.copyWith(frames: [definition.frames[idleFrame]]),
                size: 96,
              ),
            ),
          ),
          const SizedBox(height: 8),
          StudioCommitField(
            key: ValueKey('animation-speed-${selected.id}'),
            label: 'Vitesse',
            value: animation.speed.toString(),
            tryCommit: (value) {
              final result = commands.speed(value);
              if (result) widget.onChanged();
              return result;
            },
          ),
          const SizedBox(height: 16),
          Text('Déclencheurs', style: text.titleSmall),
          const SizedBox(height: 6),
          Text(
            'Choisissez quand lancer, activer ou arrêter l’animation.',
            style: text.bodySmall,
          ),
          for (final (index, behavior) in behaviors)
            Row(
              children: [
                Expanded(
                  child: StudioChoice(
                    label:
                        '${mapDecorTriggerLabel(behavior.trigger)} · ${mapDecorEffectLabel(behavior.effect)}',
                    selected: behavior.enabled,
                    onTap: () {
                      commands.setBehaviorEnabled(index, !behavior.enabled);
                      widget.onChanged();
                    },
                  ),
                ),
                StudioTool(
                  label: 'Supprimer ce déclencheur',
                  icon: Icons.close,
                  onPressed: () {
                    commands.removeBehavior(index);
                    widget.onChanged();
                  },
                ),
              ],
            ),
          const SizedBox(height: 8),
          DropdownButtonFormField<MapPlacedElementTriggerType>(
            initialValue: _trigger,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Quand ?'),
            items: [
              for (final trigger in MapPlacedElementTriggerType.values)
                DropdownMenuItem(
                  value: trigger,
                  child: Text(mapDecorTriggerLabel(trigger)),
                ),
            ],
            onChanged: (value) => setState(() => _trigger = value ?? _trigger),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _effect,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Faire quoi ?'),
            items: [
              for (final effect in const ['once', 'start', 'stop'])
                DropdownMenuItem(
                  value: effect,
                  child: Text(switch (effect) {
                    'once' => 'Jouer une fois',
                    'start' => 'Activer en boucle',
                    _ => 'Arrêter',
                  }),
                ),
            ],
            onChanged: (value) => setState(() => _effect = value ?? _effect),
          ),
          const SizedBox(height: 8),
          StudioButton(
            label: 'Ajouter le déclencheur',
            icon: Icons.add,
            onPressed: () {
              commands.addBehavior(_trigger, _effect);
              widget.onChanged();
            },
          ),
        ],
      ],
    );
  }
}
