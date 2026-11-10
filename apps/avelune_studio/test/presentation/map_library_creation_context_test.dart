import 'dart:io';

import 'package:avelune_studio/features/project_creation/application/project_creation_controller.dart';
import 'package:avelune_studio/features/project_creation/application/project_template_contents.dart';
import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core_domain.dart';

import '../map_workspace/map_catalog_fixture.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<MapCatalogFixture> open({
    bool empty = false,
    ProjectDimension dimension = ProjectDimension.twoD,
  }) async {
    final root = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await root.create(recursive: true);
    final fixture = await MapCatalogFixture.create(
      parent: root,
      empty: empty,
      dimension: dimension,
    );
    addTearDown(fixture.dispose);
    return fixture;
  }

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

  test('a 3D map is created without a 2D default sheet', () async {
    final fixture = await open(empty: true, dimension: ProjectDimension.threeD);
    final result = await fixture.createMap('spatial');
    expect(result.integrated, isTrue, reason: result.error);
    await fixture.controller.activate(fixture.controller.project!.maps.single);
    final map = fixture.controller.active!.current;
    expect(map.tilesetId, isEmpty);
    expect(map.spatialScene, isNotNull);
    expect(map.size, const GridSize(width: 7, height: 5));
  });

  test('opening another map keeps the previous map and its history', () async {
    final fixture = await open();
    final controller = fixture.controller;
    final jardin = controller.project!.maps.singleWhere(
      (map) => map.id == 'jardin',
    );
    final clairiere = controller.project!.maps.singleWhere(
      (map) => map.id == 'clairiere',
    );
    await controller.activate(jardin);
    final previous = controller.active!;
    previous.commit(previous.current.copyWith(name: 'Jardin modifié'));
    expect(previous.canUndo, isTrue);
    await controller.activate(clairiere);
    expect(controller.active!.current.id, 'clairiere');
    expect(identical(controller.documents['jardin'], previous), isTrue);
    expect(controller.documents['jardin']!.canUndo, isTrue);
    expect(controller.documents['jardin']!.current.name, 'Jardin modifié');
  });

  test(
    'a duplicate map identity refuses creation without changing the files',
    () async {
      final fixture = await open();
      final original = fixture.controller.project!;
      final file = File('${fixture.root.path}/project.json');
      final bytes = await file.readAsBytes();
      final result = await fixture.createMap(original.maps.first.id);
      expect(result.published, isFalse);
      expect(result.integrated, isFalse);
      expect(result.error, isNotNull);
      expect(fixture.controller.project, same(original));
      expect(await file.readAsBytes(), bytes);
      expect(fixture.catalog.mutations, 1);
    },
  );

  test(
    'the creation request retains the chosen parent and suggested folder name',
    () {
      final controller = ProjectCreationController(offlineProjectCreation)
        ..setName('Mon aventure');
      addTearDown(controller.dispose);
      expect(controller.folderName, 'mon-aventure');
      expect(controller.request.parentPath, isEmpty);
      controller.parentPath = '/Projets';
      expect(controller.request.parentPath, '/Projets');
      expect(controller.request.folderName, 'mon-aventure');
      controller.setTemplate(ProjectCreationTemplate.empty);
      expect(controller.request.template, ProjectCreationTemplate.empty);
    },
  );

  test('a cancelled folder picker leaves no destination to create', () async {
    final controller = ProjectCreationController(offlineProjectCreation)
      ..setName('Mon aventure');
    addTearDown(controller.dispose);
    var picks = 0;
    await controller.chooseParent(() async {
      picks++;
      return null;
    });
    expect(picks, 1);
    expect(controller.parentPath, isEmpty);
    expect(controller.destination, isNull);
    expect(controller.receipt, isNull);
    expect(controller.selecting, isFalse);
    expect(controller.request.validate, throwsFormatException);
  });
}
