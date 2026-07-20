import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('duplicates a cinematic with fresh asset and timeline ids', () {
    final project = _project();

    final result = duplicateCinematicAsset(
      project,
      cinematicId: 'cinematic_intro',
    );

    expect(result.cinematic.id, 'cinematic_intro_copy');
    expect(result.cinematic.title, 'Intro (copie)');
    expect(result.cinematic.timeline.steps.single.id, isNot('step_wait'));
    expect(project.cinematics, hasLength(1));
    expect(result.updatedProject.cinematics, hasLength(2));
  });

  test('archives and bulk-tags cinematics without dropping metadata', () {
    final archived = setCinematicArchived(
      _project(),
      cinematicId: 'cinematic_intro',
      archived: true,
    );
    expect(isCinematicArchived(archived.cinematic), isTrue);
    expect(archived.cinematic.metadata['custom'], 'preserved');

    final tagged = bulkTagCinematics(
      archived.updatedProject,
      cinematicIds: const ['cinematic_intro'],
      tags: const ['boss', 'port', 'boss'],
    );
    expect(tagged.cinematics.single.tags, ['boss', 'port']);
    expect(isCinematicArchived(tagged.cinematics.single), isTrue);

    final restored = bulkSetCinematicsArchived(
      tagged.updatedProject,
      cinematicIds: const ['cinematic_intro'],
      archived: false,
    );
    expect(isCinematicArchived(restored.cinematics.single), isFalse);
  });
}

ProjectManifest _project() => ProjectManifest(
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
      name: 'library',
      maps: const [],
      tilesets: const [],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro',
          metadata: const {'custom': 'preserved'},
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                durationMs: 200,
              ),
            ],
          ),
        ),
      ],
    );
