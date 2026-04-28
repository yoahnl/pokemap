// Surface Studio — shell UI lecture seule (Lot 52).
//
// Consomme un [SurfaceStudioReadModel] déjà construit côté [map_core] : pas de
// re-diagnostic, pas de mutation manifest, pas d’I/O. Les actions futures sont
// désactivées ; seul le placeholder « Actions auteur » reste pour un lot ultérieur.
//
// Style : aligné sur [EditorChrome] / îlots de l’éditeur (pas de Card Material
// clair isolé) — cohérent avec World Explorer et le shell macOS.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_editing.dart';
import 'surface_studio_atlas_authoring_prep.dart';
import 'surface_studio_catalog_browser.dart';
import 'surface_studio_diagnostics_view.dart';
import 'surface_studio_selection.dart';
import 'surface_studio_selection_inspector.dart';
import 'surface_studio_selection_summary.dart';

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

/// Panneau présentationnel **lecture seule** pour Surface Studio.
class SurfaceStudioPanel extends StatefulWidget {
  const SurfaceStudioPanel({
    super.key,
    required this.readModel,
    this.onSurfaceCatalogSaveRequested,
    this.onRequestProjectSave,
    this.projectTilesets,
    this.projectRootPath,
  });

  final SurfaceStudioReadModel readModel;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;
  final Future<bool> Function()? onRequestProjectSave;
  final List<ProjectTilesetEntry>? projectTilesets;

  /// Racine projet sur disque pour résoudre les chemins d’images tileset (aperçu Lot 72).
  final String? projectRootPath;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String partialAuthoringBadgeText = 'Édition partielle';
  static const String workflowStepsHintText =
      'Étapes : état → nouvel atlas → inspection → contenu → signaux';
  static const String productDescriptionText =
      'Surfaces animées : eau, lave, glace, hautes herbes — ici, sans code.';
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
  static const String projectDiskSaveRequestedNote = 'Sauvegarde projet demandée.';
  static const String projectDiskSaveFailureNote =
      'Échec de sauvegarde projet — voir la barre d’état.';

  @override
  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
}

class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
  late SurfaceStudioReadModel _workReadModel;
  String? _saveFlowPrepNote;
  String? _projectSaveDiskNote;
  int _atlasEditSignal = 0;

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
        _saveFlowPrepNote = wasAbsorbed
            ? SurfaceStudioPanel.manifestMemoryUpdatedNote
            : null;
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

  @override
  Widget build(BuildContext context) {
    final s = _workReadModel.summary;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final isPartial =
        widget.onSurfaceCatalogSaveRequested != null;
    final canMutateCatalog = widget.onSurfaceCatalogSaveRequested != null;
    final authoring = SurfaceStudioAtlasAuthoringPrep(
      readModel: _workReadModel,
      selection: _selection,
      requestEditSignal: _atlasEditSignal,
      projectTilesets: widget.projectTilesets,
      projectRootPath: widget.projectRootPath,
      onSurfaceCatalogChanged: (cat) {
        setState(() {
          _saveFlowPrepNote = null;
          _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
          _selection = _selectionAfterCatalogChanged(cat);
        });
      },
      onWorkCatalogAnimationsCreated: (createdIds) {
        if (createdIds.isEmpty) {
          return;
        }
        setState(() {
          _selection = SurfaceStudioSelection.animation(createdIds.first);
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
    );
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

    return SingleChildScrollView(
      key: const ValueKey('surface_studio_root_scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompactStudioHeader(
            key: const ValueKey('surface_studio_workflow_header'),
            label: label,
            subtle: subtle,
            summary: s,
            readOnly: !isPartial,
          ),
          const SizedBox(height: 8),
          Text(
            SurfaceStudioPanel.workflowStepsHintText,
            key: const ValueKey('surface_studio_workflow_steps'),
            style: TextStyle(
              color: subtle.withValues(alpha: 0.88),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          if (_hasWorkCatalogChanges) ...[
            const SizedBox(height: 10),
            _CatalogStateStrip(
              key: const ValueKey('surface_studio_catalog_status_strip'),
              subtle: subtle,
              workCatalogNote: SurfaceStudioPanel.workCatalogDirtyStateText,
              onSurfaceSavePrep: widget.onSurfaceCatalogSaveRequested != null
                  ? _onSurfaceCatalogSavePrep
                  : null,
              onResetWorkCatalog: () {
                setState(() {
                  _workReadModel = widget.readModel;
                  _selection =
                      _selectionValidInReadModel(_workReadModel, _selection);
                  _saveFlowPrepNote = null;
                });
              },
            ),
            if (widget.onSurfaceCatalogSaveRequested == null)
              Text(
                key: const ValueKey('surface_studio_save_prep_not_connected'),
                SurfaceStudioPanel.savePrepNotConnectedNote,
                style: TextStyle(
                  color: subtle.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (widget.onRequestProjectSave != null) ...[
              const SizedBox(height: 6),
              CupertinoButton(
                key: const ValueKey(
                    'surface_studio_project_save_via_official_flow'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: _onRequestProjectSave,
                child: const Text(
                  SurfaceStudioPanel.projectSaveViaExistingFlowButtonLabel,
                ),
              ),
              if (_projectSaveDiskNote != null)
                Text(
                  _projectSaveDiskNote!,
                  key: const ValueKey('surface_studio_project_save_disk_note'),
                  style: TextStyle(
                    color: _surfaceStudioAccent.withValues(alpha: 0.88),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ] else if (widget.onRequestProjectSave != null) ...[
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey(
                  'surface_studio_project_save_via_official_flow'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onPressed: _onRequestProjectSave,
              child: const Text(
                SurfaceStudioPanel.projectSaveViaExistingFlowButtonLabel,
              ),
            ),
            if (_projectSaveDiskNote != null) ...[
              const SizedBox(height: 4),
              Text(
                _projectSaveDiskNote!,
                key: const ValueKey('surface_studio_project_save_disk_note'),
                style: TextStyle(
                  color: _surfaceStudioAccent.withValues(alpha: 0.88),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
          if (_saveFlowPrepNote != null) ...[
            const SizedBox(height: 6),
            Text(
              _saveFlowPrepNote!,
              key: const ValueKey('surface_studio_save_prep_transmitted'),
              style: TextStyle(
                color: _surfaceStudioAccent.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 820) {
                return Row(
                  key: const ValueKey('surface_studio_main_two_column'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 58,
                      child: authoring,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 42,
                      child: inspection,
                    ),
                  ],
                );
              }
              return Column(
                key: const ValueKey('surface_studio_main_stacked'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  authoring,
                  const SizedBox(height: 12),
                  inspection,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SurfaceStudioCatalogBrowser(
            readModel: _workReadModel,
            selection: _selection,
            onSelectionChanged: (v) {
              setState(() => _selection = v);
            },
          ),
          const SizedBox(height: 10),
          SurfaceStudioDiagnosticsView(readModel: _workReadModel),
          const SizedBox(height: 12),
          const _FutureActions(
            onImportVertical: null,
          ),
          const SizedBox(height: 10),
          const _SectionPlaceholder(
            title: SurfaceStudioPanel.placeholderActionsTitle,
          ),
        ],
      ),
    );
  }
}

class _CompactStudioHeader extends StatelessWidget {
  const _CompactStudioHeader({
    super.key,
    required this.label,
    required this.subtle,
    required this.summary,
    required this.readOnly,
  });

  final Color label;
  final Color subtle;
  final SurfaceStudioCatalogSummaryReadModel summary;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StudioHeaderIcon(accent: _surfaceStudioAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      SurfaceStudioPanel.titleText,
                      style: TextStyle(
                        color: label,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (readOnly)
                    const _ReadOnlyBadge(
                      label: SurfaceStudioPanel.readOnlyBadgeText,
                    )
                  else
                    const _ReadOnlyBadge(
                      label: SurfaceStudioPanel.partialAuthoringBadgeText,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                SurfaceStudioPanel.productDescriptionText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtle,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final counters = _CounterRow(
      atlas: summary.atlasCount,
      animations: summary.animationCount,
      presets: summary.presetCount,
      compact: true,
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleRow,
              const SizedBox(height: 8),
              counters,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleRow),
            const SizedBox(width: 6),
            counters,
          ],
        );
      },
    );
  }
}

class _CatalogStateStrip extends StatelessWidget {
  const _CatalogStateStrip({
    super.key,
    required this.subtle,
    required this.workCatalogNote,
    required this.onResetWorkCatalog,
    this.onSurfaceSavePrep,
  });

  final Color subtle;
  final String workCatalogNote;
  final VoidCallback onResetWorkCatalog;
  final void Function()? onSurfaceSavePrep;

  @override
  Widget build(BuildContext context) {
    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            workCatalogNote,
            key: const ValueKey('surface_studio_work_catalog_dirty_state'),
            style: TextStyle(
              color: _surfaceStudioAccent.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            SurfaceStudioPanel.savePrepNoDiskNote,
            style: TextStyle(
              color: subtle.withValues(alpha: 0.88),
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (onSurfaceSavePrep != null)
                CupertinoButton(
                  key: const ValueKey('surface_studio_save_prep_catalog'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onPressed: onSurfaceSavePrep,
                  child: const Text(SurfaceStudioPanel.savePrepActionLabel),
                ),
              CupertinoButton(
                key: const ValueKey('surface_studio_reset_work_catalog'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: onResetWorkCatalog,
                child: const Text('Réinitialiser le catalogue de travail'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudioHeaderIcon extends StatelessWidget {
  const _StudioHeaderIcon({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    const hi = Color(0xFFFFFFFF);
    const lo = Color(0xFF120808);
    final onAccent =
        accent.computeLuminance() > 0.55 ? const Color(0xFF1A0A08) : hi;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(hi, accent, 0.72)!,
            Color.lerp(accent, lo, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.88),
          width: 1.2,
        ),
        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
      ),
      alignment: Alignment.center,
      child: MacosIcon(
        Icons.auto_awesome_motion,
        color: onAccent,
        size: 22,
      ),
    );
  }
}

class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const accent = _surfaceStudioAccent;
    final fill = Color.lerp(
      EditorChrome.islandFillElevated(context),
      accent,
      0.14,
    )!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _surfaceStudioAccent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.atlas,
    required this.animations,
    required this.presets,
    this.compact = false,
  });

  final int atlas;
  final int animations;
  final int presets;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('surface_studio_header_counters'),
      spacing: compact ? 6 : 12,
      runSpacing: compact ? 6 : 10,
      children: [
        _CounterChip(label: 'Atlas', value: atlas, compact: compact),
        _CounterChip(label: 'Animations', value: animations, compact: compact),
        _CounterChip(label: 'Presets', value: presets, compact: compact),
      ],
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final labelColor = EditorChrome.primaryLabel(context);

    return _StudioCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 16,
        vertical: compact ? 7 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: compact ? 3 : 6),
          Text(
            '$value',
            style: TextStyle(
              color: labelColor,
              fontSize: compact ? 16 : 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte interne : même relief que les tuiles inspecteur / sections.
class _StudioCard extends StatelessWidget {
  const _StudioCard({
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

class _FutureActions extends StatelessWidget {
  const _FutureActions({
    required this.onImportVertical,
  });

  final VoidCallback? onImportVertical;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions futures (non disponibles)',
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _GhostAction(
              label: SurfaceStudioPanel.actionImportVerticalAtlasLabel,
              onPressed: onImportVertical,
            ),
          ],
        ),
      ],
    );
  }
}

class _GhostAction extends StatelessWidget {
  const _GhostAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.48,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? EditorChrome.inspectorJoyCyan : subtle,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
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
      projectTilesets: _manifest.tilesets,
      projectRootPath: widget.projectRootPath,
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
