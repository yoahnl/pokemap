import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/border_studio_draft.dart';
import 'border_studio_presentation.dart';

class BorderPreviewPublicationStep extends StatelessWidget {
  const BorderPreviewPublicationStep({
    super.key,
    required this.state,
    required this.onNewVariation,
    required this.onSaveDraft,
    required this.onPublish,
    this.feedback,
  });

  final BorderStudioDraftState state;
  final VoidCallback onNewVariation;
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
    final canPublish = publication.isAllowed && unresolved.isEmpty;
    final disabledReason = definition != null &&
            definition.template != BorderBlueprintTemplate.organicEdge
        ? publication.disabledReason
        : unresolved.isNotEmpty
            ? 'Attribuez les rôles requis avant de publier : ${unresolved.join(', ')}.'
            : publication.disabledReason;
    return BorderStudioStepScaffold(
      title: '5. Aperçu et publication',
      description:
          'Validez la recette dans un bac à sable neutre, puis choisissez explicitement de sauvegarder ou publier.',
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
                          'Ce rendu de validation n’est jamais une carte du monde.',
                      trailing: PokeMapButton(
                        key: const ValueKey<String>(
                          'border-studio-new-variation',
                        ),
                        onPressed: onNewVariation,
                        variant: PokeMapButtonVariant.secondary,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.shuffle),
                        child: const Text('Nouvelle variation'),
                      ),
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sample in _samples(definition.template))
                        PokeMapStatusTile(
                          label: 'Cas canonique',
                          value: sample,
                          icon: CupertinoIcons.waveform_path,
                          tone: PokeMapTone.info,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PokeMapCard(
                  child: Row(
                    children: [
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
                      if (disabledReason != null) ...[
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
                            onPressed: onSaveDraft,
                            variant: PokeMapButtonVariant.secondary,
                            leading: const Icon(CupertinoIcons.archivebox),
                            child: const Text('Enregistrer le brouillon'),
                          ),
                          Tooltip(
                            message: canPublish
                                ? 'Publier une révision immuable'
                                : disabledReason ?? 'Publication indisponible',
                            child: PokeMapButton(
                              key: const ValueKey<String>(
                                'border-studio-publish',
                              ),
                              onPressed: canPublish ? onPublish : null,
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

  List<String> _samples(BorderBlueprintTemplate template) => switch (template) {
        BorderBlueprintTemplate.organicEdge => const <String>[
            'Longue portion',
            'Courbe douce',
            'Angle prononcé',
            'Extrémité',
            'Petite boucle ou îlot',
          ],
        BorderBlueprintTemplate.masonryLine => const <String>[
            'Longue portion',
            'Angle prononcé',
            'Extrémité',
          ],
        BorderBlueprintTemplate.postAndRailLine => const <String>[
            'Longue portion',
            'Angle prononcé',
            'Extrémité',
            'Ouverture',
          ],
      };

  int _diagnosticCount(
    BorderStudioDraftState state,
    BorderDiagnosticSeverity severity,
  ) =>
      state.diagnostics.diagnostics
          .where((diagnostic) => diagnostic.severity == severity)
          .length;
}
