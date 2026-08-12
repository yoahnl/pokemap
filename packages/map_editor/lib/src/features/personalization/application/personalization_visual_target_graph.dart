import 'package:flutter/widgets.dart';

import 'personalization_inspector_target.dart';
import 'personalization_preview_surface_descriptor.dart';

final class PersonalizationVisualTargetNode {
  const PersonalizationVisualTargetNode({
    required this.scene,
    required this.target,
    required this.normalizedBounds,
    required this.priority,
  });

  final PersonalizationStudioScene scene;
  final PersonalizationInspectorTarget target;
  final Rect normalizedBounds;
  final int priority;

  String get id => personalizationInspectorTargetId(target);

  bool contains(Offset position) => normalizedBounds.contains(position);
}

final class PersonalizationVisualTargetGraph {
  PersonalizationVisualTargetGraph._(this._nodes);

  factory PersonalizationVisualTargetGraph.standard() =>
      PersonalizationVisualTargetGraph._(_standardNodes);

  final List<PersonalizationVisualTargetNode> _nodes;

  List<PersonalizationVisualTargetNode> targetsFor(
    PersonalizationStudioScene scene,
  ) => List<PersonalizationVisualTargetNode>.unmodifiable(
    _nodes.where((node) => node.scene == scene),
  );

  PersonalizationVisualTargetNode? hitTest({
    required PersonalizationStudioScene scene,
    required Offset normalizedPosition,
    String? preferredTargetId,
  }) {
    final matches =
        _nodes
            .where(
              (node) =>
                  node.scene == scene && node.contains(normalizedPosition),
            )
            .toList(growable: false)
          ..sort((left, right) {
            final leftPreferred = left.id == preferredTargetId;
            final rightPreferred = right.id == preferredTargetId;
            if (leftPreferred != rightPreferred) return leftPreferred ? -1 : 1;
            return right.priority.compareTo(left.priority);
          });
    return matches.firstOrNull;
  }
}

const _full = Rect.fromLTWH(0, 0, 1, 1);

const _standardNodes = <PersonalizationVisualTargetNode>[
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.globalStyle,
    target: GlobalColorsTarget(),
    normalizedBounds: _full,
    priority: 0,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.globalStyle,
    target: GlobalTypographyTarget(),
    normalizedBounds: Rect.fromLTWH(.5, 0, .5, .5),
    priority: 1,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.globalStyle,
    target: GlobalFormsTarget(),
    normalizedBounds: Rect.fromLTWH(0, .5, 1, .5),
    priority: 1,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.title,
    target: TitlePresentationTarget(),
    normalizedBounds: _full,
    priority: 0,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.intro,
    target: IntroPresentationTarget(),
    normalizedBounds: _full,
    priority: 0,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.pause,
    target: PauseLayoutTarget(),
    normalizedBounds: _full,
    priority: 0,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.pause,
    target: PauseAppearanceTarget(),
    normalizedBounds: Rect.fromLTWH(.04, .08, .92, .84),
    priority: 1,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.pause,
    target: PauseLabelsTarget(),
    normalizedBounds: Rect.fromLTWH(.06, .18, .88, .7),
    priority: 2,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.dialogue,
    target: DialogueLayoutTarget(),
    normalizedBounds: _full,
    priority: 0,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.dialogue,
    target: DialogueAppearanceTarget(),
    normalizedBounds: Rect.fromLTWH(.02, .64, .96, .34),
    priority: 1,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.dialogue,
    target: DialogueTypographyTarget(),
    normalizedBounds: Rect.fromLTWH(.2, .68, .76, .26),
    priority: 2,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.battle,
    target: BattleHudTarget(),
    normalizedBounds: Rect.fromLTWH(0, 0, 1, .28),
    priority: 1,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.battle,
    target: BattleCommandsTarget(),
    normalizedBounds: Rect.fromLTWH(.02, .7, .96, .28),
    priority: 1,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.battle,
    target: BattleMovesTarget(),
    normalizedBounds: Rect.fromLTWH(.02, .7, .96, .28),
    priority: 1,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.battle,
    target: BattleTargetsTarget(),
    normalizedBounds: Rect.fromLTWH(.02, .7, .96, .28),
    priority: 1,
  ),
  PersonalizationVisualTargetNode(
    scene: PersonalizationStudioScene.battle,
    target: BattleMessageTarget(),
    normalizedBounds: Rect.fromLTWH(.02, .7, .96, .28),
    priority: 1,
  ),
];
