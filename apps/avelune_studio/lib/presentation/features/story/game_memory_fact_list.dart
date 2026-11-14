import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_fact_rows.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_creation_form.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_labels.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameMemoryFactList extends StatefulWidget {
  const GameMemoryFactList({super.key, required this.memory});

  final GameMemoryController memory;

  @override
  State<GameMemoryFactList> createState() => _GameMemoryFactListState();
}

class _GameMemoryFactListState extends State<GameMemoryFactList> {
  late final _search = TextEditingController(text: widget.memory.query);
  var _creating = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final memory = widget.memory;
    final editable = memory.staging.editable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.l,
            StudioSpacing.l,
            StudioSpacing.l,
            0,
          ),
          child: StudioSearchField(
            key: const ValueKey('memory-fact-search'),
            controller: _search,
            label: l10n.memorySearchFacts,
            onChanged: memory.search,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(StudioSpacing.l),
          child: Wrap(
            spacing: StudioSpacing.s,
            runSpacing: StudioSpacing.s,
            children: [
              for (final filter in GameMemoryFactFilter.values)
                StudioFilterChip(
                  key: ValueKey('memory-filter-${filter.name}'),
                  label: switch (filter) {
                    GameMemoryFactFilter.neverRead =>
                      l10n.memoryFilterNeverRead,
                    GameMemoryFactFilter.neverWritten =>
                      l10n.memoryFilterNeverWritten,
                  },
                  selected: memory.filters.contains(filter),
                  onSelected: memory.facts.ready
                      ? (_) => memory.toggle(filter)
                      : null,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
          child: _creating
              ? GameMemoryCreationForm(
                  key: const ValueKey('memory-fact-creation'),
                  onCancel: () => setState(() => _creating = false),
                  onCreate: (label, kind) {
                    if (memory.createFact(label, kind) != null) {
                      setState(() => _creating = false);
                    }
                  },
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: StudioButton(
                    key: const ValueKey('memory-new-fact'),
                    label: l10n.memoryNewFact,
                    icon: Icons.add,
                    variant: StudioButtonVariant.secondary,
                    onPressed: editable && memory.facts.ready
                        ? () => setState(() => _creating = true)
                        : null,
                  ),
                ),
        ),
        const SizedBox(height: StudioSpacing.m),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    final memory = widget.memory;
    final state = gameMemoryResourceState(
      context,
      memory.facts,
      loading: l10n.memoryFactsLoading,
      onRetry: memory.retry,
    );
    if (state != null) return state;
    if (memory.filters.isNotEmpty) {
      final usages = gameMemoryResourceState(
        context,
        memory.usagesFilter,
        loading: l10n.memoryUsagesLoading,
        onRetry: memory.retryUsages,
      );
      if (usages != null) return usages;
    }
    final rows = memory.rows;
    if (rows.isEmpty) {
      final filtered =
          memory.query.trim().isNotEmpty || memory.filters.isNotEmpty;
      return StudioEmptyState(
        key: const ValueKey('memory-facts-empty'),
        icon: filtered ? Icons.search_off_outlined : Icons.lightbulb_outline,
        title: filtered ? l10n.memoryFactsNoMatch : l10n.memoryFactsEmpty,
        description: filtered
            ? l10n.memoryFactsNoMatchHint
            : l10n.memoryFactsEmptyHint,
        action: filtered
            ? StudioButton(
                label: l10n.memoryShowAll,
                variant: StudioButtonVariant.secondary,
                onPressed: () {
                  _search.clear();
                  memory.search('');
                  for (final filter in [...memory.filters]) {
                    memory.toggle(filter);
                  }
                },
              )
            : StudioButton(
                label: l10n.memoryNewFact,
                icon: Icons.add,
                onPressed: memory.staging.editable
                    ? () => setState(() => _creating = true)
                    : null,
              ),
      );
    }
    return ListView.builder(
      key: const ValueKey('memory-fact-list'),
      padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
      itemCount: rows.length,
      itemBuilder: (context, index) => _row(context, rows[index]),
    );
  }

  Widget _row(BuildContext context, GameMemoryFactRow row) {
    final l10n = context.l10n;
    final memory = widget.memory;
    if (row.value == null) memory.reveal(row.id);
    final value = row.value;
    return StudioChoice(
      key: ValueKey('memory-fact-${row.id}'),
      label: row.label,
      subtitle: value == null
          ? l10n.memoryRowReading
          : l10n.memoryRowSubtitle(
              l10n.memoryKind(value.kind),
              l10n.memoryValue(value),
            ),
      selected: memory.selectedFact == row.id,
      trailing: row.unsaved ? StudioBadge(l10n.memoryUnsaved) : null,
      onTap: () => memory.select(row.id),
    );
  }
}
