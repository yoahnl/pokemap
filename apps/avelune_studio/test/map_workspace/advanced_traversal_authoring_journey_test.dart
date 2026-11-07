import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_model_entity_controls.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_model_roles.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_platform_controls.dart';
import 'package:avelune_studio/presentation/features/map_workspace/traversal_labels.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

SpatialModelInstance _instance(
  String id, {
  String modelId = 'oak',
  bool blocks = true,
  String? entityId,
}) => SpatialModelInstance(
  id: id,
  modelId: modelId,
  blocksMovement: blocks,
  entityId: entityId,
  position: Model3dVector3(x: 2.5, y: 0, z: 2.5),
);

ProjectManifest _project({List<NarrativeEventRecord> events = const []}) {
  final base = spatialEnvironmentProject();
  final oak = base.models3d.single;
  return base.copyWith(
    models3d: [
      oak,
      ProjectModel3dEntry(
        id: 'slope',
        name: 'Pente',
        sourceAssetId: 'slope-source',
        relativePath: 'assets/models3d/slope.glb',
        inspection: oak.inspection,
        rampProfile: Model3dRampProfile(
          x: 0,
          z: 0,
          width: 1,
          depth: 2,
          lowHeight: 0,
          highHeight: 1.5,
          direction: SpatialRampDirection.north,
        ),
      ),
    ],
    eventRegistry: events.isEmpty
        ? null
        : NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: events,
            legacyClaims: const [],
          ),
  );
}

MapData _map(
  List<SpatialModelInstance> instances, {
  List<MapEntity> entities = const [],
  List<SpatialPlatformDefinition> platforms = const [],
}) => spatialEnvironmentMap().copyWith(
  entities: entities,
  spatialScene: MapSpatialScene(
    width: 12,
    depth: 10,
    instances: instances,
    platforms: platforms,
  ),
);

void main() {
  test('a ledge jump is described with the values the game applies', () {
    expect(
      ledgeJumpSummary(BorderJumpBehavior(durationMs: 500, peakHeightPx: 24)),
      'Saut de 2 cases en 0,5 s, hauteur 24 px. Le rebord ne se franchit que depuis le côté choisi ; l’autre côté reste bloquant.',
    );
  });

  test('a 3D ledge is described with its direction and applied values', () {
    expect(
      spatialLedgeSummary(
        SpatialLedge(
          id: 'l',
          x: 26,
          z: 6,
          direction: SpatialRampDirection.east,
        ),
      ),
      'Saut de 2 cases vers la droite en 0,4 s, hauteur 0,65 case ; '
      'le retour est bloqué.',
    );
  });

  test('a platform duration reads in seconds without losing milliseconds', () {
    expect(traversalDurationLabel(1500), '1,5 s');
    expect(traversalDurationLabel(1250), '1,25 s');
    expect(traversalDurationLabel(30000), '30 s');
    expect(traversalDurationLabel(100), '0,1 s');
  });

  test('a decor separates interaction, object movement and traversal', () {
    final tree = _instance('tree', entityId: 'cut');
    final rock = _instance('rock', entityId: 'push');
    final ice = _instance('ice', entityId: 'slide');
    final statue = _instance('statue');
    final slope = _instance('slope-1', modelId: 'slope', blocks: false);
    final deck = _instance('deck', blocks: false);
    MapEntity obstacle(String id, FieldObstacleKind kind) => MapEntity(
      id: id,
      name: id,
      kind: MapEntityKind.custom,
      pos: const GridPos(x: 2, y: 2),
      fieldObstacle: MapEntityFieldObstacleData(kind: kind),
    );
    final map = _map(
      [tree, rock, ice, statue, slope, deck],
      entities: [
        obstacle('cut', FieldObstacleKind.cutTree),
        obstacle('push', FieldObstacleKind.strengthBoulder),
        obstacle('slide', FieldObstacleKind.iceBlock),
      ],
      platforms: [
        SpatialPlatformDefinition(
          id: 'ferry',
          name: 'Bac',
          instanceId: 'deck',
          x: 2,
          z: 2,
          width: 1,
          depth: 1,
          height: 0,
          durationMs: 2500,
          routes: [
            SpatialPlatformRoute(
              id: 'route-1',
              waypoints: [
                SpatialPlatformStop(x: 0, z: 0),
                SpatialPlatformStop(x: 3, z: 0),
              ],
            ),
          ],
        ),
      ],
    );
    final project = _project(
      events: [
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: 'evt_00000000-0000-7000-8000-000000000001',
            name: 'Lire la plaque',
            source: NarrativeEventSourceRef.modelInteract('a', 'statue'),
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        ),
      ],
    );

    final cut = spatialModelRoles(map, project, tree);
    expect(
      cut.interaction,
      'Obstacle Coupe : le joueur le coupe. Réglé ci-dessous, pour ce décor '
      'seulement.',
    );
    expect(cut.movement, 'Aucun : le décor reste à sa place.');
    expect(
      cut.traversal,
      'Bloque le passage tant que l’obstacle est en place.',
    );

    expect(
      spatialModelRoles(map, project, rock).movement,
      'Poussé par le joueur avec Force.',
    );
    final slide = spatialModelRoles(map, project, ice);
    expect(slide.interaction, contains('ne le fait pas glisser'));
    expect(slide.movement, contains('ne glisse pas sur une carte 3D'));

    final plaque = spatialModelRoles(map, project, statue);
    expect(
      plaque.interaction,
      '1 événement à l’interaction, réglés dans Événements.',
    );
    expect(plaque.traversal, 'Bloque le passage du joueur.');

    expect(
      spatialModelRoles(map, project, slope).traversal,
      'Escalier franchissable : montée vers le fond, de la hauteur 0 à 1,5. '
      'Réglé dans la ressource du modèle, pour toutes ses occurrences.',
    );
    final ferry = spatialModelRoles(map, project, deck);
    expect(
      ferry.movement,
      'Plateforme « Bac » : transporte le joueur sur 1 trajet en 2,5 s. '
      'Réglée dans « Plateforme sur trajet » ci-dessous.',
    );
    expect(ferry.traversal, contains('au départ et à l’arrivée'));
    expect(ferry.interaction, startsWith('Aucune'));
  });

  test('a refused field obstacle states the rule it breaks', () {
    final project = _project();
    final oak = project.models3d.first;
    final slope = project.models3d.last;
    expect(
      spatialFieldObstacleRefusal(_instance('a', blocks: false), oak, null),
      startsWith('Activez la collision du décor'),
    );
    expect(
      spatialFieldObstacleRefusal(
        _instance('b', modelId: 'slope'),
        slope,
        null,
      ),
      startsWith('Une rampe sert à la traversée'),
    );
    expect(
      spatialFieldObstacleRefusal(
        _instance('c', entityId: 'npc'),
        oak,
        const MapEntity(
          id: 'npc',
          name: 'Guide',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
        ),
      ),
      startsWith('Ce décor porte déjà un autre élément du jeu'),
    );
    expect(spatialFieldObstacleRefusal(_instance('d'), null, null), isNotNull);
    expect(spatialFieldObstacleRefusal(_instance('e'), oak, null), isNull);
  });

  Future<EditableMapDocument> pump(
    WidgetTester tester,
    MapData map,
    Widget Function(EditableMapDocument document) build,
  ) async {
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'saved', mapId: 'a'),
    );
    tester.view.physicalSize = const Size(700, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(body: SingleChildScrollView(child: build(document))),
      ),
    );
    return document;
  }

  testWidgets(
    'the inspector names the roles and explains a disabled obstacle',
    (tester) async {
      final open = _instance('open', blocks: false);
      final map = _map([open]);
      await pump(
        tester,
        map,
        (document) => SpatialModelEntityControls(
          document: document,
          project: _project(),
          instance: open,
          onChanged: () {},
        ),
      );
      expect(find.text('Rôles de ce décor'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('spatial-model-role-traversal')),
          matching: find.text('Aucune collision : le joueur passe à travers.'),
        ),
        findsOneWidget,
      );
      final refusal = find.byKey(
        const ValueKey('spatial-model-field-obstacle-refusal'),
      );
      expect(refusal, findsOneWidget);
      expect(
        find.descendant(
          of: refusal,
          matching: find.textContaining('Activez la collision du décor'),
        ),
        findsOneWidget,
      );
      final select = tester.widget<DropdownButtonFormField<String>>(
        find.descendant(
          of: find.byKey(const ValueKey('spatial-model-field-obstacle')),
          matching: find.byType(DropdownButtonFormField<String>),
        ),
      );
      expect(select.onChanged, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a blocking decor cannot start a platform and says why', (
    tester,
  ) async {
    final wall = _instance('wall');
    final document = await pump(
      tester,
      _map([wall]),
      (document) => SpatialPlatformControls(
        document: document,
        project: _project(),
        instance: wall,
        onChanged: () {},
      ),
    );
    expect(
      find.text(
        'Pour en faire une plateforme, désactivez d’abord la collision du modèle complet.',
      ),
      findsOneWidget,
    );
    final create = tester.widget<StudioButton>(
      find.widgetWithText(StudioButton, 'Créer le trajet'),
    );
    expect(create.onPressed, isNull);
    expect(document.current.spatialScene!.platforms, isEmpty);
    expect(document.undoCount, 0);
    expect(tester.takeException(), isNull);
  });
}
