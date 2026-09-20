import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart'
    hide dialogueSteps;
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'dialogue_document_toolbar.dart';
import '../narrative/narrative_name_dialog.dart';
import 'dialogue_view_state.dart';
import 'dialogue_library.dart';
import 'dialogue_graph_canvas.dart';
import 'dialogue_inspector.dart';
import 'dialogue_preview_panel.dart';
import 'dialogue_portrait_image.dart';
import 'dialogue_add_toolbar.dart';
import '../../theme/studio_dialogue_theme.dart';

part 'dialogue_page_commands.dart';

class DialogueWorkspacePage extends StatefulWidget {
  const DialogueWorkspacePage({
    super.key,
    required this.controller,
    required this.views,
    required this.onBack,
    this.backLabel = 'Histoire',
  });
  final DialogueWorkspaceController controller;
  final DialogueViewStore views;
  final VoidCallback onBack;
  final String backLabel;
  @override
  State<DialogueWorkspacePage> createState() => _DialogueWorkspacePageState();
}

class _DialogueWorkspacePageState extends State<DialogueWorkspacePage> {
  DialogueWorkspaceController get controller => widget.controller;
  DialogueViewState? get view => controller.activeId == null
      ? null
      : widget.views.forDialogue(controller.activeId!);
  void refresh() {
    if (mounted) setState(() {});
  }

  bool flush() {
    final previous = controller.error;
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    return controller.error == null || controller.error == previous;
  }

  @override
  Widget build(BuildContext context) {
    final session = controller.active;
    final state = view;
    if (session != null) state!.reconcile(session.document);
    final editable = session != null && session.readOnlyReason == null;
    return StudioDialogueTheme(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true): save,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): save,
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 1080 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            final small = constraints.maxHeight < 650;
            final library = DialogueLibrary(
              controller: controller,
              views: widget.views,
              changed: refresh,
              onOpen: open,
              onCreate: create,
            );
            final inspector = session == null
                ? null
                : DialogueInspector(
                    controller: controller,
                    view: state!,
                    changed: refresh,
                    onAddOutcome: addOutcome,
                    onDelete: deleteSelection,
                    onConnect: connect,
                    portrait: portrait,
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StudioButton(
                      label: 'Retour à ${widget.backLabel}',
                      secondary: true,
                      icon: Icons.arrow_back,
                      onPressed: () {
                        flush();
                        widget.onBack();
                      },
                    ),
                  ),
                ),
                StudioPageHeader(
                  title: 'Éditeur de dialogue',
                  prominent: !small,
                  description: small
                      ? null
                      : 'Écrivez les répliques, reliez les réponses, essayez chaque chemin.',
                  alignActionsToEnd: true,
                  actions: [
                    StudioTool(
                      label: 'Bibliothèque de dialogues',
                      icon: Icons.view_sidebar,
                      onPressed: () {
                        flush();
                        widget.views.libraryOpen = !widget.views.libraryOpen;
                        widget.views.inspectorOpen = false;
                        refresh();
                      },
                    ),
                    StudioTool(
                      label: 'Inspecteur du dialogue',
                      icon: Icons.tune,
                      onPressed: () {
                        flush();
                        widget.views.inspectorOpen =
                            !widget.views.inspectorOpen;
                        widget.views.libraryOpen = false;
                        refresh();
                      },
                    ),
                    StudioTool(
                      label: 'Annuler le dialogue',
                      icon: Icons.undo,
                      onPressed: editable ? undo : null,
                    ),
                    StudioTool(
                      label: 'Rétablir le dialogue',
                      icon: Icons.redo,
                      onPressed: editable ? redo : null,
                    ),
                    StudioButton(
                      label: 'Tester',
                      icon: Icons.play_arrow,
                      secondary: true,
                      onPressed: session == null
                          ? null
                          : () {
                              if (!flush()) return;
                              state!.previewOpen = true;
                              if (compact || small) {
                                widget.views.inspectorOpen = true;
                                widget.views.libraryOpen = false;
                                state.tab = 'preview';
                              }
                              controller.startPreview();
                            },
                    ),
                    StudioButton(
                      label: 'Enregistrer',
                      icon: Icons.save_outlined,
                      onPressed: session == null || controller.busy
                          ? null
                          : save,
                    ),
                  ],
                ),
                if (controller.error ?? session?.error case final error?)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: StudioNotice(error, isError: true),
                      ),
                    ),
                  ),
                if (session?.readOnlyReason case final reason?)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(child: StudioNotice(reason)),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!compact ||
                            widget.views.libraryOpen ||
                            session == null) ...[
                          SizedBox(width: compact ? 250 : 238, child: library),
                          const SizedBox(width: 8),
                        ],
                        if (compact &&
                            widget.views.inspectorOpen &&
                            inspector != null)
                          Expanded(child: inspector)
                        else
                          Expanded(
                            child: session == null
                                ? Center(
                                    child: controller.busy
                                        ? const CircularProgressIndicator()
                                        : const Text(
                                            'Ouvrez un dialogue ou créez votre première conversation.',
                                          ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      DialogueDocumentToolbar(
                                        name: session.entry.name,
                                        dirty: session.dirty,
                                        onRename: editable ? rename : null,
                                        onDuplicate: duplicate,
                                        onDelete: deleteDialogue,
                                        onReload: reload,
                                        onPreview: () {
                                          flush();
                                          if (compact || small) {
                                            widget.views.inspectorOpen = true;
                                            state!.tab = 'preview';
                                          } else {
                                            state!.previewOpen =
                                                !state.previewOpen;
                                          }
                                          refresh();
                                        },
                                      ),
                                      if (editable)
                                        DialogueAddToolbar(
                                          onNode: addNode,
                                          onLine: () => addLine(false),
                                          onNarration: () => addLine(true),
                                          onChoice: addChoice,
                                        ),
                                      Expanded(
                                        child: DialogueGraphCanvas(
                                          key: ValueKey(session.entry.id),
                                          document: session.document,
                                          view: state!,
                                          changed: refresh,
                                          onConnect: connect,
                                          portrait: portrait,
                                          outcomes: {
                                            for (final o
                                                in session
                                                    .entry
                                                    .declaredOutcomes)
                                              o.id: o.label,
                                          },
                                          onDelete: deleteSelection,
                                          onUndo: controller.undo,
                                          onRedo: controller.redo,
                                          onSave: save,
                                        ),
                                      ),
                                      if (state.previewOpen &&
                                          !small &&
                                          !compact) ...[
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 218,
                                          child: DialoguePreviewPanel(
                                            controller: controller,
                                            portrait: portrait,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        if (!compact && inspector != null) ...[
                          const SizedBox(width: 8),
                          SizedBox(width: 286, child: inspector),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
