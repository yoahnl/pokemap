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
  });

  final PersonalizationPreviewScenario scenario;
  final PersonalizationStudioSceneBuilder surfaceBuilder;

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
                      child: AnimatedSwitcher(
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
                                  aspectRatio: scenario.viewport.aspectRatio,
                                  reducedMotion:
                                      scenario.effectiveReducedMotion,
                                ),
                              )
                            : surfaceBuilder(
                                profile: scenario.draftProfile,
                                scene: scenario.surface,
                                aspectRatio: scenario.viewport.aspectRatio,
                                reducedMotion: scenario.effectiveReducedMotion,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final beforePreview = _LabeledPreview(
          key: const ValueKey<String>('personalization-preview-before'),
          label: 'Avant',
          child: before,
        );
        final afterPreview = _LabeledPreview(
          key: const ValueKey<String>('personalization-preview-after'),
          label: 'Maintenant',
          child: after,
        );
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: beforePreview),
              const SizedBox(width: 12),
              Expanded(child: afterPreview),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            beforePreview,
            const SizedBox(height: 12),
            afterPreview,
          ],
        );
      },
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
