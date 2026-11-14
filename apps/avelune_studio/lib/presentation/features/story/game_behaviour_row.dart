import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_summary.dart';
import 'package:avelune_studio/presentation/features/story/game_behaviour_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameBehaviourRowTile extends StatelessWidget {
  const GameBehaviourRowTile({
    super.key,
    required this.row,
    required this.summary,
    required this.factName,
    required this.onTap,
  });

  final GameBehaviourRow row;
  final GameBehaviourSummary? summary;
  final String? Function(String factId) factName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = this.summary;
    final badge = switch (row) {
      GameBehaviourRow(presence: GameBehaviourPresence.deletedElsewhere) => (
        l10n.behavioursDeletedElsewhere,
        StudioTone.danger,
      ),
      GameBehaviourRow(presence: GameBehaviourPresence.notLoaded) => (
        l10n.behavioursNotLoadedBadge,
        StudioTone.warning,
      ),
      GameBehaviourRow(unsaved: true) => (l10n.memoryUnsaved, StudioTone.info),
      GameBehaviourRow(toRepair: true) => (
        l10n.behavioursToRepair,
        StudioTone.warning,
      ),
      GameBehaviourRow(disabled: true) => (
        l10n.storyDisabled,
        StudioTone.neutral,
      ),
      GameBehaviourRow(record: final record?)
          when record.enabledOrNull == null =>
        (l10n.storyDraft, StudioTone.neutral),
      _ => null,
    };
    final place = l10n.behaviourPlace(row);
    return StudioChoice(
      key: ValueKey('behaviour-${row.id}'),
      label: l10n.behaviourName(row),
      subtitle: summary == null
          ? place
          : '$place\n${l10n.behaviourSummary(summary, factName)}',
      maxLines: 1,
      trailing: badge == null ? null : StudioBadge(badge.$1, tone: badge.$2),
      onTap: onTap,
    );
  }
}
