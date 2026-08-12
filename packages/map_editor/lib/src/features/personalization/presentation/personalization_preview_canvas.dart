import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_preview_projection.dart';
import '../application/personalization_preview_scenario.dart';
import '../application/personalization_preview_surface_descriptor.dart';

typedef PersonalizationStudioSceneBuilder =
    Widget Function({
      required ProjectPresentationProfile profile,
      required PersonalizationStudioScene scene,
      required double aspectRatio,
      required bool reducedMotion,
    });

class PersonalizationPreviewCanvas extends StatelessWidget {
  const PersonalizationPreviewCanvas({
    super.key,
    required this.scenario,
    required this.surfaceBuilder,
    this.contentBuilder,
  });

  final PersonalizationPreviewScenario scenario;
  final PersonalizationStudioSceneBuilder surfaceBuilder;
  final Widget Function(
    BuildContext context,
    ProjectPresentationBreakpoint breakpoint,
    Widget child,
  )?
  contentBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = scenario.metrics;
        final maxWidth = switch (scenario.viewport) {
          PersonalizationPreviewViewport.landscape => constraints.maxWidth,
          PersonalizationPreviewViewport.portrait =>
            constraints.maxWidth.clamp(0, 320).toDouble(),
          PersonalizationPreviewViewport.square =>
            constraints.maxWidth.clamp(0, 480).toDouble(),
          PersonalizationPreviewViewport.phoneLandscape =>
            constraints.maxWidth.clamp(0, 560).toDouble(),
        };
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: AspectRatio(
              aspectRatio: metrics.aspectRatio,
              child: Semantics(
                key: const ValueKey<String>(
                  'personalization-preview-contained-frame',
                ),
                container: true,
                explicitChildNodes: true,
                label:
                    'Aperçu ${_semanticViewportLabel(scenario.viewport)} '
                    'entièrement visible',
                child: FittedBox(
                  fit: BoxFit.contain,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: metrics.logicalWidth,
                    height: metrics.logicalHeight,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(metrics.logicalWidth, metrics.logicalHeight),
                        padding: EdgeInsets.fromLTRB(
                          metrics.safeLeft,
                          metrics.safeTop,
                          metrics.safeRight,
                          metrics.safeBottom,
                        ),
                        textScaler: TextScaler.linear(scenario.textScale),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey<String>(
                          'personalization-preview-viewport-frame-'
                          '${scenario.viewport.name}',
                        ),
                        child: Builder(
                          builder: (context) {
                            final content = AnimatedSwitcher(
                              duration:
                                  scenario.effectiveReducedMotion ||
                                      MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 160),
                              child: scenario.showComparison
                                  ? _ComparisonPreview(
                                      key: ValueKey<String>(
                                        'personalization-comparison-'
                                        '${scenario.surface.name}-'
                                        '${scenario.viewport.name}',
                                      ),
                                      before: _buildBaseline(),
                                      after: surfaceBuilder(
                                        profile: scenario.draftProfile,
                                        scene: scenario.surface,
                                        aspectRatio:
                                            scenario.viewport.aspectRatio,
                                        reducedMotion:
                                            scenario.effectiveReducedMotion,
                                      ),
                                    )
                                  : surfaceBuilder(
                                      profile: scenario.draftProfile,
                                      scene: scenario.surface,
                                      aspectRatio:
                                          scenario.viewport.aspectRatio,
                                      reducedMotion:
                                          scenario.effectiveReducedMotion,
                                    ),
                            );
                            final builder = contentBuilder;
                            if (builder == null || scenario.showComparison) {
                              return content;
                            }
                            final breakpoint =
                                const ProjectPresentationLayoutResolver()
                                    .classify(
                                      width:
                                          metrics.logicalWidth -
                                          metrics.safeLeft -
                                          metrics.safeRight,
                                      height:
                                          metrics.logicalHeight -
                                          metrics.safeTop -
                                          metrics.safeBottom,
                                    );
                            return builder(context, breakpoint, content);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBaseline() {
    final baseline = scenario.baselineProfile!;
    return surfaceBuilder(
      profile: baseline,
      scene: scenario.surface,
      aspectRatio: scenario.viewport.aspectRatio,
      reducedMotion: scenario.effectiveReducedMotion,
    );
  }
}

String _semanticViewportLabel(PersonalizationPreviewViewport viewport) =>
    switch (viewport) {
      PersonalizationPreviewViewport.landscape => 'paysage',
      PersonalizationPreviewViewport.portrait => 'portrait',
      PersonalizationPreviewViewport.square => 'carré',
      PersonalizationPreviewViewport.phoneLandscape => 'téléphone paysage',
    };

class _ComparisonPreview extends StatelessWidget {
  const _ComparisonPreview({
    super.key,
    required this.before,
    required this.after,
  });

  final Widget before;
  final Widget after;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _LabeledPreview(
            key: const ValueKey<String>('personalization-preview-before'),
            label: 'Avant',
            child: before,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LabeledPreview(
            key: const ValueKey<String>('personalization-preview-after'),
            label: 'Maintenant',
            child: after,
          ),
        ),
      ],
    );
  }
}

class _LabeledPreview extends StatelessWidget {
  const _LabeledPreview({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: PokeMapBadge(label: label, variant: PokeMapBadgeVariant.info),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
