import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_source.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviours_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_staging.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/presentation/features/story/game_behaviours_view.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_rule_creation.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_usages.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_view.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

enum StoryTab { world, memory }

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
  });

  final NarrativeIndexPort? port;
  final GameMemoryStaging staging;
  final List<ProjectMapEntry> maps;
  final GameMemoryMapLoader? loadMap;
  final GameMemoryBehaviourLink behaviours;
  final GameBehaviourSource behaviourSource;
  final VoidCallback openMap;

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  var _tab = StoryTab.world;
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
    unawaited(_memory!.open());
    _behaviours = GameBehavioursController(
      port: port,
      source: () => widget.behaviourSource,
      changed: _changed,
    );
    unawaited(_behaviours!.open());
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
    return Column(
      key: const ValueKey('studio-story'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioTabBar<StoryTab>(
          key: const ValueKey('story-tabs'),
          tabs: [
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
                  StoryTab.world => GameBehavioursView(
                    behaviours: _behaviours!,
                    navigate: widget.behaviours.open,
                    openMap: widget.openMap,
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
