import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const itemId = 'target-item';

  test('indexes every canonical item usage with an editable path', () {
    final project = ProjectManifest(
      name: 'Item references',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      newGame: const ProjectNewGameConfig(
        initialBag: <BagEntry>[BagEntry(itemId: itemId, quantity: 2)],
        initialParty: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'starter-a',
            natureId: 'hardy',
            abilityId: 'starter-ability',
            heldItemId: itemId,
          ),
        ],
        starterOptions: <ProjectStarterOption>[
          ProjectStarterOption(
            id: 'starter-option-a',
            label: 'Starter A',
            pokemon: PlayerPokemon(
              speciesId: 'starter-b',
              natureId: 'hardy',
              abilityId: 'starter-ability',
              heldItemId: itemId,
            ),
          ),
        ],
      ),
      scenes: <SceneAsset>[
        SceneAsset(
          id: 'scene-items',
          name: 'Scene Items',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: <SceneNode>[
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'give',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                  SceneConsequence.giveItem(itemId: itemId, quantity: 1),
                ),
              ),
              SceneNode(
                id: 'take',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                  SceneConsequence.takeItem(itemId: itemId, quantity: 1),
                ),
              ),
              SceneNode(
                id: 'condition',
                kind: SceneNodeKind.condition,
                payload: SceneConditionPayload(
                  conditionSource: SceneConditionSource(
                    sourceKind: SceneConditionSourceKind.inventoryItem,
                    sourceId: itemId,
                    operator: SceneConditionOperator.equals,
                    value: '1',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      scripts: const <ProjectScriptEntry>[
        ProjectScriptEntry(
          id: 'script-items',
          name: 'Script Items',
          asset: ScriptAsset(
            id: 'script-items',
            nodes: <ScriptNode>[
              ScriptNode(
                id: 'start',
                commands: <ScriptCommand>[
                  ScriptCommand(
                    type: ScriptCommandType.giveItem,
                    params: <String, String>{'itemId': itemId},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
      scenarios: <ScenarioAsset>[
        ScenarioAsset(
          id: 'scenario-items',
          name: 'Scenario Items',
          entryNodeId: 'give',
          nodes: <ScenarioNode>[
            ScenarioNode(
              id: 'give',
              payload: ScenarioNodePayload(
                actionKind: 'giveItem',
                params: const <String, String>{'itemId': itemId},
                condition: ScriptConditionFactory.itemQuantityAtLeast(
                  itemId,
                  1,
                ),
              ),
            ),
          ],
        ),
      ],
      shops: <ShopDefinition>[
        ShopDefinition(
          id: 'shop-items',
          label: 'Shop Items',
          entries: const <ShopEntryDefinition>[
            ShopEntryDefinition(itemId: itemId, price: 100),
          ],
          states: <ShopStateDefinition>[
            ShopStateDefinition(
              id: 'state-items',
              label: 'State Items',
              activation: ScriptConditionFactory.itemQuantityAtLeast(itemId, 1),
              entries: const <ShopEntryDefinition>[
                ShopEntryDefinition(itemId: itemId, price: 80),
              ],
            ),
          ],
        ),
      ],
      trainers: const <ProjectTrainerEntry>[
        ProjectTrainerEntry(
          id: 'trainer-items',
          name: 'Trainer Items',
          trainerClass: 'Tester',
          rewardItemGrants: <ProjectTrainerItemGrant>[
            ProjectTrainerItemGrant(itemId: itemId),
          ],
          team: <ProjectTrainerPokemonEntry>[
            ProjectTrainerPokemonEntry(
              speciesId: 'trainer-species',
              level: 5,
              heldItemId: itemId,
            ),
          ],
        ),
      ],
    );
    const map = MapData(
      id: 'map-items',
      name: 'Map Items',
      size: GridSize(width: 4, height: 4),
      entities: <MapEntity>[
        MapEntity(
          id: 'pickup-items',
          kind: MapEntityKind.item,
          pos: GridPos(x: 1, y: 2),
          item: MapEntityItemData(gameItemId: itemId),
        ),
      ],
    );
    const catalog = ProjectItemCatalog(
      schemaVersion: 1,
      entries: <ProjectItemDefinition>[
        ProjectItemDefinition(
          id: itemId,
          displayName: 'Target Item',
          pocketId: 'custom',
          machine: ProjectMoveMachineItemDefinition(
            moveId: 'target-move',
            kind: ProjectMoveMachineKind.tm,
            consumable: true,
          ),
        ),
      ],
    );
    const evolution = ProjectItemReference(
      itemId: itemId,
      kind: ProjectItemReferenceKind.evolutionRequirement,
      sourceKind: 'evolution',
      sourceId: 'starter-a',
      editablePath: 'pokemon.evolutions[starter-a].rules[0].itemId',
    );

    final index = buildProjectItemReferenceIndex(
      project: project,
      maps: const <MapData>[map],
      itemCatalog: catalog,
      additionalReferences: const <ProjectItemReference>[evolution],
    );
    final references = index.referencesFor(' target-item ');

    expect(references, hasLength(17));
    expect(
      references.map((reference) => reference.kind).toSet(),
      ProjectItemReferenceKind.values.toSet(),
    );
    expect(
      references.map((reference) => reference.editablePath),
      containsAll(<String>[
        'newGame.initialBag[0].itemId',
        'newGame.initialParty[0].heldItemId',
        'newGame.starterOptions[0].pokemon.heldItemId',
        'scenes[scene-items].graph.nodes[1].payload.consequence.itemId',
        'scripts[script-items].asset.nodes[0].commands[0].params.itemId',
        'scenarios[scenario-items].nodes[0].payload.params.itemId',
        'shops[shop-items].states[0].entries[0].itemId',
        'trainers[trainer-items].rewardItemGrants[0].itemId',
        'maps[map-items].entities[0].item.gameItemId',
        'itemCatalog.entries[0].machine',
        evolution.editablePath,
      ]),
    );
    expect(
      references.every((reference) => reference.editablePath.isNotEmpty),
      isTrue,
    );
    expect(index.blockingReferencesFor(itemId), hasLength(16));
    expect(
      references
          .singleWhere(
            (reference) =>
                reference.kind == ProjectItemReferenceKind.machineCapability,
          )
          .blocksDeletion,
      isFalse,
    );
    expect(index.referencesFor('missing-item'), isEmpty);
  });

  test('sorts and deduplicates references deterministically', () {
    const first = ProjectItemReference(
      itemId: 'b',
      kind: ProjectItemReferenceKind.evolutionRequirement,
      sourceKind: 'evolution',
      sourceId: 'species-b',
      editablePath: 'evolutions[b].itemId',
    );
    const second = ProjectItemReference(
      itemId: 'a',
      kind: ProjectItemReferenceKind.evolutionRequirement,
      sourceKind: 'evolution',
      sourceId: 'species-a',
      editablePath: 'evolutions[a].itemId',
    );
    final project = ProjectManifest(
      name: 'Empty',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
    );

    final index = buildProjectItemReferenceIndex(
      project: project,
      additionalReferences: const <ProjectItemReference>[first, second, first],
    );

    expect(index.references, const <ProjectItemReference>[second, first]);
  });
}
