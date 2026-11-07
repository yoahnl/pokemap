import 'package:avelune_studio/features/project_creation/application/project_creation_controller.dart';
import 'package:avelune_studio/features/project_creation/application/project_template_contents.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_catalogue_creation_dialog.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_catalogue_workspace_actions.dart';
import 'package:avelune_studio/presentation/features/project_creation/project_creation_dialog.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_library_navigator.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_library_tree.dart';
import 'package:avelune_studio/presentation/features/project_creation/project_creation_steps.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart';
import '../support/synthetic_template_fixture.dart';

ProjectManifest _hgssScaleCatalogue() {
  const regions = ['Johto', 'Kanto'];
  final groups = <ProjectMapGroup>[
    for (final region in regions)
      ProjectMapGroup(
        id: region.toLowerCase(),
        name: region,
        type: MapGroupType.special,
      ),
    for (final region in regions)
      for (var town = 0; town < 6; town++)
        ProjectMapGroup(
          id: '${region.toLowerCase()}-$town',
          name: town == 0 ? 'Bourg Géon' : 'Ville $town',
          type: MapGroupType.city,
          parentGroupId: region.toLowerCase(),
          sortOrder: town,
        ),
  ];
  final maps = <ProjectMapEntry>[];
  for (var index = 0; index < 102; index++) {
    final region = regions[index % 2].toLowerCase();
    final town = (index ~/ 2) % 6;
    maps.add(
      ProjectMapEntry(
        id: 'map-$index',
        name: index == 0
            ? 'Maison du joueur — chambre à l’étage avec fenêtre'
            : 'Carte $index',
        relativePath: 'maps/map-$index.json',
        groupId: '$region-$town',
        sortOrder: index,
      ),
    );
  }
  return ProjectManifest(
    name: 'HGSS',
    maps: maps,
    groups: groups,
    tilesets: const [],
  );
}

Widget _host(Widget child) => MaterialApp(
  theme: studioTheme(),
  home: Scaffold(body: child),
);

class _NavigatorHost extends StatefulWidget {
  const _NavigatorHost({required this.project});
  final ProjectManifest project;
  @override
  State<_NavigatorHost> createState() => _NavigatorHostState();
}

class _NavigatorHostState extends State<_NavigatorHost> {
  String? active = 'map-0';
  final opened = <String>[];
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        height: 700,
        child: MapLibraryNavigator(
          project: widget.project,
          activeMapId: active,
          dirtyMapIds: const {},
          width: 300,
          onActivate: (entry) => setState(() {
            opened.add(entry.id);
            active = entry.id;
          }),
          onOrganize: null,
        ),
      ),
    ],
  );
}

void main() {
  testWidgets('the active map shows its full name and folder path', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(_NavigatorHost(project: _hgssScaleCatalogue())),
    );
    await tester.pump();

    final detail = find.byKey(const ValueKey('map-library-detail-map-0'));
    expect(detail, findsOneWidget);
    expect(
      find.descendant(
        of: detail,
        matching: find.text(
          'Maison du joueur — chambre à l’étage avec fenêtre',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: detail,
        matching: find.textContaining('Johto / Bourg Géon'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('map-library-detail-map-2')),
      findsNothing,
    );
  });

  test('search reads folders and names without accents or case', () {
    final project = _hgssScaleCatalogue();
    List<String> found(String query) => [
      for (final row in MapLibraryTree(
        groups: project.groups,
        maps: project.maps,
        query: query,
      ).rows)
        if (row.map != null) row.map!.id,
    ];

    final byFolder = found('bourg geon');
    expect(byFolder, isNotEmpty);
    expect(
      byFolder.every(
        (id) => {
          'johto-0',
          'kanto-0',
        }.contains(project.maps.singleWhere((map) => map.id == id).groupId),
      ),
      isTrue,
    );
    expect(found('kanto geon').every((id) => id.isNotEmpty), isTrue);
    expect(
      found('KANTO GÉON')
          .map((id) => project.maps.singleWhere((map) => map.id == id).groupId),
      everyElement('kanto-0'),
    );
    expect(found('etage'), ['map-0']);
  });

  testWidgets('opening a map in another folder keeps the open folders', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(_NavigatorHost(project: _hgssScaleCatalogue())),
    );
    await tester.pump();
    await tester.tap(find.text('Bourg Géon').first);
    await tester.pump();
    expect(find.byKey(const ValueKey('map-library-map-0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('map-library-map-2')));
    await tester.pump();

    final host = tester.state<_NavigatorHostState>(find.byType(_NavigatorHost));
    expect(host.opened, ['map-2']);
    expect(find.byKey(const ValueKey('map-library-map-0')), findsNothing);
    expect(find.byKey(const ValueKey('map-library-map-14')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-library-detail-map-2')),
      findsOneWidget,
    );
  });

  Future<void> openNewMapDialog(
    WidgetTester tester,
    ProjectManifest project,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showNewMapDialog(
              context,
              project: project,
              onCreate: ({
                required name,
                required width,
                required height,
                required role,
                groupId,
                tilesetId,
              }) async => null,
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  final sheets = [
    const ProjectTilesetEntry(
      id: 'player-sheet',
      name: 'Joueur',
      relativePath: 'assets/player.png',
      sortOrder: 0,
    ),
    const ProjectTilesetEntry(
      id: 'grounds',
      name: 'Sols de Johto',
      relativePath: 'assets/grounds.png',
      sortOrder: 1,
    ),
  ];
  const character = ProjectCharacterEntry(
    id: 'player',
    name: 'Joueur',
    tilesetId: 'player-sheet',
  );

  testWidgets('a 3D map is created without the 2D sheet its API refuses', (
    tester,
  ) async {
    await openNewMapDialog(
      tester,
      ProjectManifest(
        name: '3D',
        version: ProjectVersion.v9,
        maps: const [],
        tilesets: sheets,
        characters: const [character],
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      ),
    );
    expect(find.text('Planche par défaut'), findsNothing);
    expect(
      find.textContaining('Une carte 3D n’utilise pas de planche'),
      findsOneWidget,
    );
  });

  testWidgets('a 2D map names what its default sheet is used for', (
    tester,
  ) async {
    await openNewMapDialog(
      tester,
      ProjectManifest(
        name: '2D',
        maps: const [],
        tilesets: sheets,
        characters: const [character],
      ),
    );
    expect(find.text('Planche par défaut'), findsOneWidget);
    expect(
      find.textContaining('tuiles de cette carte qui ne désignent pas'),
      findsOneWidget,
    );
    final options = newMapSheetOptions(
      ProjectManifest(
        name: '2D',
        maps: const [],
        tilesets: sheets,
        characters: const [character],
      ),
    );
    expect(options.keys.toList(), ['', 'grounds', 'player-sheet']);
    expect(options['grounds'], 'Décor · Sols de Johto');
    expect(options['player-sheet'], 'Personnage · Joueur');
  });

  test('each template states what it really contains before creation', () {
    final playable = projectTemplateContents(
      dimension: ProjectDimension.twoD,
      template: ProjectCreationTemplate.playable,
      width: '20',
      height: '15',
    );
    expect(playable.rows['Carte'], 'Première carte, 20 × 15 cases');
    expect(playable.rows['Personnage joueur'], 'Inclus');
    expect(playable.rows['Départ du joueur'], 'Inclus sur la première carte');
    expect(playable.rows['Pokémon'], 'Désactivés, activables ensuite');
    expect(playable.beforeTest, contains('Tester la carte'));
    expect(playable.beforeTest, isNot(contains('prêt à tester')));

    final empty = projectTemplateContents(
      dimension: ProjectDimension.twoD,
      template: ProjectCreationTemplate.empty,
      width: '20',
      height: '15',
    );
    expect(empty.rows['Carte'], 'Aucune');
    expect(empty.rows['Personnage joueur'], 'Aucun');
    expect(empty.beforeTest, contains('une carte, un personnage et un départ'));

    final spatial = projectTemplateContents(
      dimension: ProjectDimension.threeD,
      template: ProjectCreationTemplate.empty,
      width: '20',
      height: '15',
    );
    expect(
      spatial.rows['Carte'],
      'Première carte 3D, terrain plat de 20 × 15 cases',
    );
    expect(spatial.rows['Personnage joueur'], 'Aucun');

    final catalogue = projectTemplateContents(
      dimension: ProjectDimension.twoD,
      template: ProjectCreationTemplate.catalogue,
      width: '12',
      height: '10',
      catalogueLabel: 'Template Alpha',
    );
    expect(
      catalogue.rows['Personnage joueur'],
      'Fourni par Template Alpha, détaillé après création',
    );
  });

  testWidgets(
    'the model step compares contents and the first step previews the path',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = ProjectCreationController(offlineProjectCreation)
        ..setName('Mon aventure');
      addTearDown(controller.dispose);
      Future<void> show() async {
        await tester.pumpWidget(
          _host(
            SingleChildScrollView(
              child: ProjectCreationSteps(
                controller: controller,
                chooseParent: () async {},
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await show();
      expect(find.text('Nom du projet'), findsOneWidget);
      expect(find.textContaining('mon-aventure'), findsWidgets);
      expect(
        find.textContaining('Emplacement choisi à la dernière étape'),
        findsOneWidget,
      );
      controller.parentPath = '/Projets';
      await show();
      expect(find.text('/Projets/mon-aventure'), findsOneWidget);

      controller.next();
      await show();
      expect(
        find.byKey(const ValueKey('creation-template-contents')),
        findsOneWidget,
      );
      expect(find.text('Personnage joueur'), findsOneWidget);
      expect(find.text('Inclus'), findsOneWidget);
      controller.setTemplate(ProjectCreationTemplate.empty);
      await show();
      expect(find.text('Aucun'), findsWidgets);
      expect(find.textContaining('prêt à tester'), findsNothing);
    },
  );

  testWidgets('opening another map keeps the previous map and its history', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() => M2UiFixture.create(tester)))!;
    addTearDown(fixture.dispose);
    final controller = fixture.controller;
    final jardin = controller.project!.maps.singleWhere(
      (map) => map.id == 'jardin',
    );
    final clairiere = controller.project!.maps.singleWhere(
      (map) => map.id == 'clairiere',
    );
    await tester.runAsync(() => controller.activate(jardin));
    final previous = controller.active!;
    previous.commit(previous.current.copyWith(name: 'Jardin modifié'));
    expect(previous.canUndo, isTrue);

    await tester.runAsync(() => controller.activate(clairiere));

    expect(controller.active!.current.id, 'clairiere');
    expect(identical(controller.documents['jardin'], previous), isTrue);
    expect(controller.documents['jardin']!.canUndo, isTrue);
    expect(controller.documents['jardin']!.current.name, 'Jardin modifié');
  });

  test('renaming names the stable identity that passages keep using', () {
    final note = mapRenameIdentityNote(
      const ProjectMapEntry(
        id: 'bourg-geon',
        name: 'Bourg Geon',
        relativePath: 'maps/bourg-geon.json',
      ),
    );
    expect(note, contains('« bourg-geon »'));
    expect(note, contains('passages'));
  });

  testWidgets('a refused new map keeps the form open and creates nothing', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showNewMapDialog(
              context,
              project: const ProjectManifest(
                name: '2D',
                maps: [],
                tilesets: [],
              ),
              onCreate:
                  ({
                    required name,
                    required width,
                    required height,
                    required role,
                    groupId,
                    tilesetId,
                  }) async {
                    calls.add(name);
                    return 'Une carte porte déjà cet identifiant.';
                  },
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    StudioButton create() => tester.widget<StudioButton>(
      find.widgetWithText(StudioButton, 'Créer la carte'),
    );
    expect(create().onPressed, isNull);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('new-map-name')),
        matching: find.byType(TextField),
      ),
      'Route 29',
    );
    await tester.pump();
    expect(create().onPressed, isNotNull);
    await tester.tap(find.widgetWithText(StudioButton, 'Créer la carte'));
    await tester.pumpAndSettle();
    expect(calls, ['Route 29']);
    expect(find.text('Une carte porte déjà cet identifiant.'), findsOneWidget);
    expect(find.text('Nouvelle carte'), findsOneWidget);
  });

  testWidgets('a cancelled folder picker leaves no destination to create', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var picks = 0;
    await tester.pumpWidget(
      _host(
        ProjectCreationDialog(
          port: offlineProjectCreation,
          chooseParent: () async {
            picks++;
            return null;
          },
          openCreated: (_) async => false,
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom du projet'),
      'Mon aventure',
    );
    for (var step = 0; step < 3; step++) {
      await tester.tap(find.text('Suivant'));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.byKey(const ValueKey('creation-choose-parent')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(picks, 1);
    expect(find.text('Aucun dossier choisi'), findsOneWidget);
    expect(
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('create-project-confirm')),
          )
          .onPressed,
      isNull,
    );
  });
}
