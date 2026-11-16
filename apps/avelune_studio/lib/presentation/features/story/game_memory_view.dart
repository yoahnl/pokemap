import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_fact_detail.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_fact_list.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_rule_creation.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_rule_editor.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_rule_list.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_usages.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'story_workspace.dart';

class GameMemoryView extends StatefulWidget {
  const GameMemoryView({
    super.key,
    required this.memory,
    required this.maps,
    required this.loadMap,
    required this.behaviours,
    required this.panels,
  });

  final GameMemoryController memory;
  final List<ProjectMapEntry> maps;
  final GameMemoryMapLoader? loadMap;
  final GameMemoryBehaviourLink behaviours;
  final StoryPanelBuilder panels;

  @override
  State<GameMemoryView> createState() => _GameMemoryViewState();
}

class _GameMemoryViewState extends State<GameMemoryView> {
  var _creatingRule = false;

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    if (TickerMode.valuesOf(context).enabled) scheduleMicrotask(memory.sync);
    final loadMap = widget.loadMap;
    final canCreateRule =
        memory.staging.editable &&
        loadMap != null &&
        memory.allFacts.isNotEmpty &&
        widget.maps.isNotEmpty;
    return widget.panels(
      Column(
        key: const ValueKey('memory-list-panel'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: memory.section == GameMemorySection.facts
                ? GameMemoryFactList(memory: memory)
                : GameMemoryRuleList(
                    memory: memory,
                    onCreate: canCreateRule
                        ? () => setState(() => _creatingRule = true)
                        : null,
                  ),
          ),
        ],
      ),
      _detail(context),
    );
  }

  Widget _detail(BuildContext context) {
    final l10n = context.l10n;
    final memory = widget.memory;
    if (memory.section == GameMemorySection.facts) {
      final id = memory.selectedFact;
      return id == null
          ? StudioEmptyState(
              icon: Icons.touch_app_outlined,
              title: l10n.memorySelectFact,
            )
          : GameMemoryFactDetail(
              key: ValueKey('memory-fact-detail-host-$id'),
              memory: memory,
              factId: id,
              behaviours: widget.behaviours,
            );
    }
    final loadMap = widget.loadMap;
    if (_creatingRule && loadMap != null) {
      return GameMemoryRuleCreation(
        memory: memory,
        maps: widget.maps,
        loadMap: loadMap,
        onClose: () => setState(() => _creatingRule = false),
      );
    }
    final rule = switch (memory.rules.selected) {
      final id? => memory.rules.rule(id),
      null => null,
    };
    return rule == null
        ? StudioEmptyState(icon: Icons.rule, title: l10n.memorySelectRule)
        : GameMemoryRuleEditor(memory: memory, rule: rule);
  }
}
