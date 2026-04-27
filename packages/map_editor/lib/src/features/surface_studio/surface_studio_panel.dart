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
  });

  final SurfaceStudioReadModel readModel;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String productDescriptionText =
      'Préparez et contrôlez les surfaces animées du projet : eau, lave, glace, hautes herbes.';
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

  @override
  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
}

class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
  late SurfaceStudioReadModel _workReadModel;
  String? _saveFlowPrepNote;

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

  @override
  Widget build(BuildContext context) {
    final s = _workReadModel.summary;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _StudioHeaderIcon(accent: _surfaceStudioAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  SurfaceStudioPanel.titleText,
                  style: TextStyle(
                    color: label,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.35,
                  ),
                ),
              ),
              const _ReadOnlyBadge(label: SurfaceStudioPanel.readOnlyBadgeText),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            SurfaceStudioPanel.productDescriptionText,
            style: TextStyle(
              color: subtle,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous pouvez ajouter un atlas au catalogue de travail en mémoire. '
            'Aucune sauvegarde projet sur disque, pas d’édition ni suppression d’atlas existant.',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.92),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          if (_hasWorkCatalogChanges) ...[
            const SizedBox(height: 10),
            Text(
              SurfaceStudioPanel.workCatalogDirtyStateText,
              key: const ValueKey('surface_studio_work_catalog_dirty_state'),
              style: TextStyle(
                color: _surfaceStudioAccent.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              SurfaceStudioPanel.savePrepNoDiskNote,
              style: TextStyle(
                color: subtle.withValues(alpha: 0.9),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            if (widget.onSurfaceCatalogSaveRequested != null) ...[
              CupertinoButton(
                key: const ValueKey('surface_studio_save_prep_catalog'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: _onSurfaceCatalogSavePrep,
                child: const Text(SurfaceStudioPanel.savePrepActionLabel),
              ),
            ] else ...[
              Text(
                key: const ValueKey('surface_studio_save_prep_not_connected'),
                SurfaceStudioPanel.savePrepNotConnectedNote,
                style: TextStyle(
                  color: subtle.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 6),
            CupertinoButton(
              key: const ValueKey('surface_studio_reset_work_catalog'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onPressed: () {
                setState(() {
                  _workReadModel = widget.readModel;
                  _selection =
                      _selectionValidInReadModel(_workReadModel, _selection);
                  _saveFlowPrepNote = null;
                });
              },
              child: const Text('Réinitialiser le catalogue de travail'),
            ),
          ],
          if (_saveFlowPrepNote != null) ...[
            const SizedBox(height: 8),
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
          const SizedBox(height: 20),
          _CounterRow(
            atlas: s.atlasCount,
            animations: s.animationCount,
            presets: s.presetCount,
          ),
          const SizedBox(height: 12),
          SurfaceStudioSelectionSummary(selection: _selection),
          const SizedBox(height: 12),
          SurfaceStudioSelectionInspector(
            readModel: _workReadModel,
            selection: _selection,
          ),
          const SizedBox(height: 12),
          SurfaceStudioCatalogBrowser(
            readModel: _workReadModel,
            selection: _selection,
            onSelectionChanged: (v) {
              setState(() => _selection = v);
            },
          ),
          const SizedBox(height: 16),
          SurfaceStudioDiagnosticsView(readModel: _workReadModel),
          const SizedBox(height: 20),
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _workReadModel,
            selection: _selection,
            onSurfaceCatalogChanged: (cat) {
              final newId = cat.atlases.isNotEmpty
                  ? cat.atlases.last.id
                  : '';
              setState(() {
                _saveFlowPrepNote = null;
                _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
                if (newId.isNotEmpty) {
                  _selection = SurfaceStudioSelection.atlas(newId);
                }
              });
            },
          ),
          const SizedBox(height: 20),
          const _FutureActions(
            onImportVertical: null,
          ),
          const SizedBox(height: 20),
          const _SectionPlaceholder(
            title: SurfaceStudioPanel.placeholderActionsTitle,
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
  });

  final int atlas;
  final int animations;
  final int presets;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('surface_studio_header_counters'),
      spacing: 12,
      runSpacing: 10,
      children: [
        _CounterChip(label: 'Atlas', value: atlas),
        _CounterChip(label: 'Animations', value: animations),
        _CounterChip(label: 'Presets', value: presets),
      ],
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final labelColor = EditorChrome.primaryLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              color: labelColor,
              fontSize: 22,
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
  });

  final ProjectManifest manifest;
  final ValueChanged<ProjectManifest>? onProjectManifestChanged;

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
      onSurfaceCatalogSaveRequested: (c) {
        final n = replaceProjectManifestSurfaceCatalog(_manifest, c);
        setState(() {
          _manifest = n;
        });
        widget.onProjectManifestChanged?.call(n);
      },
    );
  }
}
