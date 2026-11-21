import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/application/project_resource_preview.dart';
import '../../../features/resources/domain/project_character_workshop_port.dart';
import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'project_character_animation_editor.dart';
import 'project_character_portrait_editor.dart';
import 'project_character_workshop_preview.dart';
import 'project_character_workspace_layout.dart';

typedef ProjectCharacterEditor = ({
  ProjectCharacterWorkshopPort port,
  Future<PickedProjectLibraryFile?> Function() pickImage,
  ResourceMutationReceipt? pending,
  void Function(ResourceMutationReceipt?) retain,
  void Function(ResourceMutationReceipt) publish,
});

enum _CharacterPage { animations, portraits }

class ProjectCharacterWorkshop extends StatefulWidget {
  const ProjectCharacterWorkshop({
    super.key,
    required this.item,
    required this.previews,
    required this.visuals,
    required this.active,
    required this.onBack,
    this.onRename,
    this.editor,
    this.onBusyChanged,
    this.onDraftChanged,
  });

  final ProjectLibraryItem item;
  final ProjectResourcePreviews previews;
  final MapWorkspaceVisuals? visuals;
  final bool active;
  final VoidCallback onBack;
  final Future<void> Function()? onRename;
  final ProjectCharacterEditor? editor;
  final ValueChanged<bool>? onBusyChanged;
  final ValueChanged<bool>? onDraftChanged;

  @override
  State<ProjectCharacterWorkshop> createState() =>
      _ProjectCharacterWorkshopState();
}

class _ProjectCharacterWorkshopState extends State<ProjectCharacterWorkshop> {
  var _page = _CharacterPage.animations;
  ProjectResourcePreviewLease? _lease;
  late var _pending = widget.editor?.pending;
  ProjectCharacterWorkshopRead? _current;
  var _editorGeneration = 0;
  bool _working = false;
  bool _dirty = false;
  bool _leaving = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ProjectCharacterWorkshop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editor?.port != oldWidget.editor?.port ||
        (widget.editor == null && widget.previews != oldWidget.previews) ||
        (widget.editor != null && widget.item.name != oldWidget.item.name)) {
      _load();
    }
  }

  @override
  void dispose() {
    _lease?.release();
    super.dispose();
  }

  Future<void> _load() => _run(() async {
    _lease?.release();
    _lease = null;
    final editor = widget.editor;
    if (editor != null) {
      _current = await editor.port.readWorkshopCharacter(widget.item.id);
      return;
    }
    final lease = _lease = widget.previews.acquire(widget.item);
    final preview = await lease.result;
    if (preview == null || preview.item.character == null) {
      throw const ResourceFailure('Personnage introuvable.');
    }
    _current = (project: preview.project, revision: '');
  }, blocksNavigation: false);

  Future<bool> _run(
    Future<void> Function() work, {
    bool blocksNavigation = true,
  }) async {
    if (_working) return false;
    setState(() {
      _working = true;
      _problem = null;
    });
    if (blocksNavigation) widget.onBusyChanged?.call(true);
    try {
      await work();
      return mounted;
    } on ResourceFailure catch (failure) {
      if (!mounted) return false;
      _problem = failure.message;
      if (failure.partialReceipt case final partial?) {
        _pending = partial;
        widget.editor?.retain(partial);
      }
      return false;
    } on Object {
      if (mounted) {
        _problem = _current == null
            ? 'Impossible de lire le personnage'
            : 'L’opération a échoué. Votre saisie est conservée.';
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _working = false);
        if (blocksNavigation) widget.onBusyChanged?.call(false);
      }
    }
  }

  Future<bool> _edit(
    String action,
    Map<String, Object?> parameters, {
    PickedProjectLibraryFile? image,
  }) async {
    final current = _current;
    final editor = widget.editor;
    if (editor == null || current == null || _pending != null) return false;
    return _run(() async {
      final receipt = await editor.port.editWorkshopCharacter(
        widget.item.id,
        action,
        parameters,
        expectedRevision: current.revision,
        image: image,
      );
      if (mounted) _accept(editor, receipt);
    });
  }

  void _accept(ProjectCharacterEditor editor, ResourceMutationReceipt receipt) {
    if (receipt.noChange) return;
    _pending = receipt;
    editor.retain(receipt);
    editor.publish(receipt);
    final previous = _current!.project;
    final character = receipt.manifest.characters
        .where((value) => value.id == widget.item.id)
        .firstOrNull;
    final definitions =
        receipt.actionId == 'characterStudio.portraitState.create' ||
        receipt.actionId == 'characterStudio.animationDefinition.create';
    _current = (
      project: previous.copyWith(
        characters: character == null ? previous.characters : [character],
        characterStudioCatalog: definitions
            ? receipt.manifest.characterStudioCatalog
            : previous.characterStudioCatalog,
      ),
      revision: receipt.revision,
    );
    _pending = null;
    editor.retain(null);
  }

  Future<void> _reconcile() async {
    final receipt = _pending;
    final editor = widget.editor;
    if (receipt == null || editor == null) return;
    final success = await _run(() async {
      await editor.port.reconcileWorkshopCharacter(widget.item.id, receipt);
      if (mounted) _accept(editor, receipt);
    });
    if (success && _dirty) {
      setState(() => _editorGeneration++);
      _setDirty(false);
    }
  }

  void _setDirty(bool dirty) {
    if (_dirty == dirty) return;
    setState(() => _dirty = dirty);
    widget.onDraftChanged?.call(dirty);
  }

  Future<void> _back() async {
    if (_working || _leaving) return;
    if (_dirty && _pending == null) {
      _leaving = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => StudioReviewDialog(
          title: 'Quitter l’atelier',
          content: const Text(
            'Les modifications de cette animation seront perdues.',
          ),
          confirmLabel: 'Abandonner les modifications',
          onConfirmed: () => Navigator.pop(context, true),
          onCancelled: () => Navigator.pop(context, false),
        ),
      );
      _leaving = false;
      if (discard != true || !mounted) return;
    }
    if (!mounted) return;
    _setDirty(false);
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final editor = widget.editor;
    final enabled = widget.active && !_working && _pending == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProjectCharacterWorkshopHeader(
          name: widget.item.name,
          onBack: _working ? null : _back,
          onRename: enabled && !_dirty ? widget.onRename : null,
          showRename: widget.onRename != null,
        ),
        if (editor != null)
          StudioTabBar(
            selected: _page,
            tabs: [
              StudioTab(
                value: _CharacterPage.animations,
                label: 'Animations',
                enabled: enabled && !_dirty,
              ),
              StudioTab(
                value: _CharacterPage.portraits,
                label: 'Portraits',
                enabled: enabled && !_dirty,
              ),
            ],
            onSelected: (page) => setState(() {
              _page = page;
              _problem = null;
            }),
          )
        else
          const Divider(height: 1),
        if (_working && _current != null)
          const LinearProgressIndicator(minHeight: 2),
        if (_problem case final problem?)
          Padding(
            padding: const EdgeInsets.all(StudioSpacing.l),
            child: StudioNotice(problem, isError: true),
          ),
        if (_pending != null)
          StudioButton(
            label: 'Relire l’enregistrement',
            icon: Icons.sync,
            onPressed: _working || _current == null ? null : _reconcile,
          ),
        Expanded(child: _body(editor, enabled)),
      ],
    );
  }

  Widget _body(ProjectCharacterEditor? editor, bool enabled) {
    final project = _current?.project;
    final character = project?.characters
        .where((value) => value.id == widget.item.id)
        .firstOrNull;
    if (project == null || character == null) {
      return Center(
        child: _working
            ? const CircularProgressIndicator(
                semanticsLabel: 'Chargement du personnage',
              )
            : StudioButton(label: 'Réessayer', onPressed: _load),
      );
    }
    if (editor == null) {
      return ListView(
        padding: const EdgeInsets.all(StudioSpacing.xl),
        children: [
          ProjectCharacterWorkshopPreview(
            character: character,
            project: project,
            active: widget.active,
            visuals: widget.visuals,
          ),
        ],
      );
    }
    return switch (_page) {
      _CharacterPage.animations => ProjectCharacterAnimationEditor(
        key: ValueKey(_editorGeneration),
        project: project,
        character: character,
        visuals: widget.visuals,
        enabled: enabled,
        edit: _edit,
        pickImage: editor.pickImage,
        onDirty: _setDirty,
      ),
      _CharacterPage.portraits => ProjectCharacterPortraitEditor(
        catalog: project.characterStudioCatalog,
        character: character,
        enabled: enabled,
        edit: _edit,
        pickImage: editor.pickImage,
        readPortrait: (id) =>
            editor.port.readCharacterPortrait(character.id, id),
      ),
    };
  }
}
