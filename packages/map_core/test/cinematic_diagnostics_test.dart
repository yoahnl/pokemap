import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Cinematic diagnostics', () {
    test('reports empty timeline as authoring warning', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_empty',
          title: 'Empty cinematic',
          timeline: CinematicTimeline(),
        ),
      );

      final diagnostic =
          report.byCode(CinematicDiagnosticCode.cinematicEmptyTimeline).single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.warning);
      expect(diagnostic.cinematicId, 'cinematic_empty');
    });

    test('reports duplicate step ids and invalid durations', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                durationMs: -1,
              ),
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.marker,
              ),
            ],
          ),
        ),
      );

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicDuplicateStepId),
        hasLength(1),
      );
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicInvalidStepDuration),
        hasLength(1),
      );
    });

    test('reports legacy gameplay step leakage carried by metadata', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_legacy',
          title: 'Legacy cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_legacy',
                kind: CinematicTimelineStepKind.marker,
                metadata: const {'legacy.kind': 'setFact'},
              ),
            ],
          ),
        ),
      );

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.cinematicUnsupportedGameplayStep)
          .single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.error);
      expect(diagnostic.stepId, 'step_legacy');
    });

    test('accepts authoring draft marker without gameplay diagnostics', () {
      final project = ProjectManifest(
        name: 'Cinematic diagnostics test',
        maps: const [],
        tilesets: const [],
        cinematics: [
          _cinematic(id: 'cinematic_intro'),
        ],
      );
      final result = addCinematicTimelineDraftStep(
        project,
        cinematicId: 'cinematic_intro',
      );

      final report = diagnoseCinematicAsset(result.cinematic);

      expect(isCinematicTimelineDraftStep(result.step), isTrue);
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnsupportedGameplayStep),
        isEmpty,
      );
      expect(report.hasErrors, isFalse);
    });

    test('reports duplicate cinematic ids in a collection', () {
      final report = diagnoseCinematics([
        _cinematic(id: 'cinematic_intro'),
        _cinematic(id: 'cinematic_intro', title: 'Duplicate intro'),
      ]);

      final diagnostic =
          report.byCode(CinematicDiagnosticCode.cinematicDuplicateId).single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.error);
      expect(diagnostic.cinematicId, 'cinematic_intro');
    });

    test('reports unknown storyline, chapter, and map references', () {
      final project = ProjectManifest(
        name: 'Cinematic diagnostics test',
        maps: const [
          ProjectMapEntry(
            id: 'map_known',
            name: 'Known Map',
            relativePath: 'maps/map_known.json',
          ),
        ],
        tilesets: const [],
        storylines: [
          StorylineAsset(
            id: 'story_known',
            type: StorylineType.main,
            title: 'Known Story',
            chapters: [
              StorylineChapter(
                id: 'chapter_known',
                title: 'Known Chapter',
                order: 0,
              ),
            ],
          ),
        ],
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            storylineId: 'story_missing',
            chapterId: 'chapter_missing',
            mapId: 'map_missing',
          ),
        ],
      );

      final report = diagnoseCinematicsAgainstProject(project);

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnknownStorylineRef),
        hasLength(1),
      );
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnknownChapterRef),
        hasLength(1),
      );
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnknownMapRef),
        hasLength(1),
      );
    });

    test('reports legacy bridge without making it canonical runtime', () {
      final report = diagnoseCinematicAsset(
        _cinematic(
          id: 'cinematic_bridge',
          legacyBridge: CinematicLegacyBridge(
            sourceKind: CinematicLegacyBridgeSourceKind.scenarioAsset,
            scenarioId: 'scenario_bridge',
            cutsceneSchema: 'cutscene_studio_v2',
          ),
        ),
      );

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicLegacyBridge),
        hasLength(1),
      );
      expect(
        report.byCode(
          CinematicDiagnosticCode.cinematicScenarioBridgeNotCanonical,
        ),
        hasLength(1),
      );
    });
  });
}

CinematicAsset _cinematic({
  required String id,
  String title = 'Intro cinematic',
  String? storylineId,
  String? chapterId,
  String? mapId,
  CinematicLegacyBridge? legacyBridge,
}) {
  return CinematicAsset(
    id: id,
    title: title,
    storylineId: storylineId,
    chapterId: chapterId,
    mapId: mapId,
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          durationMs: 100,
        ),
      ],
    ),
    legacyBridge: legacyBridge,
  );
}
