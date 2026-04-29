import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_grid_overlay.dart';
import 'surface_studio_vertical_atlas_animation_generator.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

/// Rectangle source (atlas) pour une frame — plan local uniquement.
@immutable
class SurfaceStudioVerticalAtlasAnimationGenerationSourceRect {
  const SurfaceStudioVerticalAtlasAnimationGenerationSourceRect({
    required this.frameIndex,
    required this.sourceX,
    required this.sourceY,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  final int frameIndex;
  final int sourceX;
  final int sourceY;
  final int sourceWidth;
  final int sourceHeight;
}

/// Statut d’une ligne du plan (aucune persistance catalogue).
enum SurfaceStudioVerticalAtlasAnimationPlanItemStatus {
  ready,
  invalid,
  duplicate,
}

/// Une animation Surface qui serait créée à partir d’une colonne mappée.
@immutable
class SurfaceStudioVerticalAtlasAnimationGenerationItem {
  const SurfaceStudioVerticalAtlasAnimationGenerationItem({
    required this.atlasId,
    required this.columnIndex,
    required this.role,
    required this.proposedAnimationId,
    required this.frameCount,
    required this.durationMsPerFrame,
    required this.totalDurationMs,
    required this.sourceRects,
    required this.isReady,
    required this.status,
    required this.problems,
  });

  final String atlasId;
  final int columnIndex;
  final SurfaceVariantRole role;
  final String proposedAnimationId;
  final int frameCount;
  final int durationMsPerFrame;
  final int totalDurationMs;
  final List<SurfaceStudioVerticalAtlasAnimationGenerationSourceRect>
      sourceRects;
  final bool isReady;
  final SurfaceStudioVerticalAtlasAnimationPlanItemStatus status;
  final List<String> problems;
}

/// Résumé agrégé du plan.
@immutable
class SurfaceStudioVerticalAtlasAnimationGenerationSummary {
  const SurfaceStudioVerticalAtlasAnimationGenerationSummary({
    required this.assignedColumnCount,
    required this.readyAnimationCount,
    required this.errorAnimationCount,
    required this.durationMsPerFrame,
    required this.durationFieldValid,
  });

  final int assignedColumnCount;
  final int readyAnimationCount;
  final int errorAnimationCount;
  final int durationMsPerFrame;
  final bool durationFieldValid;
}

/// Plan complet (local, non persisté).
@immutable
class SurfaceStudioVerticalAtlasAnimationGenerationPlan {
  const SurfaceStudioVerticalAtlasAnimationGenerationPlan({
    required this.items,
    required this.summary,
    required this.gridValid,
    required this.atlasIdSlug,
  });

  final List<SurfaceStudioVerticalAtlasAnimationGenerationItem> items;
  final SurfaceStudioVerticalAtlasAnimationGenerationSummary summary;
  final bool gridValid;
  final String atlasIdSlug;
}

/// Slug ASCII pour segment d’id (`a-z`, `0-9`, `-`).
String surfaceStudioSlugForAnimationIdSegment(String raw) {
  final folded = _foldLatin1Accents(raw.trim().toLowerCase());
  final out = StringBuffer();
  var prevHyphen = false;
  for (final unit in folded.runes) {
    final c = String.fromCharCode(unit);
    if ((c.compareTo('a') >= 0 && c.compareTo('z') <= 0) ||
        (c.compareTo('0') >= 0 && c.compareTo('9') <= 0)) {
      out.write(c);
      prevHyphen = false;
    } else {
      if (!prevHyphen && out.isNotEmpty) {
        out.write('-');
        prevHyphen = true;
      }
    }
  }
  var s = out.toString();
  while (s.startsWith('-')) {
    s = s.substring(1);
  }
  while (s.endsWith('-')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

String _foldLatin1Accents(String s) {
  const from = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝŸÇÑ';
  const to = 'aaaaaaeeeeiiiiooooouuuuyyncaaaaaaeeeeiiiiooooouuuuyync';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

/// Slug rôle pour id proposé (stable, minuscules, tirets).
String surfaceStudioRoleSlugForProposedAnimationId(SurfaceVariantRole role) {
  switch (role) {
    case SurfaceVariantRole.isolated:
      return 'plein';
    case SurfaceVariantRole.endNorth:
      return 'bord-haut';
    case SurfaceVariantRole.endEast:
      return 'bord-droit';
    case SurfaceVariantRole.endSouth:
      return 'bord-bas';
    case SurfaceVariantRole.endWest:
      return 'bord-gauche';
    case SurfaceVariantRole.horizontal:
      return 'horizontal';
    case SurfaceVariantRole.vertical:
      return 'vertical';
    case SurfaceVariantRole.cornerNE:
      return 'coin-ne';
    case SurfaceVariantRole.cornerSE:
      return 'coin-se';
    case SurfaceVariantRole.cornerSW:
      return 'coin-sw';
    case SurfaceVariantRole.cornerNW:
      return 'coin-nw';
    case SurfaceVariantRole.innerCornerNE:
      return 'coin-int-ne';
    case SurfaceVariantRole.innerCornerSE:
      return 'coin-int-se';
    case SurfaceVariantRole.innerCornerSW:
      return 'coin-int-sw';
    case SurfaceVariantRole.innerCornerNW:
      return 'coin-int-nw';
    case SurfaceVariantRole.teeNorth:
      return 'te-haut';
    case SurfaceVariantRole.teeEast:
      return 'te-droit';
    case SurfaceVariantRole.teeSouth:
      return 'te-bas';
    case SurfaceVariantRole.teeWest:
      return 'te-gauche';
    case SurfaceVariantRole.cross:
      return 'croix';
  }
}

String surfaceStudioProposedAnimationId({
  required String atlasIdRaw,
  required SurfaceVariantRole role,
}) {
  final atlasSeg = surfaceStudioSlugForAnimationIdSegment(atlasIdRaw);
  final roleSeg = surfaceStudioRoleSlugForProposedAnimationId(role);
  if (atlasSeg.isEmpty || roleSeg.isEmpty) {
    return '';
  }
  return '$atlasSeg-$roleSeg-loop';
}

List<SurfaceStudioVerticalAtlasAnimationGenerationSourceRect>
    surfaceStudioVerticalAtlasAnimationGenerationSourceRects({
  required int columnIndex,
  required int tileWidth,
  required int tileHeight,
  required int rows,
}) {
  final out = <SurfaceStudioVerticalAtlasAnimationGenerationSourceRect>[];
  for (var f = 0; f < rows; f++) {
    out.add(
      SurfaceStudioVerticalAtlasAnimationGenerationSourceRect(
        frameIndex: f,
        sourceX: columnIndex * tileWidth,
        sourceY: f * tileHeight,
        sourceWidth: tileWidth,
        sourceHeight: tileHeight,
      ),
    );
  }
  return out;
}

/// Construit le plan local (aucune écriture catalogue).
SurfaceStudioVerticalAtlasAnimationGenerationPlan
    buildSurfaceStudioVerticalAtlasAnimationGenerationPlan({
  required String atlasIdRaw,
  required SurfaceStudioColumnRoleMappingDraft mappingDraft,
  required int? tileWidth,
  required int? tileHeight,
  required int? columns,
  required int? rows,
  required int durationMsPerFrame,
  required Set<String> existingAnimationIds,
}) {
  final gridValid = surfaceStudioAtlasGridOverlayDraftValid(
    tileWidth,
    tileHeight,
    columns,
    rows,
  );
  final atlasSeg = surfaceStudioSlugForAnimationIdSegment(atlasIdRaw);
  final durationOk = durationMsPerFrame > 0;
  final tw = tileWidth ?? 0;
  final th = tileHeight ?? 0;
  final rws = rows ?? 0;

  final assigned = mappingDraft.assignments
      .where((a) => a.role != null)
      .toList()
    ..sort((a, b) => a.columnIndex.compareTo(b.columnIndex));

  final items = <SurfaceStudioVerticalAtlasAnimationGenerationItem>[];
  var ready = 0;
  var err = 0;

  for (final a in assigned) {
    final role = a.role!;
    final problems = <String>[];
    late final SurfaceStudioVerticalAtlasAnimationPlanItemStatus status;
    late final bool isReady;

    if (!gridValid) {
      problems.add('Grille invalide pour cette animation.');
    }
    if (!durationOk) {
      problems.add('Durée par frame invalide.');
    }
    if (atlasSeg.isEmpty) {
      problems
          .add('Identifiant d’atlas requis pour proposer un id d’animation.');
    }

    final proposed = surfaceStudioProposedAnimationId(
      atlasIdRaw: atlasIdRaw,
      role: role,
    );
    final baseInvalid = !gridValid || !durationOk || atlasSeg.isEmpty;
    final duplicateId = !baseInvalid &&
        proposed.isNotEmpty &&
        existingAnimationIds.contains(proposed);
    if (duplicateId) {
      problems.add('Une animation existe déjà avec cet id.');
    }
    if (baseInvalid) {
      status = SurfaceStudioVerticalAtlasAnimationPlanItemStatus.invalid;
      isReady = false;
    } else if (duplicateId) {
      status = SurfaceStudioVerticalAtlasAnimationPlanItemStatus.duplicate;
      isReady = false;
    } else {
      status = SurfaceStudioVerticalAtlasAnimationPlanItemStatus.ready;
      isReady = true;
      problems.clear();
    }

    final rects = gridValid && tw > 0 && th > 0 && rws > 0
        ? surfaceStudioVerticalAtlasAnimationGenerationSourceRects(
            columnIndex: a.columnIndex,
            tileWidth: tw,
            tileHeight: th,
            rows: rws,
          )
        : const <SurfaceStudioVerticalAtlasAnimationGenerationSourceRect>[];

    final fc = gridValid ? rws : 0;
    final totalMs = durationOk && fc > 0 ? fc * durationMsPerFrame : 0;

    if (isReady) {
      ready++;
    } else {
      err++;
    }

    items.add(
      SurfaceStudioVerticalAtlasAnimationGenerationItem(
        atlasId: atlasIdRaw.trim(),
        columnIndex: a.columnIndex,
        role: role,
        proposedAnimationId: proposed,
        frameCount: fc,
        durationMsPerFrame: durationMsPerFrame,
        totalDurationMs: totalMs,
        sourceRects: rects,
        isReady: isReady,
        status: status,
        problems: List<String>.unmodifiable(problems),
      ),
    );
  }

  final summary = SurfaceStudioVerticalAtlasAnimationGenerationSummary(
    assignedColumnCount: assigned.length,
    readyAnimationCount: ready,
    errorAnimationCount: err,
    durationMsPerFrame: durationMsPerFrame,
    durationFieldValid: durationOk,
  );

  return SurfaceStudioVerticalAtlasAnimationGenerationPlan(
    items: List<SurfaceStudioVerticalAtlasAnimationGenerationItem>.unmodifiable(
      items,
    ),
    summary: summary,
    gridValid: gridValid,
    atlasIdSlug: atlasSeg,
  );
}

/// Section UI : plan de génération (affichage uniquement).
class SurfaceStudioVerticalAtlasAnimationGenerationPlanSection
    extends StatefulWidget {
  const SurfaceStudioVerticalAtlasAnimationGenerationPlanSection({
    super.key,
    required this.label,
    required this.subtle,
    required this.readModel,
    required this.atlasIdDraft,
    required this.atlasDisplayName,
    this.atlasCategoryDraft,
    required this.mappingDraft,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    this.onWorkCatalogChanged,
    this.onWorkCatalogAnimationsCreated,
  });

  static const ValueKey<String> sectionKey =
      ValueKey<String>('surface_studio_vertical_atlas_generation_plan');

  final Color label;
  final Color subtle;
  final SurfaceStudioReadModel readModel;
  final String atlasIdDraft;
  final String atlasDisplayName;
  final String? atlasCategoryDraft;
  final SurfaceStudioColumnRoleMappingDraft mappingDraft;
  final int? tileWidth;
  final int? tileHeight;
  final int? columns;
  final int? rows;
  final ValueChanged<ProjectSurfaceCatalog>? onWorkCatalogChanged;
  final ValueChanged<List<String>>? onWorkCatalogAnimationsCreated;

  @override
  State<SurfaceStudioVerticalAtlasAnimationGenerationPlanSection>
      createState() =>
          _SurfaceStudioVerticalAtlasAnimationGenerationPlanSectionState();
}

class _SurfaceStudioVerticalAtlasAnimationGenerationPlanSectionState
    extends State<SurfaceStudioVerticalAtlasAnimationGenerationPlanSection> {
  static const int _defaultDurationMs = 120;

  late final TextEditingController _durationMs =
      TextEditingController(text: '$_defaultDurationMs');
  bool _showDetails = false;
  String? _appendFeedback;

  @override
  void didUpdateWidget(
    covariant SurfaceStudioVerticalAtlasAnimationGenerationPlanSection
        oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (widget.mappingDraft != oldWidget.mappingDraft ||
        widget.atlasIdDraft != oldWidget.atlasIdDraft ||
        widget.rows != oldWidget.rows ||
        widget.columns != oldWidget.columns ||
        widget.tileWidth != oldWidget.tileWidth ||
        widget.tileHeight != oldWidget.tileHeight) {
      _appendFeedback = null;
    }
  }

  @override
  void dispose() {
    _durationMs.dispose();
    super.dispose();
  }

  int? _parseDurationMs() {
    return int.tryParse(_durationMs.text.trim());
  }

  void _resetDuration() {
    setState(() {
      _durationMs.text = '$_defaultDurationMs';
    });
  }

  void _tryAppendAnimations(
      SurfaceStudioVerticalAtlasAnimationGenerationPlan plan) {
    final cb = widget.onWorkCatalogChanged;
    if (cb == null) {
      return;
    }
    if (plan.summary.readyAnimationCount == 0) {
      setState(() {
        _appendFeedback = 'Aucune animation prête à créer.';
      });
      return;
    }
    final atlasId = widget.atlasIdDraft.trim();
    if (atlasId.isEmpty) {
      setState(() {
        _appendFeedback =
            'Définissez un identifiant d’atlas avant de créer des animations.';
      });
      return;
    }
    String? catId;
    final atl = widget.readModel.catalog.atlasById(atlasId);
    if (atl != null) {
      final c = atl.categoryId?.trim();
      if (c != null && c.isNotEmpty) {
        catId = c;
      }
    }
    final draftCat = widget.atlasCategoryDraft?.trim();
    catId ??= (draftCat == null || draftCat.isEmpty) ? null : draftCat;
    final baseSort = widget.readModel.catalog.animations.length;
    final outcome = surfaceStudioCollectNewAnimationsFromReadyPlan(
      plan: plan,
      atlasIdForTileRefs: atlasId,
      animationDisplayNamePrefix: widget.atlasDisplayName,
      categoryId: catId,
      sortOrderBase: baseSort,
    );
    if (outcome.newAnimations.isEmpty) {
      setState(() {
        _appendFeedback = 'Aucune animation prête à créer.';
      });
      return;
    }
    try {
      final next = surfaceStudioAppendAnimationsToWorkCatalog(
        catalog: widget.readModel.catalog,
        newAnimations: outcome.newAnimations,
      );
      cb(next);
      widget.onWorkCatalogAnimationsCreated?.call(
        outcome.newAnimations.map((a) => a.id).toList(),
      );
      final n = outcome.newAnimations.length;
      final ign = outcome.ignoredReadyCount;
      setState(() {
        _appendFeedback = ign > 0
            ? 'Animations créées dans le catalogue de travail ($n). $ign ignorée(s). '
                'Aucun preset créé. Pensez à appliquer au manifest puis sauvegarder le projet.'
            : 'Animations créées dans le catalogue de travail ($n). '
                'Aucun preset créé. Pensez à appliquer au manifest puis sauvegarder le projet.';
      });
    } on ValidationException {
      setState(() {
        _appendFeedback =
            'Impossible d’ajouter les animations (validation du catalogue).';
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
    final assignedCount =
        widget.mappingDraft.assignments.where((a) => a.role != null).length;
    final durationParsed = _parseDurationMs();
    final durationEffective =
        durationParsed != null && durationParsed > 0 ? durationParsed : 0;

    final existingIds = <String>{
      for (final row in widget.readModel.animations) row.id,
    };

    final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
      atlasIdRaw: widget.atlasIdDraft,
      mappingDraft: widget.mappingDraft,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      columns: widget.columns,
      rows: widget.rows,
      durationMsPerFrame: durationEffective,
      existingAnimationIds: existingIds,
    );

    final summary = plan.summary;
    final unassigned = widget.mappingDraft.columnCount - assignedCount;

    return Container(
      key: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection.sectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Plan de génération des animations',
              style: TextStyle(
                color: widget.label,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Plan de génération uniquement. Aucun preset n’est créé à cette étape.',
              style:
                  TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.35),
            ),
            Text(
              'Les animations ne sont pas encore dans le catalogue tant que vous ne les ajoutez pas.',
              style:
                  TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.35),
            ),
            const SizedBox(height: 8),
            if (!gridOk) ...[
              Text(
                'Corrigez la grille avant de préparer les animations.',
                style:
                    TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
              ),
            ] else if (assignedCount == 0) ...[
              Text(
                'Assignez au moins une colonne à un rôle pour préparer les animations.',
                style:
                    TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
              ),
            ] else ...[
              Text(
                'Colonnes assignées : $assignedCount',
                style: TextStyle(
                    color: widget.label, fontSize: 11.5, height: 1.35),
              ),
              if (unassigned > 0)
                Text(
                  'Colonnes non assignées : $unassigned',
                  style: TextStyle(
                      color: widget.subtle, fontSize: 11, height: 1.35),
                ),
              Text(
                'Animations prêtes : ${summary.readyAnimationCount}',
                style: TextStyle(
                    color: widget.label, fontSize: 11.5, height: 1.35),
              ),
              Text(
                'Animations en erreur : ${summary.errorAnimationCount}',
                style: TextStyle(
                    color: widget.label, fontSize: 11.5, height: 1.35),
              ),
              Text(
                summary.durationFieldValid
                    ? 'Durée par frame : ${summary.durationMsPerFrame} ms'
                    : 'Durée par frame : invalide',
                style:
                    TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key:
                          const ValueKey('surface_studio_gen_plan_duration_ms'),
                      controller: _durationMs,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: widget.label, fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Durée par frame (ms)',
                        isDense: true,
                        errorText: summary.durationFieldValid
                            ? null
                            : 'Entier strictement positif requis',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton(
                    key: const ValueKey('surface_studio_gen_plan_preview'),
                    onPressed: () => setState(() => _showDetails = true),
                    child: const Text('Prévisualiser le plan'),
                  ),
                  OutlinedButton(
                    key: const ValueKey(
                        'surface_studio_gen_plan_reset_duration'),
                    onPressed: _resetDuration,
                    child: const Text('Réinitialiser la durée par frame'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (summary.readyAnimationCount == 0)
                Text(
                  'Aucune animation prête à créer.',
                  style: TextStyle(
                      color: widget.subtle, fontSize: 10.5, height: 1.35),
                ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('surface_studio_gen_plan_append_ready'),
                onPressed: widget.onWorkCatalogChanged != null &&
                        summary.readyAnimationCount > 0 &&
                        summary.durationFieldValid &&
                        widget.atlasIdDraft.trim().isNotEmpty
                    ? () => _tryAppendAnimations(plan)
                    : null,
                child: const Text(
                  'Ajouter les animations prêtes au catalogue de travail',
                ),
              ),
              if (_appendFeedback != null) ...[
                const SizedBox(height: 8),
                Text(
                  _appendFeedback!,
                  style: TextStyle(
                      color: widget.label, fontSize: 11, height: 1.35),
                ),
              ],
              if (_showDetails) ...[
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final it in plan.items) ...[
                          _itemCard(context, it),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _itemCard(
    BuildContext context,
    SurfaceStudioVerticalAtlasAnimationGenerationItem it,
  ) {
    final statusLabel = switch (it.status) {
      SurfaceStudioVerticalAtlasAnimationPlanItemStatus.ready => 'prête',
      SurfaceStudioVerticalAtlasAnimationPlanItemStatus.invalid => 'invalide',
      SurfaceStudioVerticalAtlasAnimationPlanItemStatus.duplicate => 'doublon',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: widget.label.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rôle : ${SurfaceStudioRoleLabels.labelForRole(it.role)}',
              style: TextStyle(color: widget.label, fontSize: 11.5),
            ),
            Text(
              'Colonne : ${it.columnIndex}',
              style: TextStyle(color: widget.label, fontSize: 11.5),
            ),
            Text(
              'Animation proposée : ${it.proposedAnimationId.isEmpty ? '—' : it.proposedAnimationId}',
              style: TextStyle(color: widget.label, fontSize: 11.5),
            ),
            Text(
              'Frames : ${it.frameCount}',
              style: TextStyle(color: widget.label, fontSize: 11.5),
            ),
            Text(
              'Durée totale : ${it.totalDurationMs} ms',
              style: TextStyle(color: widget.label, fontSize: 11.5),
            ),
            Text(
              'Statut : $statusLabel',
              style: TextStyle(color: widget.subtle, fontSize: 11),
            ),
            if (it.problems.isNotEmpty)
              ...it.problems.map(
                (p) => Text(
                  p,
                  style: TextStyle(
                    color: widget.subtle,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
