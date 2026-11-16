import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_preview.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class StoryDialogueStatus extends StatelessWidget {
  const StoryDialogueStatus({super.key, required this.preview, this.locale});

  final DialogueCatalogPreview preview;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (preview.status) {
      DialogueCatalogStatus.source => l10n.dialogueCatalogSource,
      DialogueCatalogStatus.translated => l10n.dialogueCatalogTranslated,
      DialogueCatalogStatus.missing => l10n.dialogueCatalogMissing,
      DialogueCatalogStatus.needsReview => l10n.dialogueCatalogNeedsReview,
      DialogueCatalogStatus.unlocalized => l10n.dialogueCatalogUnlocalized,
      DialogueCatalogStatus.unsupported => l10n.dialogueCatalogUnsupported,
    };
    return StudioBadge(
      locale == null ? label : '${locale!.toUpperCase()} · $label',
      tone: switch (preview.status) {
        DialogueCatalogStatus.translated => StudioTone.success,
        DialogueCatalogStatus.source => StudioTone.info,
        DialogueCatalogStatus.missing ||
        DialogueCatalogStatus.needsReview => StudioTone.warning,
        _ => StudioTone.neutral,
      },
    );
  }
}
