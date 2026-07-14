import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/border_studio_draft.dart';
import '../application/border_studio_publication_coordinator.dart';
import 'border_canonical_gallery_canvas.dart';
import 'border_studio_presentation.dart';

class BorderPreviewPublicationStep extends StatelessWidget {
  const BorderPreviewPublicationStep({
    super.key,
    required this.state,
    required this.preview,
    required this.isPreparing,
    required this.isPublishing,
    required this.onPreparePreview,
    required this.onNewVariation,
    required this.onAcknowledgeWarning,
    required this.onSaveDraft,
    required this.onPublish,
    this.feedback,
  });

  final BorderStudioDraftState state;
  final BorderStudioPublicationPreview? preview;
  final bool isPreparing;
  final bool isPublishing;
  final VoidCallback onPreparePreview;
  final VoidCallback onNewVariation;
  final ValueChanged<String> onAcknowledgeWarning;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final String? feedback;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final definition = state.workingDraft?.blueprint.definition;
    final unresolved = definition == null
        ? const <String>[]
        : unresolvedBorderRoleLabels(definition);
    final publication = state.publicationAvailability;
    final expectedCases = definition == null
        ? 0
        : borderCanonicalGalleryCasesForTemplate(definition.template).length;
    final hasCompleteGallery = preview != null &&
        preview!.canonicalGalleryCases.length == expectedCases &&
        preview!.canonicalGalleryCases.every(
          (sample) => sample.resolution.canApply,
        );
    final canPublish = preview != null &&
        hasCompleteGallery &&
        preview!.canPublish &&
        publication.isAllowed &&
        unresolved.isEmpty &&
        !isPreparing &&
        !isPublishing;
    final disabledReason = _disabledReason(
      publication: publication,
      unresolved: unresolved,
      hasPreview: preview != null,
      hasCompleteGallery: hasCompleteGallery,
    );
    final previewFrames = preview == null
        ? const <String, List<BorderCanonicalGalleryFrame>>{}
        : _framesBySnapshotId(preview!);

    return BorderStudioStepScaffold(
      title: '5. Aperçu et publication',
      description:
          'Générez les six cas canoniques dans un bac à sable neutre, puis publiez exactement les pixels affichés.',
      child: definition == null
          ? const PokeMapEmptyState(
              title: 'Créez un blueprint pour afficher sa galerie',
              icon: Icon(CupertinoIcons.play_rectangle),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PokeMapPanel(
                  key: const ValueKey<String>(
                    'border-studio-neutral-sandbox',
                  ),
                  header: Padding(
                    padding: const EdgeInsets.all(12),
                    child: PokeMapSectionHeader(
                      title: 'Bac à sable neutre',
                      description:
                          'Chaque vignette ci-dessous provient du solveur réel et des snapshots immuables candidats.',
                      trailing: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          PokeMapButton(
                            key: const ValueKey<String>(
                              'border-studio-prepare-preview',
                            ),
                            onPressed: isPreparing || isPublishing
                                ? null
                                : onPreparePreview,
                            isLoading: isPreparing,
                            variant: PokeMapButtonVariant.secondary,
                            size: PokeMapButtonSize.small,
                            leading: const Icon(CupertinoIcons.play),
                            child: Text(
                              preview == null
                                  ? 'Générer l’aperçu'
                                  : 'Régénérer',
                            ),
                          ),
                          PokeMapButton(
                            key: const ValueKey<String>(
                              'border-studio-new-variation',
                            ),
                            onPressed: isPreparing || isPublishing
                                ? null
                                : onNewVariation,
                            variant: PokeMapButtonVariant.secondary,
                            size: PokeMapButtonSize.small,
                            leading: const Icon(CupertinoIcons.shuffle),
                            child: const Text('Nouvelle variation'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: preview == null
                      ? const PokeMapEmptyState(
                          key: ValueKey<String>(
                            'border-studio-gallery-not-prepared',
                          ),
                          title: 'Aucun aperçu canonique préparé',
                          description:
                              'La publication reste bloquée tant que les six cas réels ne sont pas générés.',
                          icon: Icon(CupertinoIcons.rectangle_grid_2x2),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final sample in preview!.canonicalGalleryCases)
                              SizedBox(
                                key: ValueKey<String>(
                                  'border-studio-gallery-case-${sample.galleryCase.name}',
                                ),
                                width: 272,
                                child: PokeMapCard(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _galleryCaseLabel(sample.galleryCase),
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      BorderCanonicalGalleryCanvas(
                                        semanticsLabel:
                                            '${_galleryCaseLabel(sample.galleryCase)} généré',
                                        geometry: sample.geometry,
                                        tileSizePx: GridSize(
                                          width: preview!.candidate.nextManifest
                                              .settings.tileWidth,
                                          height: preview!.candidate
                                              .nextManifest.settings.tileHeight,
                                        ),
                                        materialization:
                                            sample.resolution.materialization,
                                        catalog: preview!.candidate.nextManifest
                                            .borderCatalog,
                                        framesBySnapshotId: previewFrames,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                PokeMapCard(
                  child: Row(
                    children: [
                      PokeMapStatusTile(
                        label: 'Cas réels',
                        value:
                            '${preview?.canonicalGalleryCases.length ?? 0}/$expectedCases',
                        tone: hasCompleteGallery
                            ? PokeMapTone.success
                            : PokeMapTone.warning,
                      ),
                      const SizedBox(width: 8),
                      PokeMapStatusTile(
                        label: 'Erreurs',
                        value: '${_diagnosticCount(
                          state,
                          BorderDiagnosticSeverity.error,
                        )}',
                        tone: _diagnosticCount(
                                  state,
                                  BorderDiagnosticSeverity.error,
                                ) ==
                                0
                            ? PokeMapTone.success
                            : PokeMapTone.danger,
                      ),
                      const SizedBox(width: 8),
                      PokeMapStatusTile(
                        label: 'Avertissements',
                        value: '${_diagnosticCount(
                          state,
                          BorderDiagnosticSeverity.warning,
                        )}',
                        tone: state.warningCodes.isEmpty
                            ? PokeMapTone.success
                            : PokeMapTone.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          unresolved.isEmpty
                              ? 'Tous les rôles requis sont résolus.'
                              : 'Rôles non résolus : ${unresolved.join(', ')}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.warningCodes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  PokeMapPanel(
                    header: const Padding(
                      padding: EdgeInsets.all(12),
                      child: PokeMapSectionHeader(
                        title: 'Validation visuelle requise',
                        description:
                            'Examinez la galerie avant d’accepter un avertissement.',
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final warningCode in state.warningCodes) ...[
                          BorderStudioNotice(
                            title: 'Avertissement du solveur',
                            description: _warningLabel(warningCode),
                            tone: PokeMapTone.warning,
                            icon: CupertinoIcons.exclamationmark_triangle,
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: PokeMapButton(
                              key: ValueKey<String>(
                                'border-studio-acknowledge-warning-$warningCode',
                              ),
                              onPressed: state.acknowledgedWarningCodes
                                      .contains(warningCode)
                                  ? null
                                  : () => onAcknowledgeWarning(warningCode),
                              variant: PokeMapButtonVariant.secondary,
                              size: PokeMapButtonSize.small,
                              leading: const Icon(CupertinoIcons.check_mark),
                              child: Text(
                                state.acknowledgedWarningCodes
                                        .contains(warningCode)
                                    ? 'Avertissement accepté'
                                    : 'J’ai vérifié cet avertissement',
                              ),
                            ),
                          ),
                          if (warningCode != state.warningCodes.last)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                PokeMapPanel(
                  header: const Padding(
                    padding: EdgeInsets.all(12),
                    child: PokeMapSectionHeader(
                      title: 'Actions finales',
                      description:
                          'Le brouillon et la révision publiée restent deux états distincts.',
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!canPublish && disabledReason != null) ...[
                        BorderStudioNotice(
                          title: 'Publication indisponible',
                          description: disabledReason,
                          tone: PokeMapTone.warning,
                          icon: CupertinoIcons.lock,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (feedback != null) ...[
                        BorderStudioNotice(
                          title: 'Border Studio',
                          description: feedback!,
                          tone: PokeMapTone.info,
                          icon: CupertinoIcons.info,
                        ),
                        const SizedBox(height: 10),
                      ],
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          PokeMapButton(
                            key: const ValueKey<String>(
                              'border-studio-save-draft',
                            ),
                            onPressed: isPreparing || isPublishing
                                ? null
                                : onSaveDraft,
                            variant: PokeMapButtonVariant.secondary,
                            leading: const Icon(CupertinoIcons.archivebox),
                            child: const Text('Enregistrer le brouillon'),
                          ),
                          Tooltip(
                            message: canPublish
                                ? 'Publier la révision immuable affichée'
                                : disabledReason ?? 'Publication indisponible',
                            child: PokeMapButton(
                              key: const ValueKey<String>(
                                'border-studio-publish',
                              ),
                              onPressed: canPublish ? onPublish : null,
                              isLoading: isPublishing,
                              variant: PokeMapButtonVariant.primary,
                              leading: const Icon(CupertinoIcons.cloud_upload),
                              child: const Text('Publier'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String? _disabledReason({
    required BorderStudioPublicationAvailability publication,
    required List<String> unresolved,
    required bool hasPreview,
    required bool hasCompleteGallery,
  }) {
    final templateGate = publication.disabledReason;
    if (templateGate != null && templateGate.contains('BORD-06')) {
      return templateGate;
    }
    if (unresolved.isNotEmpty) {
      return 'Attribuez les rôles requis avant de publier : ${unresolved.join(', ')}.';
    }
    if (!hasPreview) {
      return 'Générez l’aperçu canonique avant de publier.';
    }
    if (!hasCompleteGallery) {
      return 'Les six cas canoniques doivent être résolus sans erreur avant de publier.';
    }
    return publication.disabledReason;
  }

  Map<String, List<BorderCanonicalGalleryFrame>> _framesBySnapshotId(
    BorderStudioPublicationPreview prepared,
  ) {
    final bytesByPath = <String, Uint8List>{
      for (final file in prepared.candidate.files)
        file.relativePath: file.bytes,
    };
    final result = <String, List<BorderCanonicalGalleryFrame>>{};
    for (final snapshot
        in prepared.candidate.nextManifest.borderCatalog.visualSnapshots) {
      final frames = <BorderCanonicalGalleryFrame>[];
      for (final metadata in snapshot.frames) {
        final bytes = bytesByPath[metadata.relativeAssetPath];
        if (bytes == null) {
          frames.clear();
          break;
        }
        frames.add((bytes: bytes, metadata: metadata));
      }
      if (frames.length == snapshot.frames.length && frames.isNotEmpty) {
        result[snapshot.id] = List<BorderCanonicalGalleryFrame>.unmodifiable(
          frames,
        );
      }
    }
    return result;
  }

  String _galleryCaseLabel(BorderCanonicalGalleryCase galleryCase) =>
      switch (galleryCase) {
        BorderCanonicalGalleryCase.longEdge => 'Longue portion',
        BorderCanonicalGalleryCase.gentleCurve => 'Courbe douce',
        BorderCanonicalGalleryCase.sharpConvexCorner => 'Angle convexe',
        BorderCanonicalGalleryCase.sharpConcaveCorner => 'Angle concave',
        BorderCanonicalGalleryCase.hole => 'Contour intérieur',
        BorderCanonicalGalleryCase.smallIsland => 'Petit îlot',
        BorderCanonicalGalleryCase.sharpCorner => 'Angle prononcé',
        BorderCanonicalGalleryCase.endpoint => 'Extrémité',
        BorderCanonicalGalleryCase.opening => 'Ouverture',
      };

  String _warningLabel(String code) {
    if (code.contains('repetition')) {
      return 'Certaines séquences visuelles se répètent. Vérifiez que le résultat reste naturel sur les six cas.';
    }
    return 'Le solveur a détecté un point non bloquant qui demande votre validation visuelle.';
  }

  int _diagnosticCount(
    BorderStudioDraftState state,
    BorderDiagnosticSeverity severity,
  ) =>
      state.diagnostics.diagnostics
          .where((diagnostic) => diagnostic.severity == severity)
          .length;
}
