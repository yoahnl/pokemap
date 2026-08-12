sealed class PersonalizationInspectorTarget {
  const PersonalizationInspectorTarget();
}

String personalizationInspectorTargetId(
  PersonalizationInspectorTarget target,
) => switch (target) {
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
  BattleHudTarget() => 'battleHud',
  BattleMovesTarget() => 'battleMoves',
  BattleTargetsTarget() => 'battleTarget',
  BattleMessageTarget() => 'battleMessage',
  BattleAppearanceTarget() => 'battleAppearance',
};

final class GlobalColorsTarget extends PersonalizationInspectorTarget {
  const GlobalColorsTarget();
}

final class GlobalTypographyTarget extends PersonalizationInspectorTarget {
  const GlobalTypographyTarget();
}

final class GlobalFormsTarget extends PersonalizationInspectorTarget {
  const GlobalFormsTarget();
}

final class TitlePresentationTarget extends PersonalizationInspectorTarget {
  const TitlePresentationTarget();
}

final class IntroPresentationTarget extends PersonalizationInspectorTarget {
  const IntroPresentationTarget();
}

final class PauseLabelsTarget extends PersonalizationInspectorTarget {
  const PauseLabelsTarget({this.actionName});

  final String? actionName;
}

final class PauseAppearanceTarget extends PersonalizationInspectorTarget {
  const PauseAppearanceTarget();
}

final class PauseLayoutTarget extends PersonalizationInspectorTarget {
  const PauseLayoutTarget();
}

final class DialogueAppearanceTarget extends PersonalizationInspectorTarget {
  const DialogueAppearanceTarget();
}

final class DialogueTypographyTarget extends PersonalizationInspectorTarget {
  const DialogueTypographyTarget();
}

final class DialogueLayoutTarget extends PersonalizationInspectorTarget {
  const DialogueLayoutTarget();
}

final class BattleCommandsTarget extends PersonalizationInspectorTarget {
  const BattleCommandsTarget();
}

final class BattleHudTarget extends PersonalizationInspectorTarget {
  const BattleHudTarget();
}

final class BattleMovesTarget extends PersonalizationInspectorTarget {
  const BattleMovesTarget();
}

final class BattleTargetsTarget extends PersonalizationInspectorTarget {
  const BattleTargetsTarget();
}

final class BattleMessageTarget extends PersonalizationInspectorTarget {
  const BattleMessageTarget();
}

final class BattleAppearanceTarget extends PersonalizationInspectorTarget {
  const BattleAppearanceTarget();
}
