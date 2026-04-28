import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_grid_overlay.dart';
import 'surface_studio_vertical_atlas_preset_generator.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

/// Section « création preset » après le plan d’animations (Lot 79) — catalogue travail uniquement.
class SurfaceStudioVerticalAtlasPresetCreationSection extends StatefulWidget {
  const SurfaceStudioVerticalAtlasPresetCreationSection({
    super.key,
    required this.label,
    required this.subtle,
    required this.catalog,
    required this.atlasIdDraft,
    required this.atlasDisplayName,
    this.atlasCategoryDraft,
    required this.mappingDraft,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    this.onWorkCatalogChanged,
    this.onWorkCatalogPresetCreated,
  });

  static const ValueKey<String> sectionKey =
      ValueKey<String>('surface_studio_vertical_atlas_preset_creation');

  final Color label;
  final Color subtle;
  final ProjectSurfaceCatalog catalog;
  final String atlasIdDraft;
  final String atlasDisplayName;
  final String? atlasCategoryDraft;
  final SurfaceStudioColumnRoleMappingDraft mappingDraft;
  final int? tileWidth;
  final int? tileHeight;
  final int? columns;
  final int? rows;
  final ValueChanged<ProjectSurfaceCatalog>? onWorkCatalogChanged;
  final ValueChanged<String>? onWorkCatalogPresetCreated;

  @override
  State<SurfaceStudioVerticalAtlasPresetCreationSection> createState() =>
      _SurfaceStudioVerticalAtlasPresetCreationSectionState();
}

class _SurfaceStudioVerticalAtlasPresetCreationSectionState
    extends State<SurfaceStudioVerticalAtlasPresetCreationSection> {
  String? _presetFeedback;

  @override
  void didUpdateWidget(covariant SurfaceStudioVerticalAtlasPresetCreationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mappingDraft != oldWidget.mappingDraft ||
        widget.atlasIdDraft != oldWidget.atlasIdDraft ||
        widget.catalog != oldWidget.catalog ||
        widget.rows != oldWidget.rows ||
        widget.columns != oldWidget.columns ||
        widget.tileWidth != oldWidget.tileWidth ||
        widget.tileHeight != oldWidget.tileHeight) {
      _presetFeedback = null;
    }
  }

  String _statusLabel(SurfaceStudioVerticalAtlasPresetPlanStatus s) {
    return switch (s) {
      SurfaceStudioVerticalAtlasPresetPlanStatus.ready => 'prêt',
      SurfaceStudioVerticalAtlasPresetPlanStatus.incomplete => 'incomplet',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedEmptyAtlasId ||
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedInvalidGrid ||
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedNoMapping ||
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations ||
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId =>
        'bloqué',
    };
  }

  void _tryAppendPreset(SurfaceStudioVerticalAtlasPresetAppendPlan plan) {
    final cb = widget.onWorkCatalogChanged;
    if (cb == null || !plan.canCreate) {
      return;
    }
    final gridOk = surfaceStudioAtlasGridOverlayDraftValid(
      widget.tileWidth,
      widget.tileHeight,
      widget.columns,
      widget.rows,
    );
    try {
      final preset = surfaceStudioBuildVerticalAtlasPreset(
        catalog: widget.catalog,
        atlasIdRaw: widget.atlasIdDraft,
        atlasDisplayName: widget.atlasDisplayName,
        atlasCategoryDraft: widget.atlasCategoryDraft,
        mappingDraft: widget.mappingDraft,
        gridValid: gridOk,
      );
      final next = surfaceStudioAppendPresetToWorkCatalog(
        catalog: widget.catalog,
        preset: preset,
      );
      cb(next);
      widget.onWorkCatalogPresetCreated?.call(preset.id);
      setState(() {
        _presetFeedback = 'Preset Surface créé dans le catalogue de travail. '
            'Préparez la sauvegarde du catalogue Surface comme d’habitude, puis sauvegardez le projet.';
      });
    } on ValidationException {
      setState(() {
        _presetFeedback = 'Impossible d’ajouter le preset (validation du catalogue).';
      });
    } on StateError {
      setState(() {
        _presetFeedback = 'Impossible de créer le preset dans l’état actuel.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridOk = surfaceStudioAtlasGridOverlayDraftValid(
      widget.tileWidth,
      widget.tileHeight,
      widget.columns,
      widget.rows,
    );
    final assignedCount = widget.mappingDraft.assignments
        .where((a) => a.role != null)
        .length;

    final plan = surfaceStudioPlanVerticalAtlasPresetAppend(
      catalog: widget.catalog,
      atlasIdRaw: widget.atlasIdDraft,
      atlasDisplayName: widget.atlasDisplayName,
      atlasCategoryDraft: widget.atlasCategoryDraft,
      mappingDraft: widget.mappingDraft,
      gridValid: gridOk,
    );

    return Container(
      key: SurfaceStudioVerticalAtlasPresetCreationSection.sectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Création du preset Surface',
            style: TextStyle(
              color: widget.label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aucune animation n’est créée à cette étape.',
            style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 8),
          if (!gridOk)
            Text(
              'Corrigez la grille avant de créer le preset.',
              style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
            )
          else if (assignedCount == 0)
            Text(
              'Assignez des colonnes à des rôles pour préparer le preset.',
              style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
            )
          else ...[
            Text(
              plan.proposedPresetId.isEmpty
                  ? 'Preset proposé : —'
                  : 'Preset proposé : ${plan.proposedPresetId}',
              style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
            ),
            Text(
              'Nom : ${plan.proposedPresetName}',
              style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
            ),
            Text(
              'Rôles couverts : ${plan.rolesCoveredCount}',
              style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
            ),
            Text(
              'Rôles non couverts : ${plan.rolesNotCoveredCount}',
              style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
            ),
            Text(
              'Animations manquantes : ${plan.missingAnimationCount}',
              style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
            ),
            Text(
              'Statut : ${_statusLabel(plan.status)}',
              style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
            ),
            if (plan.status ==
                    SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations)
              Text(
                'Générez les animations avant de créer le preset.',
                style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
              ),
            if (plan.status ==
                SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId)
              Text(
                'Un preset existe déjà avec cet id.',
                style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
              ),
            if (plan.partialPresetUserMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  plan.partialPresetUserMessage!,
                  style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.35),
                ),
              ),
            if (plan.canCreate) ...[
              const SizedBox(height: 6),
              Text(
                plan.status == SurfaceStudioVerticalAtlasPresetPlanStatus.incomplete
                    ? 'Preset prêt à créer (incomplet).'
                    : 'Preset prêt à créer.',
                style: TextStyle(color: widget.label, fontSize: 11, height: 1.35),
              ),
            ],
            const SizedBox(height: 10),
            FilledButton(
              key: const ValueKey('surface_studio_preset_append_vertical_atlas'),
              onPressed: widget.onWorkCatalogChanged != null && plan.canCreate
                  ? () => _tryAppendPreset(plan)
                  : null,
              child: const Text('Créer le preset Surface dans le catalogue de travail'),
            ),
          ],
          if (_presetFeedback != null) ...[
            const SizedBox(height: 8),
            Text(
              _presetFeedback!,
              style: TextStyle(color: widget.label, fontSize: 11, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
