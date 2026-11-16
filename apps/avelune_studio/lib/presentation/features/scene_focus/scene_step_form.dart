import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/features/story/story_dialogue_link.dart';

part 'scene_step_form_fields.dart';

class SceneStepForm extends StatelessWidget {
  const SceneStepForm({
    super.key,
    required this.scene,
    required this.project,
    required this.map,
    required this.node,
    required this.enabled,
    required this.onEdit,
  });

  final SceneAsset scene;
  final ProjectManifest project;
  final MapData? map;
  final SceneNode node;
  final bool enabled;
  final ValueChanged<SceneNode> onEdit;

  static bool covers(SceneNode node) => switch (node.payload) {
    SceneActionPayload(consequence: final SceneSetFactConsequence fact) =>
      fact.narrativeValue.kind == NarrativeValueKind.boolean,
    SceneActionPayload(consequence: SceneSetNpcPresenceConsequence()) => true,
    SceneYarnDialoguePayload() => true,
    SceneBattlePayload(battleKind: 'trainer') => true,
    SceneConditionPayload() => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) =>
      _formOf(_Form(this, context), node) ?? const SizedBox.shrink();
}

final class _Form {
  _Form(this.widget, this.context);

  final SceneStepForm widget;
  final BuildContext context;

  bool get editable => widget.enabled;
  SceneAsset get scene => widget.scene;
  ProjectManifest get project => widget.project;
  MapData? get map => widget.map;
  AppLocalizations get l10n => context.l10n;

  void edit(SceneNode node) => widget.onEdit(node);
}

class SceneStepCaption extends StatelessWidget {
  const SceneStepCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
