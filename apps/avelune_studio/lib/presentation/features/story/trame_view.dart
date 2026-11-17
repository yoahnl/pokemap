import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_source.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_view.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'game_memory_states.dart';
import 'story_workspace.dart';
import 'trame_detail.dart';
import 'trame_outline.dart';
import 'trame_selection.dart';
import 'trame_start.dart';

class TrameView extends StatefulWidget {
  const TrameView({
    super.key,
    required this.trame,
    required this.source,
    required this.navigate,
    required this.panels,
    this.openScene,
    this.onSelected,
  });

  final StorylineTrameController trame;
  final GameBehaviourSource source;
  final Future<bool> Function(String eventId) navigate;
  final SceneOpener? openScene;
  final StoryPanelBuilder panels;
  final ValueChanged<String?>? onSelected;

  @override
  State<TrameView> createState() => _TrameViewState();
}

class _TrameViewState extends State<TrameView> {
  TrameSelection? _selected;
  var _showArchived = false;
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

  void _select(TrameSelection selection) {
    setState(() => _selected = selection);
    widget.onSelected?.call(selection.storylineId);
  }

  void _focusUsage(StorylineTrameView view) {
    final target = widget.trame.usageFocus;
    if (target == null) return;
    widget.trame.usageFocus = null;
    widget.trame.focus = null;
    final story = view.outline.storylines
        .where((story) => story.id == target.storylineId)
        .firstOrNull;
    if (story == null) return;
    final chapter = target.stepId == null
        ? null
        : story.chapters
              .where(
                (chapter) =>
                    chapter.milestones.any((step) => step.id == target.stepId),
              )
              .firstOrNull;
    if (target.stepId != null && chapter == null) return;
    final step = chapter?.milestones
        .where((step) => step.id == target.stepId)
        .firstOrNull;
    _selected = (
      item: step == null ? TrameItem.storyline : TrameItem.milestone,
      storylineId: story.id,
      chapterId: chapter?.id,
      milestoneId: step?.id,
    );
    if (story.status == StorylineStatus.archived ||
        chapter?.status == StorylineStatus.archived ||
        step?.status == StorylineStatus.archived) {
      _showArchived = true;
    }
    scheduleMicrotask(() {
      if (mounted) widget.onSelected?.call(story.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trame = widget.trame;
    if (TickerMode.valuesOf(context).enabled) scheduleMicrotask(trame.sync);
    final state = gameMemoryResourceState(
      context,
      trame.outline,
      loading: l10n.trameLoading,
      onRetry: trame.retry,
    );
    if (state != null) return _panels(state);
    final view = trame.view!;
    _focusUsage(view);
    if (trame.focus case final id?) {
      trame.focus = null;
      if (view.milestone(id) case final at?) {
        _selected = (
          item: TrameItem.milestone,
          storylineId: at.storyline.id,
          chapterId: at.chapter.id,
          milestoneId: id,
        );
        if (at.storyline.status == StorylineStatus.archived ||
            at.chapter.status == StorylineStatus.archived ||
            at.milestone.status == StorylineStatus.archived) {
          _showArchived = true;
        }
        scheduleMicrotask(() {
          if (mounted) widget.onSelected?.call(at.storyline.id);
        });
      } else if (view.outline.storylines
              .where((story) => story.id == id)
              .firstOrNull
          case final story?) {
        _selected = (
          item: TrameItem.storyline,
          storylineId: story.id,
          chapterId: null,
          milestoneId: null,
        );
        if (story.status == StorylineStatus.archived) _showArchived = true;
        scheduleMicrotask(() {
          if (mounted) widget.onSelected?.call(story.id);
        });
      }
    }
    final selectedId = _selected?.milestoneId;
    if (_selected?.item == TrameItem.milestone && selectedId != null) {
      if (view.milestones
              .where(
                (at) =>
                    at.storyline.id == _selected?.storylineId &&
                    at.milestone.id == selectedId,
              )
              .firstOrNull
          case final at?) {
        _selected = (
          item: TrameItem.milestone,
          storylineId: at.storyline.id,
          chapterId: at.chapter.id,
          milestoneId: selectedId,
        );
      }
    }
    if (!_showArchived) {
      final previous = _selected;
      _selected = visibleTrameSelection(view.outline, previous);
      if (previous?.storylineId != _selected?.storylineId) {
        final selected = _selected;
        scheduleMicrotask(() {
          if (mounted && selected == _selected) {
            widget.onSelected?.call(selected?.storylineId);
          }
        });
      }
    }
    if (view.outline.storylines.isEmpty) {
      return _panels(TrameStart(trame: trame));
    }
    if (view.milestones.any((at) => at.milestone.completionFactId != null)) {
      scheduleMicrotask(trame.ensureFactNames);
    }
    scheduleMicrotask(trame.ensureSceneNames);
    return widget.panels(
      TrameOutline(
        trame: trame,
        view: view,
        selection: _selected,
        showArchived: _showArchived,
        onShowArchived: (value) => setState(() => _showArchived = value),
        onSelected: _select,
      ),
      TrameDetail(
        trame: trame,
        view: view,
        selection: _selected,
        behaviours: _behaviours,
        navigate: widget.navigate,
        openScene: widget.openScene,
      ),
    );
  }

  Widget _panels(Widget content) => widget.panels(
    content,
    StudioEmptyState(
      icon: Icons.touch_app_outlined,
      title: context.l10n.trameSelect,
    ),
  );
}
