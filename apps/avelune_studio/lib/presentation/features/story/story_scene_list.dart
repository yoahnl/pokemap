import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_resource.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'game_memory_states.dart';
import 'story_workspace.dart';

class StorySceneList extends StatefulWidget {
  const StorySceneList({
    super.key,
    required this.port,
    required this.openScene,
    required this.panels,
  });

  final NarrativeIndexPort port;
  final SceneOpener? openScene;
  final StoryPanelBuilder panels;

  @override
  State<StorySceneList> createState() => _StorySceneListState();
}

class _StorySceneListState extends State<StorySceneList> {
  final _titles = GameMemoryResource<List<NarrativeTitle>>();
  NarrativeTitle? _selected;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_load);
  }

  void _load({bool force = false}) => unawaited(
    _titles.load(() => widget.port.titles(NarrativeTitleKind.scenes), () {
      if (mounted) setState(() {});
    }, force: force),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = gameMemoryResourceState(
      context,
      _titles,
      loading: l10n.storyScenesLoading,
      onRetry: () => _load(force: true),
    );
    final selected = _selected;
    return widget.panels(
      state ??
          (_titles.value!.isEmpty
              ? StudioEmptyState(
                  icon: Icons.account_tree_outlined,
                  title: l10n.storyScenesEmpty,
                  description: l10n.storyScenesEmptyHint,
                )
              : ListView.builder(
                  key: const ValueKey('story-scenes-list'),
                  padding: const EdgeInsets.all(StudioSpacing.l),
                  itemCount: _titles.value!.length,
                  itemBuilder: (context, index) {
                    final title = _titles.value![index];
                    return StudioChoice(
                      key: ValueKey('story-scene-${title.id}'),
                      label: _label(title),
                      selected: title.id == selected?.id,
                      onTap: () => setState(() => _selected = title),
                    );
                  },
                )),
      selected == null
          ? StudioEmptyState(
              icon: Icons.touch_app_outlined,
              title: l10n.storySelectScene,
            )
          : ListView(
              padding: const EdgeInsets.all(StudioSpacing.l),
              children: [
                Text(
                  _label(selected),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: StudioSpacing.l),
                StudioButton(
                  key: const ValueKey('story-scene-open'),
                  label: l10n.sceneGraphOpen,
                  icon: Icons.open_in_new,
                  onPressed: widget.openScene == null
                      ? null
                      : () => widget.openScene!(selected.id, null),
                ),
              ],
            ),
    );
  }

  String _label(NarrativeTitle title) =>
      title.title.trim().isEmpty ? context.l10n.storyUnnamedScene : title.title;
}
