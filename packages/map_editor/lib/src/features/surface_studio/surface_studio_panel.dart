// Surface Studio — assistant premium de mapping d'atlas.
//
// Le viewport principal porte un seul workflow guide moderne. Les anciennes
// briques utiles restent accessibles dans le drawer avance, sans second
// Surface Studio rendu sous l'assistant.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'importers/tiled_tsx_animation_browser.dart';
import 'importers/tiled_tsx_workspace.dart';
import 'surface_studio_atlas_editing.dart';
import 'surface_studio_atlas_image_preview.dart';
import 'surface_studio_catalog_browser.dart';
import 'surface_studio_diagnostics_view.dart';
import 'surface_studio_paintable_surfaces_panel.dart';
import 'surface_studio_preset_editor_controller.dart';
import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_role_mapping_editor.dart';
import 'surface_studio_selection.dart';
import 'surface_studio_selection_inspector.dart';
import 'surface_studio_selection_summary.dart';
import 'surface_studio_screen.dart';

SurfaceStudioSelection _selectionValidInReadModel(
  SurfaceStudioReadModel rm,
  SurfaceStudioSelection sel,
) {
  if (sel.isNone) return sel;
  if (sel.isAtlas) {
    for (final row in rm.atlases) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isAnimation) {
    for (final row in rm.animations) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isPreset) {
    for (final row in rm.presets) {
      if (row.id == sel.id) return sel;
    }
  }
  return const SurfaceStudioSelection.none();
}

/// Accent produit Surface Studio (même base que la tuile World Explorer).
const Color _surfaceStudioAccent = Color(0xFF2DD4BF);

enum _SurfaceStudioPrimaryWorkspace {
  catalogue,
  tallGrass,
  tsx,
  diagnostics,
}

/// Panneau présentationnel **lecture seule** pour Surface Studio.
class SurfaceStudioPanel extends StatefulWidget {
  const SurfaceStudioPanel({
    super.key,
    required this.readModel,
    this.onSurfaceCatalogSaveRequested,
    this.onRequestProjectSave,
    this.projectTilesets,
    this.projectRootPath,
    this.projectSettings,
    this.surfaceMappingImageLoader,
    this.aiMappingSuggester,
    this.tallGrassAuthoringView,
    this.tsxFileLoader = const TiledTsxPlatformFileLoader(),
  });

  final SurfaceStudioReadModel readModel;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;
  final Future<bool> Function()? onRequestProjectSave;
  final List<ProjectTilesetEntry>? projectTilesets;
  final ProjectSettings? projectSettings;
  final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
  final SurfaceStudioAiMappingSuggester? aiMappingSuggester;
  final TallGrassAuthoringView? tallGrassAuthoringView;
  final TiledTsxFileLoader tsxFileLoader;

  /// Racine projet sur disque pour résoudre les chemins d’images tileset (aperçu Lot 72).
  final String? projectRootPath;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String partialAuthoringBadgeText = 'Édition partielle';
  static const String workflowStepsHintText =
      'Étapes : atlas → grille → animations → surfaces prêtes à peindre';
  static const String productDescriptionText =
      'Créer des surfaces peintes à partir d’un atlas, étape par étape.';
  static const String placeholderActionsTitle = 'Actions auteur';
  static const String placeholderSoonText = 'Bientôt';
  static const String actionImportVerticalAtlasLabel =
      'Importer un atlas vertical';
  static const String workCatalogDirtyStateText =
      'Catalogue de travail modifié — sauvegarde projet non effectuée.';
  static const String savePrepActionLabel =
      'Préparer la sauvegarde du catalogue Surface';
  static const String savePrepTransmittedNote =
      'Catalogue de travail transmis au parent.';
  static const String savePrepNotConnectedNote =
      'Sauvegarde non connectée dans ce contexte.';
  static const String savePrepNoDiskNote =
      'Aucune écriture disque ne sera effectuée par Surface Studio.';
  static const String manifestMemoryUpdatedNote =
      'Manifest projet mis à jour en mémoire — écriture disque non effectuée.';
  static const String projectSaveViaExistingFlowButtonLabel =
      'Sauvegarder le projet via le flux existant';
  static const String projectDiskSaveResultSuccessNote =
      'Projet sauvegardé via le flux projet existant.';
  static const String projectDiskSaveRequestedNote =
      'Sauvegarde projet demandée.';
  static const String projectDiskSaveFailureNote =
      'Échec de sauvegarde projet — voir la barre d’état.';

  @override
  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
}

class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
  _SurfaceStudioPrimaryWorkspace _primaryWorkspace =
      _SurfaceStudioPrimaryWorkspace.catalogue;
  late SurfaceStudioReadModel _workReadModel;
  String? _saveFlowPrepNote;
  String? _projectSaveDiskNote;
  int _atlasEditSignal = 0;
  String? _tsxBrowserImagePath;
  Uint8List? _tsxBrowserImageBytes;

  @override
  void initState() {
    super.initState();
    _workReadModel = widget.readModel;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readModel != oldWidget.readModel) {
      final hadDirty = _workReadModel != oldWidget.readModel;
      final absNow = widget.readModel ==
          buildSurfaceStudioReadModelFromCatalog(_workReadModel.catalog);
      final wasAbsorbed = hadDirty && absNow;
      setState(() {
        _workReadModel = widget.readModel;
        _selection = _selectionValidInReadModel(_workReadModel, _selection);
        _saveFlowPrepNote =
            wasAbsorbed ? SurfaceStudioPanel.manifestMemoryUpdatedNote : null;
      });
    }
  }

  bool get _hasWorkCatalogChanges => _workReadModel != widget.readModel;

  void _bumpAtlasEditSignal() {
    setState(() => _atlasEditSignal += 1);
  }

  void _onConfirmDeleteSelectedAtlas() {
    final id = _selection.id;
    if (id == null || !_selection.isAtlas) {
      return;
    }
    try {
      final next = removeAtlasIdFromWorkCatalog(_workReadModel.catalog, id);
      setState(() {
        _saveFlowPrepNote = null;
        _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
        _selection = const SurfaceStudioSelection.none();
      });
    } on StateError {
      return;
    }
  }

  SurfaceStudioSelection _selectionAfterCatalogChanged(
    ProjectSurfaceCatalog cat,
  ) {
    if (_selection.isAtlas) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.atlases) {
          if (a.id == sid) {
            return SurfaceStudioSelection.atlas(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isAnimation) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.animations) {
          if (a.id == sid) {
            return SurfaceStudioSelection.animation(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isPreset) {
      final sid = _selection.id;
      if (sid != null) {
        for (final p in cat.presets) {
          if (p.id == sid) {
            return SurfaceStudioSelection.preset(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (cat.atlases.isNotEmpty) {
      return SurfaceStudioSelection.atlas(cat.atlases.last.id);
    }
    return const SurfaceStudioSelection.none();
  }

  void _onSurfaceCatalogSavePrep() {
    final cb = widget.onSurfaceCatalogSaveRequested;
    if (cb == null) {
      return;
    }
    cb(_workReadModel.catalog);
    setState(() {
      _saveFlowPrepNote = SurfaceStudioPanel.savePrepTransmittedNote;
    });
  }

  Future<void> _onRequestProjectSave() async {
    final fn = widget.onRequestProjectSave;
    if (fn == null) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = SurfaceStudioPanel.projectDiskSaveRequestedNote;
    });
    final ok = await fn();
    if (!mounted) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = ok
          ? SurfaceStudioPanel.projectDiskSaveResultSuccessNote
          : SurfaceStudioPanel.projectDiskSaveFailureNote;
    });
  }

  ProjectSurfacePreset? _selectedWorkPreset() {
    final id = _selection.id;
    if (id == null || !_selection.isPreset) {
      return null;
    }
    return _workReadModel.catalog.presetById(id);
  }

  void _selectPreset(String presetId) {
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  void _onPresetRoleAnimationChanged(
    SurfaceVariantRole role,
    String animationId,
  ) {
    final presetId = _selection.id;
    if (presetId == null || !_selection.isPreset) {
      return;
    }
    final next = surfaceStudioReplacePresetRoleAnimation(
      catalog: _workReadModel.catalog,
      presetId: presetId,
      role: role,
      animationId: animationId,
    );
    setState(() {
      _saveFlowPrepNote = null;
      _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  Future<void> _openPresetMappingEditor(String presetId) async {
    final preset = _workReadModel.catalog.presetById(presetId);
    if (preset == null) {
      return;
    }
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
    await showMacosSheet<void>(
      context: context,
      builder: (ctx) => Center(
        child: MacosSheet(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              key: const ValueKey('surface_mapping_editor_sheet'),
              width: 1120,
              height: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Surface Mapping Editor',
                          style: editorMacosSheetTitleStyle(ctx),
                        ),
                      ),
                      PushButton(
                        key: const ValueKey('surface_mapping_editor_close'),
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Étape 1 : choisissez un slot visuel. Étape 2 : cliquez directement une colonne dans l’atlas réel.',
                    style: TextStyle(
                      color: _surfaceStudioAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SurfaceStudioRoleMappingEditor(
                        catalog: _workReadModel.catalog,
                        preset: preset,
                        projectRootPath: widget.projectRootPath,
                        projectTilesets: widget.projectTilesets ??
                            const <ProjectTilesetEntry>[],
                        imageLoader: widget.surfaceMappingImageLoader,
                        onRoleAnimationChanged: _onPresetRoleAnimationChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSurfaceCatalogChanged(ProjectSurfaceCatalog cat) {
    setState(() {
      _saveFlowPrepNote = null;
      _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
      _selection = _selectionAfterCatalogChanged(cat);
    });
  }

  ProjectSurfaceAtlas? _atlasForAnimationBrowser() {
    for (final animation in _workReadModel.catalog.animations) {
      final frames = animation.timeline.frames;
      if (frames.isEmpty) {
        continue;
      }
      final atlas = _workReadModel.catalog.atlasById(
        frames.first.tileRef.atlasId,
      );
      if (atlas != null) {
        return atlas;
      }
    }
    return _workReadModel.catalog.atlases.isEmpty
        ? null
        : _workReadModel.catalog.atlases.first;
  }

  Uint8List? _atlasImageBytesForBrowser(ProjectSurfaceAtlas? atlas) {
    if (atlas == null) {
      _tsxBrowserImagePath = null;
      _tsxBrowserImageBytes = null;
      return null;
    }
    final resolution = resolveSurfaceStudioAtlasImagePreview(
      projectRootPath: widget.projectRootPath,
      projectTilesets: widget.projectTilesets ?? const <ProjectTilesetEntry>[],
      technicalTilesetId: atlas.tilesetId,
    );
    final path = resolution.resolvedAbsolutePath;
    if (path == null || path.isEmpty) {
      _tsxBrowserImagePath = null;
      _tsxBrowserImageBytes = null;
      return null;
    }
    if (_tsxBrowserImagePath == path && _tsxBrowserImageBytes != null) {
      return _tsxBrowserImageBytes;
    }
    try {
      final bytes = File(path).readAsBytesSync();
      _tsxBrowserImagePath = path;
      _tsxBrowserImageBytes = bytes;
      return bytes;
    } catch (_) {
      _tsxBrowserImagePath = path;
      _tsxBrowserImageBytes = null;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canMutateCatalog = widget.onSurfaceCatalogSaveRequested != null;
    final inspection = Column(
      key: const ValueKey('surface_studio_inspection_column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceStudioSelectionSummary(selection: _selection),
        const SizedBox(height: 10),
        SurfaceStudioSelectionInspector(
          readModel: _workReadModel,
          selection: _selection,
          onRequestEditSelectedAtlas:
              canMutateCatalog ? _bumpAtlasEditSignal : null,
          onConfirmDeleteSelectedAtlas:
              canMutateCatalog ? _onConfirmDeleteSelectedAtlas : null,
        ),
      ],
    );
    final selectedPreset = _selectedWorkPreset();
    final paintableSurfaces = SurfaceStudioPaintableSurfacesPanel(
      readModel: _workReadModel,
      selectedPresetId: selectedPreset?.id,
      onPresetSelected: _selectPreset,
      onEditMappingPressed: canMutateCatalog ? _openPresetMappingEditor : null,
      onSaveCatalogPressed: widget.onSurfaceCatalogSaveRequested != null
          ? _onSurfaceCatalogSavePrep
          : null,
    );
    final tsxBrowserAtlas = _atlasForAnimationBrowser();
    Widget buildAdvancedDetails() {
      return _AdvancedDetailsSection(
        inspection: inspection,
        browser: SurfaceStudioCatalogBrowser(
          readModel: _workReadModel,
          selection: _selection,
          onSelectionChanged: (v) {
            setState(() => _selection = v);
          },
        ),
        tsxAnimations: TiledTsxAnimationBrowser(
          atlas: tsxBrowserAtlas,
          animations: _workReadModel.catalog.animations,
          atlasImageBytes: _atlasImageBytesForBrowser(tsxBrowserAtlas),
          sourceLabel: 'Catalogue de travail',
          catalog: _workReadModel.catalog,
          projectSettings: widget.projectSettings,
          onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
        ),
        diagnostics: SurfaceStudioDiagnosticsView(readModel: _workReadModel),
        futureActions: paintableSurfaces,
        placeholder: const _SectionPlaceholder(
          title: SurfaceStudioPanel.placeholderActionsTitle,
        ),
      );
    }

    final advancedDrawer = SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: buildAdvancedDetails(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final shellWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 1600.0;
        final shellHeight =
            constraints.hasBoundedHeight ? constraints.maxHeight : 900.0;
        final tsxWorkspaceAtlas = _atlasForAnimationBrowser();
        final content = switch (_primaryWorkspace) {
          _SurfaceStudioPrimaryWorkspace.catalogue => SurfaceStudioScreen(
              readModel: _workReadModel,
              projectSettings: widget.projectSettings,
              projectTilesets: widget.projectTilesets ?? const [],
              projectRootPath: widget.projectRootPath,
              surfaceMappingImageLoader: widget.surfaceMappingImageLoader,
              hasWorkCatalogChanges: _hasWorkCatalogChanges,
              saveFlowPrepNote: _saveFlowPrepNote,
              projectSaveDiskNote: _projectSaveDiskNote,
              onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
              onWorkCatalogAnimationsCreated: (createdIds) {
                if (createdIds.isEmpty) {
                  return;
                }
                setState(() {
                  _selection =
                      SurfaceStudioSelection.animation(createdIds.first);
                });
              },
              onWorkCatalogPresetCreated: (presetId) {
                if (presetId.isEmpty) {
                  return;
                }
                setState(() {
                  _selection = SurfaceStudioSelection.preset(presetId);
                });
              },
              onResetWorkCatalog: () {
                setState(() {
                  _workReadModel = widget.readModel;
                  _selection =
                      _selectionValidInReadModel(_workReadModel, _selection);
                  _saveFlowPrepNote = null;
                });
              },
              onSurfaceCatalogSavePrep:
                  widget.onSurfaceCatalogSaveRequested == null
                      ? null
                      : _onSurfaceCatalogSavePrep,
              onRequestProjectSave: widget.onRequestProjectSave == null
                  ? null
                  : _onRequestProjectSave,
              advancedDrawer: advancedDrawer,
              aiMappingSuggester: widget.aiMappingSuggester,
            ),
          _SurfaceStudioPrimaryWorkspace.tallGrass => _TallGrassStudioPanel(
              view: widget.tallGrassAuthoringView,
            ),
          _SurfaceStudioPrimaryWorkspace.tsx => TiledTsxWorkspace(
              catalog: _workReadModel.catalog,
              projectTilesets: widget.projectTilesets ?? const [],
              onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
              fileLoader: widget.tsxFileLoader,
              atlasImageBytes: _atlasImageBytesForBrowser(tsxWorkspaceAtlas),
              projectSettings: widget.projectSettings,
            ),
          _SurfaceStudioPrimaryWorkspace.diagnostics => SingleChildScrollView(
              key: const ValueKey('surface_studio.diagnostics_workspace'),
              padding: const EdgeInsets.all(14),
              child: buildAdvancedDetails(),
            ),
        };
        return SizedBox(
          width: shellWidth,
          height: shellHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SurfaceStudioPrimaryTabs(
                selected: _primaryWorkspace,
                onSelected: (workspace) {
                  setState(() => _primaryWorkspace = workspace);
                },
              ),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}

class _SurfaceStudioPrimaryTabs extends StatelessWidget {
  const _SurfaceStudioPrimaryTabs({
    required this.selected,
    required this.onSelected,
  });

  final _SurfaceStudioPrimaryWorkspace selected;
  final ValueChanged<_SurfaceStudioPrimaryWorkspace> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surface_studio.primary_tabs'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: EditorChrome.appBackground(context),
      child: Row(
        children: [
          _SurfaceStudioPrimaryTabButton(
            key: const ValueKey('surface_studio.tab.catalogue'),
            label: 'Catalogue Surface',
            selected: selected == _SurfaceStudioPrimaryWorkspace.catalogue,
            onPressed: () =>
                onSelected(_SurfaceStudioPrimaryWorkspace.catalogue),
          ),
          const SizedBox(width: 8),
          _SurfaceStudioPrimaryTabButton(
            key: const ValueKey('surface_studio.tab.tall_grass'),
            label: 'Hautes herbes',
            selected: selected == _SurfaceStudioPrimaryWorkspace.tallGrass,
            onPressed: () =>
                onSelected(_SurfaceStudioPrimaryWorkspace.tallGrass),
          ),
          const SizedBox(width: 8),
          _SurfaceStudioPrimaryTabButton(
            key: const ValueKey('surface_studio.tab.tsx'),
            label: 'TSX',
            selected: selected == _SurfaceStudioPrimaryWorkspace.tsx,
            onPressed: () => onSelected(_SurfaceStudioPrimaryWorkspace.tsx),
          ),
          const SizedBox(width: 8),
          _SurfaceStudioPrimaryTabButton(
            key: const ValueKey('surface_studio.tab.diagnostics'),
            label: 'Diagnostics',
            selected: selected == _SurfaceStudioPrimaryWorkspace.diagnostics,
            onPressed: () =>
                onSelected(_SurfaceStudioPrimaryWorkspace.diagnostics),
          ),
        ],
      ),
    );
  }
}

class _SurfaceStudioPrimaryTabButton extends StatelessWidget {
  const _SurfaceStudioPrimaryTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _surfaceStudioAccent.withValues(alpha: 0.2)
        : EditorChrome.elevatedPanelBackground(context);
    final textColor =
        selected ? _surfaceStudioAccent : EditorChrome.primaryLabel(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: color,
      borderRadius: BorderRadius.circular(9),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _TallGrassStudioPanel extends StatelessWidget {
  const _TallGrassStudioPanel({this.view});

  final TallGrassAuthoringView? view;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      key: const ValueKey('surfaceStudio.tallGrass.panel'),
      decoration:
          BoxDecoration(color: EditorChrome.scaffoldBackground(context)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StudioCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        EditorChrome.elevatedPanelBackground(context),
                        _surfaceStudioAccent,
                        0.24,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const MacosIcon(
                      CupertinoIcons.leaf_arrow_circlepath,
                      color: _surfaceStudioAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hautes herbes',
                          style: TextStyle(
                            color: label,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Terrain spécial traversable avec rencontres, overlay joueur et bruissement local.',
                          style: TextStyle(
                            color: subtle,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  const _TallGrassCapabilityCard(
                    title: 'Visuel',
                    value: 'Preset terrain + overlay',
                    icon: CupertinoIcons.square_stack_3d_down_right,
                  ),
                  const _TallGrassCapabilityCard(
                    title: 'Comportement',
                    value: 'Rencontres en marchant',
                    icon: CupertinoIcons.arrow_right_circle,
                  ),
                  const _TallGrassCapabilityCard(
                    title: 'Animation locale',
                    value: 'Bruissement au pas',
                    icon: CupertinoIcons.waveform_path_ecg,
                  ),
                  const _TallGrassCapabilityCard(
                    title: 'Overlay joueur',
                    value: 'Masque bas du sprite',
                    icon: CupertinoIcons.person_crop_square,
                  ),
                ];
                if (constraints.maxWidth >= 980) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final card in cards) ...[
                        Expanded(child: card),
                        if (card != cards.last) const SizedBox(width: 12),
                      ],
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _TallGrassProjectSignalsCard(view: view),
          ],
        ),
      ),
    );
  }
}

class _TallGrassCapabilityCard extends StatelessWidget {
  const _TallGrassCapabilityCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MacosIcon(icon, size: 18, color: _surfaceStudioAccent),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TallGrassProjectSignalsCard extends StatelessWidget {
  const _TallGrassProjectSignalsCard({required this.view});

  final TallGrassAuthoringView? view;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final grassTerrainCount = view?.grassTerrainPresets.length ?? 0;
    final tallGrassPathCount = view?.tallGrassPathPresets.length ?? 0;
    final walkTableCount = view?.walkEncounterTables.length ?? 0;
    final walkZoneCount = view?.walkEncounterZones.length ?? 0;
    final readinessItems =
        view?.readinessItems ?? _emptyTallGrassReadinessItems;

    return _StudioCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Signaux projet',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lecture des presets et rencontres existants, sans nouveau modèle Surface.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          _TallGrassSignalRow(
            label: 'Terrain herbe',
            value:
                _tallGrassCountLabel(grassTerrainCount, 'terrain', 'terrains'),
          ),
          const SizedBox(height: 8),
          _TallGrassSignalRow(
            label: 'Chemins hautes herbes',
            value:
                _tallGrassCountLabel(tallGrassPathCount, 'chemin', 'chemins'),
          ),
          const SizedBox(height: 8),
          _TallGrassSignalRow(
            label: 'Tables rencontres walk',
            value: _tallGrassCountLabel(walkTableCount, 'table', 'tables'),
          ),
          const SizedBox(height: 8),
          _TallGrassSignalRow(
            label: 'Zones rencontres walk',
            value: _tallGrassCountLabel(walkZoneCount, 'zone', 'zones'),
          ),
          const SizedBox(height: 14),
          Text(
            'Préparation',
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in readinessItems) ...[
            _TallGrassSignalRow(
              label: _tallGrassReadinessLabel(item.id),
              value: _tallGrassReadinessStatus(item),
            ),
            if (item != readinessItems.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TallGrassSignalRow extends StatelessWidget {
  const _TallGrassSignalRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final primary = EditorChrome.primaryLabel(context);
    final secondary = EditorChrome.subtleLabel(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: secondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _tallGrassCountLabel(int count, String singular, String plural) {
  return '$count ${count <= 1 ? singular : plural}';
}

const _emptyTallGrassReadinessItems = [
  TallGrassAuthoringReadinessItem(
    id: TallGrassAuthoringReadinessItem.visualCandidateId,
    isSatisfied: false,
  ),
  TallGrassAuthoringReadinessItem(
    id: TallGrassAuthoringReadinessItem.walkEncounterTableId,
    isSatisfied: false,
  ),
  TallGrassAuthoringReadinessItem(
    id: TallGrassAuthoringReadinessItem.mappedWalkEncounterZoneId,
    isSatisfied: false,
  ),
];

String _tallGrassReadinessLabel(String id) {
  return switch (id) {
    TallGrassAuthoringReadinessItem.visualCandidateId => 'Visuel hautes herbes',
    TallGrassAuthoringReadinessItem.walkEncounterTableId =>
      'Table rencontres walk',
    TallGrassAuthoringReadinessItem.mappedWalkEncounterZoneId =>
      'Zones walk posées',
    _ => id,
  };
}

String _tallGrassReadinessStatus(TallGrassAuthoringReadinessItem item) {
  if (!item.isSatisfied) {
    return item.id == TallGrassAuthoringReadinessItem.mappedWalkEncounterZoneId
        ? 'À poser'
        : 'À créer';
  }
  return item.id == TallGrassAuthoringReadinessItem.walkEncounterTableId
      ? 'Prête'
      : 'Prêt';
}

class _AdvancedDetailsSection extends StatelessWidget {
  const _AdvancedDetailsSection({
    required this.inspection,
    required this.browser,
    required this.tsxAnimations,
    required this.diagnostics,
    required this.futureActions,
    required this.placeholder,
  });

  final Widget inspection;
  final Widget browser;
  final Widget tsxAnimations;
  final Widget diagnostics;
  final Widget futureActions;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      key: const ValueKey('surface_studio_advanced_details'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Détails avancés',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catalogue, inspection et diagnostics restent disponibles sans remplacer le workflow principal.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 960) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: inspection),
                    const SizedBox(width: 12),
                    Expanded(child: browser),
                    const SizedBox(width: 12),
                    Expanded(child: diagnostics),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  inspection,
                  const SizedBox(height: 12),
                  browser,
                  const SizedBox(height: 12),
                  diagnostics,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          tsxAnimations,
          const SizedBox(height: 12),
          futureActions,
          const SizedBox(height: 10),
          placeholder,
        ],
      ),
    );
  }
}

/// Carte interne : même relief que les tuiles inspecteur / sections.
class _StudioCard extends StatelessWidget {
  const _StudioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  SurfaceStudioPanel.placeholderSoonText,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          MacosIcon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: subtle,
          ),
        ],
      ),
    );
  }
}

/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
class SurfaceStudioPanelFromManifest extends StatefulWidget {
  const SurfaceStudioPanelFromManifest({
    super.key,
    required this.manifest,
    this.onProjectManifestChanged,
    this.onRequestProjectSave,
    this.projectRootPath,
  });

  final ProjectManifest manifest;
  final ValueChanged<ProjectManifest>? onProjectManifestChanged;
  final Future<bool> Function()? onRequestProjectSave;

  /// Dossier projet ouvert (même source que l’éditeur) pour résoudre les fichiers image.
  final String? projectRootPath;

  @override
  State<SurfaceStudioPanelFromManifest> createState() =>
      _SurfaceStudioPanelFromManifestState();
}

class _SurfaceStudioPanelFromManifestState
    extends State<SurfaceStudioPanelFromManifest> {
  late ProjectManifest _manifest;

  @override
  void initState() {
    super.initState();
    _manifest = widget.manifest;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanelFromManifest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manifest != oldWidget.manifest) {
      setState(() {
        _manifest = widget.manifest;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceStudioPanel(
      readModel: buildSurfaceStudioReadModel(_manifest),
      projectSettings: _manifest.settings,
      projectTilesets: _manifest.tilesets,
      projectRootPath: widget.projectRootPath,
      tallGrassAuthoringView: createTallGrassAuthoringView(manifest: _manifest),
      onSurfaceCatalogSaveRequested: (c) {
        final n = replaceProjectManifestSurfaceCatalog(_manifest, c);
        setState(() {
          _manifest = n;
        });
        widget.onProjectManifestChanged?.call(n);
      },
      onRequestProjectSave: widget.onRequestProjectSave,
    );
  }
}
