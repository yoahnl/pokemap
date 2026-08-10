import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_preview_projection.dart';
import '../application/personalization_preview_scenario.dart';
import '../application/personalization_preview_surface_descriptor.dart';

typedef PersonalizationStudioSceneBuilder =
    Widget Function({
      required ProjectPresentationProfile profile,
      required PersonalizationStudioScene surface,
      required PersonalizationStudioSceneProjection projection,
      required double aspectRatio,
      required PersonalizationPreviewViewportMetrics metrics,
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
    final projection = PersonalizationPreviewProjection(
      scenario.draftProfile,
    ).surface(scenario.surface);
    return LayoutBuilder(
      builder: (context, constraints) {
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
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scenario.textScale)),
              child: KeyedSubtree(
                key: ValueKey<String>(
                  'personalization-preview-viewport-frame-'
                  '${scenario.viewport.name}',
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
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
                            surface: scenario.surface,
                            projection: projection,
                            aspectRatio: scenario.viewport.aspectRatio,
                            metrics: scenario.metrics,
                            reducedMotion: scenario.reducedMotion,
                          ),
                        )
                      : surfaceBuilder(
                          profile: scenario.draftProfile,
                          surface: scenario.surface,
                          projection: projection,
                          aspectRatio: scenario.viewport.aspectRatio,
                          metrics: scenario.metrics,
                          reducedMotion: scenario.reducedMotion,
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
      surface: scenario.surface,
      projection: PersonalizationPreviewProjection(
        baseline,
      ).surface(scenario.surface),
      aspectRatio: scenario.viewport.aspectRatio,
      metrics: scenario.metrics,
      reducedMotion: scenario.reducedMotion,
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
