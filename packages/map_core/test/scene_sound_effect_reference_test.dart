import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SceneAsset soundScene(String id, String mediaId) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'sound',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: mediaId,
            volume: 0.8,
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'sound',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port in ['completed', 'blocked'])
        SceneEdge(
          id: port,
          fromNodeId: 'sound',
          fromPortId: port,
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);

CinematicMediaAsset media({
  CinematicMediaAssetKind kind = CinematicMediaAssetKind.sound,
  bool loop = false,
}) => CinematicMediaAsset(
  id: 'door',
  label: 'Door',
  kind: kind,
  relativePath: 'audio/door.wav',
  loopByDefault: loop,
);
ProjectManifest project(SceneAsset scene, List<CinematicMediaAsset> assets) =>
    ProjectManifest(
      name: 'QA',
      maps: const [],
      tilesets: const [],
      scenes: [scene],
      cinematicMediaAssets: assets,
    );

void main() {
  test('known non looping sound has one exact native dependency', () {
    final scene = soundScene('scene', 'door');
    final manifest = project(scene, [media()]);
    expect(diagnoseSceneAgainstProject(scene, manifest).hasErrors, isFalse);
    final index = buildNarrativeDependencyIndex(project: manifest);
    final uses = index.usagesFor(
      const NarrativeDependencyKey(NarrativeDependencyTargetKind.media, 'door'),
    );
    expect(uses, hasLength(1));
    expect(uses.single.owner, const NarrativeDependencyKey.scene('scene'));
    expect(
      uses.single.path,
      'scenes[scene].graph.nodes[1].payload.interactiveCommand.mediaAssetId',
    );
    expect(
      uses.single.criticality,
      NarrativeDependencyCriticality.runtimeBlocking,
    );
    expect(uses.single.resolution, NarrativeDependencyResolution.resolved);
  });

  test(
    'missing sound is diagnosed and indexed without breaking project loading',
    () {
      final scene = soundScene('draft', 'missing');
      final manifest = project(scene, []);
      final diagnostics = diagnoseSceneAgainstProject(scene, manifest);
      expect(
        diagnostics.diagnostics.where(
          (item) => item.code.name == 'commandUnknownSoundMedia',
        ),
        hasLength(1),
      );
      expect(diagnostics.hasErrors, isTrue);
      final index = buildNarrativeDependencyIndex(project: manifest);
      final uses = index.usagesFor(
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.media,
          'missing',
        ),
      );
      expect(uses, hasLength(1));
      expect(uses.single.resolution, NarrativeDependencyResolution.missing);
      expect(
        index.issues.where(
          (issue) =>
              issue.kind == NarrativeDependencyIssueKind.missingReference &&
              issue.target.id == 'missing',
        ),
        hasLength(1),
      );
      expect(() => ProjectValidator.validate(manifest), returnsNormally);
    },
  );

  for (final invalid in [
    media(kind: CinematicMediaAssetKind.music),
    media(kind: CinematicMediaAssetKind.cinematicFx),
    media(loop: true),
  ]) {
    test(
      'sound command refuses ${invalid.kind.name} loop=${invalid.loopByDefault}',
      () {
        final scene = soundScene('scene', 'door');
        final manifest = project(scene, [invalid]);
        expect(
          diagnoseSceneAgainstProject(scene, manifest).diagnostics.where(
            (item) => item.code.name == 'commandInvalidSoundMedia',
          ),
          hasLength(1),
        );
        final uses = buildNarrativeDependencyIndex(project: manifest).usagesFor(
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.media,
            'door',
          ),
        );
        expect(uses, hasLength(1));
        expect(
          uses.single.resolution,
          NarrativeDependencyResolution.unavailable,
        );
      },
    );
  }

  test(
    'unavailable sound reports media compatibility instead of missing maps',
    () {
      for (final invalid in [
        media(kind: CinematicMediaAssetKind.music),
        media(kind: CinematicMediaAssetKind.cinematicFx),
        media(loop: true),
      ]) {
        final index = buildNarrativeDependencyIndex(
          project: project(soundScene('scene', 'door'), [invalid]),
        );
        final issue = index.issues.singleWhere(
          (issue) =>
              issue.kind == NarrativeDependencyIssueKind.unavailableReference &&
              issue.target.kind == NarrativeDependencyTargetKind.media,
        );
        expect(issue.message, 'media:door is not a non-looping sound effect.');
        expect(issue.owner, const NarrativeDependencyKey.scene('scene'));
        expect(
          issue.path,
          'scenes[scene].graph.nodes[1].payload.interactiveCommand.mediaAssetId',
        );
        expect(
          issue.criticality,
          NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
    },
  );

  test('unavailable map data retains its map-specific diagnostic', () {
    final manifest = project(soundScene('scene', 'door'), [media()]).copyWith(
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'map',
        startSpawnId: 'spawn',
      ),
    );
    final index = buildNarrativeDependencyIndex(project: manifest);
    final issue = index.issues.singleWhere(
      (issue) =>
          issue.kind == NarrativeDependencyIssueKind.unavailableReference &&
          issue.path == 'newGame.startSpawnId',
    );
    expect(
      issue.message,
      '${issue.target} is declared but its map data is unavailable.',
    );
  });

  test('duplicate media remains ambiguous instead of selecting the first', () {
    final scene = soundScene('scene', 'door');
    final manifest = project(scene, [media(), media(loop: true)]);
    expect(
      diagnoseSceneAgainstProject(scene, manifest).diagnostics.where(
        (item) => item.code.name == 'commandInvalidSoundMedia',
      ),
      hasLength(1),
    );
    final uses = buildNarrativeDependencyIndex(project: manifest).usagesFor(
      const NarrativeDependencyKey(NarrativeDependencyTargetKind.media, 'door'),
    );
    expect(uses, hasLength(1));
    expect(uses.single.resolution, NarrativeDependencyResolution.ambiguous);
  });

  test('world tone has no media dependency or persistent reference', () {
    final scene = SceneAsset(
      id: 'tone',
      name: 'Tone',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'tone',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.worldTone(
                red: -255,
                green: -255,
                blue: -255,
                gray: 0,
                durationMs: 300,
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'tone',
            kind: SceneEdgeKind.defaultFlow,
          ),
          for (final port in ['completed', 'blocked'])
            SceneEdge(
              id: port,
              fromNodeId: 'tone',
              fromPortId: port,
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
        ],
      ),
    );
    final manifest = project(scene, []);
    expect(diagnoseSceneAgainstProject(scene, manifest).hasErrors, isFalse);
    expect(
      buildNarrativeDependencyIndex(project: manifest).usages.where(
        (usage) => usage.target.kind == NarrativeDependencyTargetKind.media,
      ),
      isEmpty,
    );
  });
}
