import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_editing.dart';
import 'surface_studio_atlas_grid_preview.dart';
import 'surface_studio_atlas_image_preview.dart';
import 'surface_studio_atlas_source_picker.dart';
import 'surface_studio_column_role_mapping_block.dart';
import 'surface_studio_selection.dart';
import 'surface_studio_vertical_atlas_animation_preview.dart';
import 'surface_studio_vertical_atlas_assistant.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

const ValueKey<String> kSurfaceStudioAtlasAuthoringPrepKey =
    ValueKey<String>('SurfaceStudioAtlasAuthoringPrep');

List<String> validateSurfaceStudioAtlasDraft({
  required SurfaceStudioReadModel readModel,
  required String idRaw,
  required String nameRaw,
  required String tilesetIdRaw,
  required String tileWidthRaw,
  required String tileHeightRaw,
  required String columnsRaw,
  required String rowsRaw,
  required String sortOrderRaw,
  required String? categoryIdRaw,
  String? editingExistingAtlasId,
}) {
  final errors = <String>[];
  final id = idRaw.trim();
  final name = nameRaw.trim();
  final tilesetId = tilesetIdRaw.trim();
  if (id.isEmpty) {
    errors.add('Identifiant requis');
  }
  if (name.isEmpty) {
    errors.add('Nom requis');
  }
  if (tilesetId.isEmpty) {
    errors.add('Une source d’image (jeu d’images) est requise');
  }

  int? tw = int.tryParse(tileWidthRaw.trim());
  if (tw == null) {
    errors.add('Largeur de tuile : entier requis');
  } else if (tw <= 0) {
    errors.add('Largeur de tuile : valeur positive requise');
  }

  int? th = int.tryParse(tileHeightRaw.trim());
  if (th == null) {
    errors.add('Hauteur de tuile : entier requis');
  } else if (th <= 0) {
    errors.add('Hauteur de tuile : valeur positive requise');
  }

  int? c = int.tryParse(columnsRaw.trim());
  if (c == null) {
    errors.add('Colonnes : entier requis');
  } else if (c <= 0) {
    errors.add('Colonnes : valeur positive requise');
  }

  int? r = int.tryParse(rowsRaw.trim());
  if (r == null) {
    errors.add('Lignes : entier requis');
  } else if (r <= 0) {
    errors.add('Lignes : valeur positive requise');
  }

  int? so = int.tryParse(sortOrderRaw.trim());
  if (so == null) {
    errors.add('Ordre : entier requis');
  } else if (so < 0) {
    errors.add('Ordre : valeur négative interdite pour ce brouillon');
  }

  if (id.isNotEmpty) {
    for (final a in readModel.atlases) {
      if (a.id == id) {
        if (editingExistingAtlasId != null && editingExistingAtlasId == id) {
          break;
        }
        errors.add('Un atlas existe déjà avec cet id.');
        break;
      }
    }
  }

  return errors;
}

ProjectSurfaceAtlas? tryBuildProjectSurfaceAtlasFromDraft(
  SurfaceStudioAtlasDraft draft,
) {
  try {
    return ProjectSurfaceAtlas(
      id: draft.id,
      name: draft.name,
      tilesetId: draft.tilesetId,
      geometry: SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(
          width: draft.tileWidth,
          height: draft.tileHeight,
        ),
        gridSize: SurfaceAtlasGridSize(
          columns: draft.columns,
          rows: draft.rows,
        ),
        layout: draft.layout,
      ),
      categoryId: draft.categoryId,
      sortOrder: draft.sortOrder,
    );
  } on ValidationException {
    return null;
  }
}

class SurfaceStudioAtlasDraft {
  const SurfaceStudioAtlasDraft({
    required this.id,
    required this.name,
    required this.tilesetId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.layout,
    required this.sortOrder,
    this.categoryId,
  });

  final String id;
  final String name;
  final String tilesetId;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final int rows;
  final SurfaceAtlasLayout layout;
  final int sortOrder;
  final String? categoryId;

  int get tileCount => columns * rows;
}

SurfaceStudioAtlasDraft? tryBuildDraftFromForm({
  required String idRaw,
  required String nameRaw,
  required String tilesetIdRaw,
  required String tileWidthRaw,
  required String tileHeightRaw,
  required String columnsRaw,
  required String rowsRaw,
  required String sortOrderRaw,
  required String? categoryIdRaw,
  required SurfaceAtlasLayout layout,
}) {
  final id = idRaw.trim();
  final name = nameRaw.trim();
  final tilesetId = tilesetIdRaw.trim();
  final tw = int.tryParse(tileWidthRaw.trim());
  final th = int.tryParse(tileHeightRaw.trim());
  final c = int.tryParse(columnsRaw.trim());
  final r = int.tryParse(rowsRaw.trim());
  final so = int.tryParse(sortOrderRaw.trim());
  if (id.isEmpty ||
      name.isEmpty ||
      tilesetId.isEmpty ||
      tw == null ||
      th == null ||
      c == null ||
      r == null ||
      so == null) {
    return null;
  }
  if (tw <= 0 || th <= 0 || c <= 0 || r <= 0 || so < 0) {
    return null;
  }
  final cat = categoryIdRaw?.trim();
  return SurfaceStudioAtlasDraft(
    id: id,
    name: name,
    tilesetId: tilesetId,
    tileWidth: tw,
    tileHeight: th,
    columns: c,
    rows: r,
    layout: layout,
    sortOrder: so,
    categoryId: (cat == null || cat.isEmpty) ? null : cat,
  );
}

class SurfaceStudioAtlasAuthoringPrep extends StatefulWidget {
  const SurfaceStudioAtlasAuthoringPrep({
    super.key,
    required this.readModel,
    required this.selection,
    this.onSurfaceCatalogChanged,
    this.requestEditSignal = 0,
    this.projectTilesets,
    this.projectRootPath,
  });

  final SurfaceStudioReadModel readModel;
  final SurfaceStudioSelection selection;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
  final int requestEditSignal;
  final List<ProjectTilesetEntry>? projectTilesets;

  /// Dossier projet sur disque (optionnel) — utilisé pour résoudre [ProjectTilesetEntry.relativePath].
  final String? projectRootPath;

  @override
  State<SurfaceStudioAtlasAuthoringPrep> createState() =>
      _SurfaceStudioAtlasAuthoringPrepState();
}

class _SurfaceStudioAtlasAuthoringPrepState
    extends State<SurfaceStudioAtlasAuthoringPrep> {
  late final TextEditingController _id = TextEditingController();
  late final TextEditingController _name = TextEditingController();
  late final TextEditingController _tilesetId = TextEditingController();
  late final TextEditingController _tileW = TextEditingController(text: '32');
  late final TextEditingController _tileH = TextEditingController(text: '32');
  late final TextEditingController _cols = TextEditingController(text: '1');
  late final TextEditingController _rows = TextEditingController(text: '1');
  late final TextEditingController _sort = TextEditingController(text: '0');
  late final TextEditingController _categoryId = TextEditingController();

  SurfaceAtlasLayout _layout = SurfaceAtlasLayout.grid;
  bool _showPreview = false;
  String? _creationNote;
  bool _isEditMode = false;
  String? _editingAtlasId;
  bool _userEditedId = false;
  SurfaceStudioColumnRoleMappingDraft _columnRoleMappingDraft =
      const SurfaceStudioColumnRoleMappingDraft.empty(0);

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _tilesetId.dispose();
    _tileW.dispose();
    _tileH.dispose();
    _cols.dispose();
    _rows.dispose();
    _sort.dispose();
    _categoryId.dispose();
    super.dispose();
  }

  void _resetToDefaults() {
    setState(() {
      _id.clear();
      _name.clear();
      _tilesetId.clear();
      _tileW.text = '32';
      _tileH.text = '32';
      _cols.text = '1';
      _rows.text = '1';
      _sort.text = '0';
      _categoryId.clear();
      _layout = SurfaceAtlasLayout.grid;
      _creationNote = null;
      _isEditMode = false;
      _editingAtlasId = null;
      _userEditedId = false;
      _columnRoleMappingDraft =
          const SurfaceStudioColumnRoleMappingDraft.empty(0);
    });
  }

  void _updateColumnRoleMappingDraft() {
    final newColumns = int.tryParse(_cols.text.trim());
    if (newColumns == null || newColumns <= 0) {
      return;
    }

    // Si le nombre de colonnes a changé, on réinitialise le mapping
    if (newColumns != _columnRoleMappingDraft.columnCount) {
      setState(() {
        _columnRoleMappingDraft =
            SurfaceStudioColumnRoleMappingDraft.empty(newColumns);
      });
    }
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioAtlasAuthoringPrep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestEditSignal != oldWidget.requestEditSignal) {
      _enterEditModeFromSelection();
    }
    if (_isEditMode && _editingAtlasId != null) {
      if (!widget.selection.isAtlas || widget.selection.id != _editingAtlasId) {
        setState(() {
          _isEditMode = false;
          _editingAtlasId = null;
          _userEditedId = false;
          _id.clear();
          _name.clear();
          _tilesetId.clear();
          _tileW.text = '32';
          _tileH.text = '32';
          _cols.text = '1';
          _rows.text = '1';
          _sort.text = '0';
          _categoryId.clear();
          _layout = SurfaceAtlasLayout.grid;
          _creationNote = null;
          _columnRoleMappingDraft =
              const SurfaceStudioColumnRoleMappingDraft.empty(0);
        });
      }
    }
  }

  SurfaceStudioAtlasReadModel? _atlasRowForSelection() {
    final sel = widget.selection;
    if (!sel.isAtlas) {
      return null;
    }
    for (final a in widget.readModel.atlases) {
      if (a.id == sel.id) {
        return a;
      }
    }
    return null;
  }

  void _cancelEditMode() {
    setState(() {
      _isEditMode = false;
      _editingAtlasId = null;
      _userEditedId = false;
      _id.clear();
      _name.clear();
      _tilesetId.clear();
      _tileW.text = '32';
      _tileH.text = '32';
      _cols.text = '1';
      _rows.text = '1';
      _sort.text = '0';
      _categoryId.clear();
      _layout = SurfaceAtlasLayout.grid;
      _creationNote = null;
      _columnRoleMappingDraft =
          const SurfaceStudioColumnRoleMappingDraft.empty(0);
    });
  }

  void _enterEditModeFromSelection() {
    final sel = widget.selection;
    if (!sel.isAtlas) {
      return;
    }
    SurfaceStudioAtlasReadModel? row;
    for (final a in widget.readModel.atlases) {
      if (a.id == sel.id) {
        row = a;
        break;
      }
    }
    if (row == null) {
      return;
    }
    setState(() {
      _isEditMode = true;
      _userEditedId = true;
      _editingAtlasId = row!.atlas.id;
      _id.text = row.atlas.id;
      _name.text = row.atlas.name;
      _tilesetId.text = row.atlas.tilesetId;
      _tileW.text = '${row.tileWidth}';
      _tileH.text = '${row.tileHeight}';
      _cols.text = '${row.columns}';
      _rows.text = '${row.rows}';
      _sort.text = '${row.sortOrder}';
      _layout = row.atlas.geometry.layout;
      _categoryId.text = row.categoryId ?? '';
      _creationNote = null;
      _columnRoleMappingDraft =
          const SurfaceStudioColumnRoleMappingDraft.empty(0);
    });
  }

  void _loadFromSelection() {
    final sel = widget.selection;
    if (!sel.isAtlas) {
      return;
    }
    SurfaceStudioAtlasReadModel? row;
    for (final a in widget.readModel.atlases) {
      if (a.id == sel.id) {
        row = a;
        break;
      }
    }
    if (row == null) {
      return;
    }
    setState(() {
      _isEditMode = false;
      _editingAtlasId = null;
      _userEditedId = true;
      _id.text = row!.atlas.id;
      _name.text = row.atlas.name;
      _tilesetId.text = row.atlas.tilesetId;
      _tileW.text = '${row.tileWidth}';
      _tileH.text = '${row.tileHeight}';
      _cols.text = '${row.columns}';
      _rows.text = '${row.rows}';
      _sort.text = '${row.sortOrder}';
      _layout = row.atlas.geometry.layout;
      _categoryId.text = row.categoryId ?? '';
      _creationNote = null;
      _columnRoleMappingDraft =
          const SurfaceStudioColumnRoleMappingDraft.empty(0);
    });
  }

  void _applyEditToWorkCatalog() {
    final callback = widget.onSurfaceCatalogChanged;
    if (callback == null || !_isEditMode || _editingAtlasId == null) {
      return;
    }
    setState(() => _creationNote = null);
    final errs = validateSurfaceStudioAtlasDraft(
      readModel: widget.readModel,
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
      editingExistingAtlasId: _editingAtlasId,
    );
    if (errs.isNotEmpty) {
      return;
    }
    final draft = tryBuildDraftFromForm(
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
      layout: _layout,
    );
    if (draft == null) {
      return;
    }
    if (draft.id != _editingAtlasId) {
      return;
    }
    final atlas = tryBuildProjectSurfaceAtlasFromDraft(draft);
    if (atlas == null) {
      return;
    }
    try {
      final next = replaceAtlasInCatalogInPlace(
        widget.readModel.catalog,
        atlas,
      );
      callback(next);
      setState(() {
        _creationNote =
            'Modifications enregistrées dans le catalogue de travail. Sauvegarde projet non effectuée.';
      });
    } on ValidationException {
      setState(() {
        _creationNote = 'Impossible d’appliquer le catalogue (validation).';
      });
    } on StateError {
      setState(() {
        _creationNote = 'Impossible d’appliquer : atlas introuvable dans le catalogue.';
      });
    }
  }

  void _addToWorkCatalog() {
    final callback = widget.onSurfaceCatalogChanged;
    if (callback == null) {
      return;
    }
    if (_isEditMode) {
      return;
    }
    setState(() => _creationNote = null);
    final errs = validateSurfaceStudioAtlasDraft(
      readModel: widget.readModel,
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
    );
    if (errs.isNotEmpty) {
      return;
    }
    final draft = tryBuildDraftFromForm(
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
      layout: _layout,
    );
    if (draft == null) {
      return;
    }
    final atlas = tryBuildProjectSurfaceAtlasFromDraft(draft);
    if (atlas == null) {
      return;
    }
    try {
      final next = ProjectSurfaceCatalog(
        atlases: [
          ...widget.readModel.catalog.atlases,
          atlas,
        ],
        animations: List<ProjectSurfaceAnimation>.from(
          widget.readModel.catalog.animations,
        ),
        presets: List<ProjectSurfacePreset>.from(
          widget.readModel.catalog.presets,
        ),
      );
      callback(next);
      setState(() {
        _creationNote =
            'Atlas créé dans le catalogue de travail. Sauvegarde projet non effectuée.';
      });
    } on ValidationException {
      setState(() {
        _creationNote = 'Un atlas existe déjà avec cet id.';
      });
    }
  }

  String _layoutMenuLabel(SurfaceAtlasLayout l) {
    switch (l) {
      case SurfaceAtlasLayout.grid:
        return 'Grille libre';
      case SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames:
        return 'Colonnes = variantes, lignes = frames';
      case SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames:
        return 'Lignes = variantes, colonnes = frames';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = Color(0xFF2DD4BF);

    final errs = validateSurfaceStudioAtlasDraft(
      readModel: widget.readModel,
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
      editingExistingAtlasId: _isEditMode ? _editingAtlasId : null,
    );
    final isValid = errs.isEmpty;
    final draft = tryBuildDraftFromForm(
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
      layout: _layout,
    );

    final rawTilesets = widget.projectTilesets;
    final sortedTilesets = sortedTilesetChoices(
      rawTilesets == null
          ? const <ProjectTilesetEntry>[]
          : List<ProjectTilesetEntry>.from(rawTilesets),
    );
    final hasImagePicker = sortedTilesets.isNotEmpty;
    final tilesetIdTrim = _tilesetId.text.trim();
    final sourceLabel =
        tilesetIdTrim.isEmpty ? null : tilesetIdTrim;
    ProjectTilesetEntry? selectedTilesetEntry;
    if (tilesetIdTrim.isNotEmpty) {
      for (final e in sortedTilesets) {
        if (e.id == tilesetIdTrim) {
          selectedTilesetEntry = e;
          break;
        }
      }
    }
    String? gridSourceDisplayForUi;
    if (tilesetIdTrim.isNotEmpty) {
      if (selectedTilesetEntry != null) {
        final n = selectedTilesetEntry.name.trim();
        if (n.isNotEmpty) {
          gridSourceDisplayForUi = n;
        } else {
          final rp = selectedTilesetEntry.relativePath.trim();
          gridSourceDisplayForUi =
              rp.isNotEmpty ? p.basename(rp) : 'Jeu d’images sans nom';
        }
      } else {
        gridSourceDisplayForUi = 'Saisie technique (options avancées)';
      }
    }

    final imagePreviewResolution = resolveSurfaceStudioAtlasImagePreview(
      projectRootPath: widget.projectRootPath,
      projectTilesets: rawTilesets,
      technicalTilesetId: tilesetIdTrim.isEmpty ? null : tilesetIdTrim,
    );
    final previewTileWidth = int.tryParse(_tileW.text.trim());
    final previewTileHeight = int.tryParse(_tileH.text.trim());
    final previewColumns = int.tryParse(_cols.text.trim());
    final previewRows = int.tryParse(_rows.text.trim());

    final sel = widget.selection;
    String? contextNote;
    if (sel.isAnimation || sel.isPreset) {
      contextNote = 'La sélection actuelle n’est pas un atlas.';
    } else if (sel.isAtlas) {
      var found = false;
      for (final a in widget.readModel.atlases) {
        if (a.id == sel.id) {
          found = true;
          break;
        }
      }
      if (!found) {
        contextNote =
            'Atlas sélectionné introuvable, brouillon atlas indépendant.';
      }
    }

    return material.Material(
      type: material.MaterialType.transparency,
      child: Container(
        key: kSurfaceStudioAtlasAuthoringPrepKey,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EditorChrome.elevatedPanelBackground(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Color.lerp(
              EditorChrome.editorIslandRim(context),
              accent,
              0.35,
            )!,
          ),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: material.Theme(
          data: _surfaceStudioAuthoringMaterialTheme(context, label, subtle),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          Text(
            'Préparation atlas',
            key: const ValueKey('surface_studio_authoring_main_title'),
            style: TextStyle(
              color: label,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_isEditMode) ...[
            const SizedBox(height: 4),
            const Text(
              'Édition locale de l’atlas',
              key: ValueKey<String>('surface_studio_atlas_edit_mode_label'),
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            'Brouillon : rien n’est écrit sur le disque tant que le projet n’est pas sauvegardé.',
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Brouillon local · non sauvegardé · en mémoire seulement',
            style: TextStyle(
              color: accent.withValues(alpha: 0.95),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (contextNote != null) ...[
            const SizedBox(height: 8),
            Text(
              contextNote,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (_isEditMode) ...[
                CupertinoButton(
                  key: const ValueKey('surface_studio_cancel_atlas_edit'),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onPressed: _cancelEditMode,
                  child: const Text('Annuler l’édition'),
                ),
                CupertinoButton(
                  key: const ValueKey('surface_studio_apply_atlas_edit'),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onPressed: isValid ? _applyEditToWorkCatalog : null,
                  child: const Text(
                    'Appliquer les modifications au catalogue de travail',
                  ),
                ),
              ] else ...[
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onPressed: _resetToDefaults,
                  child: const Text('Réinitialiser le brouillon'),
                ),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onPressed: _loadFromSelection,
                  child: const Text('Charger la sélection dans le brouillon'),
                ),
                if (widget.onSurfaceCatalogChanged != null &&
                    widget.selection.isAtlas &&
                    _atlasRowForSelection() != null)
                  CupertinoButton(
                    key: const ValueKey('surface_studio_start_edit_atlas'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onPressed: _enterEditModeFromSelection,
                    child: const Text('Modifier cet atlas'),
                  ),
                if (widget.onSurfaceCatalogChanged != null)
                  CupertinoButton(
                    key: const ValueKey('surface_studio_create_atlas_work_catalog'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onPressed: isValid ? _addToWorkCatalog : null,
                    child: const Text('Créer l’atlas dans le catalogue de travail'),
                  ),
              ],
            ],
          ),
          if (_creationNote != null) ...[
            const SizedBox(height: 8),
            Text(
              _creationNote!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ).copyWith(color: accent),
            ),
          ],
          const SizedBox(height: 6),
          SurfaceStudioAtlasImageSourceBlock(
            hasPicker: hasImagePicker,
            sortedTilesets: sortedTilesets,
            selectedTilesetId: _tilesetId.text.trim().isEmpty
                ? null
                : _tilesetId.text.trim(),
            onSelectTilesetId: (v) {
              setState(() {
                _tilesetId.text = v ?? '';
              });
            },
            label: label,
            subtle: subtle,
          ),
          const SizedBox(height: 10),
          SurfaceStudioVerticalAtlasAssistant(
            label: label,
            subtle: subtle,
            draftTileWidth: previewTileWidth,
            draftTileHeight: previewTileHeight,
            draftColumns: previewColumns,
            draftRows: previewRows,
          ),
          const SizedBox(height: 10),
          SurfaceStudioColumnRoleMappingBlock(
            label: label,
            subtle: subtle,
            draft: _columnRoleMappingDraft,
            onDraftChanged: (newDraft) {
              setState(() {
                _columnRoleMappingDraft = newDraft;
              });
            },
            draftTileWidth: previewTileWidth,
            draftTileHeight: previewTileHeight,
            draftColumns: previewColumns,
            draftRows: previewRows,
          ),
          const SizedBox(height: 10),
          SurfaceStudioVerticalAtlasAnimationPreview(
            label: label,
            subtle: subtle,
            mappingDraft: _columnRoleMappingDraft,
            tileWidth: previewTileWidth,
            tileHeight: previewTileHeight,
            columns: previewColumns,
            rows: previewRows,
            resolvedImagePath: imagePreviewResolution.status ==
                    SurfaceStudioAtlasImagePreviewResolveStatus.resolved
                ? imagePreviewResolution.resolvedAbsolutePath
                : null,
          ),
          const SizedBox(height: 10),
          SurfaceStudioAtlasImagePreview(
            resolution: imagePreviewResolution,
            label: label,
            subtle: subtle,
            draftTileWidth: previewTileWidth,
            draftTileHeight: previewTileHeight,
            draftColumns: previewColumns,
            draftRows: previewRows,
            draftLayoutLabel: _layoutMenuLabel(_layout),
            largeFormat: true,
          ),
          const SizedBox(height: 10),
          _formGroupTitle('Grille de l’image', label),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_tile_w'),
                  controller: _tileW,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Largeur tuile',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_tile_h'),
                  controller: _tileH,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Hauteur tuile',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_cols'),
                  controller: _cols,
                  onChanged: (_) {
                    _updateColumnRoleMappingDraft();
                    setState(() {});
                  },
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Colonnes',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_rows'),
                  controller: _rows,
                  onChanged: (_) {
                    _updateColumnRoleMappingDraft();
                    setState(() {});
                  },
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Lignes',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Disposition', style: TextStyle(color: label, fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: material.DropdownButton<SurfaceAtlasLayout>(
                  isExpanded: true,
                  value: _layout,
                  style: TextStyle(color: label, fontSize: 12),
                  iconEnabledColor: label,
                  dropdownColor: EditorChrome.elevatedPanelBackground(context),
                  items: SurfaceAtlasLayout.values
                      .map(
                        (e) => material.DropdownMenuItem(
                          value: e,
                          child: Text(
                            _layoutMenuLabel(e),
                            style: TextStyle(color: label, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _layout = v);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SurfaceStudioAtlasGridPreview(
            sourceLabel: sourceLabel,
            sourceDisplayForUi: gridSourceDisplayForUi,
            tileWidth: previewTileWidth,
            tileHeight: previewTileHeight,
            columns: previewColumns,
            rows: previewRows,
            layoutLabel: _layoutMenuLabel(_layout),
          ),
          const SizedBox(height: 10),
          material.TextField(
            key: const ValueKey('atlas_draft_name'),
            controller: _name,
            onChanged: (_) {
              if (!_isEditMode && !_userEditedId) {
                final t = _name.text;
                if (t.trim().isEmpty) {
                  _id.clear();
                } else {
                  _id.text = suggestInternalAtlasIdFromName(t);
                }
              }
              setState(() {});
            },
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Nom affiché',
              isDense: true,
            ),
          ),
          const SizedBox(height: 5),
          material.TextField(
            key: const ValueKey('atlas_draft_id'),
            controller: _id,
            readOnly: _isEditMode,
            onChanged: (_) {
              _userEditedId = true;
              setState(() {});
            },
            style: TextStyle(color: label, fontSize: 13),
            decoration: material.InputDecoration(
              labelText: 'Identifiant interne',
              isDense: true,
              helperText: _isEditMode
                  ? 'ID verrouillé pour préserver les références'
                  : (_userEditedId
                      ? null
                      : 'Identifiant interne proposé à partir du nom'),
            ),
          ),
          const SizedBox(height: 8),
          _formGroupTitle('Options avancées', label),
          const SizedBox(height: 4),
          if (!hasImagePicker) ...[
            material.TextField(
              key: const ValueKey('atlas_draft_tileset_advanced'),
              controller: _tilesetId,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: label, fontSize: 13),
              decoration: const material.InputDecoration(
                labelText: 'Identifiant technique du jeu d’images',
                helperText:
                    'Temporaire : ce champ sera remplacé par un sélecteur d’image.',
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
          ],
          material.TextField(
            key: const ValueKey('atlas_draft_category'),
            controller: _categoryId,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Catégorie (optionnel)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 5),
          material.TextField(
            key: const ValueKey('atlas_draft_sort'),
            controller: _sort,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Ordre d’affichage',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              material.Switch(
                value: _showPreview,
                onChanged: (v) => setState(() => _showPreview = v),
              ),
              const SizedBox(width: 4),
              Text(
                'Prévisualisation locale',
                style: TextStyle(color: label, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isValid ? 'Brouillon prêt localement' : 'Brouillon invalide',
            style: TextStyle(
              color: isValid ? accent : const Color(0xFFE8887A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Aucune sauvegarde ne sera effectuée',
            style: TextStyle(color: subtle, fontSize: 11),
          ),
          if (errs.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final e in errs)
              Text(
                e,
                style: const TextStyle(
                  color: Color(0xFFE8887A),
                  fontSize: 11,
                ),
              ),
          ],
          if (_showPreview && draft != null) ...[
            const SizedBox(height: 10),
            Text(
              'Aperçu : ${draft.tileWidth}×${draft.tileHeight} · Grille ${draft.columns}×${draft.rows} · ${draft.tileCount} tuiles · ordre ${draft.sortOrder}',
              style: TextStyle(color: label, fontSize: 12),
            ),
            Text(
              'Disposition : ${_layoutMenuLabel(draft.layout)}',
              style: TextStyle(color: subtle, fontSize: 11),
            ),
            Text(
              'Catégorie : ${draft.categoryId ?? '—'}',
              style: TextStyle(color: subtle, fontSize: 11),
            ),
          ],
        ],
              ),
            ),
          ),
        ),
    );
  }
}

material.ThemeData _surfaceStudioAuthoringMaterialTheme(
  BuildContext context,
  Color label,
  Color subtle,
) {
  final base = material.Theme.of(context);
  final surface = EditorChrome.elevatedPanelBackground(context);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      surface: surface,
      onSurface: label,
      onSurfaceVariant: subtle,
    ),
    inputDecorationTheme: material.InputDecorationTheme(
      isDense: true,
      labelStyle: TextStyle(color: label, fontSize: 13),
      floatingLabelStyle: TextStyle(color: label, fontSize: 12),
      hintStyle: TextStyle(color: subtle, fontSize: 12),
      helperStyle: TextStyle(color: subtle, fontSize: 11),
    ),
  );
}

Widget _formGroupTitle(String t, Color label) {
  return Text(
    t,
    style: TextStyle(
      color: label.withValues(alpha: 0.85),
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.35,
    ),
  );
}
