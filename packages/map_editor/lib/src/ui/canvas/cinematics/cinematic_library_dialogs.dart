import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/cinematic_library_authoring_gateway.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

export '../../../application/authoring_api/cinematic_library_authoring_gateway.dart'
    show CinematicLibraryWorldStartingPoint;

typedef CinematicLibraryCreateCallback =
    Future<String?> Function(CinematicLibraryCreateRequest request);

typedef CinematicLibraryDuplicateCallback =
    Future<String?> Function({
      required CinematicLibraryFamily family,
      required String cinematicId,
      String? folderId,
    });

typedef CinematicLibraryRenameCallback =
    Future<void> Function({
      required CinematicLibraryFamily family,
      required String cinematicId,
      required String title,
    });

typedef CinematicLibraryMoveCallback =
    Future<void> Function({
      required CinematicLibraryFamily family,
      required String cinematicId,
      String? folderId,
    });

typedef CinematicLibraryArchiveCallback =
    Future<void> Function({
      required CinematicLibraryFamily family,
      required String cinematicId,
      required bool archived,
    });

typedef CinematicLibraryDeleteCallback =
    Future<void> Function({
      required CinematicLibraryFamily family,
      required String cinematicId,
    });

enum CinematicLibraryManagementCommand {
  rename,
  move,
  duplicate,
  archive,
  restore,
  delete,
}

Future<CinematicLibraryManagementCommand?>
showCinematicLibraryManagementDialog({
  required BuildContext context,
  required String title,
  required bool archived,
}) {
  return showPokeMapConfirmationDialog<CinematicLibraryManagementCommand>(
    context: context,
    title: title,
    message: 'Choisissez une action pour cette cinématique.',
    actions: [
      const PokeMapDialogAction(
        label: 'Renommer',
        value: CinematicLibraryManagementCommand.rename,
      ),
      const PokeMapDialogAction(
        label: 'Déplacer',
        value: CinematicLibraryManagementCommand.move,
      ),
      const PokeMapDialogAction(
        label: 'Dupliquer',
        value: CinematicLibraryManagementCommand.duplicate,
      ),
      PokeMapDialogAction(
        label: archived ? 'Restaurer' : 'Archiver',
        value: archived
            ? CinematicLibraryManagementCommand.restore
            : CinematicLibraryManagementCommand.archive,
      ),
      const PokeMapDialogAction(
        label: 'Supprimer',
        value: CinematicLibraryManagementCommand.delete,
        variant: PokeMapButtonVariant.danger,
      ),
    ],
  );
}

Future<bool> showCinematicLibraryRenameDialog({
  required BuildContext context,
  required String initialTitle,
  required Future<void> Function(String title) onRename,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _CinematicLibraryRenameDialog(
      initialTitle: initialTitle,
      onRename: onRename,
    ),
  );
  return result ?? false;
}

Future<bool> showCinematicLibraryMoveDialog({
  required BuildContext context,
  required String? initialFolderId,
  required List<CinematicLibraryFolder> folders,
  required Future<void> Function(String? folderId) onMove,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _CinematicLibraryMoveDialog(
      initialFolderId: initialFolderId,
      folders: folders,
      onMove: onMove,
    ),
  );
  return result ?? false;
}

final class CinematicLibraryCreateRequest {
  const CinematicLibraryCreateRequest({
    required this.family,
    required this.title,
    required this.folderId,
    this.worldStartingPoint,
    this.presentationTemplateId,
    this.presentationTemplateVersion,
  });

  final CinematicLibraryFamily family;
  final String title;
  final String? folderId;
  final CinematicLibraryWorldStartingPoint? worldStartingPoint;
  final String? presentationTemplateId;
  final int? presentationTemplateVersion;
}

Future<String?> showCinematicLibraryCreateDialog({
  required BuildContext context,
  required CinematicLibraryFamily family,
  required String? initialFolderId,
  required List<CinematicLibraryFolder> folders,
  required CinematicLibraryCreateCallback onCreate,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _CinematicLibraryCreateDialog(
      family: family,
      initialFolderId: initialFolderId,
      folders: folders,
      onCreate: onCreate,
    ),
  );
}

class _CinematicLibraryCreateDialog extends StatefulWidget {
  const _CinematicLibraryCreateDialog({
    required this.family,
    required this.initialFolderId,
    required this.folders,
    required this.onCreate,
  });

  final CinematicLibraryFamily family;
  final String? initialFolderId;
  final List<CinematicLibraryFolder> folders;
  final CinematicLibraryCreateCallback onCreate;

  @override
  State<_CinematicLibraryCreateDialog> createState() =>
      _CinematicLibraryCreateDialogState();
}

class _CinematicLibraryCreateDialogState
    extends State<_CinematicLibraryCreateDialog> {
  static const _rootFolder = '__root__';

  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();
  late String _folderValue;
  CinematicLibraryWorldStartingPoint _worldStartingPoint =
      CinematicLibraryWorldStartingPoint.blank;
  String _presentationTemplateId = 'blank';
  String? _error;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    final availableIds = widget.folders.map((folder) => folder.id).toSet();
    _folderValue = availableIds.contains(widget.initialFolderId)
        ? widget.initialFolderId!
        : _rootFolder;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPresentation = widget.family == CinematicLibraryFamily.presentation;
    final title = isPresentation
        ? 'Nouvelle cinématique de présentation'
        : 'Nouvelle cinématique in-game';
    return PokeMapDialog(
      title: title,
      icon: isPresentation
          ? Icons.movie_creation_outlined
          : Icons.videogame_asset_outlined,
      maxWidth: 780,
      footer: _DialogFooter(
        pending: _pending,
        onCancel: () => Navigator.of(context).pop(),
        onSubmit: _submit,
      ),
      child: SizedBox(
        height: (MediaQuery.sizeOf(context).height - 210).clamp(300, 620),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PokeMapTextField(
                label: 'Titre',
                fieldKey: const ValueKey('cinematic-create-title'),
                controller: _titleController,
                focusNode: _titleFocusNode,
                autofocus: true,
                enabled: !_pending,
                errorText: _titleError,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              PokeMapDropdownField<String>(
                label: 'Dossier',
                value: _folderValue,
                enabled: !_pending,
                items: [
                  const PokeMapDropdownItem(
                    value: _rootFolder,
                    label: 'Racine de la bibliothèque',
                  ),
                  for (final folder in _sortedFolders())
                    PokeMapDropdownItem(
                      value: folder.id,
                      label: _folderPath(folder),
                    ),
                ],
                onChanged: (value) => setState(() => _folderValue = value),
              ),
              const SizedBox(height: 18),
              Text(
                isPresentation ? 'Preset de départ' : 'Point de départ',
                style: TextStyle(
                  color: context.pokeMapColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (isPresentation)
                _PresentationTemplatePicker(
                  selectedId: _presentationTemplateId,
                  enabled: !_pending,
                  onChanged: (value) =>
                      setState(() => _presentationTemplateId = value),
                )
              else
                _WorldStartingPointPicker(
                  selected: _worldStartingPoint,
                  enabled: !_pending,
                  onChanged: (value) =>
                      setState(() => _worldStartingPoint = value),
                ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                PokeMapActionBanner(
                  tone: PokeMapTone.danger,
                  title: 'Création impossible',
                  message: _error!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? get _titleError {
    if (_error == null || _titleController.text.trim().isNotEmpty) return null;
    return 'Le titre est obligatoire.';
  }

  List<CinematicLibraryFolder> _sortedFolders() {
    final copy = widget.folders.toList();
    copy.sort((left, right) => _folderPath(left).compareTo(_folderPath(right)));
    return copy;
  }

  String _folderPath(CinematicLibraryFolder folder) {
    final byId = <String, CinematicLibraryFolder>{
      for (final candidate in widget.folders) candidate.id: candidate,
    };
    final parts = <String>[folder.name];
    var parentId = folder.parentFolderId;
    final visited = <String>{folder.id};
    while (parentId != null && visited.add(parentId)) {
      final parent = byId[parentId];
      if (parent == null) break;
      parts.insert(0, parent.name);
      parentId = parent.parentFolderId;
    }
    return parts.join(' / ');
  }

  Future<void> _submit() async {
    if (_pending) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(
        () => _error = 'Saisissez un titre avant de créer la cinématique.',
      );
      _titleFocusNode.requestFocus();
      return;
    }
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final template = PresentationCinematicTemplateCatalog.canonical().require(
        _presentationTemplateId,
        version: 1,
      );
      final id = await widget.onCreate(
        CinematicLibraryCreateRequest(
          family: widget.family,
          title: title,
          folderId: _folderValue == _rootFolder ? null : _folderValue,
          worldStartingPoint: widget.family == CinematicLibraryFamily.world
              ? _worldStartingPoint
              : null,
          presentationTemplateId:
              widget.family == CinematicLibraryFamily.presentation
              ? template.id
              : null,
          presentationTemplateVersion:
              widget.family == CinematicLibraryFamily.presentation
              ? template.version
              : null,
        ),
      );
      if (!mounted) return;
      if (id == null || id.trim().isEmpty) {
        setState(() {
          _pending = false;
          _error = 'La commande n’a retourné aucune cinématique.';
        });
        _titleFocusNode.requestFocus();
        return;
      }
      Navigator.of(context).pop(id);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = false;
        _error = error.toString();
      });
      _titleFocusNode.requestFocus();
    }
  }
}

class _CinematicLibraryRenameDialog extends StatefulWidget {
  const _CinematicLibraryRenameDialog({
    required this.initialTitle,
    required this.onRename,
  });

  final String initialTitle;
  final Future<void> Function(String title) onRename;

  @override
  State<_CinematicLibraryRenameDialog> createState() =>
      _CinematicLibraryRenameDialogState();
}

class _CinematicLibraryRenameDialogState
    extends State<_CinematicLibraryRenameDialog> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  String? _error;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PokeMapDialog(
    title: 'Renommer la cinématique',
    icon: Icons.drive_file_rename_outline_rounded,
    footer: _CommandDialogFooter(
      pending: _pending,
      submitLabel: 'Renommer',
      onCancel: () => Navigator.of(context).pop(false),
      onSubmit: _submit,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PokeMapTextField(
          label: 'Titre',
          fieldKey: const ValueKey('cinematic-rename-title'),
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          enabled: !_pending,
          errorText: _controller.text.trim().isEmpty ? _error : null,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null && _controller.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          PokeMapActionBanner(
            tone: PokeMapTone.danger,
            title: 'Renommage impossible',
            message: _error!,
          ),
        ],
      ],
    ),
  );

  Future<void> _submit() async {
    if (_pending) return;
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Le titre est obligatoire.');
      _focusNode.requestFocus();
      return;
    }
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      await widget.onRename(title);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = false;
        _error = error.toString();
      });
      _focusNode.requestFocus();
    }
  }
}

class _CinematicLibraryMoveDialog extends StatefulWidget {
  const _CinematicLibraryMoveDialog({
    required this.initialFolderId,
    required this.folders,
    required this.onMove,
  });

  final String? initialFolderId;
  final List<CinematicLibraryFolder> folders;
  final Future<void> Function(String? folderId) onMove;

  @override
  State<_CinematicLibraryMoveDialog> createState() =>
      _CinematicLibraryMoveDialogState();
}

class _CinematicLibraryMoveDialogState
    extends State<_CinematicLibraryMoveDialog> {
  static const _rootFolder = '__root__';
  late String _folderValue;
  String? _error;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _folderValue =
        widget.folders.any((folder) => folder.id == widget.initialFolderId)
        ? widget.initialFolderId!
        : _rootFolder;
  }

  @override
  Widget build(BuildContext context) => PokeMapDialog(
    title: 'Déplacer la cinématique',
    icon: Icons.drive_file_move_outline,
    footer: _CommandDialogFooter(
      pending: _pending,
      submitLabel: 'Déplacer',
      onCancel: () => Navigator.of(context).pop(false),
      onSubmit: _submit,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PokeMapDropdownField<String>(
          label: 'Dossier de destination',
          value: _folderValue,
          enabled: !_pending,
          items: [
            const PokeMapDropdownItem(
              value: _rootFolder,
              label: 'Racine de la bibliothèque',
            ),
            for (final folder in _sortedFolders())
              PokeMapDropdownItem(value: folder.id, label: _folderPath(folder)),
          ],
          onChanged: (value) => setState(() => _folderValue = value),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          PokeMapActionBanner(
            tone: PokeMapTone.danger,
            title: 'Déplacement impossible',
            message: _error!,
          ),
        ],
      ],
    ),
  );

  List<CinematicLibraryFolder> _sortedFolders() {
    final copy = widget.folders.toList();
    copy.sort((left, right) => _folderPath(left).compareTo(_folderPath(right)));
    return copy;
  }

  String _folderPath(CinematicLibraryFolder folder) {
    final byId = <String, CinematicLibraryFolder>{
      for (final candidate in widget.folders) candidate.id: candidate,
    };
    final parts = <String>[folder.name];
    var parentId = folder.parentFolderId;
    final visited = <String>{folder.id};
    while (parentId != null && visited.add(parentId)) {
      final parent = byId[parentId];
      if (parent == null) break;
      parts.insert(0, parent.name);
      parentId = parent.parentFolderId;
    }
    return parts.join(' / ');
  }

  Future<void> _submit() async {
    if (_pending) return;
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      await widget.onMove(_folderValue == _rootFolder ? null : _folderValue);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = false;
        _error = error.toString();
      });
    }
  }
}

class _CommandDialogFooter extends StatelessWidget {
  const _CommandDialogFooter({
    required this.pending,
    required this.submitLabel,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool pending;
  final String submitLabel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 8,
    runSpacing: 8,
    children: [
      PokeMapButton(
        onPressed: pending ? null : onCancel,
        variant: PokeMapButtonVariant.secondary,
        child: const Text('Annuler'),
      ),
      PokeMapButton(
        onPressed: pending ? null : onSubmit,
        isLoading: pending,
        child: Text(submitLabel),
      ),
    ],
  );
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({
    required this.pending,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool pending;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 8,
    runSpacing: 8,
    children: [
      PokeMapButton(
        onPressed: pending ? null : onCancel,
        variant: PokeMapButtonVariant.secondary,
        child: const Text('Annuler'),
      ),
      PokeMapButton(
        key: const ValueKey('cinematic-create-submit'),
        onPressed: pending ? null : onSubmit,
        isLoading: pending,
        leading: const Icon(Icons.add_rounded),
        child: const Text('Créer'),
      ),
    ],
  );
}

class _WorldStartingPointPicker extends StatelessWidget {
  const _WorldStartingPointPicker({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final CinematicLibraryWorldStartingPoint selected;
  final bool enabled;
  final ValueChanged<CinematicLibraryWorldStartingPoint> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final value in CinematicLibraryWorldStartingPoint.values) ...[
        SizedBox(
          key: ValueKey('world-starting-point-${value.name}'),
          child: PokeMapCard(
            key: const ValueKey('world-starting-point-card'),
            selected: selected == value,
            keyboardInteractive: enabled,
            semanticLabel: _worldLabel(value),
            onTap: enabled ? () => onChanged(value) : null,
            child: Row(
              children: [
                Icon(
                  _worldIcon(value),
                  color: context.pokeMapColors.brandPrimary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _worldLabel(value),
                        style: TextStyle(
                          color: context.pokeMapColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _worldDescription(value),
                        style: TextStyle(
                          color: context.pokeMapColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ],
  );
}

class _PresentationTemplatePicker extends StatelessWidget {
  const _PresentationTemplatePicker({
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
  });

  final String selectedId;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final templates =
        PresentationCinematicTemplateCatalog.canonical().templates;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 620
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final template in templates)
              SizedBox(
                width: cardWidth,
                child: PokeMapCard(
                  key: const ValueKey('presentation-template-card'),
                  selected: selectedId == template.id,
                  keyboardInteractive: enabled,
                  semanticLabel: _templateLabel(template.id),
                  onTap: enabled ? () => onChanged(template.id) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TemplatePreview(template: template),
                      const SizedBox(height: 9),
                      Text(
                        _templateLabel(template.id),
                        key: ValueKey('presentation-template-${template.id}'),
                        style: TextStyle(
                          color: context.pokeMapColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _templateDescription(template.id),
                        style: TextStyle(
                          color: context.pokeMapColors.textSecondary,
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TemplatePreview extends StatelessWidget {
  const _TemplatePreview({required this.template});

  final PresentationCinematicTemplate template;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final slotCount = template.mediaSlots.length;
    return Container(
      height: 68,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            decoration: BoxDecoration(
              color: colors.cardSelected,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.brandPrimaryBorder),
            ),
            child: Center(
              child: Icon(
                _templateIcon(template.id),
                color: colors.brandPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slotCount == 0
                      ? 'Composition libre'
                      : '$slotCount média${slotCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paysage + portrait natifs',
                  style: TextStyle(color: colors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _worldLabel(CinematicLibraryWorldStartingPoint value) => switch (value) {
  CinematicLibraryWorldStartingPoint.blank => 'Vide',
  CinematicLibraryWorldStartingPoint.establishingShot => 'Plan d’établissement',
  CinematicLibraryWorldStartingPoint.dialogueBeat => 'Temps de dialogue',
};

String _worldDescription(CinematicLibraryWorldStartingPoint value) =>
    switch (value) {
      CinematicLibraryWorldStartingPoint.blank =>
        'Une timeline vide à construire dans le Studio in-game actuel.',
      CinematicLibraryWorldStartingPoint.establishingShot =>
        'Un cadrage d’ouverture puis un temps de respiration.',
      CinematicLibraryWorldStartingPoint.dialogueBeat =>
        'Un premier temps narratif prêt à recevoir un dialogue.',
    };

IconData _worldIcon(CinematicLibraryWorldStartingPoint value) =>
    switch (value) {
      CinematicLibraryWorldStartingPoint.blank => Icons.crop_free_rounded,
      CinematicLibraryWorldStartingPoint.establishingShot =>
        Icons.center_focus_strong_rounded,
      CinematicLibraryWorldStartingPoint.dialogueBeat =>
        Icons.chat_bubble_outline_rounded,
    };

String _templateLabel(String id) => switch (id) {
  'blank' => 'Vide',
  'titleIdentity' => 'Titre & identité',
  'immersiveOpening' => 'Ouverture immersive',
  'stagedStory' => 'Récit mis en scène',
  'interactivePath' => 'Parcours interactif',
  'adaptiveVideo' => 'Vidéo adaptative',
  _ => id,
};

String _templateDescription(String id) => switch (id) {
  'blank' => 'Une composition libre, sans média imposé.',
  'titleIdentity' => 'Installe un titre, une identité et un fond responsive.',
  'immersiveOpening' =>
    'Construit une ouverture visuelle, sonore et immédiatement cinématique.',
  'stagedStory' =>
    'Superpose décors, narration et voix pour une séquence plus longue.',
  'interactivePath' =>
    'Prépare les repères où une Scene peut demander un choix ou une saisie.',
  'adaptiveVideo' => 'Démarre autour d’une vidéo et de son poster adaptatifs.',
  _ => '',
};

IconData _templateIcon(String id) => switch (id) {
  'blank' => Icons.crop_free_rounded,
  'titleIdentity' => Icons.title_rounded,
  'immersiveOpening' => Icons.auto_awesome_rounded,
  'stagedStory' => Icons.layers_outlined,
  'interactivePath' => Icons.account_tree_outlined,
  'adaptiveVideo' => Icons.video_library_outlined,
  _ => Icons.movie_creation_outlined,
};
