import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_source.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/features/story/trame_detail.dart';
import 'package:avelune_studio/presentation/features/story/trame_labels.dart';
import 'package:avelune_studio/presentation/features/story/trame_selection.dart';
import 'package:avelune_studio/presentation/features/story/trame_start.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class TrameView extends StatefulWidget {
  const TrameView({
    super.key,
    required this.trame,
    required this.source,
    required this.navigate,
  });

  final StorylineTrameController trame;
  final GameBehaviourSource source;
  final Future<bool> Function(String eventId) navigate;

  @override
  State<TrameView> createState() => _TrameViewState();
}

class _TrameViewState extends State<TrameView> {
  TrameSelection? _selected;
  (Object?, List<GameBehaviourRow>)? _rows;

  List<GameBehaviourRow> get _behaviours {
    final registry = widget.source.registry;
    final cached = _rows;
    if (cached != null && identical(cached.$1, registry)) return cached.$2;
    final rows = gameBehaviourRows(
      saved: [
        for (final record
            in registry?.records ?? const <NarrativeEventRecord>[])
          NarrativeTitle(id: record.id, title: ''),
      ],
      source: widget.source,
    );
    _rows = (registry, rows);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final trame = widget.trame;
    if (TickerMode.valuesOf(context).enabled) scheduleMicrotask(trame.sync);
    final state = gameMemoryResourceState(
      context,
      trame.outline,
      loading: l10n.trameLoading,
      onRetry: trame.retry,
    );
    if (state != null) return state;
    final view = trame.view!;
    if (view.outline.storylines.isEmpty) {
      return TrameStart(trame: trame);
    }
    if (view.milestones.any((at) => at.milestone.completionFactId != null)) {
      scheduleMicrotask(trame.ensureFactNames);
    }
    final entries = <(TrameSelection, Widget)>[];
    for (final storyline in view.outline.storylines) {
      final key = (
        item: TrameItem.storyline,
        storylineId: storyline.id,
        chapterId: null,
        milestoneId: null,
      );
      entries.add((
        key,
        _entry(
          key,
          l10n.trameName(storyline.title, l10n.trameUnnamed),
          l10n.trameType(storyline.type),
          0,
          archived: trameArchived(storyline.status),
        ),
      ));
      for (final chapter in storyline.chapters) {
        final chapterKey = (
          item: TrameItem.chapter,
          storylineId: storyline.id,
          chapterId: chapter.id,
          milestoneId: null,
        );
        entries.add((
          chapterKey,
          _entry(
            chapterKey,
            l10n.trameName(chapter.title, l10n.trameUnnamed),
            l10n.trameMilestoneCount(chapter.milestones.length),
            1,
            archived: trameArchived(chapter.status),
          ),
        ));
        for (final milestone in chapter.milestones) {
          final milestoneKey = (
            item: TrameItem.milestone,
            storylineId: storyline.id,
            chapterId: chapter.id,
            milestoneId: milestone.id,
          );
          entries.add((
            milestoneKey,
            _entry(
              milestoneKey,
              l10n.trameName(milestone.title, l10n.trameUnnamed),
              l10n.trameMilestoneSummary(
                view.behavioursOf(milestone).length,
                milestone.issues.length,
              ),
              2,
              archived: trameArchived(milestone.status),
              warning: milestone.issues.isNotEmpty,
            ),
          ));
        }
      }
    }
    entries.add((
      trameOutside,
      _entry(
        trameOutside,
        l10n.trameOutside,
        l10n.trameOutsideCount(view.outsideBehaviours.length),
        0,
      ),
    ));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Ink(
          key: const ValueKey('trame-outline'),
          width: 380,
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(right: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (trame.refusal case final code?)
                Padding(
                  padding: const EdgeInsets.all(StudioSpacing.l),
                  child: StudioNotice(
                    key: const ValueKey('trame-refusal'),
                    l10n.trameRefused(code),
                    isError: true,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  key: const ValueKey('trame-list'),
                  padding: const EdgeInsets.all(StudioSpacing.l),
                  itemCount: entries.length,
                  itemBuilder: (context, index) => entries[index].$2,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Material(
            color: scheme.surfaceContainerLowest,
            child: TrameDetail(
              trame: trame,
              view: view,
              selection: _selected,
              behaviours: _behaviours,
              navigate: widget.navigate,
            ),
          ),
        ),
      ],
    );
  }

  Widget _entry(
    TrameSelection key,
    String label,
    String subtitle,
    int depth, {
    bool archived = false,
    bool warning = false,
  }) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(left: depth * StudioSpacing.xl),
      child: StudioChoice(
        key: ValueKey(
          'trame-${key.item.name}-${key.milestoneId ?? key.chapterId ?? key.storylineId ?? 'outside'}',
        ),
        label: label,
        subtitle: subtitle,
        selected: _selected == key,
        tone: warning ? StudioTone.warning : null,
        trailing: archived ? StudioBadge(l10n.trameArchivedBadge) : null,
        onTap: () => setState(() => _selected = key),
      ),
    );
  }
}
