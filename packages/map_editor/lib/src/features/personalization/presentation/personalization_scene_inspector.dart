import 'package:flutter/material.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_inspector_target.dart';
import '../application/personalization_preview_surface_descriptor.dart';
import '../application/personalization_visual_target_graph.dart';

class PersonalizationSceneInspector extends StatelessWidget {
  static const capabilityIds = <String>{'inspector.targetNavigation'};

  const PersonalizationSceneInspector({
    super.key,
    required this.scene,
    required this.target,
    required this.onTargetSelected,
    required this.title,
    required this.description,
    required this.child,
  });

  final PersonalizationStudioScene scene;
  final PersonalizationInspectorTarget target;
  final ValueChanged<PersonalizationInspectorTarget> onTargetSelected;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) => PokeMapPanel(
    key: const ValueKey<String>('personalization-studio-scene-inspector'),
    expandChild: true,
    padding: EdgeInsets.zero,
    header: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const PokeMapBadge(
                label: 'Interface du jeu',
                variant: PokeMapBadgeVariant.mapAccent,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description),
          if (scene != PersonalizationStudioScene.globalStyle) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final node
                    in PersonalizationVisualTargetGraph.standard().targetsFor(
                      scene,
                    ))
                  PokeMapButton(
                    key: ValueKey<String>(
                      'personalization-inspector-target-${node.id}',
                    ),
                    size: PokeMapButtonSize.large,
                    variant: PokeMapButtonVariant.secondary,
                    isSelected: node.target.runtimeType == target.runtimeType,
                    onPressed: () => onTargetSelected(node.target),
                    child: Text(_targetLabel(node.target)),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
    child: ListView(
      key: const ValueKey<String>('personalization-studio-inspector-scroll'),
      padding: const EdgeInsets.all(16),
      children: <Widget>[child],
    ),
  );
}

String _targetLabel(PersonalizationInspectorTarget target) => switch (target) {
  GlobalColorsTarget() => 'Couleurs',
  GlobalTypographyTarget() => 'Typographie',
  GlobalFormsTarget() => 'Fenêtres',
  TitlePresentationTarget() => 'Écran titre',
  IntroPresentationTarget() => 'Média',
  PauseLabelsTarget() => 'Libellés',
  PauseAppearanceTarget() => 'Apparence',
  PauseLayoutTarget() => 'Disposition',
  DialogueAppearanceTarget() => 'Apparence',
  DialogueTypographyTarget() => 'Typographie',
  DialogueLayoutTarget() => 'Disposition',
  BattleCommandsTarget() => 'Commandes',
  BattleHudTarget() => 'HUD et PV',
  BattleMovesTarget() => 'Capacités',
  BattleTargetsTarget() => 'Cible',
  BattleMessageTarget() => 'Message',
  BattleAppearanceTarget() => 'Apparence',
};
