import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_source.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviours_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_staging.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/verification/application/project_verification_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/verification/application/verification_problems.dart';
import 'package:avelune_studio/presentation/features/story/game_behaviours_view.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_rule_creation.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_usages.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_view.dart';
import 'package:avelune_studio/presentation/features/story/trame_view.dart';
import 'package:avelune_studio/presentation/features/story/verification_view.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

part 'story_page_navigation.dart';

enum StoryTab { trame, world, memory, verify }

class StoryPage extends StatefulWidget {
  const StoryPage({
    super.key,
    required this.port,
    required this.staging,
    required this.maps,
    required this.loadMap,
    required this.behaviours,
    required this.behaviourSource,
    required this.openMap,
    required this.trame,
    required this.verification,
    required this.simulate,
    required this.openMapEntry,
    required this.unsaved,
    this.openScene,
  });

  final NarrativeIndexPort? port;
  final GameMemoryStaging staging;
  final List<ProjectMapEntry> maps;
  final GameMemoryMapLoader? loadMap;
  final GameMemoryBehaviourLink behaviours;
  final GameBehaviourSource behaviourSource;
  final VoidCallback openMap;
  final StorylineTrameController? trame;
  final ProjectVerificationController? verification;
  final Future<bool> Function(String eventId) simulate;
  final Future<bool> Function(String mapId) openMapEntry;
  final bool unsaved;
  final SceneOpener? openScene;

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  var _tab = StoryTab.trame;
  final _opened = <StoryTab>{};
  GameMemoryController? _memory;
  GameBehavioursController? _behaviours;

  @override
  void initState() {
    super.initState();
    final port = widget.port;
    if (port == null) return;
    _memory = GameMemoryController(
      port: port,
      staging: widget.staging,
      changed: _changed,
    )..rules.mapName = _mapName;
    _behaviours = GameBehavioursController(
      port: port,
      source: () => widget.behaviourSource,
      changed: _changed,
    );
  }

  void _openTab(StoryTab tab) {
    if (!_opened.add(tab)) return;
    scheduleMicrotask(
      () => unawaited(switch (tab) {
        StoryTab.trame => widget.trame?.open() ?? Future<void>.value(),
        StoryTab.world => _behaviours!.open(),
        StoryTab.memory => _memory!.open(),
        StoryTab.verify => Future<void>.value(),
      }),
    );
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  String? _mapName(String id) =>
      widget.maps.where((entry) => entry.id == id).firstOrNull?.name;

  @override
  void dispose() {
    _memory?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final memory = _memory;
    final trame = widget.trame;
    if (memory != null) _openTab(_tab);
    return Column(
      key: const ValueKey('studio-story'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioTabBar<StoryTab>(
          key: const ValueKey('story-tabs'),
          tabs: [
            StudioTab(
              key: const ValueKey('story-tab-trame'),
              value: StoryTab.trame,
              label: l10n.storyTabTrame,
            ),
            StudioTab(
              key: const ValueKey('story-tab-world'),
              value: StoryTab.world,
              label: l10n.storyTabWorld,
            ),
            StudioTab(
              key: const ValueKey('story-tab-memory'),
              value: StoryTab.memory,
              label: l10n.storyTabMemory,
            ),
            StudioTab(
              key: const ValueKey('story-tab-verify'),
              value: StoryTab.verify,
              label: l10n.storyTabVerify,
            ),
          ],
          selected: _tab,
          onSelected: (tab) => setState(() => _tab = tab),
        ),
        Expanded(
          child: memory == null
              ? StudioEmptyState(
                  key: const ValueKey('memory-unavailable'),
                  icon: Icons.inventory_2_outlined,
                  title: l10n.memoryUnavailable,
                  description: l10n.memoryUnavailableHint,
                )
              : switch (_tab) {
                  StoryTab.trame when trame != null => TrameView(
                    trame: trame,
                    source: widget.behaviourSource,
                    navigate: widget.behaviours.open,
                    openScene: widget.openScene,
                  ),
                  StoryTab.trame => StudioEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.memoryUnavailable,
                    description: l10n.memoryUnavailableHint,
                  ),
                  StoryTab.world => GameBehavioursView(
                    behaviours: _behaviours!,
                    navigate: widget.behaviours.open,
                    openMap: widget.openMap,
                    trame: trame,
                    simulate: widget.simulate,
                    openScene: widget.openScene,
                  ),
                  StoryTab.verify => VerificationView(
                    verification: widget.verification,
                    unsaved: widget.unsaved,
                    destination: _destination,
                  ),
                  StoryTab.memory => GameMemoryView(
                    memory: memory,
                    maps: widget.maps,
                    loadMap: widget.loadMap,
                    behaviours: widget.behaviours,
                  ),
                },
        ),
      ],
    );
  }
}
