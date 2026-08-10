sealed class PersonalizationInspectorTarget {
  const PersonalizationInspectorTarget();
}

final class GlobalColorsTarget extends PersonalizationInspectorTarget {
  const GlobalColorsTarget();
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

final class DialogueAppearanceTarget extends PersonalizationInspectorTarget {
  const DialogueAppearanceTarget();
}

final class BattleCommandsTarget extends PersonalizationInspectorTarget {
  const BattleCommandsTarget();
}
