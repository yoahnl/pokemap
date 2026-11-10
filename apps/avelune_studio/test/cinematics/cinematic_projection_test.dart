import 'package:avelune_studio/features/cinematics/application/cinematic_diagnostics.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_map_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/spatial_narrative_fixture.dart';

void main() {
  test(
    'spatial actor projection resolves feet without changing authored data',
    () {
      final asset = spatialNarrativeCinematic();
      final map = spatialNarrativeMap();
      final before = map.toJson();
      final model = CinematicMapModel(asset, spatialNarrativeProject(), map);
      final chief = model.actors.actorById('chief')!.position;
      expect((chief.x, chief.y), (13.5, 7.5));
      final hero = model.actors.actorById('hero')!.position;
      expect((hero.x, hero.y), (8.5, 9.5));
      expect(model.background.entities, isEmpty);
      expect(map.toJson(), before);
      final flat = CinematicMapModel(
        asset,
        spatialNarrativeProject(),
        map.copyWith(spatialScene: null),
      );
      expect(flat.actors.actorById('chief')!.position.y, 7);
    },
  );

  test(
    'diagnostic grouping retains targets and separates blocking severity',
    () {
      CinematicPreviewPlaybackDiagnostic diagnostic(
        bool blocking,
        String step,
      ) => CinematicPreviewPlaybackDiagnostic(
        code: CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackMoveDestinationMissing,
        severity: blocking
            ? CinematicPreviewPlaybackDiagnosticSeverity.error
            : CinematicPreviewPlaybackDiagnosticSeverity.warning,
        message: 'Destination introuvable',
        stepId: step,
        actorId: 'guide',
        blocking: blocking,
      );
      final groups = groupCinematicDiagnostics([
        diagnostic(false, 's1'),
        diagnostic(true, 's2'),
        diagnostic(true, 's2'),
        diagnostic(true, 's3'),
      ]);
      expect(groups, hasLength(2));
      expect(groups.first.blocking, isTrue);
      expect(groups.first.count, 3);
      expect(groups.first.stepIds, ['s2', 's3']);
      expect(groups.first.actorIds, ['guide']);
      expect(
        cinematicDiagnosticSummary(groups),
        'Lecture possible mais incomplète : 1 problème à corriger, 1 avertissement.',
      );
      expect(
        cinematicDiagnosticSummary([]),
        'Lecture possible : 0 avertissement sans effet bloquant.',
      );
    },
  );
  test('identical diagnostics are grouped with their targets', () {
    CinematicPreviewPlaybackDiagnostic diagnostic(
      String message, {
      String? step,
      String? actor,
      bool blocking = false,
    }) => CinematicPreviewPlaybackDiagnostic(
      code: CinematicPreviewPlaybackDiagnosticCode
          .cinematicPreviewPlaybackMoveDestinationMissing,
      severity: blocking
          ? CinematicPreviewPlaybackDiagnosticSeverity.error
          : CinematicPreviewPlaybackDiagnosticSeverity.warning,
      message: message,
      stepId: step,
      actorId: actor,
      blocking: blocking,
    );
    final groups = groupCinematicDiagnostics([
      diagnostic('Destination introuvable', step: 's1', blocking: true),
      diagnostic('Durée indicative', step: 's2'),
      diagnostic('Destination introuvable', step: 's3', blocking: true),
      diagnostic('Destination introuvable', step: 's1', blocking: true),
      diagnostic('Durée indicative', actor: 'mother'),
    ]);
    expect(groups, hasLength(2));
    expect(groups.first.message, 'Destination introuvable');
    expect(groups.first.blocking, isTrue);
    expect(groups.first.count, 3);
    expect(groups.first.stepIds, ['s1', 's3']);
    expect(groups.last.stepIds, ['s2']);
    expect(groups.last.actorIds, ['mother']);
    expect(
      cinematicDiagnosticSummary(groups),
      'Lecture possible mais incomplète : 1 problème à corriger, 1 avertissement.',
    );
  });
}
