import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_source.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviours_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_staging.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/story_workspace/application/story_workspace_state.dart';
import 'package:avelune_studio/features/story_workspace/application/story_history_scope.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/verification/application/project_verification_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_catalog_controller.dart';
import 'package:avelune_studio/features/verification/application/verification_problems.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_controller.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_draft_host.dart';
import 'package:avelune_studio/presentation/features/story/game_behaviours_view.dart';
import 'package:avelune_studio/presentation/features/story/game_behaviour_labels.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_rule_creation.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_usages.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_view.dart';
import 'package:avelune_studio/presentation/features/story/trame_view.dart';
import 'package:avelune_studio/presentation/features/story/verification_view.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'dialogues/story_dialogues_view.dart';
import 'behaviours/game_behaviour_workspace.dart';
import 'story_behaviour_context.dart';
import '../map_builder/map_builder_story_catalog_binding.dart';
import '../map_builder/map_builder_story_binding.dart';
import 'scenes/scene_catalog_view.dart';
import 'story_workspace.dart';

part 'story_page_navigation.dart';
part 'story_page_dialogues.dart';
part 'story_page_body.dart';

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
    this.saveError,
    this.openScene,
    this.beforeNavigation,
    this.onHistoryScopeChanged,
    this.catalog,
    this.behaviourCatalog,
    this.dialoguePort,
    this.dialogueRequest,
    this.behaviourRequest,
    this.dialogueStaging,
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
  final String? saveError;
  final SceneOpener? openScene;
  final Future<void> Function()? beforeNavigation;
  final ValueChanged<StoryHistoryScope>? onHistoryScopeChanged;
  final SceneCatalogController? catalog;
  final MapBuilderStoryCatalogBinding? behaviourCatalog;
  final DialogueCatalogPort? dialoguePort;
  final ({String id, int token})? dialogueRequest;
  final ({String id, int token})? behaviourRequest;
  final DialogueDraftHost? dialogueStaging;

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  var _workspace = const StoryWorkspaceState();
  final _opened = <StorySection>{};
  GameMemoryController? _memory;
  GameBehavioursController? _behaviours;
  SceneCatalogController? _catalog;
  DialogueCatalogController? _dialogues;

  @override
  void initState() {
    super.initState();
    if (widget.dialogueRequest != null) {
      _workspace = _workspace.select(StorySection.dialogues);
      scheduleMicrotask(_consumeDialogueRequest);
    }
    if (widget.behaviourRequest != null) {
      _workspace = _workspace.select(StorySection.behaviours);
      scheduleMicrotask(_consumeBehaviourRequest);
    }
  }

  @override
  void didUpdateWidget(StoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dialogueRequest != widget.dialogueRequest) {
      scheduleMicrotask(_consumeDialogueRequest);
    }
    if (oldWidget.behaviourRequest != widget.behaviourRequest) {
      scheduleMicrotask(_consumeBehaviourRequest);
    }
  }

  void _openSection(StorySection section) {
    final port = widget.port;
    if (section == StorySection.dialogues && port != null) {
      _dialogues ??= DialogueCatalogController(
        index: port,
        port: widget.dialoguePort,
        draft: widget.staging.draft,
        revision: () => widget.behaviourSource.revision,
        changed: _changed,
        editing: widget.dialogueStaging,
      );
    }
    if (port != null) {
      if (section == StorySection.scenes) {
        _catalog ??=
            widget.catalog ??
            SceneCatalogController(
              port: port,
              storylines: widget.trame?.port,
              draft: widget.staging.draft,
              source: () => widget.behaviourSource,
              changed: _changed,
            );
      }
      if (section == StorySection.facts || section == StorySection.rules) {
        _memory ??= GameMemoryController(
          port: port,
          staging: widget.staging,
          changed: _changed,
        )..rules.mapName = _mapName;
        _memory!.section = section == StorySection.facts
            ? GameMemorySection.facts
            : GameMemorySection.rules;
      }
      if (section == StorySection.behaviours) {
        _behaviours ??= GameBehavioursController(
          port: port,
          source: () => widget.behaviourSource,
          changed: _changed,
        );
      }
    }
    if (!_opened.add(section)) return;
    scheduleMicrotask(() {
      if (!mounted) return;
      unawaited(switch (section) {
        StorySection.trame => widget.trame?.open() ?? Future<void>.value(),
        StorySection.behaviours => _behaviours?.open() ?? Future<void>.value(),
        StorySection.scenes => _catalog?.open() ?? Future<void>.value(),
        StorySection.dialogues => _dialogues?.open() ?? Future<void>.value(),
        StorySection.facts => _memory?.open() ?? Future<void>.value(),
        StorySection.rules => _openRules(),
        _ => Future<void>.value(),
      });
    });
  }

  Future<void> _openRules() async {
    final memory = _memory;
    if (memory == null) return;
    await memory.open();
    await memory.rules.open();
  }

  Future<void> _select(StorySection section) async {
    await widget.beforeNavigation?.call();
    if (!mounted) return;
    _openSection(section);
    setState(() => _workspace = _workspace.select(section));
    _notifyScope();
  }

  void _selectItem(StorySection section, StoryDraftRef? ref) {
    _workspace = _workspace.selectItem(section, ref);
    _notifyScope();
  }

  void _notifyScope() {
    final id = widget.behaviourCatalog?.editor?.selectedBehaviour?.id;
    if (id != null) {
      _workspace = _workspace.selectItem(StorySection.behaviours, (
        kind: StoryDraftKind.event,
        id: id,
      ));
    }
    widget.onHistoryScopeChanged?.call(
      StoryHistoryScope([?_workspace.selection]),
    );
  }

  void _changed() {
    if (!mounted) return;
    if (_workspace.section == StorySection.facts ||
        _workspace.section == StorySection.rules) {
      _workspace = _workspace.select(
        _memory?.section == GameMemorySection.rules
            ? StorySection.rules
            : StorySection.facts,
      );
    }
    if (_memory case final memory?) {
      _workspace = _workspace
          .selectItem(StorySection.facts, switch (memory.selectedFact) {
            final id? => (kind: StoryDraftKind.fact, id: id),
            null => null,
          })
          .selectItem(StorySection.rules, switch (memory.rules.selected) {
            final id? => (kind: StoryDraftKind.worldRule, id: id),
            null => null,
          });
    }
    if (_dialogues?.selectedId case final id?) {
      _workspace = _workspace.selectItem(StorySection.dialogues, (
        kind: StoryDraftKind.dialogue,
        id: id,
      ));
    }
    _notifyScope();
    setState(() {});
  }

  String? _mapName(String id) =>
      widget.maps.where((entry) => entry.id == id).firstOrNull?.name;

  @override
  void dispose() {
    _memory?.dispose();
    _dialogues?.dispose();
    if (!identical(_catalog, widget.catalog)) _catalog?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _openSection(_workspace.section);
    return StoryWorkspace(
      section: _workspace.section,
      onSelected: _select,
      editable: widget.staging.editable,
      saveError: widget.saveError,
      inspectorAvailable: !{
        StorySection.dialogues,
        StorySection.behaviours,
      }.contains(_workspace.section),
      builder: (panels) => IndexedStack(
        index: _workspace.section.index,
        children: [
          for (final section in StorySection.values)
            TooltipVisibility(
              visible:
                  TooltipVisibility.of(context) &&
                  section == _workspace.section,
              child: TickerMode(
                enabled: section == _workspace.section,
                child: _opened.contains(section)
                    ? KeyedSubtree(
                        key: ValueKey(section),
                        child: _body(section, panels),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
