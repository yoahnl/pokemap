import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../application/use_cases/map_visual_stack_migration_use_case.dart';
import '../../theme/theme.dart';
import 'pokemap_button.dart';
import 'pokemap_card.dart';
import 'pokemap_diagnostic_callout.dart';
import 'pokemap_panel.dart';
import 'pokemap_section_header.dart';
import 'pokemap_toggle_tile.dart';

const pokeMapVisualStackMigrationDialogKey =
    ValueKey<String>('pokemap-visual-stack-migration-dialog');
const pokeMapVisualStackMigrationConsentKey =
    ValueKey<String>('pokemap-visual-stack-migration-consent');
const pokeMapVisualStackMigrationApplyKey =
    ValueKey<String>('pokemap-visual-stack-migration-apply');

Future<EditorMapVisualStackMigrationPreview?>
    showPokeMapVisualStackMigrationDialog(
  BuildContext context, {
  required Future<EditorMapVisualStackMigrationPreview> preview,
}) {
  final colors = context.pokeMapColors;
  return showGeneralDialog<EditorMapVisualStackMigrationPreview>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer la migration de pile visuelle',
    barrierColor: colors.chromeBackground.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _PokeMapVisualStackMigrationDialog(preview: preview),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final class _PokeMapVisualStackMigrationDialog extends StatefulWidget {
  const _PokeMapVisualStackMigrationDialog({
    required this.preview,
  });

  final Future<EditorMapVisualStackMigrationPreview> preview;

  @override
  State<_PokeMapVisualStackMigrationDialog> createState() =>
      _PokeMapVisualStackMigrationDialogState();
}

final class _PokeMapVisualStackMigrationDialogState
    extends State<_PokeMapVisualStackMigrationDialog> {
  bool _reviewed = false;
  EditorMapVisualStackMigrationPreview? _preview;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    widget.preview.then(
      (preview) {
        if (!mounted) return;
        setState(() => _preview = preview);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        setState(() => _loadError = error);
      },
    );
  }

  bool _needsReview(EditorMapVisualStackMigrationPreview preview) {
    return preview.migration.differences.isNotEmpty ||
        (preview.pixelComparison?.hasChanges ?? false);
  }

  void _apply() {
    final preview = _preview;
    if (preview == null ||
        !preview.canApply ||
        (_needsReview(preview) && !_reviewed)) {
      return;
    }
    Navigator.of(context).pop(preview);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final viewport = MediaQuery.sizeOf(context);
    final width = math.min(920.0, math.max(320.0, viewport.width - 48));
    final height = math.min(820.0, math.max(440.0, viewport.height - 48));
    final preview = _preview;
    final isLoading = preview == null && _loadError == null;
    final canApply = preview != null &&
        preview.canApply &&
        (!_needsReview(preview) || _reviewed);

    return SafeArea(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
        },
        child: FocusTraversalGroup(
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
                key: pokeMapVisualStackMigrationDialogKey,
                container: true,
                scopesRoute: true,
                namesRoute: true,
                label: 'Migrer la pile visuelle',
                explicitChildNodes: true,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: PokeMapPanel(
                    expandChild: true,
                    padding: EdgeInsets.zero,
                    header: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            color: preview?.canApply == true
                                ? colors.mapAccent
                                : isLoading
                                    ? colors.textMuted
                                    : colors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Adopter la pile visuelle v1',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Prévisualisation sans écriture : comparez '
                                  'la composition legacy et la pile canonique.',
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    footer: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PokeMapButton(
                            onPressed: () => Navigator.of(context).pop(),
                            variant: PokeMapButtonVariant.secondary,
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 8),
                          PokeMapButton(
                            key: pokeMapVisualStackMigrationApplyKey,
                            onPressed: canApply ? _apply : null,
                            autofocus: canApply,
                            isLoading: isLoading,
                            child: const Text('Adopter la pile v1'),
                          ),
                        ],
                      ),
                    ),
                    child: isLoading
                        ? const _MigrationLoadingState()
                        : _loadError != null
                            ? _MigrationLoadError(error: _loadError!)
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _MigrationStatus(preview: preview!),
                                    if (preview.pixelComparisonError
                                        case final error?) ...[
                                      const SizedBox(height: 12),
                                      PokeMapDiagnosticCallout(
                                        severity:
                                            PokeMapDiagnosticSeverity.error,
                                        title:
                                            'Comparaison requise indisponible',
                                        message: error,
                                      ),
                                    ],
                                    if (preview.pixelComparison
                                        case final pixels?) ...[
                                      const SizedBox(height: 16),
                                      _PixelComparisonSummary(
                                          comparison: pixels),
                                    ],
                                    const SizedBox(height: 18),
                                    const PokeMapSectionHeader(
                                      title: 'Avant / après',
                                      description:
                                          'Ordre exact exécuté par l’éditeur et le runtime',
                                    ),
                                    const SizedBox(height: 8),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final before = _PlanCard(
                                          title: 'Legacy',
                                          plan: preview.migration.beforePlan,
                                        );
                                        final after = _PlanCard(
                                          title: 'Canonique v1',
                                          plan: preview.migration.afterPlan,
                                        );
                                        if (constraints.maxWidth < 680) {
                                          return Column(
                                            children: [
                                              before,
                                              const SizedBox(height: 10),
                                              after,
                                            ],
                                          );
                                        }
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: before),
                                            const SizedBox(width: 10),
                                            Expanded(child: after),
                                          ],
                                        );
                                      },
                                    ),
                                    if (preview
                                        .migration.differences.isNotEmpty) ...[
                                      const SizedBox(height: 18),
                                      PokeMapSectionHeader(
                                        title: 'Différences de composition',
                                        description:
                                            '${preview.migration.differences.length} changement(s) déterministe(s)',
                                      ),
                                      const SizedBox(height: 8),
                                      for (final difference
                                          in preview.migration.differences) ...[
                                        PokeMapDiagnosticCallout(
                                          severity:
                                              PokeMapDiagnosticSeverity.warning,
                                          title: _compositionStepLabelFromKey(
                                            difference.stepStableKey,
                                            preview.migration.beforePlan,
                                            preview.migration.afterPlan,
                                          ),
                                          message:
                                              _differenceMessage(difference),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ],
                                    if (_needsReview(preview) &&
                                        preview.canApply) ...[
                                      const SizedBox(height: 10),
                                      KeyedSubtree(
                                        key:
                                            pokeMapVisualStackMigrationConsentKey,
                                        child: PokeMapToggleTile(
                                          label:
                                              'J’ai compris les changements affichés',
                                          description:
                                              'L’ordre des contenus et la zone des '
                                              'pixels modifiés sont affichés '
                                              'ci-dessus. La migration reste '
                                              'annulable.',
                                          value: _reviewed,
                                          onChanged: (value) =>
                                              setState(() => _reviewed = value),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _MigrationLoadingState extends StatelessWidget {
  const _MigrationLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.info,
        title: 'Calcul du rendu réel…',
        message: 'Chargement des assets projet puis comparaison RGBA de la '
            'carte complète. Vous pouvez annuler sans modifier la carte.',
      ),
    );
  }
}

final class _MigrationLoadError extends StatelessWidget {
  const _MigrationLoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.error,
        title: 'Prévisualisation impossible',
        message: 'Le rendu avant/après n’a pas pu être calculé : $error',
      ),
    );
  }
}

final class _MigrationStatus extends StatelessWidget {
  const _MigrationStatus({required this.preview});

  final EditorMapVisualStackMigrationPreview preview;

  @override
  Widget build(BuildContext context) {
    return switch (preview.migration.status) {
      MapVisualStackMigrationStatus.ready => const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: 'Migration prête',
          message: 'Aucune donnée de carte ne sera réordonnée ou réécrite. '
              'La version de document v3 et le contrat visuel v1 seront '
              'adoptés ensemble après confirmation.',
        ),
      MapVisualStackMigrationStatus.noChange => const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: 'Déjà en pile visuelle v1',
          message: 'Cette carte ne nécessite aucune migration.',
        ),
      MapVisualStackMigrationStatus.blocked => PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.error,
          title: 'Migration bloquée — lecture seule',
          message: preview.migration.diagnostics
              .map((diagnostic) => diagnostic.message)
              .join(' '),
        ),
    };
  }
}

final class _PixelComparisonSummary extends StatelessWidget {
  const _PixelComparisonSummary({required this.comparison});

  final MapVisualStackPixelComparison comparison;

  @override
  Widget build(BuildContext context) {
    final bounds = comparison.changedBounds;
    final boundsText = bounds == null
        ? 'aucune zone modifiée'
        : 'zone (${bounds.left}, ${bounds.top}) → '
            '(${bounds.right}, ${bounds.bottom})';
    final limitations = comparison.limitations.isEmpty
        ? ''
        : ' Limites : ${comparison.limitations.join(' ')}';
    return PokeMapDiagnosticCallout(
      severity: comparison.hasChanges
          ? PokeMapDiagnosticSeverity.warning
          : PokeMapDiagnosticSeverity.info,
      title: 'Comparaison des pixels RGBA rendus',
      message: '${comparison.changedPixelCount} pixel(s) rendu(s) sur '
          '${comparison.width * comparison.height} diffèrent, $boundsText.'
          '$limitations',
    );
  }
}

final class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.plan,
  });

  final String title;
  final MapVisualCompositionPlan? plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final steps = plan?.steps;
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (steps == null)
            Text(
              'Plan indisponible',
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            )
          else
            for (var index = 0; index < steps.length; index += 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${index + 1}. ${_compositionStepLabel(steps[index])}',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

String _compositionStepLabel(MapVisualCompositionStep step) {
  final layer = step.layer;
  final layerLabel = layer == null
      ? ''
      : layer.name.trim().isEmpty
          ? layer.id
          : '${layer.name} (${layer.id})';
  return switch (step.kind) {
    MapVisualCompositionStepKind.terrainLayer => 'Terrain — $layerLabel',
    MapVisualCompositionStepKind.pathLayer => 'Chemin — $layerLabel',
    MapVisualCompositionStepKind.surfaceLayer => 'Surface — $layerLabel',
    MapVisualCompositionStepKind.smartTileLayer => 'Smart Tile — $layerLabel',
    MapVisualCompositionStepKind.tileBackgroundLayer =>
      'Tuiles de fond — $layerLabel',
    MapVisualCompositionStepKind.borderLayer => 'Bordure — $layerLabel',
    MapVisualCompositionStepKind.objectNoop =>
      'Calque d’objets — $layerLabel (sans rendu)',
    MapVisualCompositionStepKind.environmentNoop =>
      'Calque d’environnement — $layerLabel (sans rendu)',
    MapVisualCompositionStepKind.shadows => 'Ombres',
    MapVisualCompositionStepKind.placedElements =>
      'Éléments posés — $layerLabel',
    MapVisualCompositionStepKind.backgroundEntities =>
      'Entités derrière le premier plan',
    MapVisualCompositionStepKind.foregroundTilesAndPlacedElements =>
      'Tuiles et éléments au premier plan',
    MapVisualCompositionStepKind.foregroundEntities =>
      'Entités au premier plan',
    MapVisualCompositionStepKind.collisionOverlay =>
      'Surcouche de collision de l’éditeur',
  };
}

String _compositionStepLabelFromKey(
  String stableKey,
  MapVisualCompositionPlan? before,
  MapVisualCompositionPlan? after,
) {
  for (final plan in <MapVisualCompositionPlan?>[before, after]) {
    for (final step in plan?.steps ?? const <MapVisualCompositionStep>[]) {
      if (step.stableKey == stableKey) {
        return _compositionStepLabel(step);
      }
    }
  }
  return 'Étape de composition';
}

String _differenceMessage(MapVisualStackDifference difference) {
  return switch (difference.kind) {
    MapVisualStackDifferenceKind.added =>
      'Ajouté à la position ${difference.afterIndex! + 1}.',
    MapVisualStackDifferenceKind.removed =>
      'Retiré de la position ${difference.beforeIndex! + 1}.',
    MapVisualStackDifferenceKind.moved =>
      'Déplacé de la position ${difference.beforeIndex! + 1} '
          'à ${difference.afterIndex! + 1}.',
  };
}
