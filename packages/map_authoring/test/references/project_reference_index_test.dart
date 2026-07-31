import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectReferenceIndex', () {
    test('adapts cross-domain references from the real project snapshot',
        () async {
      final snapshot = await _realSnapshot();

      final index = ProjectReferenceIndex.fromSnapshot(snapshot);

      expect(index.nodes, isNotEmpty);
      expect(
        index.nodes.map((node) => node.key.kind).toSet(),
        contains(NarrativeDependencyTargetKind.sourceMap.name),
      );
      expect(
        index.nodes.any(
          (node) =>
              node.key.kind == NarrativeDependencyTargetKind.sourceMap.name &&
              node.key.sourceKind == 'map',
        ),
        isTrue,
      );
      expect(index.edges, isNotEmpty);
      final physicalMap = index.nodes.singleWhere(
        (node) =>
            node.key.kind == NarrativeDependencyTargetKind.sourceMap.name &&
            node.key.sourceKind == 'map',
      );
      expect(physicalMap.key.toResourceRef().toJson(), {
        'kind': NarrativeDependencyTargetKind.sourceMap.name,
        'id': physicalMap.key.id,
        'extensions': {
          'scope': physicalMap.key.scope,
          'parentId': physicalMap.key.parentId,
          'sourceKind': 'map',
        },
      });
      expect(jsonEncode(index.toJson()), isNotEmpty);
      expect(index.toJson().toString(), isNot(contains('/Users/')));
    });

    test('provides deterministic dependency and dependent directions', () {
      const fact = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'fact.ready',
      );
      const scene = NarrativeDependencyKey.scene('scene.intro');
      const storyline = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.storyline,
        'story.main',
      );
      final index = ProjectReferenceIndex.fromNarrativeIndex(
        NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: fact, label: 'Ready'),
            NarrativeDependencyDefinition(key: scene, label: 'Intro'),
            NarrativeDependencyDefinition(key: storyline, label: 'Main'),
          ],
          usages: const [
            NarrativeDependencyUsage(
              target: fact,
              owner: scene,
              path: 'scenes[scene.intro].condition',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            ),
            NarrativeDependencyUsage(
              target: scene,
              owner: storyline,
              path: 'storylines[story.main].sceneId',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            ),
          ],
        ),
      );
      final queries = ProjectReferenceQueries(index);

      expect(
        queries
            .dependencies(ProjectReferenceKey.fromNarrativeKey(scene))
            .map((edge) => edge.target.id),
        ['fact.ready'],
      );
      expect(
        queries
            .dependents(ProjectReferenceKey.fromNarrativeKey(scene))
            .map((edge) => edge.owner.id),
        ['story.main'],
      );
    });

    test('keeps broken references coded and navigable', () {
      const missing = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'fact.missing',
      );
      const owner = NarrativeDependencyKey.scene('scene.owner');
      final index = ProjectReferenceIndex.fromNarrativeIndex(
        NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: owner, label: 'Owner'),
          ],
          usages: const [
            NarrativeDependencyUsage(
              target: missing,
              owner: owner,
              path: 'scenes[scene.owner].condition',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
              resolution: NarrativeDependencyResolution.missing,
              navigationIntent: NarrativeDependencyNavigationIntent(
                kind: NarrativeDependencyTargetKind.scene,
                assetId: 'scene.owner',
                context: 'scenes[scene.owner].condition',
              ),
            ),
          ],
          issues: const [
            NarrativeDependencyIssue(
              kind: NarrativeDependencyIssueKind.missingReference,
              target: missing,
              owner: owner,
              path: 'scenes[scene.owner].condition',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
              message: 'Missing fact.',
            ),
          ],
        ),
      );

      final broken = ProjectReferenceQueries(index).brokenReferences();

      expect(broken, hasLength(1));
      expect(broken.single.code, 'reference.missingReference');
      expect(broken.single.target.id, 'fact.missing');
      expect(broken.single.owner?.id, 'scene.owner');
      expect(broken.single.navigation, isNotNull);
      expect(broken.single.severity, ProjectReferenceSeverity.error);
    });

    test('bounded graph terminates cycles and reports truncation', () {
      const a = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'a',
      );
      const b = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'b',
      );
      const c = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'c',
      );
      final index = ProjectReferenceIndex.fromNarrativeIndex(
        NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: a, label: 'A'),
            NarrativeDependencyDefinition(key: b, label: 'B'),
            NarrativeDependencyDefinition(key: c, label: 'C'),
          ],
          usages: const [
            NarrativeDependencyUsage(
              target: b,
              owner: a,
              path: 'a.toB',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            ),
            NarrativeDependencyUsage(
              target: a,
              owner: b,
              path: 'b.toA',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            ),
            NarrativeDependencyUsage(
              target: c,
              owner: b,
              path: 'b.toC',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            ),
          ],
        ),
      );
      final queries = ProjectReferenceQueries(index);
      final complete = queries.graph(
        ProjectReferenceKey.fromNarrativeKey(a),
        maxDepth: 8,
        maxNodes: 20,
      );
      final bounded = queries.graph(
        ProjectReferenceKey.fromNarrativeKey(a),
        maxDepth: 8,
        maxNodes: 2,
      );

      expect(complete.nodes.map((node) => node.key.id), ['a', 'b', 'c']);
      expect(complete.truncated, isFalse);
      expect(bounded.nodes, hasLength(2));
      expect(bounded.truncated, isTrue);
    });

    test('computes deterministic delete and rename impact', () {
      const fact = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'fact.old',
      );
      const scene = NarrativeDependencyKey.scene('scene.owner');
      final index = ProjectReferenceIndex.fromNarrativeIndex(
        NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: fact, label: 'Old'),
            NarrativeDependencyDefinition(key: scene, label: 'Owner'),
          ],
          usages: const [
            NarrativeDependencyUsage(
              target: fact,
              owner: fact,
              path: 'facts[fact.old].self',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            ),
            NarrativeDependencyUsage(
              target: fact,
              owner: scene,
              path: 'scenes[scene.owner].condition',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            ),
          ],
        ),
      );
      final analyzer = ProjectReferenceImpactAnalyzer(index);
      final target = ProjectReferenceKey.fromNarrativeKey(fact);

      final deletion = analyzer.deletionImpact(target);
      final rename = analyzer.renameImpact(target, newId: 'fact.new');

      expect(
        deletion.directDependents.map((dependent) => dependent.id),
        ['fact.old', 'scene.owner'],
      );
      expect(deletion.affectedEdges, hasLength(2));
      expect(deletion.runtimeBlocking, isTrue);
      expect(rename.replacement?.id, 'fact.new');
      expect(rename.directDependents, deletion.directDependents);
    });

    test('reuses canonical picker read models including missing selection', () {
      const map = NarrativeDependencyKey.map('map.port');
      const scene = NarrativeDependencyKey.scene('scene.port');
      final index = ProjectReferenceIndex.fromNarrativeIndex(
        NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: map, label: 'Port'),
            NarrativeDependencyDefinition(key: scene, label: 'Arrival'),
          ],
        ),
      );

      final picker = ProjectReferenceQueries(index).picker(
        allowedKinds: const {NarrativeDependencyTargetKind.scene},
        selectedKey: const NarrativeDependencyKey.scene('scene.missing'),
      );

      expect(picker.groups.single.label, 'Scenes');
      expect(picker.groups.single.options.single.key.id, 'scene.port');
      expect(picker.missingSelection?.key.id, 'scene.missing');
      expect(
        picker.missingSelection?.availability,
        NarrativeReferenceAvailability.missing.name,
      );
    });

    test('is deterministic independently of source declaration order', () {
      const fact = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'fact.ready',
      );
      const scene = NarrativeDependencyKey.scene('scene.intro');
      final forward = NarrativeDependencyIndex(
        definitions: [
          NarrativeDependencyDefinition(key: fact, label: 'Ready'),
          NarrativeDependencyDefinition(key: scene, label: 'Intro'),
        ],
      );
      final reverse = NarrativeDependencyIndex(
        definitions: [
          NarrativeDependencyDefinition(key: scene, label: 'Intro'),
          NarrativeDependencyDefinition(key: fact, label: 'Ready'),
        ],
      );

      expect(
        ProjectReferenceIndex.fromNarrativeIndex(forward).toJson(),
        ProjectReferenceIndex.fromNarrativeIndex(reverse).toJson(),
      );
    });
  });
}

Future<ProjectSnapshot> _realSnapshot() async {
  final fixture = Directory(
    [
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'p3_narrative_smoke_slice',
    ].join(Platform.pathSeparator),
  );
  var token = 0;
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [fixture.parent.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore(
    clock: () => DateTime.utc(2026, 7, 31, 12),
    tokenFactory: (prefix) => '$prefix${token++}',
  );
  final opened = await ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
  ).openProject(fixture.path);
  return ProjectSnapshotLoader(handles: handles).load(opened.projectHandle);
}
