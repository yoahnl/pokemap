import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_controller.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_preview.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'story_dialogue_status.dart';

class StoryDialogueDocument extends StatefulWidget {
  const StoryDialogueDocument({
    super.key,
    required this.catalog,
    required this.id,
  });
  final DialogueCatalogController catalog;
  final String id;

  @override
  State<StoryDialogueDocument> createState() => _StoryDialogueDocumentState();
}

class _StoryDialogueDocumentState extends State<StoryDialogueDocument> {
  bool _sourceShown = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = widget.catalog;
    final resource = catalog.resource(widget.id);
    if (TickerMode.valuesOf(context).enabled &&
        catalog.viewing &&
        catalog.selectedId == widget.id &&
        !resource.loading &&
        resource.value == null &&
        resource.problem == null) {
      scheduleMicrotask(() {
        if (mounted && catalog.viewing && catalog.selectedId == widget.id) {
          unawaited(catalog.load(widget.id));
        }
      });
    }
    final state = gameMemoryResourceState(
      context,
      resource,
      loading: l10n.dialogueCatalogLoadingPreview,
      onRetry: () => unawaited(catalog.load(widget.id, force: true)),
    );
    if (state != null) return state;
    final document = catalog.document(widget.id);
    if (document == null) {
      return StudioEmptyState(
        icon: Icons.link_off,
        title: l10n.dialogueCatalogDeleted,
      );
    }
    final preview = catalog.preview(widget.id)!;
    final theme = Theme.of(context);
    return ListView(
      key: ValueKey('dialogue-document-${widget.id}'),
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        Text(
          document.dialogue.entry.name,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: StudioSpacing.m),
        Wrap(
          spacing: StudioSpacing.s,
          runSpacing: StudioSpacing.s,
          children: [
            StoryDialogueStatus(preview: preview),
            if (preview.fallback)
              StudioBadge(
                l10n.dialogueCatalogFallback(
                  preview.textLocales.join(', ').toUpperCase(),
                ),
                tone: StudioTone.warning,
              ),
            StudioBadge(
              l10n.dialogueCatalogSceneCount(document.sceneIds.length),
            ),
          ],
        ),
        const SizedBox(height: StudioSpacing.m),
        StudioNotice(l10n.dialogueCatalogReadOnlyPreview),
        if (document.notCovered.isNotEmpty) ...[
          const SizedBox(height: StudioSpacing.s),
          StudioNotice(
            document.notCovered.contains('sceneDialogueIndex')
                ? l10n.dialogueCatalogUsagesUnavailable
                : l10n.dialogueCatalogUsageCoverage,
          ),
        ],
        const SizedBox(height: StudioSpacing.xl),
        if (preview.status == DialogueCatalogStatus.unsupported) ...[
          StudioNotice(l10n.dialogueCatalogUnsupportedHint),
          const SizedBox(height: StudioSpacing.m),
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              key: const ValueKey('dialogue-catalog-source'),
              label: l10n.dialogueCatalogShowSource,
              icon: Icons.description_outlined,
              variant: StudioButtonVariant.secondary,
              onPressed: () => setState(() => _sourceShown = !_sourceShown),
            ),
          ),
          if (_sourceShown)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.m),
              child: SelectableText(document.dialogue.source),
            ),
        ] else if (preview.texts.isEmpty)
          Text(l10n.dialogueCatalogNoText)
        else
          for (final text in preview.texts)
            Padding(
              padding: const EdgeInsets.only(bottom: StudioSpacing.m),
              child: SelectableText(text, style: theme.textTheme.bodyLarge),
            ),
      ],
    );
  }
}
