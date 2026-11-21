import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/domain/project_character_workshop_port.dart';
import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'project_character_workspace_layout.dart';

class ProjectCharacterPortraitEditor extends StatefulWidget {
  const ProjectCharacterPortraitEditor({
    super.key,
    required this.catalog,
    required this.character,
    required this.enabled,
    required this.edit,
    required this.pickImage,
    required this.readPortrait,
  });

  final ProjectCharacterStudioCatalog catalog;
  final ProjectCharacterEntry character;
  final bool enabled;
  final EditWorkshopCharacter edit;
  final Future<PickedProjectLibraryFile?> Function() pickImage;
  final Future<Uint8List?> Function(String id) readPortrait;

  @override
  State<ProjectCharacterPortraitEditor> createState() =>
      _ProjectCharacterPortraitEditorState();
}

class _ProjectCharacterPortraitEditorState
    extends State<ProjectCharacterPortraitEditor> {
  String? _selection;
  String? _problem;
  String? _awaitedName;
  ({String id, String asset, Future<Uint8List?> result})? _image;

  List<CharacterPortraitStateDefinition> get _states =>
      widget.catalog.portraitStates.toList()..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        return order == 0
            ? left.displayName.compareTo(right.displayName)
            : order;
      });

  @override
  void didUpdateWidget(ProjectCharacterPortraitEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final name = _awaitedName;
    if (name != null) {
      final state = widget.catalog.portraitStates
          .where((state) => state.displayName == name)
          .firstOrNull;
      if (state != null) {
        _selection = state.id;
        _awaitedName = null;
      }
    }
  }

  Future<void> _newExpression() async {
    var name = '';
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, change) => StudioReviewDialog(
          title: 'Nouvelle expression',
          confirmLabel: 'Créer l’expression',
          onConfirmed: name.trim().isEmpty
              ? null
              : () => Navigator.pop(context, name.trim()),
          onCancelled: () => Navigator.pop(context),
          content: StudioDraftField(
            label: 'Nom de l’expression',
            value: name,
            autofocus: true,
            onChanged: (value) => change(() => name = value),
          ),
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _awaitedName = chosen;
      _problem = null;
    });
    final saved = await widget.edit('characterStudio.portraitState.create', {
      'displayName': chosen,
    });
    if (!saved && mounted) _awaitedName = null;
  }

  Future<void> _import(CharacterPortraitStateDefinition state) async {
    try {
      final image = await widget.pickImage();
      if (!mounted || image == null) return;
      if (image.imageSize == null) {
        throw const ResourceFailure('Choisissez un portrait PNG.');
      }
      setState(() => _problem = null);
      await widget.edit('characterStudio.asset.import', {
        'mediaKind': 'portrait',
        'binding': {
          'kind': 'portrait',
          'portraitStateId': state.id,
          'fitMode': 'contain',
        },
      }, image: image);
    } on ResourceFailure catch (failure) {
      if (mounted) setState(() => _problem = failure.message);
    }
  }

  Future<void> _detach(CharacterPortraitStateDefinition state) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => StudioReviewDialog(
        title: 'Détacher « ${state.displayName} »',
        content: const Text(
          'Les répliques qui utilisent cette expression perdront leur portrait. '
          'L’image restera disponible dans les fichiers du projet.',
        ),
        confirmLabel: 'Détacher le portrait',
        confirmVariant: StudioButtonVariant.destructive,
        onConfirmed: () => Navigator.pop(context, true),
        onCancelled: () => Navigator.pop(context, false),
      ),
    );
    if (remove != true || !mounted) return;
    await widget.edit('characterStudio.character.portrait.clear', {
      'portraitStateId': state.id,
    });
  }

  Future<void> _copyDirective(CharacterPortraitStateDefinition state) async {
    await Clipboard.setData(
      ClipboardData(text: '<<portrait ${widget.character.id} ${state.id}>>'),
    );
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Commande de portrait copiée.')),
      );
    }
  }

  Widget _portrait(CharacterPortraitVariant? portrait) {
    if (portrait == null) {
      return const StudioEmptyState(
        title: 'Aucune image pour cette expression',
      );
    }
    final state = portrait.portraitStateId;
    if (_image?.id != state || _image?.asset != portrait.assetId) {
      _image = (
        id: state,
        asset: portrait.assetId,
        result: widget.readPortrait(state),
      );
    }
    return FutureBuilder<Uint8List?>(
      key: ValueKey(portrait.assetId),
      future: _image!.result,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bytes = snapshot.data;
        return bytes == null
            ? StudioEmptyState(
                title: 'Image du portrait indisponible',
                action: StudioButton(
                  label: 'Réessayer',
                  variant: StudioButtonVariant.secondary,
                  onPressed: widget.enabled
                      ? () => setState(() => _image = null)
                      : null,
                ),
              )
            : Image.memory(
                bytes,
                width: 240,
                height: 240,
                cacheWidth: 480,
                filterQuality: FilterQuality.medium,
                fit: portrait.fitMode == CharacterPortraitFitMode.cover
                    ? BoxFit.cover
                    : BoxFit.contain,
                errorBuilder: (context, error, stack) => const StudioEmptyState(
                  title: 'Image du portrait indisponible',
                ),
              );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final states = _states;
    final assignments = {
      for (final portrait in widget.character.portraits)
        portrait.portraitStateId: portrait,
    };
    final state =
        states.where((entry) => entry.id == _selection).firstOrNull ??
        states
            .where((entry) => assignments.containsKey(entry.id))
            .firstOrNull ??
        states.firstOrNull;
    final portrait = assignments[state?.id];
    return ProjectCharacterWorkspaceLayout(
      sidebar: StudioPanel(
        title: 'Expressions',
        compact: true,
        children: [
          _createButton(),
          const Divider(),
          Expanded(
            child: ListView(
              primary: false,
              children: [
                for (final entry in states)
                  Padding(
                    padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
                    child: StudioNavigationEntry(
                      key: ValueKey('character-expression-${entry.id}'),
                      label: entry.displayName,
                      icon: Icons.face_outlined,
                      detail: assignments.containsKey(entry.id)
                          ? 'Image associée'
                          : 'Sans image',
                      selected: entry.id == state?.id,
                      onTap: widget.enabled ? () => _select(entry.id) : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      compactSelector: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state != null)
            StudioSelect(
              label: 'Expression',
              value: state.id,
              options: {
                for (final entry in states) entry.id: entry.displayName,
              },
              onChanged: widget.enabled ? _select : null,
            ),
          _createButton(),
        ],
      ),
      content: _details(context, state, portrait),
    );
  }

  void _select(String id) => setState(() {
    _selection = id;
    _problem = null;
  });

  Widget _createButton() => StudioButton(
    label: 'Nouvelle expression',
    icon: Icons.add,
    variant: StudioButtonVariant.quiet,
    onPressed: widget.enabled ? _newExpression : null,
  );

  Widget _details(
    BuildContext context,
    CharacterPortraitStateDefinition? state,
    CharacterPortraitVariant? portrait,
  ) => StudioPanel(
    children: [
      if (state == null)
        const StudioEmptyState(
          title: 'Aucune expression',
          description: 'Créez une expression, puis ajoutez le portrait de ce personnage.',
        )
      else ...[
        Row(
          children: [
            Expanded(
              child: Text(
                state.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (portrait != null) _portraitActions(state),
          ],
        ),
        const SizedBox(height: StudioSpacing.l),
        StudioAssetPreview(
          height: 300,
          child: portrait == null
              ? StudioEmptyState(
                  title: 'Aucune image pour cette expression',
                  description:
                      'Ajoutez le visage qui apparaîtra dans le dialogue.',
                  action: StudioButton(
                    label: 'Importer un portrait PNG',
                    icon: Icons.upload_file_outlined,
                    onPressed: widget.enabled ? () => _import(state) : null,
                  ),
                )
              : _portrait(portrait),
        ),
        if (portrait != null) ...[
          const SizedBox(height: StudioSpacing.l),
          StudioButton(
            label: 'Remplacer l’image',
            icon: Icons.upload_file_outlined,
            variant: StudioButtonVariant.secondary,
            onPressed: widget.enabled ? () => _import(state) : null,
          ),
        ],
      ],
      if (_problem case final problem?) StudioNotice(problem, isError: true),
    ],
  );

  Widget _portraitActions(CharacterPortraitStateDefinition state) =>
      StudioContextMenuButton(
        tooltip: 'Actions du portrait',
        items: () => [
          StudioContextMenuEntry(
            label: 'Copier la commande de dialogue',
            icon: Icons.content_copy_outlined,
            onSelected: widget.enabled ? () => _copyDirective(state) : null,
          ),
          const StudioContextMenuSeparator(),
          StudioContextMenuEntry(
            label: 'Détacher le portrait',
            icon: Icons.link_off,
            destructive: true,
            onSelected: widget.enabled ? () => _detach(state) : null,
          ),
        ],
      );
}
