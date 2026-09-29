import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';

class MapDecorAnimationPanel extends StatefulWidget {
  const MapDecorAnimationPanel({
    super.key,
    required this.document,
    required this.project,
    required this.onChanged,
  });

  final EditableMapDocument document;
  final ProjectManifest project;
  final VoidCallback onChanged;

  @override
  State<MapDecorAnimationPanel> createState() => _MapDecorAnimationPanelState();
}

class _MapDecorAnimationPanelState extends State<MapDecorAnimationPanel> {
  MapPlacedElementTriggerType _trigger = MapPlacedElementTriggerType.onAction;
  String _effect = 'once';

  void _updateAnimation(MapPlacedElementAnimation animation) {
    final selected = widget.document.selected;
    if (selected == null) return;
    widget.document.commit(
      setMapPlacedElementAnimation(
        widget.document.current,
        instanceId: selected.id,
        animation: animation,
      ),
    );
    widget.onChanged();
  }

  void _updateBehavior(MapData Function(MapData) update) {
    widget.document.commit(update(widget.document.current));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.document.selected;
    if (selected == null) return const SizedBox();
    final definition = widget.project.elements
        .where((entry) => entry.id == selected.elementId)
        .firstOrNull;
    final frames = definition?.frames.length ?? 0;
    final animation = selected.animation ?? const MapPlacedElementAnimation();
    final behaviors = selected.behaviors.indexed.where(
      (entry) =>
          entry.$2.effect.type ==
              MapPlacedElementEffectType.setAnimationEnabled ||
          entry.$2.effect.type == MapPlacedElementEffectType.playAnimationOnce,
    );
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
        if (frames > 1) ...[
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
              animation.copyWith(randomStart: !animation.randomStart),
            ),
          ),
          StudioCommitField(
            key: ValueKey('animation-speed-${selected.id}'),
            label: 'Vitesse',
            value: animation.speed.toString(),
            tryCommit: (value) {
              final speed = double.tryParse(value.replaceAll(',', '.'));
              if (speed == null || !speed.isFinite || speed <= 0) return false;
              _updateAnimation(animation.copyWith(speed: speed));
              return true;
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
                        '${_triggerLabel(behavior.trigger)} · ${_effectLabel(behavior.effect)}',
                    selected: behavior.enabled,
                    onTap: () => _updateBehavior(
                      (map) => setMapPlacedElementBehaviorEnabledAt(
                        map,
                        instanceId: selected.id,
                        behaviorIndex: index,
                        enabled: !behavior.enabled,
                      ),
                    ),
                  ),
                ),
                StudioTool(
                  label: 'Supprimer ce déclencheur',
                  icon: Icons.close,
                  onPressed: () => _updateBehavior(
                    (map) => removeMapPlacedElementBehaviorAt(
                      map,
                      instanceId: selected.id,
                      behaviorIndex: index,
                    ),
                  ),
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
                  child: Text(_triggerLabel(trigger)),
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
            onPressed: () => _updateBehavior(
              (map) => addMapPlacedElementBehavior(
                map,
                instanceId: selected.id,
                behavior: MapPlacedElementBehavior(
                  trigger: _trigger,
                  effect: MapPlacedElementEffect(
                    type: _effect == 'once'
                        ? MapPlacedElementEffectType.playAnimationOnce
                        : MapPlacedElementEffectType.setAnimationEnabled,
                    animationEnabled: _effect == 'once'
                        ? null
                        : _effect == 'start',
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _triggerLabel(MapPlacedElementTriggerType trigger) =>
      switch (trigger) {
        MapPlacedElementTriggerType.onAction => 'À l’interaction',
        MapPlacedElementTriggerType.onEnter => 'À l’entrée',
        MapPlacedElementTriggerType.onBump => 'Au contact',
        MapPlacedElementTriggerType.onExit => 'À la sortie',
        MapPlacedElementTriggerType.onNear => 'À proximité',
      };

  String _effectLabel(MapPlacedElementEffect effect) => switch (effect.type) {
    MapPlacedElementEffectType.playAnimationOnce => 'Jouer une fois',
    MapPlacedElementEffectType.setAnimationEnabled =>
      effect.animationEnabled == true ? 'Activer' : 'Arrêter',
    _ => 'Autre effet',
  };
}
