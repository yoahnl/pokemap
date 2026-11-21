import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/decors/application/decor_draft.dart';
import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/rendering/contracts/scoped_resource_preview_visuals.dart';
import '../../../features/resources/application/resource_preview_source.dart';
import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'project_library_edit_dialog.dart';

class ProjectDecorEditorDialog extends StatefulWidget {
  const ProjectDecorEditorDialog({
    super.key,
    required this.project,
    required this.tileset,
    required this.original,
    required this.visuals,
    required this.publish,
    required this.reconcile,
  });

  final ProjectManifest project;
  final ProjectTilesetEntry tileset;
  final ProjectElementEntry? original;
  final MapWorkspaceVisuals? visuals;
  final Future<ProjectLibraryEdit> Function(ProjectElementEntry) publish;
  final Future<ProjectLibraryEdit> Function(ResourceMutationReceipt) reconcile;

  @override
  State<ProjectDecorEditorDialog> createState() =>
      _ProjectDecorEditorDialogState();
}

class _ProjectDecorEditorDialogState extends State<ProjectDecorEditorDialog> {
  late final _draft = DecorDraft(
    tileset: widget.tileset,
    original: widget.original,
  );
  late final _atlas = widget.tileset.source as ProjectRegularAtlasTilesetSource;
  late final _fields = _rectFields(_draft.selection);
  late final _previewBase = _draft
      .build(validateName: false)
      .copyWith(name: widget.tileset.name, collisionProfile: null);
  late String? _category =
      widget.original?.categoryId ??
      widget.project.elementCategories.firstOrNull?.id;
  bool _saving = false;
  String? _problem;
  ResourceMutationReceipt? _pending;

  bool get _editable => !_saving && _pending == null;
  bool get _mayCrop => (_draft.original?.frames.length ?? 1) == 1;

  static List<String> _rectFields(TilesetSourceRect rect) => [
    '${rect.x + 1}',
    '${rect.y + 1}',
    '${rect.width}',
    '${rect.height}',
  ];

  TilesetSourceRect? _rect() {
    final values = _fields.map((value) => int.tryParse(value.trim())).toList();
    if (values.any((value) => value == null || value < 1)) return null;
    final x = values[0]! - 1;
    final y = values[1]! - 1;
    final width = values[2]!;
    final height = values[3]!;
    if (width > _atlas.columns - x || height > _atlas.rows - y) return null;
    return TilesetSourceRect(x: x, y: y, width: width, height: height);
  }

  void _change(VoidCallback edit) => setState(() {
    edit();
    _problem = null;
  });

  bool get _valid =>
      _category != null &&
      _draft.name.trim().isNotEmpty &&
      (!_mayCrop || _rect() == _draft.selection);

  ProjectElementEntry _value() =>
      _draft.build(validateName: false).copyWith(categoryId: _category ?? '');

  ProjectElementEntry _cutout() {
    final first = _previewBase.frames.first;
    return !_mayCrop || first.source == _draft.selection
        ? _previewBase
        : _previewBase.copyWith(
            frames: [first.copyWith(source: _draft.selection)],
          );
  }

  Future<void> _save() async {
    if (_saving || (_pending == null && !_valid)) return;
    final pending = _pending;
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      final edit = pending == null
          ? await widget.publish(_value())
          : await widget.reconcile(pending);
      if (!mounted) return;
      Navigator.pop<ProjectLibraryEditDialogResult>(context, (
        edit: edit,
        partialReceipt: null,
      ));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = error is ResourceFailure
            ? error.partialReceipt ?? pending
            : pending;
        _problem = switch (error) {
          ResourceFailure(:final message) => message,
          _ => 'Ce décor n’a pas pu être publié. Vos réglages sont conservés.',
        };
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _preview(ResourcePreviewSource source, double size) {
    final visuals = widget.visuals;
    return SizedBox(
      width: size,
      height: size,
      child: switch (visuals) {
        final ScopedResourcePreviewVisuals renderer =>
          renderer.scopedResourcePreview(source, widget.project, size: size),
        _ => const StudioEmptyState(title: 'Aperçu indisponible'),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _draft.blocked.length;
    final allBlocked =
        blocked == _draft.selection.width * _draft.selection.height;
    final hasCollision = blocked > 0 || _draft.hasFineCollision;
    final project = widget.project;
    const cropLabels = ['Colonne', 'Ligne', 'Largeur', 'Hauteur'];
    return PopScope(
      canPop: false,
      child: StudioReviewDialog(
        title: widget.original == null
            ? 'Nouveau décor 2D'
            : 'Modifier le décor 2D',
        confirmLabel: _pending != null
            ? 'Relire la publication'
            : _saving
            ? 'Publication…'
            : 'Publier le décor',
        onConfirmed: _saving || (_pending == null && !_valid) ? null : _save,
        cancelLabel: _pending == null ? 'Annuler' : 'Fermer',
        onCancelled: _saving
            ? null
            : () => Navigator.pop<ProjectLibraryEditDialogResult>(context, (
                edit: null,
                partialReceipt: _pending,
              )),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioDraftField(
              label: 'Nom du décor',
              value: _draft.name,
              enabled: _editable,
              onChanged: (name) => _change(() => _draft.name = name),
            ),
            if (project.elementCategories.isNotEmpty)
              StudioSelect(
                label: 'Catégorie du décor',
                value: _category,
                options: {
                  for (final item in project.elementCategories)
                    item.id: item.name,
                },
                onChanged: !_editable || widget.original != null
                    ? null
                    : (category) => _change(() => _category = category),
              ),
            const SizedBox(height: StudioSpacing.l),
            Text(
              widget.tileset.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: StudioSpacing.m,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _preview(
                  AtlasPreviewSource(widget.tileset.id, showGrid: true),
                  180,
                ),
                _preview(ElementPreviewSource(_cutout()), 96),
              ],
            ),
            if (_mayCrop) ...[
              Text('Découpage en cases · ${_atlas.columns} × ${_atlas.rows}'),
              const SizedBox(height: StudioSpacing.s),
              Wrap(
                spacing: StudioSpacing.s,
                runSpacing: StudioSpacing.s,
                children: [
                  for (final (index, label) in cropLabels.indexed)
                    SizedBox(
                      width: 118,
                      child: StudioDraftField(
                        key: ValueKey('decor-crop-$index'),
                        label: label,
                        value: _fields[index],
                        keyboardType: TextInputType.number,
                        enabled: _editable,
                        onChanged: (value) => _change(() {
                          _fields[index] = value;
                          if (_rect() case final rect?) {
                            _draft.selectSource(rect);
                          }
                        }),
                      ),
                    ),
                ],
              ),
              if (_rect() != _draft.selection)
                StudioNotice(
                  _rect() == null
                      ? 'Le cadre doit rester dans la planche.'
                      : _draft.error ?? 'Ce cadre est indisponible.',
                  isError: true,
                ),
            ] else
              const StudioNotice('Les images de l’animation sont conservées.'),
            const SizedBox(height: StudioSpacing.l),
            Text(
              blocked == 0
                  ? hasCollision
                        ? 'Masque de collision fin'
                        : 'Décor traversable'
                  : '$blocked case(s) bloquée(s)',
            ),
            Wrap(
              spacing: StudioSpacing.s,
              children: [
                StudioButton(
                  label: 'Bloquer tout le cadre',
                  variant: StudioButtonVariant.secondary,
                  onPressed: !_editable || allBlocked
                      ? null
                      : () => _change(() => _draft.setBlocked(true)),
                ),
                StudioButton(
                  label: 'Effacer la collision',
                  variant: StudioButtonVariant.quiet,
                  onPressed: !_editable || !hasCollision
                      ? null
                      : () => _change(() {
                          _draft.setBlocked(false);
                          if (_rect() case final rect?) {
                            _draft.selectSource(rect);
                          }
                        }),
                ),
              ],
            ),
            if (_problem case final problem?)
              StudioNotice(problem, isError: true),
          ],
        ),
      ),
    );
  }
}
