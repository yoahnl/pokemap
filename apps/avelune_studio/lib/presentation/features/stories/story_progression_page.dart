import 'package:flutter/material.dart';
import '../../../features/stories/application/story_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../narrative/narrative_name_dialog.dart';
import 'story_create_dialog.dart';
import 'story_coherence_dialog.dart';
import 'story_document_commands.dart';
import 'story_graph_canvas.dart';
import 'story_inspector.dart';
import 'story_library_panel.dart';
import 'story_progression_view_store.dart';
import 'story_structure_view.dart';
part 'story_progression_content.dart';

class StoryProgressionPage extends StatefulWidget {
  const StoryProgressionPage({
    super.key,
    required this.controller,
    required this.views,
    required this.onBack,
    this.onBackLabel = 'Histoire',
    required this.onOpenScene,
  });
  final StoryWorkspaceController controller;
  final StoryProgressionViewStore views;
  final VoidCallback onBack;
  final String onBackLabel;
  final Future<String?> Function(String) onOpenScene;
  @override
  State<StoryProgressionPage> createState() => _StoryProgressionPageState();
}

class _StoryProgressionPageState extends State<StoryProgressionPage> {
  StoryWorkspaceController get controller => widget.controller;
  StoryProgressionDocumentView get view => widget.views.forStory(
    controller.workspace,
    controller.activeId ?? '__empty',
  );
  String? _notice;
  void _refresh([VoidCallback? change]) => setState(change ?? () {});

  @override
  void initState() {
    super.initState();
    if (controller.active == null && controller.stories.isNotEmpty) {
      controller.activeId = controller.stories.first.id;
    }
  }

  void _select(StoryGraphSelection? selection) {
    FocusManager.instance.applyFocusChangesIfNeeded();
    setState(() {
      view.selection = selection;
      view.inspector = selection != null;
    });
  }

  void _open(String id) {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    controller.open(id);
    setState(() {});
  }

  Future<void> _create() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final value = await askStoryCreation(context);
    if (!mounted || value == null) return;
    controller.create(value.$1, type: value.$2);
    setState(() {});
  }

  Future<void> _add(String? chapterId) async {
    final storyId = controller.activeId;
    if (storyId == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final name = await askNarrativeName(
      context,
      chapterId == null ? 'Nouveau chapitre' : 'Nouvelle étape',
    );
    if (!mounted || name == null) return;
    final commands = StoryDocumentCommands(controller);
    if (chapterId == null) {
      commands.addChapter(storyId, name);
    } else {
      commands.addStep(storyId, chapterId, name);
    }
    setState(() {});
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    final ok = await controller.saveAll();
    if (mounted) {
      setState(() {
        _notice = ok ? 'Histoires enregistrées.' : null;
      });
    }
  }

  Future<void> _verify() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final id = controller.activeId;
    if (id == null) return;
    final target = await showStoryCoherence(context, controller.project, id);
    if (!mounted || controller.activeId != id || target == null) return;
    _select(target);
    _structure(false);
  }

  void _structure(bool value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      view.structure = value;
    });
    if (!value && view.selection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) view.graph.reveal(view.selection!);
      });
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final compact =
          size.maxWidth < 1150 ||
          MediaQuery.textScalerOf(context).scale(14) > 19;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact)
            _compactHeader()
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StudioButton(
                    label: widget.onBackLabel,
                    secondary: true,
                    icon: Icons.arrow_back,
                    onPressed: widget.onBack,
                  ),
                  Text(
                    'Histoires et progression',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  StudioButton(
                    label: 'Nouvelle histoire',
                    icon: Icons.add,
                    onPressed: _create,
                  ),
                  StudioButton(
                    label: 'Enregistrer',
                    icon: Icons.save_outlined,
                    onPressed:
                        (controller.active != null || controller.dirty) &&
                            !controller.busy
                        ? _save
                        : null,
                  ),
                  Text(
                    controller.busy
                        ? 'Enregistrement…'
                        : controller.dirty
                        ? 'Brouillons modifiés'
                        : 'Enregistré',
                  ),
                ],
              ),
            ),
          if (controller.error != null ||
              (!compact && _notice != null && !controller.dirty))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StudioNotice(
                controller.error ?? _notice!,
                isError: controller.error != null,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (compact)
                    StudioButton(
                      label: 'Bibliothèque',
                      secondary: true,
                      onPressed: () => setState(() {
                        view.library = !view.library;
                        view.inspector = false;
                      }),
                    ),
                  if (controller.active != null) ...[
                    StudioButton(
                      label: 'Graphe',
                      secondary: view.structure,
                      onPressed: () => _structure(false),
                    ),
                    StudioButton(
                      label: 'Structure',
                      secondary: !view.structure,
                      onPressed: () => _structure(true),
                    ),
                    StudioButton(
                      label: 'Ajouter un chapitre',
                      secondary: true,
                      onPressed: () => _add(null),
                    ),
                    StudioButton(
                      label: 'Vérifier la cohérence',
                      secondary: true,
                      onPressed: _verify,
                    ),
                    StudioButton(
                      label: 'Annuler',
                      secondary: true,
                      onPressed: controller.canUndo
                          ? () {
                              controller.restore(redo: false);
                              setState(() {});
                            }
                          : null,
                    ),
                    StudioButton(
                      label: 'Rétablir',
                      secondary: true,
                      onPressed: controller.canRedo
                          ? () {
                              controller.restore(redo: true);
                              setState(() {});
                            }
                          : null,
                    ),
                    if (compact)
                      StudioButton(
                        label: 'Inspecteur',
                        secondary: true,
                        onPressed: () => setState(() {
                          view.inspector = !view.inspector;
                          view.library = false;
                        }),
                      ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(child: _content(compact)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Enregistrer publie les faits et histoires modifiés, document par document. Disposition conservée pendant cette session.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    },
  );
}
