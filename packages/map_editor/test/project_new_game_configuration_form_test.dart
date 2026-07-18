import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/state/new_game_authoring_catalog_provider.dart';
import 'package:map_editor/src/features/narrative/state/scene_consequence_catalog_providers.dart';
import 'package:map_editor/src/features/narrative/application/overview/narrative_overview_read_model.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';
import 'package:map_editor/src/ui/canvas/new_game/project_new_game_configuration_sheet.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'exposes New Game authoring from the Narrative Studio overview',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: NarrativeOverviewWorkspace(
            readModel: buildNarrativeOverviewReadModel(project: _project()),
          ),
        ),
      );

      expect(
          find.byKey(projectNewGameConfigurationLauncherKey), findsOneWidget);
      expect(find.text('Nouveau Jeu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'authors a project-owned new game with guided project catalog pickers',
    (tester) async {
      ProjectNewGameConfig? saved;

      await _pumpForm(
        tester,
        project: _project(),
        mapCatalog: const NewGameMapAuthoringCatalog(
          maps: <NewGameMapAuthoringOption>[
            NewGameMapAuthoringOption(
              id: 'map_start',
              label: 'Bourg Selbrume',
              spawns: <NewGameSpawnAuthoringOption>[
                NewGameSpawnAuthoringOption(
                  id: 'spawn_home',
                  label: 'Devant la maison',
                ),
              ],
            ),
          ],
        ),
        consequenceCatalogs: const SceneConsequenceCatalogs(
          items: SceneConsequenceCatalogSection(
            status: SceneConsequenceCatalogStatus.ready,
            options: <SceneConsequenceCatalogOption>[
              SceneConsequenceCatalogOption(
                id: 'potion',
                label: 'Potion',
              ),
            ],
            message: '1 objet local disponible.',
          ),
          species: SceneConsequenceCatalogSection(
            status: SceneConsequenceCatalogStatus.ready,
            options: <SceneConsequenceCatalogOption>[
              SceneConsequenceCatalogOption(
                id: 'bulbasaur',
                label: 'Bulbizarre',
              ),
            ],
            message: '1 espèce locale disponible.',
          ),
        ),
        onSave: (config) async {
          saved = config;
          return true;
        },
      );

      await tester.tap(find.byKey(const ValueKey('new-game-enable-button')));
      await tester.pump();

      _selectDropdown(tester, 'new-game-start-map-picker', 'map_start');
      await tester.pump();
      _selectDropdown(tester, 'new-game-start-spawn-picker', 'spawn_home');
      _selectDropdown(
        tester,
        'new-game-existing-party-fact-picker',
        'fact_existing_party',
      );
      _selectDropdown(
        tester,
        'new-game-starter-scene-picker',
        'scene_starter_choice',
      );
      _selectDropdown(tester, 'new-game-bag-item-picker', 'potion');
      _selectDropdown(
        tester,
        'new-game-initial-fact-picker',
        'fact_intro_active',
      );
      _selectDropdown(
        tester,
        'new-game-starter-species-picker',
        'bulbasaur',
      );
      await tester.pump();

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('new-game-player-name-field')),
          matching: find.byType(TextField),
        ),
        'Brume',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('new-game-starting-money-field')),
          matching: find.byType(TextField),
        ),
        '750',
      );

      await tester.tap(find.byKey(const ValueKey('new-game-bag-add')));
      await tester.tap(find.byKey(const ValueKey('new-game-initial-fact-add')));
      await tester.tap(find.byKey(const ValueKey('new-game-starter-add')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('new-game-bag-entry-potion')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('new-game-initial-fact-fact_intro_active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('new-game-starter-bulbasaur')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('new-game-save')));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.enabled, isTrue);
      expect(saved!.startMapId, 'map_start');
      expect(saved!.startSpawnId, 'spawn_home');
      expect(saved!.playerName, 'Brume');
      expect(saved!.startingMoney, 750);
      expect(saved!.existingPartyFactId, 'fact_existing_party');
      expect(saved!.starterSelectionSceneId, 'scene_starter_choice');
      expect(saved!.initialBag.single.itemId, 'potion');
      expect(saved!.initialFacts, <String, bool>{'fact_intro_active': false});
      expect(saved!.starterOptions.single.pokemon.speciesId, 'bulbasaur');
      expect(find.text('Configuration sauvegardée.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keeps invalid enabled configuration unsaved and explains missing references',
    (tester) async {
      var saveCalls = 0;

      await _pumpForm(
        tester,
        project: _project(),
        mapCatalog: const NewGameMapAuthoringCatalog(maps: []),
        consequenceCatalogs: const SceneConsequenceCatalogs.unavailable(),
        onSave: (config) async {
          saveCalls += 1;
          return true;
        },
      );

      await tester.tap(find.byKey(const ValueKey('new-game-enable-button')));
      await tester.pump();

      expect(find.text('Choisissez une map de départ.'), findsOneWidget);
      expect(
        find.text('Aucun spawn de départ sélectionnable pour cette map.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('new-game-save')),
            )
            .onPressed,
        isNull,
      );
      expect(saveCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

void _selectDropdown(
  WidgetTester tester,
  String key,
  String value,
) {
  tester
      .widget<PokeMapDropdownField<String>>(find.byKey(ValueKey(key)))
      .onChanged(value);
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required ProjectManifest project,
  required NewGameMapAuthoringCatalog mapCatalog,
  required SceneConsequenceCatalogs consequenceCatalogs,
  required Future<bool> Function(ProjectNewGameConfig config) onSave,
}) async {
  tester.view.physicalSize = const Size(760, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: ProjectNewGameConfigurationForm(
          project: project,
          mapCatalog: mapCatalog,
          consequenceCatalogs: consequenceCatalogs,
          onSave: onSave,
        ),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Selbrume',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_start',
        name: 'Bourg Selbrume',
        relativePath: 'maps/map_start.json',
      ),
    ],
    tilesets: const [],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: 'fact_intro_active',
        label: 'Introduction active',
      ),
      NarrativeFactDefinition(
        id: 'fact_existing_party',
        label: 'Équipe déjà présente',
      ),
    ],
    scenes: <SceneAsset>[
      SceneAsset(
        id: 'scene_starter_choice',
        name: 'Choix du partenaire',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: <SceneEdge>[
            SceneEdge(
              id: 'edge',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      ),
    ],
  );
}
