// Inspecteur Surface Studio (Lot 59) — **lecture seule**.
//
// Consomme [SurfaceStudioReadModel] + [SurfaceStudioSelection] : n’en déduit pas
// de recalcul métier, ne mutera ni catalogue ni manifest, pas d’I/O, pas d’authoring
// ici. Prépare les lots d’édition en affichant la même sémantique visuelle que les
// fiches détail, dans une zone d’inspection unifiée.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_animation_detail_view.dart';
import 'surface_studio_atlas_detail_view.dart';
import 'surface_studio_preset_detail_view.dart';
import 'surface_studio_selection.dart';

/// Textes d’en-tête (aucun nom de type produit en chaîne).
class SurfaceStudioSelectionInspectorLabels {
  const SurfaceStudioSelectionInspectorLabels._();

  static const String title = 'Inspecteur Surface';
  static const String readOnly = 'Lecture seule';
  static const String noneTitle = 'Aucune sélection à inspecter';
  static const String noneHint =
      'Sélectionnez un atlas, une animation ou un preset pour afficher ses détails.';

  static const String missingTitle = 'Sélection introuvable';
  static const String missingBody =
      'L’élément sélectionné n’existe plus dans le catalogue.';
}

const Color _kInspectorAccent = Color(0xFF2DD4BF);

const ValueKey<String> kSurfaceStudioSelectionInspectorKey =
    ValueKey<String>('SurfaceStudioSelectionInspector');

/// Bloc d’inspection : résout la ligne de catalogue à partir de [selection] et
/// affiche les champs dérivés tels qu’exposés par le read model.
class SurfaceStudioSelectionInspector extends StatefulWidget {
  const SurfaceStudioSelectionInspector({
    super.key,
    required this.readModel,
    required this.selection,
    this.onRequestEditSelectedAtlas,
    this.onConfirmDeleteSelectedAtlas,
  });

  final SurfaceStudioReadModel readModel;

  final SurfaceStudioSelection selection;
  final VoidCallback? onRequestEditSelectedAtlas;
  final VoidCallback? onConfirmDeleteSelectedAtlas;

  @override
  State<SurfaceStudioSelectionInspector> createState() =>
      _SurfaceStudioSelectionInspectorState();
}

class _SurfaceStudioSelectionInspectorState
    extends State<SurfaceStudioSelectionInspector> {
  bool _deleteAtlasPrepared = false;

  @override
  void didUpdateWidget(covariant SurfaceStudioSelectionInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection) {
      _deleteAtlasPrepared = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = _kInspectorAccent;
    return Container(
      key: kSurfaceStudioSelectionInspectorKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.selection.isNone
              ? EditorChrome.editorIslandRim(context)
              : Color.lerp(
                  EditorChrome.editorIslandRim(context),
                  accent,
                  0.4,
                )!,
          width: widget.selection.isNone ? 1 : 1.15,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  SurfaceStudioSelectionInspectorLabels.title,
                  style: TextStyle(
                    color: label,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    EditorChrome.islandFillElevated(context),
                    accent,
                    0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.45),
                    width: 1,
                  ),
                ),
                child: Text(
                  SurfaceStudioSelectionInspectorLabels.readOnly,
                  style: TextStyle(
                    color: label,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.selection.isNone) ...[
            Text(
              SurfaceStudioSelectionInspectorLabels.noneTitle,
              style: TextStyle(
                color: subtle,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              SurfaceStudioSelectionInspectorLabels.noneHint,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ] else
            _InspectorBody(
              readModel: widget.readModel,
              selection: widget.selection,
              label: label,
              subtle: subtle,
              accent: accent,
              onRequestEditSelectedAtlas: widget.onRequestEditSelectedAtlas,
              onConfirmDeleteSelectedAtlas: widget.onConfirmDeleteSelectedAtlas,
              deleteAtlasPrepared: _deleteAtlasPrepared,
              onDeleteAtlasPreparedChanged: (v) {
                setState(() => _deleteAtlasPrepared = v);
              },
            ),
        ],
      ),
    );
  }
}

class _InspectorBody extends StatelessWidget {
  const _InspectorBody({
    required this.readModel,
    required this.selection,
    required this.label,
    required this.subtle,
    required this.accent,
    this.onRequestEditSelectedAtlas,
    this.onConfirmDeleteSelectedAtlas,
    this.deleteAtlasPrepared = false,
    this.onDeleteAtlasPreparedChanged,
  });

  final SurfaceStudioReadModel readModel;
  final SurfaceStudioSelection selection;
  final Color label;
  final Color subtle;
  final Color accent;
  final VoidCallback? onRequestEditSelectedAtlas;
  final VoidCallback? onConfirmDeleteSelectedAtlas;
  final bool deleteAtlasPrepared;
  final ValueChanged<bool>? onDeleteAtlasPreparedChanged;

  @override
  Widget build(BuildContext context) {
    if (selection.isAtlas) {
      final id = selection.id!;
      final row = _atlasById(readModel, id);
      if (row == null) {
        return _MissingBlock(id: id, label: label, subtle: subtle);
      }
      return _AtlasInspect(
        row: row,
        label: label,
        subtle: subtle,
        accent: accent,
        onRequestEditSelectedAtlas: onRequestEditSelectedAtlas,
        onConfirmDeleteSelectedAtlas: onConfirmDeleteSelectedAtlas,
        deletePrepared: deleteAtlasPrepared,
        onDeletePreparedChanged: onDeleteAtlasPreparedChanged,
      );
    }
    if (selection.isAnimation) {
      final id = selection.id!;
      final row = _animationById(readModel, id);
      if (row == null) {
        return _MissingBlock(id: id, label: label, subtle: subtle);
      }
      return _AnimationInspect(
        row: row,
        label: label,
        subtle: subtle,
        accent: accent,
      );
    }
    if (selection.isPreset) {
      final id = selection.id!;
      final row = _presetById(readModel, id);
      if (row == null) {
        return _MissingBlock(id: id, label: label, subtle: subtle);
      }
      return _PresetInspect(
        row: row,
        label: label,
        subtle: subtle,
        accent: accent,
      );
    }
    return const SizedBox.shrink();
  }
}

class _MissingBlock extends StatelessWidget {
  const _MissingBlock({
    required this.id,
    required this.label,
    required this.subtle,
  });

  final String id;
  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SurfaceStudioSelectionInspectorLabels.missingTitle,
          style: TextStyle(
            color: label,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          SurfaceStudioSelectionInspectorLabels.missingBody,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          id,
          style: TextStyle(
            color: label,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _K extends StatelessWidget {
  const _K({required this.k, required this.v, required this.valueColor});

  final String k;
  final String v;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '$k : $v',
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

SurfaceStudioAtlasReadModel? _atlasById(
  SurfaceStudioReadModel m,
  String id,
) {
  for (final a in m.atlases) {
    if (a.id == id) {
      return a;
    }
  }
  return null;
}

SurfaceStudioAnimationReadModel? _animationById(
  SurfaceStudioReadModel m,
  String id,
) {
  for (final a in m.animations) {
    if (a.id == id) {
      return a;
    }
  }
  return null;
}

SurfaceStudioPresetReadModel? _presetById(
  SurfaceStudioReadModel m,
  String id,
) {
  for (final p in m.presets) {
    if (p.id == id) {
      return p;
    }
  }
  return null;
}

class _AtlasInspect extends StatelessWidget {
  const _AtlasInspect({
    required this.row,
    required this.label,
    required this.subtle,
    required this.accent,
    this.onRequestEditSelectedAtlas,
    this.onConfirmDeleteSelectedAtlas,
    this.deletePrepared = false,
    this.onDeletePreparedChanged,
  });

  final SurfaceStudioAtlasReadModel row;
  final Color label;
  final Color subtle;
  final Color accent;
  final VoidCallback? onRequestEditSelectedAtlas;
  final VoidCallback? onConfirmDeleteSelectedAtlas;
  final bool deletePrepared;
  final ValueChanged<bool>? onDeletePreparedChanged;

  @override
  Widget build(BuildContext context) {
    final nAnim = row.usedByAnimationIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SurfaceStudioAtlasDetailViewLabels.badgeSelected,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          row.name,
          style: TextStyle(
            color: label,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelIdentifiant,
          v: row.id,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelTileset,
          v: row.tilesetId,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelTile,
          v: '${row.tileWidth}×${row.tileHeight}',
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelGrille,
          v: '${row.columns}×${row.rows}',
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelTuiles,
          v: SurfaceStudioAtlasDetailViewLabels.tileCountLigne(row.tileCount),
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelLayout,
          v: SurfaceStudioAtlasDetailViewLabels.layoutHumain(row.layout),
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelCategorie,
          v: row.categoryId == null || row.categoryId!.isEmpty
              ? SurfaceStudioAtlasDetailViewLabels.categorieAucune
              : row.categoryId!,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelOrdre,
          v: row.sortOrder.toString(),
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelUtilisation,
          v: SurfaceStudioAtlasDetailViewLabels.utilisationLigne(nAnim),
          valueColor: label,
        ),
        if (nAnim > 0) ...[
          const SizedBox(height: 4),
          Text(
            SurfaceStudioAtlasDetailViewLabels.labelAnimationsUtilisatrices,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          ...row.usedByAnimationIds.map(
            (id) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                id,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        if (onRequestEditSelectedAtlas != null) ...[
          const SizedBox(height: 10),
          CupertinoButton(
            key: const ValueKey('surface_studio_inspector_edit_atlas'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onPressed: onRequestEditSelectedAtlas,
            child: const Text('Modifier cet atlas'),
          ),
        ],
        if (onConfirmDeleteSelectedAtlas != null) ...[
          const SizedBox(height: 12),
          Text(
            'Suppression',
            style: TextStyle(
              color: subtle,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          if (nAnim > 0)
            Text(
              nAnim == 1
                  ? 'Suppression impossible : cet atlas est utilisé par 1 animation.'
                  : 'Suppression impossible : cet atlas est utilisé par $nAnim animation(s).',
              key: const ValueKey('surface_studio_inspector_delete_blocked'),
              style: const TextStyle(
                color: Color(0xFFC2410C),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            Text(
              'Atlas inutilisé — suppression possible.',
              key: const ValueKey('surface_studio_inspector_delete_allowed'),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            if (!deletePrepared)
              CupertinoButton(
                key: const ValueKey('surface_studio_inspector_prepare_delete'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: () => onDeletePreparedChanged?.call(true),
                child: const Text('Préparer la suppression de l’atlas'),
              )
            else
              CupertinoButton(
                key: const ValueKey('surface_studio_inspector_confirm_delete'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: onConfirmDeleteSelectedAtlas,
                child: const Text(
                  'Confirmer la suppression de l’atlas',
                  style: TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }
}

class _AnimationInspect extends StatelessWidget {
  const _AnimationInspect({
    required this.row,
    required this.label,
    required this.subtle,
    required this.accent,
  });

  final SurfaceStudioAnimationReadModel row;
  final Color label;
  final Color subtle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final refIds = row.referencedAtlasIds;
    final nAtlas = refIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SurfaceStudioAnimationDetailViewLabels.badgeSelected,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          row.name,
          style: TextStyle(
            color: label,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelIdentifiant,
          v: row.id,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelFrames,
          v: SurfaceStudioAnimationDetailViewLabels.framesLigne(
            row.frameCount,
          ),
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelDureeTotale,
          v: '${row.totalDurationMs} ms',
          valueColor: label,
        ),
        const SizedBox(height: 4),
        Text(
          SurfaceStudioAnimationDetailViewLabels.labelAtlasRef,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            SurfaceStudioAnimationDetailViewLabels.atlasRefSummary(nAtlas),
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (nAtlas > 0)
          ...refIds.map(
            (id) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                id,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelSync,
          v: row.syncGroupId == null || row.syncGroupId!.isEmpty
              ? SurfaceStudioAnimationDetailViewLabels.syncAucun
              : row.syncGroupId!,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelCategorie,
          v: row.categoryId == null || row.categoryId!.isEmpty
              ? SurfaceStudioAnimationDetailViewLabels.categorieAucune
              : row.categoryId!,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelOrdre,
          v: row.sortOrder.toString(),
          valueColor: label,
        ),
      ],
    );
  }
}

class _PresetInspect extends StatelessWidget {
  const _PresetInspect({
    required this.row,
    required this.label,
    required this.subtle,
    required this.accent,
  });

  final SurfaceStudioPresetReadModel row;
  final Color label;
  final Color subtle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final animIds = row.referencedAnimationIds;
    final nAnim = animIds.length;
    final roleLabels = row.roles.map(surfaceStudioSurfaceVariantRoleLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SurfaceStudioPresetDetailViewLabels.badgeSelected,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          row.name,
          style: TextStyle(
            color: label,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        _K(
          k: SurfaceStudioPresetDetailViewLabels.labelIdentifiant,
          v: row.id,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioPresetDetailViewLabels.labelVariantes,
          v: SurfaceStudioPresetDetailViewLabels.variantesLigne(
            row.variantCount,
          ),
          valueColor: label,
        ),
        const SizedBox(height: 4),
        Text(
          SurfaceStudioPresetDetailViewLabels.labelRoles,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        ...roleLabels.map(
          (r) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              r,
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          SurfaceStudioPresetDetailViewLabels.labelAnimationsLiees,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            SurfaceStudioPresetDetailViewLabels.animationsLieesSummary(
              nAnim,
            ),
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (nAnim > 0)
          ...animIds.map(
            (id) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                id,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          SurfaceStudioPresetDetailViewLabels.labelCouverture,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            row.coversStandardRoles
                ? SurfaceStudioPresetDetailViewLabels.couverturePleine
                : SurfaceStudioPresetDetailViewLabels.couverturePartielle,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _K(
          k: SurfaceStudioPresetDetailViewLabels.labelCategorie,
          v: row.categoryId == null || row.categoryId!.isEmpty
              ? SurfaceStudioPresetDetailViewLabels.categorieAucune
              : row.categoryId!,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioPresetDetailViewLabels.labelOrdre,
          v: row.sortOrder.toString(),
          valueColor: label,
        ),
      ],
    );
  }
}
