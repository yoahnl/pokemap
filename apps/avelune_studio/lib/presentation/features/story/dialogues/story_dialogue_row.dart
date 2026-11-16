import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_controller.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_rows.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'story_dialogue_status.dart';

class StoryDialogueRow extends StatefulWidget {
  const StoryDialogueRow({super.key, required this.catalog, required this.row});

  final DialogueCatalogController catalog;
  final DialogueCatalogRow row;

  @override
  State<StoryDialogueRow> createState() => _StoryDialogueRowState();
}

class _StoryDialogueRowState extends State<StoryDialogueRow> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = widget.catalog;
    final row = widget.row;
    final preview = catalog.preview(row.id);
    final document = catalog.document(row.id);
    final resource = catalog.resource(row.id);
    if (TickerMode.valuesOf(context).enabled &&
        !row.deleted &&
        !resource.loading &&
        resource.value == null &&
        resource.problem == null) {
      scheduleMicrotask(() {
        if (mounted && TickerMode.valuesOf(context).enabled) {
          unawaited(catalog.load(row.id));
        }
      });
    }
    final subtitle = row.deleted
        ? l10n.dialogueCatalogDeleted
        : resource.problem != null
        ? l10n.dialogueCatalogReadFailed
        : preview == null
        ? l10n.dialogueCatalogLoadingPreview
        : preview.texts.isEmpty
        ? l10n.dialogueCatalogNoText
        : preview.texts.first;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.m),
      child: LayoutBuilder(
        builder: (context, constraints) => StudioChoice(
          key: ValueKey('story-dialogue-${row.id}'),
          label: row.title.trim().isEmpty
              ? l10n.dialogueCatalogUnnamed
              : row.title,
          subtitle: document == null
              ? subtitle
              : '${l10n.dialogueCatalogSceneCount(document.sceneIds.length)}\n$subtitle',
          leading: Padding(
            padding: const EdgeInsets.all(StudioSpacing.m),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: .08),
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(
                  StudioMetrics.controlRadius,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(StudioSpacing.m),
                child: Icon(Icons.chat_bubble_outline, color: colors.primary),
              ),
            ),
          ),
          selected: catalog.selectedId == row.id,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (document != null && preview != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * .5,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: StudioSpacing.s,
                    runSpacing: StudioSpacing.xs,
                    children: [
                      for (final locale in catalog.locales)
                        StoryDialogueStatus(
                          preview: catalog.preview(row.id, locale: locale)!,
                          locale: locale,
                        ),
                      if (catalog.locales.isEmpty)
                        StoryDialogueStatus(preview: preview),
                    ],
                  ),
                ),
              const SizedBox(width: StudioSpacing.m),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: row.deleted ? null : () => catalog.select(row.id),
        ),
      ),
    );
  }
}
