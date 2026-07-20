import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeGlobalSearchIndex', () {
    test('indexes project labels ids tags scopes diagnostics and consumers',
        () {
      final dependencyIndex = NarrativeDependencyIndex(
        definitions: [
          NarrativeDependencyDefinition(
            key: const NarrativeDependencyKey(
              NarrativeDependencyTargetKind.fact,
              'fact.brume_apaisee',
            ),
            label: 'Brume apaisée',
          ),
          NarrativeDependencyDefinition(
            key: const NarrativeDependencyKey(
              NarrativeDependencyTargetKind.scene,
              'scene.port',
            ),
            label: 'Rencontre au port',
          ),
        ],
        usages: const [
          NarrativeDependencyUsage(
            target: NarrativeDependencyKey(
              NarrativeDependencyTargetKind.fact,
              'fact.brume_apaisee',
            ),
            owner: NarrativeDependencyKey(
              NarrativeDependencyTargetKind.scene,
              'scene.port',
            ),
            path: 'scenes[scene.port].conditions[0]',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'Selbrume',
        maps: const [
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port des Brisants',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        storylines: [
          StorylineAsset(
            id: 'story.main',
            type: StorylineType.main,
            title: 'Le secret de Selbrume',
            chapters: [
              StorylineChapter(
                id: 'chapter.port',
                title: 'Le port',
                order: 0,
                steps: [
                  StorylineStep(
                    id: 'step.meet_lysa',
                    title: 'Rencontrer Lysa',
                    order: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
        scenes: [
          SceneAsset(
            id: 'scene.port',
            name: 'Rencontre au port',
            storylineId: 'story.main',
            chapterId: 'chapter.port',
            tags: const ['lysa', 'port'],
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(
                  id: 'start',
                  kind: SceneNodeKind.start,
                  title: 'Début',
                ),
              ],
              edges: const [],
            ),
          ),
        ],
        facts: [
          NarrativeFactDefinition(
            id: 'fact.brume_apaisee',
            label: 'Brume apaisée',
            category: 'Port',
            tags: const ['mystere'],
          ),
        ],
      );
      const diagnostic = NarrativeProjectDiagnostic(
        code: 'scene.missing_exit',
        severity: NarrativeProjectDiagnosticSeverity.warning,
        domain: NarrativeProjectDiagnosticDomain.scene,
        message: 'La scène ne possède aucune sortie.',
        path: 'scenes[scene.port]',
        destination: NarrativeProjectDiagnosticDestination.scene,
        sceneId: 'scene.port',
      );

      final index = buildNarrativeGlobalSearchIndex(
        project: project,
        dependencyIndex: dependencyIndex,
        diagnostics: const [diagnostic],
        revision: 7,
      );

      final fact = index.search(
        const NarrativeGlobalSearchQuery(text: 'mystere rencontre'),
      );
      final scoped = index.search(
        NarrativeGlobalSearchQuery(
          text: 'port',
          filter: NarrativeGlobalSearchFilter(
            kinds: const {NarrativeGlobalSearchKind.scene},
            storylineId: 'story.main',
          ),
        ),
      );
      final diagnostics = index.search(
        NarrativeGlobalSearchQuery(
          text: 'sortie',
          filter: NarrativeGlobalSearchFilter(
            kinds: const {NarrativeGlobalSearchKind.diagnostic},
          ),
        ),
      );

      expect(fact.results.single.entry.technicalId, 'fact.brume_apaisee');
      expect(fact.results.single.entry.consumerLabels, ['Rencontre au port']);
      expect(scoped.results.single.entry.technicalId, 'scene.port');
      expect(scoped.results.single.entry.tags, containsAll(['lysa', 'port']));
      expect(diagnostics.results.single.entry.diagnostic, diagnostic);
      expect(index.revision, 7);
    });

    test('fuzzy matching is accent-insensitive and ties are deterministic', () {
      final index = NarrativeGlobalSearchIndex.fromEntries(
        revision: 1,
        entries: const [
          NarrativeGlobalSearchEntry(
            kind: NarrativeGlobalSearchKind.fact,
            technicalId: 'fact.z',
            label: 'Éclat de Brume',
          ),
          NarrativeGlobalSearchEntry(
            kind: NarrativeGlobalSearchKind.fact,
            technicalId: 'fact.a',
            label: 'Éclat de Brume',
          ),
          NarrativeGlobalSearchEntry(
            kind: NarrativeGlobalSearchKind.scene,
            technicalId: 'scene.other',
            label: 'Autre scène',
          ),
        ],
      );

      final response = index.search(
        const NarrativeGlobalSearchQuery(text: 'ecl brm'),
      );

      expect(
        response.results.map((result) => result.entry.technicalId),
        ['fact.a', 'fact.z'],
      );
    });

    test('handles 10000 entries, limits results and flags stale responses', () {
      final index = NarrativeGlobalSearchIndex.fromEntries(
        revision: 11,
        entries: [
          for (var index = 0; index < 10000; index++)
            NarrativeGlobalSearchEntry(
              kind: NarrativeGlobalSearchKind.fact,
              technicalId: 'fact.$index',
              label: 'Fact $index',
            ),
        ],
      );

      final response = index.search(
        const NarrativeGlobalSearchQuery(
          text: 'fact.999',
          limit: 8,
          requestRevision: 42,
        ),
      );

      expect(response.results, hasLength(8));
      expect(response.results.first.entry.technicalId, 'fact.999');
      expect(response.requestRevision, 42);
      expect(response.isStaleComparedTo(index), isFalse);
      expect(
        response.isStaleComparedTo(
          NarrativeGlobalSearchIndex.fromEntries(
            revision: 12,
            entries: const [],
          ),
        ),
        isTrue,
      );
    });
  });
}
