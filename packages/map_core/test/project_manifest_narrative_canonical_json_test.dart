import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('ProjectManifest path preset output is deep JSON for Event V2 hashes',
      () {
    final manifest = ProjectManifest(
      name: 'Narrative snapshot regression',
      maps: const [],
      tilesets: const [],
      terrainPresets: const <ProjectTerrainPreset>[
        ProjectTerrainPreset(
          id: 'terrain',
          name: 'Terrain',
          terrainType: TerrainType.grass,
          variants: <TerrainPresetVariant>[
            TerrainPresetVariant(
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
        ),
      ],
      pathPresets: const <ProjectPathPreset>[
        ProjectPathPreset(
          id: 'path',
          name: 'Path',
          variants: <PathPresetVariantMapping>[
            PathPresetVariantMapping(
              variant: TerrainPathVariant.cross,
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 2),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      () => canonicalizeNarrativeEventJson(manifest.toJson()),
      returnsNormally,
    );
  });

  test('ProjectManifest canonical JSON preserves explicit false Facts', () {
    final manifest = ProjectManifest(
      name: 'Fact canonical regression',
      maps: const [],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(
          id: 'fact_explicit_false',
          label: 'Explicit false',
          defaultValue: false,
        ),
      ],
    );

    final canonical = canonicalizeNarrativeEventJson(manifest.toJson());
    final decoded = ProjectManifest.fromJson(
      jsonDecode(canonical) as Map<String, dynamic>,
    );

    expect(canonical, contains('"defaultValue":false'));
    expect(decoded.facts.single.defaultValue, isFalse);
    expect(decoded.facts.single.id, 'fact_explicit_false');
  });

  test('legacy absent false defaults safely and a broken Fact id is refused',
      () {
    final base = ProjectManifest(
      name: 'Fact legacy regression',
      maps: const [],
      tilesets: const [],
    ).toJson();
    final legacy = ProjectManifest.fromJson({
      ...base,
      'facts': [
        {'id': 'fact_legacy', 'label': 'Legacy Fact'},
      ],
    });

    expect(legacy.facts.single.defaultValue, isFalse);
    expect(
      () => ProjectManifest.fromJson({
        ...base,
        'facts': [
          {'id': '', 'label': 'Broken Fact'},
        ],
      }),
      throwsArgumentError,
    );
  });

  test('typed Facts round-trip canonically across narrative consumers', () {
    const eventId = 'evt_019abcde-9000-7000-8000-000000000001';
    final manifest = ProjectManifest(
      name: 'Typed Fact canonical regression',
      maps: const [],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(
          id: 'fact_reputation',
          label: 'Réputation',
          initialValue: NarrativeValue.integer(1),
        ),
      ],
      scenes: [
        SceneAsset(
          id: 'scene_typed',
          name: 'Typed',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'write',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                  SceneConsequence.setFactValue(
                    factId: 'fact_reputation',
                    value: NarrativeValue.integer(8),
                  ),
                ),
              ),
            ],
            edges: const [],
          ),
        ),
      ],
      storylines: [
        StorylineAsset(
          id: 'story_typed',
          type: StorylineType.main,
          title: 'Typed',
          chapters: [
            StorylineChapter(
              id: 'chapter_typed',
              title: 'Typed',
              order: 0,
              directSceneLinkIds: const ['link_typed'],
            ),
          ],
          sceneLinks: [
            StorylineSceneLink(
              id: 'link_typed',
              chapterId: 'chapter_typed',
              label: 'Typed',
              state: StorylineSceneLinkState.linkedScenario,
              role: StorylineSceneLinkRole.primary,
              sceneRef: StorylineSceneRef(
                kind: StorylineSceneRefKind.scenario,
                targetId: 'scenario_typed',
              ),
              order: 0,
              outcomeLinks: [
                StorylineSceneOutcomeLink(
                  id: 'outcome_typed',
                  outcomeId: 'completed',
                  label: 'Completed',
                  effects: [
                    StorylineEffect.emitFactValue(
                      factId: 'fact_reputation',
                      value: NarrativeValue.integer(9),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
      worldRules: [
        WorldRuleDefinition(
          id: 'rule_typed',
          label: 'Typed',
          source: WorldRuleSource.factValue(
            factId: 'fact_reputation',
            operator: NarrativeFactOperator.greaterThanOrEqual,
            expectedValue: NarrativeValue.integer(5),
          ),
          target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEvent,
            mapId: 'map_typed',
            eventId: 'legacy_event',
          ),
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.eventEnabled,
          ),
        ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: eventId,
              name: 'Typed',
              source: NarrativeEventSourceRef.mapEnter('map_typed'),
              conditions: [
                NarrativeEventCondition.factValue(
                  'fact_reputation',
                  operator: NarrativeFactOperator.greaterThan,
                  expectedValue: NarrativeValue.integer(3),
                ),
              ],
              sceneId: 'scene_typed',
              reusePolicy: NarrativeEventReusePolicy.reusable,
              priority: 0,
              order: 0,
            ),
            enabled: true,
          ),
        ],
        legacyClaims: const [],
      ),
      newGame: ProjectNewGameConfig(
        initialFactValues: {
          'fact_reputation': NarrativeValue.integer(2),
        },
      ),
    );

    final canonical = canonicalizeNarrativeEventJson(manifest.toJson());
    final decoded = ProjectManifest.fromJson(
      jsonDecode(canonical) as Map<String, dynamic>,
    );

    expect(decoded, manifest);
    expect(canonical, contains('"valueType":"int"'));
    expect(canonical, contains('"factSchemaVersion":2'));
  });
}
