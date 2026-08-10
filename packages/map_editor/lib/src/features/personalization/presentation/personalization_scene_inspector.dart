import 'package:flutter/material.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_inspector_target.dart';
import '../application/personalization_preview_surface_descriptor.dart';

class PersonalizationSceneInspector extends StatelessWidget {
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
                label: 'En direct',
                variant: PokeMapBadgeVariant.mapAccent,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final destination in _targetsForScene(scene))
                PokeMapButton(
                  key: ValueKey<String>(
                    'personalization-inspector-target-${_targetId(destination)}',
                  ),
                  size: PokeMapButtonSize.large,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: destination.runtimeType == target.runtimeType,
                  onPressed: () => onTargetSelected(destination),
                  child: Text(_targetLabel(destination)),
                ),
            ],
          ),
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

List<PersonalizationInspectorTarget> _targetsForScene(
  PersonalizationStudioScene scene,
) => switch (scene) {
  PersonalizationStudioScene.globalStyle =>
    const <PersonalizationInspectorTarget>[
      GlobalColorsTarget(),
      GlobalTypographyTarget(),
      GlobalFormsTarget(),
    ],
  PersonalizationStudioScene.title => const <PersonalizationInspectorTarget>[
    TitlePresentationTarget(),
  ],
  PersonalizationStudioScene.intro => const <PersonalizationInspectorTarget>[
    IntroPresentationTarget(),
  ],
  PersonalizationStudioScene.pause => const <PersonalizationInspectorTarget>[
    PauseLabelsTarget(),
    PauseAppearanceTarget(),
    PauseLayoutTarget(),
  ],
  PersonalizationStudioScene.dialogue => const <PersonalizationInspectorTarget>[
    DialogueAppearanceTarget(),
    DialogueTypographyTarget(),
    DialogueLayoutTarget(),
  ],
  PersonalizationStudioScene.battle => const <PersonalizationInspectorTarget>[
    BattleCommandsTarget(),
    BattleAppearanceTarget(),
  ],
};

String _targetId(PersonalizationInspectorTarget target) => switch (target) {
  GlobalColorsTarget() => 'globalColors',
  GlobalTypographyTarget() => 'globalTypography',
  GlobalFormsTarget() => 'globalForms',
  TitlePresentationTarget() => 'titlePresentation',
  IntroPresentationTarget() => 'introPresentation',
  PauseLabelsTarget() => 'pauseLabels',
  PauseAppearanceTarget() => 'pauseAppearance',
  PauseLayoutTarget() => 'pauseLayout',
  DialogueAppearanceTarget() => 'dialogueAppearance',
  DialogueTypographyTarget() => 'dialogueTypography',
  DialogueLayoutTarget() => 'dialogueLayout',
  BattleCommandsTarget() => 'battleCommands',
  BattleAppearanceTarget() => 'battleAppearance',
};

String _targetLabel(PersonalizationInspectorTarget target) => switch (target) {
  GlobalColorsTarget() => 'Couleurs',
  GlobalTypographyTarget() => 'Typographie',
  GlobalFormsTarget() => 'Formes',
  TitlePresentationTarget() => 'Écran titre',
  IntroPresentationTarget() => 'Média',
  PauseLabelsTarget() => 'Libellés',
  PauseAppearanceTarget() => 'Apparence',
  PauseLayoutTarget() => 'Disposition',
  DialogueAppearanceTarget() => 'Apparence',
  DialogueTypographyTarget() => 'Typographie',
  DialogueLayoutTarget() => 'Disposition',
  BattleCommandsTarget() => 'Commandes',
  BattleAppearanceTarget() => 'Apparence',
};
