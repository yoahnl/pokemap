import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring.dart'
    show TilesetActions, VisualLibraryException;
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/project_tileset_workshop_port.dart';
import '../../../features/resources/domain/resource_port.dart';

String projectTilesetGridLabel(ProjectRegularAtlasTilesetSource source) {
  final columns = source.columns;
  final rows = source.rows;
  return '$columns ${columns == 1 ? 'colonne' : 'colonnes'} × '
      '$rows ${rows == 1 ? 'ligne' : 'lignes'}';
}

class ProjectTilesetGridDialog extends StatefulWidget {
  const ProjectTilesetGridDialog({
    super.key,
    required this.name,
    required this.tileset,
    required this.source,
    required this.editor,
    required this.buildPreview,
  });

  final String name;
  final ProjectTilesetEntry tileset;
  final ProjectRegularAtlasTilesetSource source;
  final ProjectTilesetGridEditor editor;
  final Widget Function(ProjectRegularAtlasTilesetSource) buildPreview;

  @override
  State<ProjectTilesetGridDialog> createState() =>
      _ProjectTilesetGridDialogState();
}

class _ProjectTilesetGridDialogState extends State<ProjectTilesetGridDialog> {
  late String _width = '${widget.source.tileWidth}';
  late String _height = '${widget.source.tileHeight}';
  late String _revision = widget.editor.revision;
  late String? _problem = _pending == null
      ? null
      : 'Le découpage est enregistré. Relisez la planche pour afficher le résultat.';
  bool _working = false;
  bool _needsPreparation = false;
  bool _prepared = false;
  late ResourceMutationReceipt? _pending = widget.editor.pendingReceipt;

  ProjectRegularAtlasTilesetSource? _candidate() {
    final width = int.tryParse(_width.trim(), radix: 10);
    final height = int.tryParse(_height.trim(), radix: 10);
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    try {
      return const TilesetActions().previewAtlasGrid(
        widget.tileset,
        tileWidth: width,
        tileHeight: height,
      );
    } on VisualLibraryException {
      return null;
    }
  }

  Future<void> _prepare() async {
    setState(() => _working = true);
    try {
      final revision = await widget.editor.prepareCatalog();
      if (!mounted) return;
      setState(() {
        _revision = revision;
        _needsPreparation = false;
        _prepared = true;
        _problem = null;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _problem = _message(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _save(ProjectRegularAtlasTilesetSource? candidate) async {
    final pending = _pending;
    final editor = widget.editor;
    if (pending == null && candidate == null) return;
    setState(() {
      _working = true;
      _problem = null;
    });
    try {
      if (pending != null) {
        await editor.reconcile(pending);
        editor.onPendingReceiptChanged(null);
      } else {
        await editor.save((
          width: candidate!.tileWidth,
          height: candidate.tileHeight,
        ), _revision);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ProjectLibraryNeedsPreparation {
      if (mounted) setState(() => _needsPreparation = true);
    } on Object catch (error) {
      final receipt = error is ResourceFailure ? error.partialReceipt : null;
      if (receipt != null) editor.onPendingReceiptChanged(receipt);
      if (!mounted) return;
      setState(() {
        _pending = receipt ?? _pending;
        _problem = _message(error);
      });
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _message(Object error) => switch (error) {
    ResourceFailure(:final message) => message,
    _ => 'Le Studio n’a pas pu terminer cette opération.',
  };

  @override
  Widget build(BuildContext context) {
    final candidate = _candidate();
    final source = widget.source;
    final changed =
        candidate != null &&
        (candidate.tileWidth != source.tileWidth ||
            candidate.tileHeight != source.tileHeight);
    final details = Theme.of(context).textTheme;
    final confirm = _working
        ? null
        : _needsPreparation
        ? _prepare
        : _pending != null || changed
        ? () => _save(candidate)
        : null;
    return PopScope(
      canPop: !_working,
      child: StudioReviewDialog(
        title: 'Modifier le découpage',
        confirmLabel: _working
            ? 'En cours…'
            : _needsPreparation
            ? 'Préparer l’index des usages'
            : _pending != null
            ? 'Relire la planche'
            : 'Enregistrer',
        onConfirmed: confirm,
        cancelLabel: _pending == null ? 'Annuler' : 'Fermer',
        onCancelled: _working ? null : () => Navigator.of(context).pop(false),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.name, style: details.titleSmall),
            const SizedBox(height: StudioSpacing.s),
            Text(
              'Image de ${source.pixelWidth} × ${source.pixelHeight} px',
              style: details.bodySmall,
            ),
            const SizedBox(height: StudioSpacing.m),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = _dimension(
                  'Largeur d’une tuile (px)',
                  'width',
                  _width,
                  (value) => setState(() => _width = value),
                );
                final height = _dimension(
                  'Hauteur d’une tuile (px)',
                  'height',
                  _height,
                  (value) => setState(() => _height = value),
                );
                return constraints.maxWidth >= 410
                    ? Row(
                        children: [
                          Expanded(child: width),
                          const SizedBox(width: StudioSpacing.m),
                          Expanded(child: height),
                        ],
                      )
                    : Column(
                        children: [
                          width,
                          const SizedBox(height: StudioSpacing.m),
                          height,
                        ],
                      );
              },
            ),
            const SizedBox(height: StudioSpacing.m),
            if (candidate == null)
              const StudioNotice(
                'Indiquez des dimensions positives qui tiennent dans l’image.',
                isError: true,
              )
            else
              Text(
                projectTilesetGridLabel(candidate),
                style: details.titleSmall,
              ),
            const SizedBox(height: StudioSpacing.m),
            SizedBox(
              height: 184,
              child: Semantics(
                label: candidate == null
                    ? 'Aperçu du découpage enregistré'
                    : 'Aperçu du découpage proposé',
                child: widget.buildPreview(candidate ?? source),
              ),
            ),
            if (_needsPreparation || _prepared || _problem != null)
              const SizedBox(height: StudioSpacing.m),
            if (_needsPreparation)
              const StudioNotice(
                'L’index des usages doit être préparé pour vérifier quelles ressources utilisent cette planche.',
              )
            else if (_prepared && _problem == null)
              const StudioNotice(
                'L’index des usages est prêt. Vous pouvez enregistrer le découpage.',
              ),
            if (_problem case final problem?)
              StudioNotice(problem, isError: true),
          ],
        ),
      ),
    );
  }

  Widget _dimension(
    String label,
    String key,
    String value,
    ValueChanged<String> onChanged,
  ) => StudioDraftField(
    key: ValueKey('tileset-grid-$key'),
    label: label,
    value: value,
    keyboardType: TextInputType.number,
    enabled: !_working && _pending == null,
    onChanged: onChanged,
  );
}
