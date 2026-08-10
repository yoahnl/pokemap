sealed class PersonalizationInspectorTarget {
  const PersonalizationInspectorTarget();
}

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

final class BattleAppearanceTarget extends PersonalizationInspectorTarget {
  const BattleAppearanceTarget();
}
