import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/border_studio_draft.dart';
import 'border_studio_presentation.dart';

final class BorderAssetStepFeedback {
  const BorderAssetStepFeedback({
    required this.title,
    required this.message,
    required this.tone,
  });

  const BorderAssetStepFeedback.success(String message)
      : this(
          title: 'Asset analysé',
          message: message,
          tone: PokeMapTone.success,
        );

  const BorderAssetStepFeedback.error(String message)
      : this(
          title: 'Analyse impossible',
          message: message,
          tone: PokeMapTone.danger,
        );

  const BorderAssetStepFeedback.info(String message)
      : this(
          title: 'Assets du blueprint',
          message: message,
          tone: PokeMapTone.info,
        );

  final String title;
  final String message;
  final PokeMapTone tone;
}

class BorderAssetsStep extends StatelessWidget {
  const BorderAssetsStep({
    super.key,
    required this.state,
    required this.manifest,
    required this.selectedSourceElementId,
    required this.onSourceElementSelected,
    required this.onAnalyzeSelected,
    required this.onReanalyzePrimitive,
    required this.onRemovePrimitive,
    required this.onAuthoredOrientationChanged,
    required this.previewBytesByPrimitiveId,
    this.feedback,
    this.isAnalyzing = false,
  });

  final BorderStudioDraftState state;
  final ProjectManifest manifest;
  final String? selectedSourceElementId;
  final ValueChanged<String> onSourceElementSelected;
  final Future<void> Function() onAnalyzeSelected;
  final Future<void> Function(String primitiveId) onReanalyzePrimitive;
  final ValueChanged<String> onRemovePrimitive;
  final void Function(
    String primitiveId,
    BorderPrimitiveOrientation orientation,
  ) onAuthoredOrientationChanged;
  final Map<String, Uint8List> previewBytesByPrimitiveId;
  final BorderAssetStepFeedback? feedback;
  final bool isAnalyzing;

  @override
  Widget build(BuildContext context) {
    final primitives = state.workingDraft?.blueprint.definition.primitives ??
        const <BorderPrimitiveDraft>[];
    final template = state.workingDraft?.blueprint.definition.template;
    final elements = manifest.elements;
    final selectedElementId = _selectedElementId(elements);
    return BorderStudioStepScaffold(
      key: const ValueKey<String>('border-studio-assets-step'),
      title: '2. Assets',
      description:
          'Choisissez des éléments existants du projet. Border Studio les analyse sans modifier leur source.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.workingDraft == null)
            const BorderStudioNotice(
              title: 'Aucun blueprint sélectionné',
              description:
                  'Créez ou sélectionnez un blueprint avant d’ajouter ses assets.',
              tone: PokeMapTone.warning,
              icon: CupertinoIcons.square_on_square,
            )
          else if (elements.isEmpty)
            const BorderStudioNotice(
              title: 'Bibliothèque d’éléments vide',
              description:
                  'Créez d’abord un élément nommé dans la bibliothèque de tilesets.',
              tone: PokeMapTone.warning,
              icon: CupertinoIcons.photo_on_rectangle,
            )
          else ...[
            PokeMapCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PokeMapDropdownField<String>(
                    key: const ValueKey<String>(
                      'border-studio-project-element-picker',
                    ),
                    label: 'Élément du projet',
                    value: selectedElementId!,
                    items: <PokeMapDropdownItem<String>>[
                      for (final element in elements)
                        PokeMapDropdownItem<String>(
                          value: element.id,
                          label: element.name,
                        ),
                    ],
                    enabled: !isAnalyzing,
                    onChanged: onSourceElementSelected,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PokeMapButton(
                      key: const ValueKey<String>(
                        'border-studio-analyze-asset',
                      ),
                      onPressed: isAnalyzing
                          ? null
                          : () {
                              onAnalyzeSelected();
                            },
                      isLoading: isAnalyzing,
                      size: PokeMapButtonSize.small,
                      leading: const Icon(CupertinoIcons.sparkles),
                      child: const Text('Analyser et ajouter'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (feedback case final feedback?) ...[
            const SizedBox(height: 10),
            BorderStudioNotice(
              title: feedback.title,
              description: feedback.message,
              tone: feedback.tone,
              icon: switch (feedback.tone) {
                PokeMapTone.success => CupertinoIcons.check_mark_circled,
                PokeMapTone.danger => CupertinoIcons.exclamationmark_triangle,
                _ => CupertinoIcons.info_circle,
              },
            ),
          ],
          const SizedBox(height: 12),
          if (primitives.isEmpty)
            const BorderStudioNotice(
              key: ValueKey<String>('border-studio-asset-error'),
              title: 'Aucun asset analysé',
              description:
                  'Ajoutez au moins une structure pour préparer la bordure.',
              tone: PokeMapTone.danger,
              icon: CupertinoIcons.exclamationmark_triangle,
            )
          else
            for (final (index, primitive) in primitives.indexed) ...[
              PokeMapCard(
                child: Row(
                  children: [
                    PokeMapAssetThumbnail(
                      key: ValueKey<String>(
                        index == 0
                            ? 'border-studio-asset-thumbnail'
                            : 'border-studio-asset-thumbnail-${primitive.id}',
                      ),
                      semanticLabel:
                          'Aperçu de ${_elementName(primitive.sourceElementId)}',
                      imageBytes: previewBytesByPrimitiveId[primitive.id],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_elementName(primitive.sourceElementId)),
                          const SizedBox(height: 3),
                          Text(
                            borderRoleLabel(
                              primitive.role,
                              template: state
                                  .workingDraft?.blueprint.definition.template,
                            ),
                          ),
                          const SizedBox(height: 6),
                          PokeMapBadge(
                            label:
                                '${primitive.currentMetrics.pixelSize.width} × ${primitive.currentMetrics.pixelSize.height} px',
                            variant: PokeMapBadgeVariant.info,
                          ),
                          if (template ==
                              BorderBlueprintTemplate.stoneChainLine) ...[
                            const SizedBox(height: 10),
                            PokeMapDropdownField<BorderPrimitiveOrientation>(
                              key: ValueKey<String>(
                                'border-studio-authored-orientation-picker-${primitive.id}',
                              ),
                              label: 'Orientation dessinée dans l\'asset',
                              value: primitive.authoredOrientation,
                              items: const <PokeMapDropdownItem<
                                  BorderPrimitiveOrientation>>[
                                PokeMapDropdownItem<BorderPrimitiveOrientation>(
                                  value: BorderPrimitiveOrientation.legacyAxis,
                                  label: 'Historique',
                                ),
                                PokeMapDropdownItem<BorderPrimitiveOrientation>(
                                  value: BorderPrimitiveOrientation.north,
                                  label: 'Nord',
                                ),
                                PokeMapDropdownItem<BorderPrimitiveOrientation>(
                                  value: BorderPrimitiveOrientation.east,
                                  label: 'Est',
                                ),
                                PokeMapDropdownItem<BorderPrimitiveOrientation>(
                                  value: BorderPrimitiveOrientation.south,
                                  label: 'Sud',
                                ),
                                PokeMapDropdownItem<BorderPrimitiveOrientation>(
                                  value: BorderPrimitiveOrientation.west,
                                  label: 'Ouest',
                                ),
                              ],
                              enabled: !isAnalyzing,
                              onChanged: (orientation) =>
                                  onAuthoredOrientationChanged(
                                primitive.id,
                                orientation,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'La direction indique le côté vers lequel descend la falaise.',
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    PokeMapButton(
                      key: ValueKey<String>(
                        'border-studio-reanalyze-asset-${primitive.id}',
                      ),
                      onPressed: isAnalyzing
                          ? null
                          : () {
                              onReanalyzePrimitive(primitive.id);
                            },
                      variant: PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      leading: const Icon(CupertinoIcons.refresh),
                      child: const Text('Réanalyser'),
                    ),
                    const SizedBox(width: 6),
                    PokeMapIconButton(
                      key: ValueKey<String>(
                        'border-studio-remove-asset-${primitive.id}',
                      ),
                      tooltip: 'Retirer cet asset',
                      variant: PokeMapIconButtonVariant.danger,
                      onPressed: isAnalyzing
                          ? null
                          : () => onRemovePrimitive(primitive.id),
                      icon: const Icon(CupertinoIcons.delete),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          if (state.requiresSourceReanalysis) ...[
            const SizedBox(height: 10),
            const BorderStudioNotice(
              title: 'Source modifiée',
              description:
                  'Réanalysez explicitement les assets signalés avant toute republication.',
              tone: PokeMapTone.warning,
              icon: CupertinoIcons.refresh_circled,
            ),
          ],
        ],
      ),
    );
  }

  String? _selectedElementId(List<ProjectElementEntry> elements) {
    for (final element in elements) {
      if (element.id == selectedSourceElementId) return element.id;
    }
    return elements.isEmpty ? null : elements.first.id;
  }

  String _elementName(String sourceElementId) {
    for (final element in manifest.elements) {
      if (element.id == sourceElementId) return element.name;
    }
    return 'Élément indisponible';
  }
}
