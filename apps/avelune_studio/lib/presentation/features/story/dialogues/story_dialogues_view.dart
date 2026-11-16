import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_controller.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'story_dialogue_document.dart';
import 'story_dialogue_row.dart';

class StoryDialoguesView extends StatefulWidget {
  const StoryDialoguesView({super.key, required this.catalog});

  final DialogueCatalogController catalog;

  @override
  State<StoryDialoguesView> createState() => _StoryDialoguesViewState();
}

class _StoryDialoguesViewState extends State<StoryDialoguesView> {
  late final _search = TextEditingController(text: widget.catalog.query);
  DialogueCatalogController get catalog => widget.catalog;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (TickerMode.valuesOf(context).enabled) scheduleMicrotask(catalog.sync);
    final l10n = context.l10n;
    final state = gameMemoryResourceState(
      context,
      catalog.titles,
      loading: l10n.dialogueCatalogLoading,
      onRetry: () => unawaited(catalog.open(force: true)),
    );
    final rows = catalog.visibleRows;
    return Column(
      key: const ValueKey('story-dialogue-catalog'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(StudioSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioNotice(l10n.dialogueCatalogOwnership),
              const SizedBox(height: StudioSpacing.m),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: StudioSpacing.m,
                  runSpacing: StudioSpacing.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth >= 640
                          ? constraints.maxWidth -
                                230 -
                                160 -
                                StudioSpacing.m * 2
                          : constraints.maxWidth,
                      child: StudioSearchField(
                        key: const ValueKey('dialogue-catalog-search'),
                        hint: l10n.dialogueCatalogSearch,
                        controller: _search,
                        label: l10n.dialogueCatalogSearch,
                        onChanged: catalog.filter,
                      ),
                    ),
                    SizedBox(
                      width: 230,
                      child: StudioSelect(
                        key: const ValueKey('dialogue-catalog-language'),
                        label: l10n.dialogueCatalogPreviewLanguage,
                        value: catalog.language,
                        options: {
                          'source': l10n.dialogueCatalogSourceText,
                          for (final locale in catalog.locales)
                            locale: locale.toUpperCase(),
                          if (catalog.language != 'source')
                            catalog.language: catalog.language.toUpperCase(),
                        },
                        onChanged: catalog.previewIn,
                      ),
                    ),
                    if (catalog.viewing)
                      StudioButton(
                        key: const ValueKey('dialogue-catalog-back'),
                        label: l10n.dialogueCatalogBack,
                        icon: Icons.arrow_back,
                        variant: StudioButtonVariant.quiet,
                        onPressed: catalog.back,
                      )
                    else
                      StudioButton(
                        key: const ValueKey('dialogue-catalog-refresh'),
                        label: l10n.sceneCatalogRefresh,
                        icon: Icons.refresh,
                        variant: StudioButtonVariant.quiet,
                        onPressed: () => unawaited(catalog.open(force: true)),
                      ),
                  ],
                ),
              ),
              if (catalog.stale) StudioNotice(l10n.dialogueCatalogStale),
              if (catalog.languages.problem != null)
                StudioNotice(l10n.dialogueCatalogLanguagesUnavailable),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: catalog.viewing ? 1 : 0,
            children: [
              TickerMode(
                enabled: !catalog.viewing,
                child:
                    state ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: StudioSpacing.l,
                          ),
                          child: Text(
                            l10n.dialogueCatalogResults(rows.length),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Expanded(
                          child: rows.isEmpty
                              ? StudioEmptyState(
                                  icon: Icons.chat_bubble_outline,
                                  title: catalog.rows.isEmpty
                                      ? l10n.dialogueCatalogEmpty
                                      : l10n.dialogueCatalogNoResults,
                                  description: l10n.dialogueCatalogSearchHint,
                                )
                              : ListView.builder(
                                  key: const PageStorageKey(
                                    'story-dialogue-list',
                                  ),
                                  padding: const EdgeInsets.all(
                                    StudioSpacing.l,
                                  ),
                                  scrollCacheExtent:
                                      const ScrollCacheExtent.pixels(0),
                                  itemCount: rows.length,
                                  itemBuilder: (context, index) =>
                                      StoryDialogueRow(
                                        key: ValueKey(rows[index].id),
                                        catalog: catalog,
                                        row: rows[index],
                                      ),
                                ),
                        ),
                      ],
                    ),
              ),
              if (catalog.selectedId case final id?)
                StoryDialogueDocument(
                  key: ValueKey(id),
                  catalog: catalog,
                  id: id,
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}
