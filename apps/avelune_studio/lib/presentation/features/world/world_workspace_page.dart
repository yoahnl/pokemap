import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/world/application/world_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'world_view_state.dart';

part 'world_library.dart';
part 'world_fact_editor.dart';
part 'world_rule_composer.dart';
part 'world_rule_pickers.dart';
part 'world_context_panel.dart';
part 'world_preview.dart';

class WorldWorkspacePage extends StatefulWidget {
  const WorldWorkspacePage({
    super.key,
    required this.controller,
    required this.view,
    required this.onBack,
    this.backLabel = 'Histoire',
    this.onOpenScene,
    this.onOpenDialogue,
    this.visuals,
  });

  final WorldWorkspaceController controller;
  final WorldViewState view;
  final VoidCallback onBack;
  final String backLabel;
  final Future<void> Function(String sceneId)? onOpenScene;
  final Future<void> Function(String dialogueId)? onOpenDialogue;
  final MapWorkspaceVisuals? visuals;

  @override
  State<WorldWorkspacePage> createState() => _WorldWorkspacePageState();
}

class _WorldWorkspacePageState extends State<WorldWorkspacePage> {
  WorldWorkspaceController get controller => widget.controller;
  WorldViewState get view => widget.view;

  void refresh() {
    if (mounted) setState(() {});
  }

  bool flush() {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    return view.invalidFields.isEmpty;
  }

  bool get _rules => view.view == WorldView.rules;

  String? get _selectedId =>
      _rules ? controller.selectedRuleId : controller.selectedFactId;

  bool get _selectionDirty =>
      _selectedId != null &&
      (_rules
          ? controller.isRuleDirty(_selectedId!)
          : controller.isFactDirty(_selectedId!));

  Future<void> _save() async {
    final id = _selectedId;
    if (!flush() || id == null) return;
    _rules ? await controller.saveRule(id) : await controller.saveFact(id);
    refresh();
  }

  void _create() {
    if (!flush()) return;
    _rules ? controller.createRule() : controller.createFact();
    refresh();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 1000 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(compact),
            if (controller.loading) const LinearProgressIndicator(),
            if (controller.error ?? view.actionError case final message?)
              StudioNotice(message, isError: true),
            const SizedBox(height: 10),
            Expanded(child: compact ? _compactBody() : _wideBody()),
          ],
        ),
      );
    },
  );

  Widget _header(bool compact) => StudioPageHeader(
    title: 'États et règles du monde',
    description:
        'Définissez les informations mémorisées et les règles qui modifient '
        'votre jeu en fonction de ces états.',
    alignActionsToEnd: true,
    actions: [
      StudioTool(
        label: 'Retour à ${widget.backLabel}',
        icon: Icons.arrow_back,
        onPressed: widget.onBack,
      ),
      if (!compact) ...[
        StudioTool(
          label: 'Bibliothèque',
          icon: Icons.view_sidebar_outlined,
          selected: view.libraryOpen,
          onPressed: () {
            view.libraryOpen = !view.libraryOpen;
            refresh();
          },
        ),
        StudioTool(
          label: 'Panneau contextuel',
          icon: Icons.tune,
          selected: view.contextOpen,
          onPressed: () {
            view.contextOpen = !view.contextOpen;
            refresh();
          },
        ),
      ],
      StudioButton(
        label: 'Enregistrer',
        icon: Icons.save_outlined,
        loading: controller.loading,
        onPressed: _selectionDirty ? _save : null,
      ),
    ],
  );

  Widget _tabs() => StudioTabs<WorldView>(
    items: const {
      WorldView.states: 'États',
      WorldView.rules: 'Règles du monde',
    },
    selected: view.view,
    onChanged: (next) {
      if (!flush()) return;
      view.view = next;
      refresh();
    },
  );

  Widget _wideBody() => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (view.libraryOpen) ...[
        SizedBox(width: 260, child: _library()),
        const SizedBox(width: 10),
      ],
      Expanded(child: _center()),
      if (view.contextOpen) ...[
        const SizedBox(width: 10),
        SizedBox(width: 300, child: _contextPanel()),
      ],
    ],
  );

  Widget _compactBody() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _tabs(),
      const SizedBox(height: 8),
      Expanded(child: _center()),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          StudioButton(
            label: 'Bibliothèque',
            secondary: true,
            onPressed: () => _sheet(_library()),
          ),
          StudioButton(
            label: 'Contexte',
            secondary: true,
            onPressed: () => _sheet(_contextPanel()),
          ),
        ],
      ),
    ],
  );

  Future<void> _sheet(Widget child) async {
    if (!flush()) return;
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 340,
          height: MediaQuery.sizeOf(context).height * .8,
          child: child,
        ),
      ),
    );
    refresh();
  }

  Widget _center() => _rules ? _ruleComposer() : _factEditor();
}
