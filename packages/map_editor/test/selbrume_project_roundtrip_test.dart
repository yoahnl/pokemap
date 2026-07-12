import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../tool/generate_selbrume_canonical_maps.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('check is read-only and write is byte-idempotent through task4',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));

    final projectFile = File(p.join(fixture.path, 'project.json'));
    final beforeProject = projectFile.readAsStringSync();

    final checkResult = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture),
    );
    expect(checkResult.exitCode, selbrumeGeneratorDivergenceExitCode);
    expect(checkResult.divergentRelativePaths, hasLength(11));
    expect(projectFile.readAsStringSync(), beforeProject);
    expect(_canonicalMapFiles(fixture), isEmpty);

    final writeResult = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture, write: true),
    );
    expect(writeResult.exitCode, 0);
    expect(writeResult.divergentRelativePaths, isEmpty);

    final firstWrite = <String, List<int>>{
      'project.json': projectFile.readAsBytesSync(),
      for (final file in _canonicalMapFiles(fixture))
        p.relative(file.path, from: fixture.path): file.readAsBytesSync(),
    };
    expect(firstWrite, hasLength(11));

    final secondWriteResult = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture, write: true),
    );
    expect(secondWriteResult.exitCode, 0);
    expect(secondWriteResult.divergentRelativePaths, isEmpty);

    final secondWrite = <String, List<int>>{
      'project.json': projectFile.readAsBytesSync(),
      for (final file in _canonicalMapFiles(fixture))
        p.relative(file.path, from: fixture.path): file.readAsBytesSync(),
    };
    expect(secondWrite, firstWrite);

    final cleanCheck = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture),
    );
    expect(cleanCheck.exitCode, 0);
    expect(cleanCheck.divergentRelativePaths, isEmpty);
    expect(
      fixture
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => p.basename(file.path).contains('.selbrume-tmp-')),
      isEmpty,
    );
  });

  test('preserves seed fingerprints and builds valid canonical skeletons',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));

    final sourceBourg = _readJson(
      File(p.join(fixture.path, 'maps', 'Selbrume.json')),
    );
    final sourceMarais = _readJson(
      File(p.join(fixture.path, 'maps', 'route 1.json')),
    );

    final result = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture, write: true),
    );
    expect(result.exitCode, 0);

    final maps = <String, MapData>{};
    for (final file in _canonicalMapFiles(fixture)) {
      final raw = _readJson(file);
      final map = MapData.fromJson(raw);
      expect(() => MapValidator.validate(map), returnsNormally);
      maps[map.id] = map;
    }
    expect(maps.keys, unorderedEquals(canonicalSelbrumeMapIds));

    final bourgRaw = _readJson(
      File(p.join(fixture.path, 'maps', 'map_bourg_selbrume.json')),
    );
    final maraisRaw = _readJson(
      File(p.join(fixture.path, 'maps', 'map_marais_salants.json')),
    );
    expect(_seedFingerprint(bourgRaw), _seedFingerprint(sourceBourg));
    expect(_seedFingerprint(maraisRaw), _seedFingerprint(sourceMarais));

    expect(maps['map_bourg_selbrume']!.connections, hasLength(2));
    expect(
      maps['map_bourg_selbrume']!.warps.single,
      isA<MapWarp>()
          .having((warp) => warp.id, 'id', 'warp_bourg_to_maison')
          .having(
            (warp) => warp.targetMapId,
            'targetMapId',
            'map_maison_joueur',
          ),
    );
    expect(maps['map_marais_salants']!.connections, hasLength(2));
    expect(maps['map_marais_salants']!.entities.map((entity) => entity.id),
        contains('grant'));
    expect(maps['map_marais_salants']!.gameplayZones, hasLength(5));

    const exteriorSkeletons = <String>{
      'map_port_brisants',
      'map_bois_chaise_brume',
      'map_passage_dames',
      'map_phare_exterieur',
    };
    const interiorSkeletons = <String>{
      'map_phare_interieur',
      'map_sommet_phare',
      'map_cabane_gardien',
      'map_maison_joueur',
    };
    for (final mapId in exteriorSkeletons) {
      _expectLayerContract(maps[mapId]!, exterior: true);
    }
    for (final mapId in interiorSkeletons) {
      _expectLayerContract(maps[mapId]!, exterior: false);
    }

    for (final map in maps.values) {
      expect(map.mapMetadata.tags,
          containsAllInOrder(<String>['selbrume', 'beta', 'map-production']));
      for (final connection in map.connections) {
        expect(connection.targetMapId, isNot(map.id));
        expect(connection.offset, 0);
      }
      for (final warp in map.warps) {
        expect(warp.targetMapId, isNot(map.id));
        final target = maps[warp.targetMapId]!;
        expect(warp.targetPos.x, inInclusiveRange(0, target.size.width - 1));
        expect(warp.targetPos.y, inInclusiveRange(0, target.size.height - 1));
      }
    }

    expect(
      maps['map_maison_joueur']!.entities.where(
            (entity) => entity.id == 'spawn_maison_joueur',
          ),
      hasLength(1),
    );
  });

  test('writes ten maps and six groups without rewriting other manifest text',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    final projectFile = File(p.join(fixture.path, 'project.json'));
    final before = projectFile.readAsStringSync();

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture, write: true),
    );

    final after = projectFile.readAsStringSync();
    expect(_maskManifestArrays(after), _maskManifestArrays(before));

    final manifest = ProjectManifest.fromJson(_readJson(projectFile));
    expect(() => ProjectValidator.validate(manifest), returnsNormally);
    // The checked-in Task 16 manifest is already cut over to the canonical
    // catalog. The fixture removes that catalog before exercising Task 4, so
    // the expected result is the ten canonical maps and six canonical groups
    // themselves, not the retired pre-cutover entries plus the new catalog.
    expect(manifest.maps, hasLength(10));
    expect(manifest.groups, hasLength(6));
    for (final mapId in canonicalSelbrumeMapIds) {
      expect(manifest.maps.where((entry) => entry.id == mapId), hasLength(1));
    }
    for (final groupId in canonicalSelbrumeGroupIds) {
      expect(
        manifest.groups.where((group) => group.id == groupId),
        hasLength(1),
      );
    }
    expect(manifest.maps.map((entry) => entry.id), canonicalSelbrumeMapIds);
    expect(manifest.groups.map((group) => group.id), canonicalSelbrumeGroupIds);
  });

  test('parses explicit project root, write mode, and task4 boundary', () {
    final options = parseSelbrumeGeneratorOptions(
      <String>[
        '--project-root',
        '/tmp/selbrume',
        '--through',
        'task4',
        '--write',
      ],
    );
    expect(options.projectRoot.path, p.normalize('/tmp/selbrume'));
    expect(options.through, 'task4');
    expect(options.write, isTrue);

    final task5 = parseSelbrumeGeneratorOptions(
      <String>[
        '--project-root',
        '/tmp/selbrume',
        '--through',
        'task5',
      ],
    );
    expect(task5.through, 'task5');
    expect(task5.write, isFalse);

    final task6 = parseSelbrumeGeneratorOptions(
      <String>[
        '--project-root',
        '/tmp/selbrume',
        '--through',
        'task6',
      ],
    );
    expect(task6.through, 'task6');
    expect(task6.write, isFalse);

    for (final boundary in const <String>[
      'task7',
      'task8',
      'task9',
      'task10',
      'task11',
      'task12',
      'task13',
      'task14',
      'task15',
      'task16',
    ]) {
      final options = parseSelbrumeGeneratorOptions(
        <String>['--project-root', '/tmp/selbrume', '--through', boundary],
      );
      expect(options.through, boundary);
      expect(options.write, isFalse);
    }

    expect(
      () => parseSelbrumeGeneratorOptions(
        <String>['--project-root', '/tmp/selbrume', '--through', 'task17'],
      ),
      throwsFormatException,
    );
  });

  test('task4 does not require task5-only manifest data or PNGs', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    final projectFile = File(p.join(fixture.path, 'project.json'));
    final project = _readJson(projectFile)..remove('pathPatternPresets');
    projectFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(project)}\n',
    );
    Directory(p.join(fixture.path, 'assets')).deleteSync(recursive: true);

    final result = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture),
    );

    expect(result.exitCode, selbrumeGeneratorDivergenceExitCode);
    expect(result.divergentRelativePaths, hasLength(11));
  });

  test('rejects a maps directory symlink that escapes the project root',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    final mapsDirectory = Directory(p.join(fixture.path, 'maps'));
    final seedBackups = Directory(p.join(fixture.path, 'seed_backups'))
      ..createSync();
    for (final fileName in const <String>['Selbrume.json', 'route 1.json']) {
      File(p.join(mapsDirectory.path, fileName)).copySync(
        p.join(seedBackups.path, fileName),
      );
    }
    mapsDirectory.deleteSync(recursive: true);
    final escapedMaps = Directory(p.join(fixture.parent.path, 'escaped_maps'))
      ..createSync();
    for (final fileName in const <String>['Selbrume.json', 'route 1.json']) {
      Link(p.join(escapedMaps.path, fileName)).createSync(
        p.join(seedBackups.path, fileName),
      );
    }
    Link(mapsDirectory.path).createSync(escapedMaps.path);
    final before = _snapshotFiles(fixture);

    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, write: true),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('maps'), contains('escapes the project root')),
        ),
      ),
    );

    expect(_snapshotFiles(fixture), before);
    expect(
      File(p.join(escapedMaps.path, 'map_port_brisants.json')).existsSync(),
      isFalse,
    );
  });

  test('check is read-only and write is byte-idempotent through task5',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    final legacySeeds = <String, List<int>>{
      for (final fileName in const <String>['Selbrume.json', 'route 1.json'])
        fileName:
            File(p.join(fixture.path, 'maps', fileName)).readAsBytesSync(),
    };
    final before = _snapshotFiles(fixture);

    final checkResult = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task5',
      ),
    );
    expect(checkResult.exitCode, selbrumeGeneratorDivergenceExitCode);
    expect(checkResult.divergentRelativePaths, hasLength(11));
    expect(_snapshotFiles(fixture), before);

    final writeResult = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task5',
        write: true,
      ),
    );
    expect(writeResult.exitCode, 0);
    expect(writeResult.divergentRelativePaths, isEmpty);
    final firstWrite = _snapshotFiles(fixture);

    final secondWriteResult = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task5',
        write: true,
      ),
    );
    expect(secondWriteResult.exitCode, 0);
    expect(secondWriteResult.divergentRelativePaths, isEmpty);
    expect(_snapshotFiles(fixture), firstWrite);

    final cleanCheck = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task5',
      ),
    );
    expect(cleanCheck.exitCode, 0);
    expect(cleanCheck.divergentRelativePaths, isEmpty);

    for (final entry in const <String, String>{
      'map_bourg_selbrume': 'Selbrume.json',
      'map_marais_salants': 'route 1.json',
    }.entries) {
      final mapId = entry.key;
      final map = _readJson(File(p.join(fixture.path, 'maps', '$mapId.json')));
      final seed = _readJson(File(p.join(fixture.path, 'maps', entry.value)));
      expect(
        (map['layers'] as List<dynamic>).where((layer) =>
            (layer as Map<String, dynamic>)['id'] == 'l_tile_objectif'),
        isEmpty,
      );
      expect(
        (map['placedElements'] as List<dynamic>).where(
          (placed) =>
              (placed as Map<String, dynamic>)['layerId'] == 'l_tile_objectif',
        ),
        isEmpty,
      );
      expect(
        map['layers'],
        (seed['layers'] as List<dynamic>)
            .where(
              (layer) =>
                  (layer as Map<String, dynamic>)['id'] != 'l_tile_objectif',
            )
            .toList(growable: false),
      );
      expect(
        map['placedElements'],
        (seed['placedElements'] as List<dynamic>)
            .where(
              (placed) =>
                  (placed as Map<String, dynamic>)['layerId'] !=
                  'l_tile_objectif',
            )
            .toList(growable: false),
      );
    }
    for (final entry in legacySeeds.entries) {
      expect(
        File(p.join(fixture.path, 'maps', entry.key)).readAsBytesSync(),
        entry.value,
        reason: '${entry.key} must remain byte-identical',
      );
    }
  });

  test('task5 patches only the five owned manifest arrays', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    final projectFile = File(p.join(fixture.path, 'project.json'));
    final before = projectFile.readAsStringSync();

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task5',
        write: true,
      ),
    );

    final after = projectFile.readAsStringSync();
    expect(_maskTask5ManifestArrays(after), _maskTask5ManifestArrays(before));
  });

  test('task5 missing PNG fails before mutating the project', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    File(
      p.join(fixture.path, 'assets', 'tilesets', 'selbrume_boat.png'),
    ).deleteSync();
    final before = _snapshotFiles(fixture);

    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: fixture,
          through: 'task5',
          write: true,
        ),
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(_snapshotFiles(fixture), before);
  });

  test('task5 malformed PNG dimensions fail before mutating the project',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    File(
      p.join(fixture.path, 'assets', 'tilesets', 'selbrume_open_sea_loop.png'),
    ).copySync(
      p.join(fixture.path, 'assets', 'tilesets', 'selbrume_boat.png'),
    );
    final before = _snapshotFiles(fixture);

    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: fixture,
          through: 'task5',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('selbrume_boat.png'), contains('160x224')),
        ),
      ),
    );
    expect(_snapshotFiles(fixture), before);
  });

  test(
      'task6 is read-only in check mode and byte-idempotent with a synthetic port atlas',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    final legacySeeds = <String, List<int>>{
      for (final fileName in const <String>['Selbrume.json', 'route 1.json'])
        fileName:
            File(p.join(fixture.path, 'maps', fileName)).readAsBytesSync(),
    };
    final before = _snapshotFiles(fixture);

    final checkResult = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task6',
      ),
    );
    expect(checkResult.exitCode, selbrumeGeneratorDivergenceExitCode);
    expect(checkResult.divergentRelativePaths, isNotEmpty);
    expect(_snapshotFiles(fixture), before);

    final writeResult = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task6',
        write: true,
      ),
    );
    expect(writeResult.exitCode, 0);
    expect(writeResult.divergentRelativePaths, isEmpty);
    final firstWrite = _snapshotFiles(fixture);

    final secondWrite = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task6',
        write: true,
      ),
    );
    expect(secondWrite.exitCode, 0);
    expect(secondWrite.divergentRelativePaths, isEmpty);
    expect(_snapshotFiles(fixture), firstWrite);

    final cleanCheck = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task6',
      ),
    );
    expect(cleanCheck.exitCode, 0);
    expect(cleanCheck.divergentRelativePaths, isEmpty);
    for (final entry in legacySeeds.entries) {
      expect(
        File(p.join(fixture.path, 'maps', entry.key)).readAsBytesSync(),
        entry.value,
        reason: '${entry.key} must remain byte-identical through task6',
      );
    }
    expect(
      fixture
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => p.basename(file.path).contains('.selbrume-tmp-')),
      isEmpty,
    );
  });

  test('task6 registers the port atlas and all sixteen element contracts',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task6',
        write: true,
      ),
    );

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    expect(() => ProjectValidator.validate(manifest), returnsNormally);
    expect(
      manifest.tilesetFolders.where((entry) => entry.id == 'tsf_selbrume_beta'),
      hasLength(1),
    );
    final portFolders = manifest.tilesetFolders
        .where((entry) => entry.id == 'tsf_selbrume_beta_port');
    expect(portFolders, hasLength(1));
    expect(portFolders.single.parentFolderId, 'tsf_selbrume_beta');
    final categories = manifest.elementCategories
        .where((entry) => entry.id == 'cat_selbrume_port_props');
    expect(categories, hasLength(1));
    expect(categories.single.parentCategoryId, 'props');

    final tilesets = manifest.tilesets
        .where((entry) => entry.id == 'ts_selbrume_port_props');
    expect(tilesets, hasLength(1));
    expect(
      tilesets.single.relativePath,
      'assets/tilesets/selbrume_port_props.png',
    );
    expect(tilesets.single.folderId, 'tsf_selbrume_beta_port');

    final elements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (_portElementContracts.containsKey(element.id)) element.id: element,
    };
    expect(elements.keys, unorderedEquals(_portElementContracts.keys));
    for (final contract in _portElementContracts.entries) {
      final element = elements[contract.key]!;
      expect(element.tilesetId, 'ts_selbrume_port_props');
      expect(element.categoryId, 'cat_selbrume_port_props');
      expect(element.frames, hasLength(1));
      expect(element.frames.single.source, contract.value.source);
      expect(element.frames.single.durationMs, isNull);
      expect(element.recommendedLayerId, contract.value.layerId);
      expect(
        element.tags,
        containsAll(<String>[
          'environment',
          'map_port_brisants',
          'beta',
          contract.key.contains('nid_') ? 'state_variant' : 'static',
        ]),
      );
      if (contract.value.collisionCells.isEmpty) {
        expect(element.collisionProfile, isNull, reason: contract.key);
      } else {
        final profile = element.collisionProfile!;
        expect(profile.source, ElementCollisionProfileSource.manual);
        expect(profile.cells, contract.value.collisionCells,
            reason: contract.key);
        expect(profile.shapeCells, contract.value.collisionCells,
            reason: contract.key);
        expect(profile.visualMask, isNotNull, reason: contract.key);
        expect(profile.collisionMask, isNotNull, reason: contract.key);
        if (contract.value.requiresOcclusion) {
          expect(profile.occlusionMask, isNotNull, reason: contract.key);
        }
      }
    }
  });

  test('task6 patches only its seven owned manifest arrays', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    final before = projectFile.readAsStringSync();

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task6',
        write: true,
      ),
    );

    final after = projectFile.readAsStringSync();
    expect(_maskTask6ManifestArrays(after), _maskTask6ManifestArrays(before));
  });

  test('rejects task6 downgrades instead of producing boundary hybrids',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task6',
        write: true,
      ),
    );
    final before = _snapshotFiles(fixture);

    for (final lowerBoundary in const <String>['task5', 'task4']) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lowerBoundary,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('task6'),
              contains(lowerBoundary),
              contains('downgrade'),
            ),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), before);
    }
  });

  test('task6 builds the connected and collision-safe Port des Brisants pilot',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task6',
        write: true,
      ),
    );

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    final port = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_port_brisants.json'))),
    );
    expect(() => MapValidator.validate(port, projectDialogueContext: manifest),
        returnsNormally);
    expect(port.size, const GridSize(width: 45, height: 45));
    expect(port.mapMetadata.isIndoor, isFalse);
    expect(
      port.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_path_primary',
        'l_path_secondary',
        'l_tile_ground',
        'l_tile_structures',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    expect(port.tilesetId, isEmpty);
    final primary = port.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_primary');
    final water = port.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_secondary');
    final collisions = port.layers.whereType<CollisionLayer>().single;
    expect(water.presetId, 'nouveau-chemin');
    for (var index = 0; index < primary.cells.length; index += 1) {
      if (!primary.cells[index]) continue;
      final x = index % 45;
      final y = index ~/ 45;
      expect(water.cells[index], isFalse,
          reason: 'primary path overlaps water at ($x,$y)');
      expect(collisions.collisions[index], isFalse,
          reason: 'primary path has static collision at ($x,$y)');
    }
    for (var x = 26; x <= 30; x += 1) {
      expect(primary.cells[x], isTrue, reason: 'north corridor x=$x');
      expect(collisions.collisions[x], isFalse, reason: 'north corridor x=$x');
    }
    for (var y = 29; y <= 39; y += 1) {
      for (var x = 25; x <= 27; x += 1) {
        final index = y * 45 + x;
        expect(primary.cells[index], isTrue, reason: 'main quay ($x,$y)');
        expect(water.cells[index], isFalse,
            reason: 'main quay must not be water ($x,$y)');
        expect(collisions.collisions[index], isFalse,
            reason: 'main quay must be walkable ($x,$y)');
      }
    }

    expect(
      port.connections,
      <MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.north,
          targetMapId: 'map_bourg_selbrume',
        ),
      ],
    );
    final bourg = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_bourg_selbrume.json'))),
    );
    expect(
      bourg.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.south &&
            connection.targetMapId == port.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );
    final bourgPortPath = bourg.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_path');
    final bourgOcean = bourg.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_oc_an');
    final bourgCollisions = bourg.layers
        .whereType<CollisionLayer>()
        .singleWhere((layer) => layer.id == 'l_collisions');
    for (var y = 46; y <= 54; y += 1) {
      for (var x = 26; x <= 30; x += 1) {
        final index = y * bourg.size.width + x;
        expect(bourgPortPath.cells[index], isTrue,
            reason: 'Bourg causeway to Port ($x,$y)');
        expect(bourgOcean.cells[index], isFalse,
            reason: 'Bourg causeway must not remain ocean ($x,$y)');
        expect(bourgCollisions.collisions[index], isFalse,
            reason: 'Bourg causeway must be walkable ($x,$y)');
      }
    }

    _expectSpecialZone(port, 'zone_port_entry', 24, 0, 8, 5);
    _expectSpecialZone(port, 'zone_port_center', 17, 16, 12, 10);
    _expectReservedTrigger(
      port,
      'zone_port_entry',
      'event_enter_port_alert',
      24,
      0,
      8,
      5,
    );
    _expectReservedTrigger(
      port,
      'zone_port_center',
      'event_ending_port',
      17,
      16,
      12,
      10,
    );
    _expectReservedTrigger(
      port,
      'tr_port_rival_scene',
      'event_selbrume_port_rival_scene',
      17,
      17,
      10,
      8,
    );
    _expectReservedTrigger(
      port,
      'tr_port_nest',
      'event_selbrume_port_nest',
      6,
      5,
      2,
      2,
    );
    expect(
      port.gameplayZones.map((zone) => zone.id),
      unorderedEquals(<String>['zone_port_entry', 'zone_port_center']),
    );
    expect(
      port.triggers.map((trigger) => trigger.id),
      unorderedEquals(<String>[
        'zone_port_entry',
        'zone_port_center',
        'tr_port_rival_scene',
        'tr_port_nest',
      ]),
    );

    _expectPlacedElement(
      port,
      id: 'pe_port_bateau',
      elementId: 'el_selbrume_port_bateau',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 3, y: 30),
    );
    final nest = _expectPlacedElement(
      port,
      id: 'pe_port_nid_goelise',
      elementId: 'el_selbrume_port_nid_vide',
      layerId: 'l_tile_ground',
      pos: const GridPos(x: 6, y: 5),
    );
    expect(nest.behaviors, isEmpty);
    expect(nest.properties, <String, String>{
      'eventId': 'event_goelise_nest_found',
      'reservedForNarrative': 'true',
    });
    expect(
      port.placedElements.map((placed) => placed.elementId),
      containsAll(<String>[
        'el_selbrume_port_quai_droit',
        'el_selbrume_port_quai_angle',
        'el_selbrume_port_quai_t',
        'el_selbrume_port_quai_fin',
        'el_selbrume_port_escalier_quai',
        'el_selbrume_port_brise_lames',
        'el_selbrume_port_hangar',
        'el_selbrume_port_bollard',
        'el_selbrume_port_corde',
        'el_selbrume_port_filets',
        'el_selbrume_port_caisses',
        'el_selbrume_port_tonneaux',
        'el_selbrume_port_bouees',
        'el_selbrume_port_nid_vide',
        'el_selbrume_port_panneau',
      ]),
    );
    expect(
      port.placedElements.where(
          (placed) => placed.elementId == 'el_selbrume_port_nid_brillant'),
      isEmpty,
    );

    _expectStructuralAnchor(port, 'anchor_port_lysa', 22, 21);
    _expectStructuralAnchor(port, 'anchor_port_soline', 34, 8);
    _expectStructuralAnchor(port, 'anchor_port_pecheurs', 8, 18);
    expect(port.events, isEmpty);

    const rivalStage = MapRect(
      pos: GridPos(x: 17, y: 17),
      size: GridSize(width: 10, height: 8),
    );
    for (var y = rivalStage.pos.y;
        y < rivalStage.pos.y + rivalStage.size.height;
        y += 1) {
      for (var x = rivalStage.pos.x;
          x < rivalStage.pos.x + rivalStage.size.width;
          x += 1) {
        expect(collisions.collisions[y * 45 + x], isFalse,
            reason: 'rival stage ($x,$y)');
      }
    }
    for (final placed in port.placedElements) {
      final element = manifest.elements.singleWhere(
        (entry) => entry.id == placed.elementId,
      );
      expect(
        _rectanglesOverlap(
          rivalStage,
          MapRect(
            pos: placed.pos,
            size: GridSize(
              width: element.frames.single.source.width,
              height: element.frames.single.source.height,
            ),
          ),
        ),
        isFalse,
        reason: '${placed.id} intrudes into the rival stage',
      );
    }
    for (var y = 30; y < 37; y += 1) {
      for (var x = 3; x < 8; x += 1) {
        expect(water.cells[y * 45 + x], isTrue,
            reason: 'boat must remain entirely over water ($x,$y)');
      }
    }
  });

  test('task6 missing or malformed port atlas fails before any mutation',
      () async {
    final missingFixture = _copySelbrumeFixture();
    addTearDown(() => missingFixture.parent.delete(recursive: true));
    final missingBefore = _snapshotFiles(missingFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: missingFixture,
          through: 'task6',
        ),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.path,
          'path',
          endsWith('selbrume_port_props.png'),
        ),
      ),
    );
    expect(_snapshotFiles(missingFixture), missingBefore);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: missingFixture,
          through: 'task6',
          write: true,
        ),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.path,
          'path',
          endsWith('selbrume_port_props.png'),
        ),
      ),
    );
    expect(_snapshotFiles(missingFixture), missingBefore);

    final malformedFixture = _copySelbrumeFixture();
    addTearDown(() => malformedFixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(malformedFixture, width: 32, height: 32);
    final malformedBefore = _snapshotFiles(malformedFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: malformedFixture,
          through: 'task6',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('selbrume_port_props.png'), contains('512x512')),
        ),
      ),
    );
    expect(_snapshotFiles(malformedFixture), malformedBefore);

    final rgbFixture = _copySelbrumeFixture();
    addTearDown(() => rgbFixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(rgbFixture, numChannels: 3);
    final rgbBefore = _snapshotFiles(rgbFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: rgbFixture,
          through: 'task6',
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('selbrume_port_props.png'), contains('8-bit RGBA')),
        ),
      ),
    );
    expect(_snapshotFiles(rgbFixture), rgbBefore);

    final transparentSlotFixture = _copySelbrumeFixture();
    addTearDown(
      () => transparentSlotFixture.parent.delete(recursive: true),
    );
    _writeSyntheticPortAtlas(transparentSlotFixture);
    _clearPortAtlasPixels(
      transparentSlotFixture,
      x: 0,
      y: 0,
      width: 128,
      height: 64,
    );
    final transparentSlotBefore = _snapshotFiles(transparentSlotFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: transparentSlotFixture,
          through: 'task6',
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('el_selbrume_port_quai_droit'),
            contains('no visible pixels'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(transparentSlotFixture), transparentSlotBefore);

    final incoherentCollisionFixture = _copySelbrumeFixture();
    addTearDown(
      () => incoherentCollisionFixture.parent.delete(recursive: true),
    );
    _writeSyntheticPortAtlas(incoherentCollisionFixture);
    _clearPortAtlasPixels(
      incoherentCollisionFixture,
      x: 3 * 32,
      y: 4 * 32,
      width: 32,
      height: 32,
    );
    final incoherentCollisionBefore =
        _snapshotFiles(incoherentCollisionFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: incoherentCollisionFixture,
          through: 'task6',
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('el_selbrume_port_brise_lames'),
            contains('collision cell (0, 1)'),
          ),
        ),
      ),
    );
    expect(
      _snapshotFiles(incoherentCollisionFixture),
      incoherentCollisionBefore,
    );
  });

  test('task7 rebuilds the bourg on the canonical exterior contract', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    final source = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'Selbrume.json'))),
    );

    final result = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task7',
        write: true,
      ),
    );
    expect(result.exitCode, 0);

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    final bourg = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_bourg_selbrume.json'))),
    );
    expect(
      () => MapValidator.validate(bourg, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(bourg.size, const GridSize(width: 55, height: 55));
    expect(bourg.tilesetId, isEmpty);
    expect(bourg.properties['selbrumeGeneratorBoundary'], 'task7');
    expect(
      bourg.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_path_primary',
        'l_path_secondary',
        'l_tile_ground',
        'l_tile_structures',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    expect(bourg.layers[0], isA<TerrainLayer>());
    expect(bourg.layers[1], isA<PathLayer>());
    expect(bourg.layers[2], isA<PathLayer>());
    for (var index = 3; index <= 6; index += 1) {
      expect(bourg.layers[index], isA<TileLayer>());
    }
    expect(bourg.layers[7], isA<CollisionLayer>());
    expect(
      bourg.layers.expand((layer) => <String>[layer.id]),
      isNot(contains('l_tile_objectif')),
    );
    expect(
      bourg.placedElements.any(
        (placed) =>
            placed.layerId == 'l_tile_objectif' || placed.elementId == 'test',
      ),
      isFalse,
    );

    final sourcePlacementSemantics = source.placedElements
        .where((placed) => placed.layerId != 'l_tile_objectif')
        .map(_placedElementSeedSemantics)
        .toList(growable: false);
    expect(
      bourg.placedElements.map(_placedElementSeedSemantics),
      unorderedEquals(sourcePlacementSemantics),
    );
    expect(bourg.placedElements, hasLength(source.placedElements.length - 1));
    expect(bourg.entities, source.entities);
    expect(
      bourg.entities.map((entity) => entity.id),
      unorderedEquals(<String>['spawn', 'p6_03_intro_sign', 'npc']),
    );
    expect(
      bourg.entities.singleWhere((entity) => entity.id == 'spawn').pos,
      const GridPos(x: 17, y: 24),
    );
    expect(
      bourg.entities.singleWhere((entity) => entity.id == 'p6_03_intro_sign'),
      source.entities.singleWhere((entity) => entity.id == 'p6_03_intro_sign'),
    );

    _expectPlacedElement(
      bourg,
      id: 'pe_bourg_maison_joueur_facade',
      elementId: 'selbrum_maison_1',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 10, y: 18),
    );
    _expectPlacedElement(
      bourg,
      id: 'pe_bourg_centre_facade',
      elementId: 'selbrume_centre_pok_mon',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 29, y: 22),
    );
    _expectPlacedElement(
      bourg,
      id: 'pe_bourg_puits',
      elementId: 'le_puits',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 23, y: 27),
    );
    _expectPlacedElement(
      bourg,
      id: 'pe_bourg_kiosque',
      elementId: 'kiosque_l_gumes',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 36, y: 35),
    );
    expect(
      bourg.placedElements
          .where(
            (placed) => placed.elementId.startsWith('selbrum_maison_'),
          )
          .length,
      greaterThanOrEqualTo(2),
    );

    expect(
      bourg.connections,
      unorderedEquals(<MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.south,
          targetMapId: 'map_port_brisants',
        ),
        const MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'map_bois_chaise_brume',
        ),
      ]),
    );
    expect(bourg.warps, hasLength(1));
    expect(
      bourg.warps.single,
      isA<MapWarp>()
          .having((warp) => warp.id, 'id', 'warp_bourg_to_maison')
          .having((warp) => warp.pos, 'pos', const GridPos(x: 13, y: 23))
          .having(
            (warp) => warp.targetMapId,
            'targetMapId',
            'map_maison_joueur',
          )
          .having(
            (warp) => warp.targetPos,
            'targetPos',
            const GridPos(x: 10, y: 13),
          ),
    );
    expect(
      <String>{
        for (final connection in bourg.connections) connection.targetMapId,
        for (final warp in bourg.warps) warp.targetMapId,
      }.intersection(
        const <String>{'Selbrume', 'route 1', 'house 1', 'house 2', 'lab'},
      ),
      isEmpty,
    );

    final primary = bourg.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_primary');
    final water = bourg.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_secondary');
    final collisions = bourg.layers.whereType<CollisionLayer>().single;
    expect(primary.presetId, 'pavement_path');
    expect(water.presetId, 'nouveau-chemin');
    expect(water.cells.where((cell) => cell), isNotEmpty);
    for (var y = 46; y <= 54; y += 1) {
      for (var x = 26; x <= 30; x += 1) {
        final index = y * 55 + x;
        expect(primary.cells[index], isTrue, reason: 'Port causeway ($x,$y)');
        expect(water.cells[index], isFalse,
            reason: 'Port causeway water ($x,$y)');
        expect(collisions.collisions[index], isFalse,
            reason: 'Port causeway collision ($x,$y)');
      }
    }
    for (var y = 24; y <= 28; y += 1) {
      final index = y * 55 + 54;
      expect(primary.cells[index], isTrue, reason: 'Bois corridor (54,$y)');
      expect(water.cells[index], isFalse,
          reason: 'Bois corridor water (54,$y)');
      expect(collisions.collisions[index], isFalse,
          reason: 'Bois corridor collision (54,$y)');
    }
    for (var y = 0; y < 55; y += 1) {
      if (y >= 24 && y <= 28) continue;
      final index = y * 55 + 54;
      expect(primary.cells[index], isFalse, reason: 'sealed east path (54,$y)');
      expect(collisions.collisions[index], isTrue,
          reason: 'sealed east collision (54,$y)');
    }
    for (var x = 0; x < 55; x += 1) {
      if (x >= 26 && x <= 30) continue;
      final index = 54 * 55 + x;
      expect(primary.cells[index], isFalse,
          reason: 'sealed south path ($x,54)');
      expect(collisions.collisions[index], isTrue,
          reason: 'sealed south collision ($x,54)');
    }
    for (final pos in const <GridPos>[
      GridPos(x: 17, y: 24),
      GridPos(x: 13, y: 23),
      GridPos(x: 13, y: 24),
      GridPos(x: 27, y: 20),
    ]) {
      expect(collisions.collisions[pos.y * 55 + pos.x], isFalse,
          reason: 'reserved Bourg cell $pos');
    }
  });

  test('task7 rejects semantic and navigation drift in the frozen seed',
      () async {
    final semanticFixture = _copySelbrumeFixture();
    addTearDown(() => semanticFixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(semanticFixture);
    final semanticSeedFile =
        File(p.join(semanticFixture.path, 'maps', 'Selbrume.json'));
    final semanticSeed = _readJson(semanticSeedFile);
    final entities = semanticSeed['entities'] as List<dynamic>;
    (entities.first as Map<String, dynamic>)['name'] = 'seed drift';
    semanticSeedFile.writeAsStringSync(jsonEncode(semanticSeed));
    final semanticBefore = _snapshotFiles(semanticFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: semanticFixture,
          through: 'task7',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('semantic fingerprint'),
            contains('cb2625eae6e98c3f'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(semanticFixture), semanticBefore);

    final navigationFixture = _copySelbrumeFixture();
    addTearDown(() => navigationFixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(navigationFixture);
    final navigationSeedFile =
        File(p.join(navigationFixture.path, 'maps', 'Selbrume.json'));
    final navigationSeed = _readJson(navigationSeedFile);
    final warps = navigationSeed['warps'] as List<dynamic>;
    final firstWarp = warps.first as Map<String, dynamic>;
    (firstWarp['pos'] as Map<String, dynamic>)['x'] = 12;
    navigationSeedFile.writeAsStringSync(jsonEncode(navigationSeed));
    final navigationBefore = _snapshotFiles(navigationFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: navigationFixture,
          through: 'task7',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('navigation fingerprint'),
            contains('4c7c8255997e9ff0'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(navigationFixture), navigationBefore);
  });

  test('task7 map marker survives a manifest-last interruption', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task7',
        write: true,
      ),
    );
    final projectFile = File(p.join(fixture.path, 'project.json'));
    final project = _readJson(projectFile);
    final groups = project['groups'] as List<dynamic>;
    final bourgGroup = groups.cast<Map<String, dynamic>>().singleWhere(
          (group) => group['id'] == 'group_selbrume_bourg',
        );
    (bourgGroup['properties'] as Map<String, dynamic>)
        .remove('selbrumeGeneratorBoundary');
    projectFile.writeAsStringSync(jsonEncode(project));
    final before = _snapshotFiles(fixture);

    for (final lower in const <String>['task6', 'task5', 'task4']) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lower,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('task7'), contains(lower), contains('downgrade')),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), before);
    }
  });

  test('task7 is idempotent and rejects every lower boundary', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    final beforeProject = projectFile.readAsStringSync();

    final check = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task7'),
    );
    expect(check.exitCode, selbrumeGeneratorDivergenceExitCode);
    expect(projectFile.readAsStringSync(), beforeProject);

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task7',
        write: true,
      ),
    );
    final firstWrite = _snapshotFiles(fixture);
    expect(
      _maskTask6ManifestArrays(projectFile.readAsStringSync()),
      _maskTask6ManifestArrays(beforeProject),
    );
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task7',
        write: true,
      ),
    );
    expect(_snapshotFiles(fixture), firstWrite);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task7'),
      ))
          .exitCode,
      0,
    );

    for (final lower in const <String>['task6', 'task5', 'task4']) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lower,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('task7'), contains(lower), contains('downgrade')),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), firstWrite);
    }
  });

  test('task8 registers the cabin atlas and builds the player house', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task8',
        write: true,
      ),
    );

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    final tilesets = manifest.tilesets.where(
      (entry) => entry.id == 'ts_selbrume_cabin_interior',
    );
    expect(tilesets, hasLength(1));
    expect(
      tilesets.single.relativePath,
      'assets/tilesets/selbrume_cabin_interior.png',
    );
    expect(tilesets.single.folderId, 'tsf_selbrume_beta_interiors');
    expect(
      manifest.tilesetFolders.where(
        (entry) => entry.id == 'tsf_selbrume_beta_interiors',
      ),
      hasLength(1),
    );
    expect(
      manifest.elementCategories.where(
        (entry) => entry.id == 'cat_selbrume_interiors',
      ),
      hasLength(1),
    );

    final cabinElements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (_cabinElementContracts.containsKey(element.id)) element.id: element,
    };
    expect(cabinElements.keys, unorderedEquals(_cabinElementContracts.keys));
    for (final contract in _cabinElementContracts.entries) {
      final element = cabinElements[contract.key]!;
      expect(element.tilesetId, 'ts_selbrume_cabin_interior');
      expect(element.categoryId, 'cat_selbrume_interiors');
      expect(element.frames, hasLength(1));
      expect(element.frames.single.tilesetId, isEmpty);
      expect(element.frames.single.source, contract.value.source);
      expect(element.recommendedLayerId, contract.value.layerId);
      if (contract.value.collisionCells.isEmpty) {
        expect(element.collisionProfile, isNull, reason: contract.key);
      } else {
        final profile = element.collisionProfile!;
        expect(profile.source, ElementCollisionProfileSource.manual);
        expect(profile.cells, unorderedEquals(contract.value.collisionCells),
            reason: contract.key);
        expect(profile.shapeCells, profile.cells, reason: contract.key);
        expect(profile.visualMask, isNotNull, reason: contract.key);
        expect(profile.collisionMask, isNotNull, reason: contract.key);
      }
    }

    final house = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_maison_joueur.json'))),
    );
    expect(
      () => MapValidator.validate(house, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(house.size, const GridSize(width: 20, height: 16));
    expect(house.tilesetId, isEmpty);
    expect(house.properties['selbrumeGeneratorBoundary'], 'task8');
    expect(
      house.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_tile_floor',
        'l_tile_walls',
        'l_tile_furniture',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    _expectPlacedElement(
      house,
      id: 'pe_maison_lit',
      elementId: 'el_selbrume_maison_lit',
      layerId: 'l_tile_furniture',
      pos: const GridPos(x: 2, y: 3),
    );
    _expectPlacedElement(
      house,
      id: 'pe_maison_bureau',
      elementId: 'el_selbrume_maison_bureau',
      layerId: 'l_tile_furniture',
      pos: const GridPos(x: 14, y: 4),
    );
    _expectPlacedElement(
      house,
      id: 'pe_maison_tapis',
      elementId: 'el_selbrume_maison_tapis',
      layerId: 'l_tile_floor',
      pos: const GridPos(x: 8, y: 8),
    );
    _expectPlacedElement(
      house,
      id: 'pe_maison_etagere',
      elementId: 'el_selbrume_cabane_etagere',
      layerId: 'l_tile_furniture',
      pos: const GridPos(x: 16, y: 3),
    );
    _expectPlacedElement(
      house,
      id: 'pe_maison_porte',
      elementId: 'el_selbrume_cabane_porte_principale',
      layerId: 'l_tile_walls',
      pos: const GridPos(x: 9, y: 13),
    );
    expect(
      house.placedElements.map((placed) => placed.layerId).toSet(),
      <String>{
        'l_tile_floor',
        'l_tile_walls',
        'l_tile_furniture',
        'l_tile_overhead',
      },
      reason: 'Every house placement stays on its semantic draw layer.',
    );

    expect(house.entities, hasLength(1));
    expect(
      house.entities.single,
      isA<MapEntity>()
          .having((entity) => entity.id, 'id', 'spawn_maison_joueur')
          .having((entity) => entity.kind, 'kind', MapEntityKind.spawn)
          .having(
            (entity) => entity.pos,
            'pos',
            const GridPos(x: 10, y: 11),
          )
          .having((entity) => entity.blocksMovement, 'blocksMovement', false),
    );
    _expectSpecialZone(house, 'zone_player_house_exit', 8, 12, 5, 4);
    _expectReservedTrigger(
      house,
      'zone_player_house_exit',
      'event_player_house_exit',
      10,
      13,
      1,
      2,
    );
    expect(house.events, isEmpty);
    expect(house.warps, hasLength(1));
    expect(
      house.warps.single,
      isA<MapWarp>()
          .having((warp) => warp.id, 'id', 'warp_maison_to_bourg')
          .having((warp) => warp.pos, 'pos', const GridPos(x: 10, y: 15))
          .having(
            (warp) => warp.targetMapId,
            'targetMapId',
            'map_bourg_selbrume',
          )
          .having(
            (warp) => warp.targetPos,
            'targetPos',
            const GridPos(x: 13, y: 24),
          ),
    );
    final collisions = house.layers.whereType<CollisionLayer>().single;
    for (final pos in const <GridPos>[
      GridPos(x: 10, y: 11),
      GridPos(x: 10, y: 12),
      GridPos(x: 10, y: 13),
      GridPos(x: 10, y: 14),
      GridPos(x: 10, y: 15),
    ]) {
      expect(collisions.collisions[pos.y * 20 + pos.x], isFalse,
          reason: 'Maison critical approach $pos');
    }
  });

  test('task8 preflight is atomic and downgrade-safe', () async {
    final missingFixture = _copySelbrumeFixture();
    addTearDown(() => missingFixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(missingFixture);
    final missingBefore = _snapshotFiles(missingFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: missingFixture,
          through: 'task8',
          write: true,
        ),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.path,
          'path',
          endsWith('selbrume_cabin_interior.png'),
        ),
      ),
    );
    expect(_snapshotFiles(missingFixture), missingBefore);

    final malformedFixture = _copySelbrumeFixture();
    addTearDown(() => malformedFixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(malformedFixture);
    _writeSyntheticCabinAtlas(malformedFixture, width: 32, height: 32);
    final malformedBefore = _snapshotFiles(malformedFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: malformedFixture,
          through: 'task8',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('selbrume_cabin_interior.png'), contains('512x512')),
        ),
      ),
    );
    expect(_snapshotFiles(malformedFixture), malformedBefore);

    final rgbFixture = _copySelbrumeFixture();
    addTearDown(() => rgbFixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(rgbFixture);
    _writeSyntheticCabinAtlas(rgbFixture, numChannels: 3);
    final rgbBefore = _snapshotFiles(rgbFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: rgbFixture,
          through: 'task8',
          write: true,
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('selbrume_cabin_interior.png'),
            contains('8-bit RGBA'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(rgbFixture), rgbBefore);

    final transparentFixture = _copySelbrumeFixture();
    addTearDown(() => transparentFixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(transparentFixture);
    _writeSyntheticCabinAtlas(transparentFixture);
    _clearCabinAtlasPixels(
      transparentFixture,
      x: 0,
      y: 0,
      width: 4 * 32,
      height: 4 * 32,
    );
    final transparentBefore = _snapshotFiles(transparentFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: transparentFixture,
          through: 'task8',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('el_selbrume_cabane_sol_bois'),
            contains('no visible pixels'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(transparentFixture), transparentBefore);

    final symlinkFixture = _copySelbrumeFixture();
    addTearDown(() => symlinkFixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(symlinkFixture);
    _writeSyntheticCabinAtlas(symlinkFixture);
    final cabinPath = p.join(
      symlinkFixture.path,
      'assets',
      'tilesets',
      'selbrume_cabin_interior.png',
    );
    final outsideCabin = File(
      p.join(symlinkFixture.parent.path, 'outside_cabin_interior.png'),
    );
    File(cabinPath).renameSync(outsideCabin.path);
    Link(cabinPath).createSync(outsideCabin.path);
    final symlinkBefore = _snapshotFiles(symlinkFixture);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: symlinkFixture,
          through: 'task8',
          write: true,
        ),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('Task 8'),
            contains('escapes the project root'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(symlinkFixture), symlinkBefore);

    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    final beforeProject = projectFile.readAsStringSync();
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task8',
        write: true,
      ),
    );
    final firstWrite = _snapshotFiles(fixture);
    expect(
      _maskTask6ManifestArrays(projectFile.readAsStringSync()),
      _maskTask6ManifestArrays(beforeProject),
    );
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task8',
        write: true,
      ),
    );
    expect(_snapshotFiles(fixture), firstWrite);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task8'),
      ))
          .exitCode,
      0,
    );
    for (final lower in const <String>[
      'task7',
      'task6',
      'task5',
      'task4',
    ]) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lower,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('task8'), contains(lower), contains('downgrade')),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), firstWrite);
    }
  });

  test('task8 map marker survives a manifest-last interruption', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task7',
        write: true,
      ),
    );
    final task7ProjectSource = projectFile.readAsStringSync();
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task8',
        write: true,
      ),
    );
    projectFile.writeAsStringSync(task7ProjectSource);
    final before = _snapshotFiles(fixture);

    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: fixture,
          through: 'task7',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('task8'), contains('task7'), contains('downgrade')),
        ),
      ),
    );
    expect(_snapshotFiles(fixture), before);
  });

  test('task9 registers the forest atlas and builds the canonical Bois',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task9',
        write: true,
      ),
    );

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    final folders = manifest.tilesetFolders.where(
      (entry) => entry.id == 'tsf_selbrume_beta_forest',
    );
    expect(folders, hasLength(1));
    expect(folders.single.parentFolderId, 'tsf_selbrume_beta');
    final categories = manifest.elementCategories.where(
      (entry) => entry.id == 'cat_selbrume_forest',
    );
    expect(categories, hasLength(1));
    expect(categories.single.parentCategoryId, 'environnement');
    final tilesets = manifest.tilesets.where(
      (entry) => entry.id == 'ts_selbrume_forest_props',
    );
    expect(tilesets, hasLength(1));
    expect(
      tilesets.single.relativePath,
      'assets/tilesets/selbrume_forest_props.png',
    );
    expect(tilesets.single.folderId, 'tsf_selbrume_beta_forest');

    final forestElements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_forest_props')
          element.id: element,
    };
    expect(forestElements.keys, unorderedEquals(_forestElementContracts.keys));
    for (final contract in _forestElementContracts.entries) {
      final element = forestElements[contract.key]!;
      expect(element.categoryId, 'cat_selbrume_forest');
      expect(element.frames, hasLength(1));
      expect(element.frames.single.source, contract.value.source);
      expect(element.recommendedLayerId, contract.value.layerId);
      expect(
        element.tags,
        containsAll(<String>[
          'environment',
          'forest',
          'map_bois_chaise_brume',
          'beta',
          'static',
        ]),
      );
      final profile = element.collisionProfile;
      if (contract.value.collisionCells.isEmpty) {
        expect(profile, isNull, reason: contract.key);
        continue;
      }
      expect(profile, isNotNull, reason: contract.key);
      expect(profile!.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, unorderedEquals(contract.value.collisionCells));
      expect(profile.shapeCells, profile.cells);
      expect(profile.visualMask, isNotNull);
      expect(profile.collisionMask, isNotNull);
      expect(
        profile.occlusionMask != null,
        contract.value.requiresOcclusion,
        reason: contract.key,
      );
      expect(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 32,
          tileHeight: 32,
          sourceWidthInTiles: contract.value.source.width,
          sourceHeightInTiles: contract.value.source.height,
        ),
        unorderedEquals(contract.value.collisionCells),
      );
    }

    final forest = MapData.fromJson(
      _readJson(
        File(p.join(fixture.path, 'maps', 'map_bois_chaise_brume.json')),
      ),
    );
    expect(
      () => MapValidator.validate(forest, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(forest.size, const GridSize(width: 45, height: 45));
    expect(forest.tilesetId, isEmpty);
    expect(forest.mapMetadata.weather, MapWeather.fog);
    expect(forest.properties['selbrumeGeneratorBoundary'], 'task9');
    expect(
      forest.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_path_primary',
        'l_path_secondary',
        'l_tile_ground',
        'l_tile_structures',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    for (final layer in forest.layers.whereType<TileLayer>()) {
      expect(layer.tilesetId, 'ts_selbrume_forest_props');
    }
    expect(
      forest.connections,
      unorderedEquals(<MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'map_bourg_selbrume',
        ),
        const MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'map_marais_salants',
        ),
      ]),
    );
    expect(forest.warps, isEmpty);
    expect(forest.events, isEmpty);
    expect(forest.triggers, isEmpty);

    const grassAreas = <String, MapRect>{
      'zone_bois_herbe_1': MapRect(
        pos: GridPos(x: 9, y: 8),
        size: GridSize(width: 8, height: 6),
      ),
      'zone_bois_herbe_2': MapRect(
        pos: GridPos(x: 26, y: 9),
        size: GridSize(width: 8, height: 7),
      ),
      'zone_bois_herbe_3': MapRect(
        pos: GridPos(x: 7, y: 29),
        size: GridSize(width: 10, height: 7),
      ),
      'zone_bois_herbe_4': MapRect(
        pos: GridPos(x: 27, y: 30),
        size: GridSize(width: 8, height: 6),
      ),
    };
    expect(
      forest.gameplayZones.map((zone) => zone.id),
      unorderedEquals(grassAreas.keys),
    );
    for (final zone in forest.gameplayZones) {
      expect(zone.area, grassAreas[zone.id]);
      expect(zone.kind, GameplayZoneKind.special);
      expect(zone.encounter, isNull);
      expect(zone.special?.scriptKey, isNull);
      expect(zone.special?.properties, <String, String>{
        'contractRole': 'tall_grass_surface',
        'inert': 'true',
      });
    }

    final primary = forest.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_primary');
    final tallGrass = forest.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_secondary');
    final blocked = _mapBlockedCells(forest, manifest);
    expect(primary.presetId, 'dirth_path');
    expect(tallGrass.presetId, 'haute_herbe');
    for (var index = 0; index < primary.cells.length; index += 1) {
      if (primary.cells[index]) expect(tallGrass.cells[index], isFalse);
    }
    for (final placed in forest.placedElements) {
      final contract = _forestElementContracts[placed.elementId]!;
      final collisionCells = contract.collisionCells.toSet();
      expect(
        placed.applyCollision,
        contract.collisionCells.isNotEmpty,
        reason: placed.id,
      );
      for (final cell in contract.collisionCells) {
        final x = placed.pos.x + cell.x;
        final y = placed.pos.y + cell.y;
        expect(
          blocked[y * forest.size.width + x],
          isTrue,
          reason: '${placed.id} base ($x,$y)',
        );
      }
      if (!contract.requiresOcclusion) continue;
      for (var localY = 0; localY < contract.source.height; localY += 1) {
        for (var localX = 0; localX < contract.source.width; localX += 1) {
          if (collisionCells.contains(GridPos(x: localX, y: localY))) continue;
          final x = placed.pos.x + localX;
          final y = placed.pos.y + localY;
          expect(
            blocked[y * forest.size.width + x],
            isFalse,
            reason: '${placed.id} canopy ($x,$y)',
          );
        }
      }
    }
    final criticalCells = <GridPos>[
      for (var y = 24; y <= 28; y += 1) ...<GridPos>[
        GridPos(x: 0, y: y),
        GridPos(x: 44, y: y),
      ],
      const GridPos(x: 14, y: 15),
      const GridPos(x: 24, y: 16),
      const GridPos(x: 24, y: 23),
      const GridPos(x: 31, y: 30),
    ];
    final reached = _reachableUnblockedCells(
      forest,
      blocked,
      primary.cells,
      const GridPos(x: 0, y: 26),
    );
    for (final pos in criticalCells) {
      final index = pos.y * forest.size.width + pos.x;
      expect(primary.cells[index], isTrue, reason: 'forest path $pos');
      expect(blocked[index], isFalse, reason: 'forest collision $pos');
      expect(reached, contains(index), reason: 'forest reachability $pos');
    }
    for (final center in const <GridPos>[
      GridPos(x: 14, y: 15),
      GridPos(x: 31, y: 30),
    ]) {
      for (var y = center.y - 1; y <= center.y + 1; y += 1) {
        for (var x = center.x - 1; x <= center.x + 1; x += 1) {
          final index = y * forest.size.width + x;
          expect(primary.cells[index], isTrue, reason: 'clearing $center');
          expect(tallGrass.cells[index], isFalse, reason: 'clearing $center');
          expect(blocked[index], isFalse, reason: 'clearing $center');
        }
      }
    }
    for (final crossing in const <List<GridPos>>[
      <GridPos>[
        GridPos(x: 13, y: 20),
        GridPos(x: 14, y: 20),
        GridPos(x: 15, y: 20),
      ],
      <GridPos>[
        GridPos(x: 23, y: 20),
        GridPos(x: 24, y: 20),
        GridPos(x: 25, y: 20),
      ],
      <GridPos>[
        GridPos(x: 30, y: 26),
        GridPos(x: 31, y: 26),
        GridPos(x: 32, y: 26),
      ],
    ]) {
      for (final pos in crossing) {
        final index = pos.y * forest.size.width + pos.x;
        expect(primary.cells[index], isTrue, reason: 'crossing $crossing');
        expect(blocked[index], isFalse, reason: 'crossing $crossing');
        expect(reached, contains(index), reason: 'crossing $crossing');
      }
    }
    final directMainSegment = <int>{
      for (var x = 15; x <= 23; x += 1) 24 * forest.size.width + x,
    };
    final loopReached = _reachableUnblockedCells(
      forest,
      blocked,
      primary.cells,
      const GridPos(x: 14, y: 24),
      excluded: directMainSegment,
    );
    expect(
      loopReached,
      contains(24 * forest.size.width + 24),
      reason: 'The optional loop must retain two distinct main-path joins.',
    );

    expect(
      forest.placedElements.map((placed) => placed.elementId).toSet(),
      _forestElementContracts.keys.toSet(),
    );
    _expectPlacedElement(
      forest,
      id: 'pe_bois_pin_grand_001',
      elementId: 'el_selbrume_bois_pin_grand',
      layerId: 'l_tile_overhead',
      pos: const GridPos(x: 2, y: 2),
    );
    _expectPlacedElement(
      forest,
      id: 'pe_bois_tronc_tombe_001',
      elementId: 'el_selbrume_bois_tronc_tombe',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 18, y: 36),
    );
    _expectPlacedElement(
      forest,
      id: 'pe_bois_panneau_001',
      elementId: 'el_selbrume_bois_panneau',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 3, y: 21),
    );
  });

  test('task9 accepts the final forest atlas from a read-only temp copy',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    final repositoryRoot = _findRepositoryRoot();
    final finalAtlas = File(
      p.join(
        repositoryRoot.path,
        'selbrume',
        'assets',
        'tilesets',
        'selbrume_forest_props.png',
      ),
    );
    expect(finalAtlas.existsSync(), isTrue);
    final finalAtlasBefore = finalAtlas.readAsBytesSync();
    final fixtureAtlas = File(
      p.join(
        fixture.path,
        'assets',
        'tilesets',
        'selbrume_forest_props.png',
      ),
    );
    finalAtlas.copySync(fixtureAtlas.path);

    final result = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task9'),
    );

    expect(result.exitCode, selbrumeGeneratorDivergenceExitCode);
    expect(result.divergentRelativePaths, isNotEmpty);
    expect(finalAtlas.readAsBytesSync(), finalAtlasBefore);
    expect(
      File(p.join(fixture.path, 'project.json'))
          .readAsStringSync()
          .contains('ts_selbrume_forest_props'),
      isFalse,
      reason: '--check must not materialize Task 9 in the temp project.',
    );
  });

  test('task9 is idempotent, preflighted, and downgrade-safe', () async {
    final missing = _copySelbrumeFixture();
    addTearDown(() => missing.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(missing);
    _writeSyntheticCabinAtlas(missing);
    final missingBefore = _snapshotFiles(missing);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: missing,
          through: 'task9',
          write: true,
        ),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.path,
          'path',
          endsWith('selbrume_forest_props.png'),
        ),
      ),
    );
    expect(_snapshotFiles(missing), missingBefore);

    final malformed = _copySelbrumeFixture();
    addTearDown(() => malformed.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(malformed);
    _writeSyntheticCabinAtlas(malformed);
    _writeSyntheticForestAtlas(malformed, width: 32, height: 32);
    final malformedBefore = _snapshotFiles(malformed);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: malformed,
          through: 'task9',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('selbrume_forest_props.png'), contains('512x512')),
        ),
      ),
    );
    expect(_snapshotFiles(malformed), malformedBefore);

    final rgb = _copySelbrumeFixture();
    addTearDown(() => rgb.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(rgb);
    _writeSyntheticCabinAtlas(rgb);
    _writeSyntheticForestAtlas(rgb, numChannels: 3);
    final rgbBefore = _snapshotFiles(rgb);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: rgb,
          through: 'task9',
          write: true,
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('selbrume_forest_props.png'),
            contains('8-bit RGBA'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(rgb), rgbBefore);

    final transparent = _copySelbrumeFixture();
    addTearDown(() => transparent.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(transparent);
    _writeSyntheticCabinAtlas(transparent);
    _writeSyntheticForestAtlas(transparent);
    _clearForestAtlasPixels(
      transparent,
      x: 0,
      y: 0,
      width: 6 * 32,
      height: 8 * 32,
    );
    final transparentBefore = _snapshotFiles(transparent);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: transparent,
          through: 'task9',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('el_selbrume_bois_pin_grand'),
            contains('no visible pixels'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(transparent), transparentBefore);

    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    final check = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task9'),
    );
    expect(check.exitCode, selbrumeGeneratorDivergenceExitCode);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task9',
        write: true,
      ),
    );
    final firstWrite = _snapshotFiles(fixture);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task9',
        write: true,
      ),
    );
    expect(_snapshotFiles(fixture), firstWrite);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task9'),
      ))
          .exitCode,
      0,
    );
    for (final lower in const <String>[
      'task8',
      'task7',
      'task6',
      'task5',
      'task4',
    ]) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lower,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('task9'), contains(lower), contains('downgrade')),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), firstWrite);
    }
  });

  test('task9 map marker survives a manifest-last interruption', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task8',
        write: true,
      ),
    );
    final task8ProjectSource = projectFile.readAsStringSync();
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task9',
        write: true,
      ),
    );
    expect(
      _readJson(
        File(p.join(fixture.path, 'maps', 'map_bois_chaise_brume.json')),
      )['properties']['selbrumeGeneratorBoundary'],
      'task9',
    );
    projectFile.writeAsStringSync(task8ProjectSource);
    final before = _snapshotFiles(fixture);

    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: fixture,
          through: 'task8',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('task9'), contains('task8'), contains('downgrade')),
        ),
      ),
    );
    expect(_snapshotFiles(fixture), before);
  });

  test('task10 registers the marsh atlas and rebuilds Marais Salants',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    final sourceMarsh = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'route 1.json'))),
    );

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task10',
        write: true,
      ),
    );

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    final folders = manifest.tilesetFolders.where(
      (entry) => entry.id == 'tsf_selbrume_beta_marsh',
    );
    expect(folders, hasLength(1));
    expect(folders.single.parentFolderId, 'tsf_selbrume_beta');
    final categories = manifest.elementCategories.where(
      (entry) => entry.id == 'cat_selbrume_marsh',
    );
    expect(categories, hasLength(1));
    expect(categories.single.parentCategoryId, 'environnement');
    final tilesets = manifest.tilesets.where(
      (entry) => entry.id == 'ts_selbrume_marsh_props',
    );
    expect(tilesets, hasLength(1));
    expect(
      tilesets.single.relativePath,
      'assets/tilesets/selbrume_marsh_props.png',
    );
    expect(tilesets.single.folderId, 'tsf_selbrume_beta_marsh');

    final marshElements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_marsh_props') element.id: element,
    };
    expect(marshElements.keys, unorderedEquals(_marshElementContracts.keys));
    for (final contract in _marshElementContracts.entries) {
      final element = marshElements[contract.key]!;
      expect(element.categoryId, 'cat_selbrume_marsh');
      expect(element.frames, hasLength(1));
      expect(element.frames.single.source, contract.value.source);
      expect(element.recommendedLayerId, contract.value.layerId);
      expect(
        element.tags,
        containsAll(<String>[
          'environment',
          'marsh',
          'map_marais_salants',
          'beta',
          contract.value.isStateVariant ? 'state_variant' : 'static',
        ]),
      );
      final profile = element.collisionProfile;
      if (contract.value.collisionCells.isEmpty) {
        expect(profile, isNull, reason: contract.key);
        continue;
      }
      expect(profile, isNotNull, reason: contract.key);
      expect(profile!.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, unorderedEquals(contract.value.collisionCells));
      expect(profile.shapeCells, profile.cells);
      expect(profile.visualMask, isNotNull);
      expect(profile.collisionMask, isNotNull);
      expect(
        profile.occlusionMask != null,
        contract.value.requiresOcclusion,
        reason: contract.key,
      );
      expect(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 32,
          tileHeight: 32,
          sourceWidthInTiles: contract.value.source.width,
          sourceHeightInTiles: contract.value.source.height,
        ),
        unorderedEquals(contract.value.collisionCells),
      );
    }

    final marsh = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_marais_salants.json'))),
    );
    expect(
      () => MapValidator.validate(marsh, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(marsh.size, const GridSize(width: 45, height: 45));
    expect(marsh.tilesetId, isEmpty);
    expect(marsh.properties['selbrumeGeneratorBoundary'], 'task10');
    expect(marsh.mapMetadata.mapType, MapType.route);
    expect(marsh.mapMetadata.isIndoor, isFalse);
    expect(
      marsh.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_path_primary',
        'l_path_secondary',
        'l_tile_ground',
        'l_tile_structures',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    for (final layer in marsh.layers.whereType<TileLayer>()) {
      expect(layer.tilesetId, 'ts_selbrume_marsh_props');
    }
    expect(
      marsh.layers.where((layer) => layer.id == 'l_tile_objectif'),
      isEmpty,
    );
    expect(
      marsh.placedElements.where(
        (placed) =>
            placed.layerId == 'l_tile_objectif' ||
            placed.elementId.contains('route_1'),
      ),
      isEmpty,
    );
    expect(
      marsh.connections,
      unorderedEquals(<MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'map_bois_chaise_brume',
        ),
        const MapConnection(
          direction: MapConnectionDirection.south,
          targetMapId: 'map_passage_dames',
        ),
      ]),
    );
    expect(marsh.warps, isEmpty);
    expect(marsh.events, isEmpty);

    final grant = marsh.entities.where((entity) => entity.id == 'grant');
    expect(grant, hasLength(1));
    expect(grant.single, sourceMarsh.entities.single);
    final mado = marsh.entities.where(
      (entity) => entity.id == 'anchor_marais_mado',
    );
    expect(mado, hasLength(1));
    expect(mado.single.kind, MapEntityKind.custom);
    expect(mado.single.pos, const GridPos(x: 10, y: 12));
    expect(mado.single.blocksMovement, isFalse);
    expect(mado.single.npc, isNull);
    expect(mado.single.properties, <String, String>{
      'contractRole': 'reserved_character_anchor',
      'inert': 'true',
    });

    final sourceZones = <String, MapGameplayZone>{
      for (final zone in sourceMarsh.gameplayZones) zone.id: zone,
    };
    final zones = <String, MapGameplayZone>{
      for (final zone in marsh.gameplayZones) zone.id: zone,
    };
    expect(
      zones.keys,
      unorderedEquals(<String>[...sourceZones.keys, 'zone_marais_entry']),
    );
    for (final sourceZone in sourceZones.entries) {
      expect(zones[sourceZone.key], sourceZone.value);
      expect(
        zones[sourceZone.key]!.encounter?.encounterTableId,
        'grass_path_route_1',
      );
    }
    final entryZone = zones['zone_marais_entry']!;
    expect(entryZone.kind, GameplayZoneKind.special);
    expect(
      entryZone.area,
      const MapRect(
        pos: GridPos(x: 0, y: 22),
        size: GridSize(width: 5, height: 7),
      ),
    );
    expect(entryZone.special?.properties, <String, String>{
      'contractRole': 'navigation_anchor',
      'inert': 'true',
    });

    const triggerContracts = <String, ({GridPos pos, String eventId})>{
      'zone_marais_entry': (
        pos: GridPos(x: 0, y: 22),
        eventId: 'event_marais_entry',
      ),
      'tr_marais_indice_verre': (
        pos: GridPos(x: 8, y: 32),
        eventId: 'event_selbrume_indice_verre',
      ),
      'tr_marais_indice_traces_electriques': (
        pos: GridPos(x: 32, y: 10),
        eventId: 'event_selbrume_indice_traces_electriques',
      ),
      'tr_marais_indice_repere_lentille': (
        pos: GridPos(x: 34, y: 34),
        eventId: 'event_selbrume_indice_repere_lentille',
      ),
      'tr_marais_cristal_1': (
        pos: GridPos(x: 14, y: 7),
        eventId: 'event_selbrume_cristal_1',
      ),
      'tr_marais_cristal_2': (
        pos: GridPos(x: 24, y: 28),
        eventId: 'event_selbrume_cristal_2',
      ),
      'tr_marais_cristal_3': (
        pos: GridPos(x: 38, y: 22),
        eventId: 'event_selbrume_cristal_3',
      ),
    };
    final triggers = <String, MapTrigger>{
      for (final trigger in marsh.triggers) trigger.id: trigger,
    };
    expect(triggers.keys, unorderedEquals(triggerContracts.keys));
    for (final contract in triggerContracts.entries) {
      final trigger = triggers[contract.key]!;
      final expectedSize = contract.key == 'zone_marais_entry'
          ? const GridSize(width: 5, height: 7)
          : const GridSize(width: 1, height: 1);
      expect(trigger.type, TriggerType.custom);
      expect(
        trigger.area,
        MapRect(pos: contract.value.pos, size: expectedSize),
      );
      expect(trigger.properties['eventId'], contract.value.eventId);
      expect(trigger.properties['reservedForNarrative'], 'true');
    }

    const placedContracts =
        <String, ({String elementId, String layer, GridPos pos})>{
      'pe_marais_cabane_paludier': (
        elementId: 'el_selbrume_marais_cabane_paludier',
        layer: 'l_tile_structures',
        pos: GridPos(x: 4, y: 14),
      ),
      'pe_marais_ecluse': (
        elementId: 'el_selbrume_marais_ecluse_fermee',
        layer: 'l_tile_structures',
        pos: GridPos(x: 27, y: 18),
      ),
      'pe_marais_indice_verre': (
        elementId: 'el_selbrume_indice_verre',
        layer: 'l_tile_ground',
        pos: GridPos(x: 8, y: 32),
      ),
      'pe_marais_indice_traces_electriques': (
        elementId: 'el_selbrume_indice_traces_electriques',
        layer: 'l_tile_fx',
        pos: GridPos(x: 32, y: 10),
      ),
      'pe_marais_indice_repere_lentille': (
        elementId: 'el_selbrume_indice_repere_lentille',
        layer: 'l_tile_ground',
        pos: GridPos(x: 34, y: 34),
      ),
      'pe_marais_cristal_1': (
        elementId: 'el_selbrume_cristal_1',
        layer: 'l_tile_fx',
        pos: GridPos(x: 14, y: 7),
      ),
      'pe_marais_cristal_2': (
        elementId: 'el_selbrume_cristal_2',
        layer: 'l_tile_fx',
        pos: GridPos(x: 24, y: 28),
      ),
      'pe_marais_cristal_3': (
        elementId: 'el_selbrume_cristal_3',
        layer: 'l_tile_fx',
        pos: GridPos(x: 38, y: 22),
      ),
    };
    for (final contract in placedContracts.entries) {
      _expectPlacedElement(
        marsh,
        id: contract.key,
        elementId: contract.value.elementId,
        layerId: contract.value.layer,
        pos: contract.value.pos,
      );
    }
    final expectedUsedElementIds = _marshElementContracts.keys
        .where((id) => id != 'el_selbrume_marais_ecluse_ouverte')
        .toSet();
    expect(
      marsh.placedElements.map((placed) => placed.elementId).toSet(),
      expectedUsedElementIds,
    );

    final primary = marsh.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_primary');
    final secondary = marsh.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_secondary');
    final blocked = _mapBlockedCells(marsh, manifest);
    final allowed = <bool>[
      for (var index = 0; index < primary.cells.length; index += 1)
        primary.cells[index] || secondary.cells[index],
    ];
    final reached = _reachableUnblockedCells(
      marsh,
      blocked,
      allowed,
      const GridPos(x: 0, y: 26),
    );
    expect(primary.presetId, 'pavement_path');
    expect(secondary.presetId, 'haute_herbe');
    for (var y = 24; y <= 28; y += 1) {
      final west = y * marsh.size.width;
      expect(primary.cells[west], isTrue);
      expect(blocked[west], isFalse);
      expect(reached, contains(west));
    }
    for (var x = 30; x <= 34; x += 1) {
      final south = 44 * marsh.size.width + x;
      expect(primary.cells[south], isTrue);
      expect(blocked[south], isFalse);
      expect(reached, contains(south));
    }
    for (final pos in const <GridPos>[
      GridPos(x: 10, y: 12),
      GridPos(x: 8, y: 32),
      GridPos(x: 32, y: 10),
      GridPos(x: 34, y: 34),
      GridPos(x: 14, y: 7),
      GridPos(x: 24, y: 28),
      GridPos(x: 38, y: 22),
      GridPos(x: 6, y: 18),
    ]) {
      final index = pos.y * marsh.size.width + pos.x;
      expect(primary.cells[index], isTrue, reason: 'marsh path $pos');
      expect(blocked[index], isFalse, reason: 'marsh collision $pos');
      expect(reached, contains(index), reason: 'marsh reachability $pos');
    }
    for (final basin in const <GridPos>[
      GridPos(x: 20, y: 5),
      GridPos(x: 40, y: 40),
      GridPos(x: 24, y: 15),
    ]) {
      expect(
        blocked[basin.y * marsh.size.width + basin.x],
        isTrue,
        reason: 'marsh basin $basin',
      );
    }
    for (final bridgeCenter in const <GridPos>[
      GridPos(x: 18, y: 24),
      GridPos(x: 31, y: 30),
      GridPos(x: 19, y: 17),
      GridPos(x: 31, y: 25),
    ]) {
      final index = bridgeCenter.y * marsh.size.width + bridgeCenter.x;
      expect(primary.cells[index], isTrue, reason: 'bridge $bridgeCenter');
      expect(blocked[index], isFalse, reason: 'bridge $bridgeCenter');
      expect(reached, contains(index), reason: 'bridge $bridgeCenter');
    }
  });

  test(
      'task10 accepts the final marsh atlas without colliding its transparent angle cell',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);

    final finalAtlas = File(
      p.join(
        _findRepositoryRoot().path,
        'selbrume',
        'assets',
        'tilesets',
        'selbrume_marsh_props.png',
      ),
    );
    expect(finalAtlas.existsSync(), isTrue);
    final finalAtlasBefore = finalAtlas.readAsBytesSync();
    finalAtlas.copySync(
      p.join(
        fixture.path,
        'assets',
        'tilesets',
        'selbrume_marsh_props.png',
      ),
    );

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task10',
        write: true,
      ),
    );

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    final angle = manifest.elements.singleWhere(
      (element) => element.id == 'el_selbrume_marais_passerelle_angle',
    );
    final profile = angle.collisionProfile!;
    const visibleCells = <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
      GridPos(x: 2, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
    ];
    const collisionCells = <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
    ];
    expect(profile.cells, unorderedEquals(collisionCells));
    expect(profile.shapeCells, unorderedEquals(collisionCells));
    expect(
      ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: profile.visualMask!,
        tileWidth: 32,
        tileHeight: 32,
        sourceWidthInTiles: 3,
        sourceHeightInTiles: 3,
      ),
      unorderedEquals(visibleCells),
      reason: 'The accepted thick L stays 8/9 visible; no alpha is invented.',
    );
    expect(
      ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: profile.collisionMask!,
        tileWidth: 32,
        tileHeight: 32,
        sourceWidthInTiles: 3,
        sourceHeightInTiles: 3,
      ),
      unorderedEquals(collisionCells),
    );
    final marsh = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_marais_salants.json'))),
    );
    expect(
      marsh.placedElements
          .singleWhere((placed) => placed.id == 'pe_marais_passerelle_angle')
          .applyCollision,
      isTrue,
    );
    expect(finalAtlas.readAsBytesSync(), finalAtlasBefore);
  });

  test('task10 is idempotent preflighted and downgrade-safe', () async {
    final missing = _copySelbrumeFixture();
    addTearDown(() => missing.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(missing);
    _writeSyntheticCabinAtlas(missing);
    _writeSyntheticForestAtlas(missing);
    final missingBefore = _snapshotFiles(missing);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: missing,
          through: 'task10',
          write: true,
        ),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.path,
          'path',
          endsWith('selbrume_marsh_props.png'),
        ),
      ),
    );
    expect(_snapshotFiles(missing), missingBefore);

    final malformed = _copySelbrumeFixture();
    addTearDown(() => malformed.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(malformed);
    _writeSyntheticCabinAtlas(malformed);
    _writeSyntheticForestAtlas(malformed);
    _writeSyntheticMarshAtlas(malformed, width: 32, height: 32);
    final malformedBefore = _snapshotFiles(malformed);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: malformed,
          through: 'task10',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('selbrume_marsh_props.png'), contains('512x512')),
        ),
      ),
    );
    expect(_snapshotFiles(malformed), malformedBefore);

    final rgb = _copySelbrumeFixture();
    addTearDown(() => rgb.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(rgb);
    _writeSyntheticCabinAtlas(rgb);
    _writeSyntheticForestAtlas(rgb);
    _writeSyntheticMarshAtlas(rgb, numChannels: 3);
    final rgbBefore = _snapshotFiles(rgb);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: rgb,
          through: 'task10',
          write: true,
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('selbrume_marsh_props.png'),
            contains('8-bit RGBA'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(rgb), rgbBefore);

    final transparent = _copySelbrumeFixture();
    addTearDown(() => transparent.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(transparent);
    _writeSyntheticCabinAtlas(transparent);
    _writeSyntheticForestAtlas(transparent);
    _writeSyntheticMarshAtlas(transparent);
    _clearMarshAtlasPixels(
      transparent,
      x: 0,
      y: 0,
      width: 5 * 32,
      height: 5 * 32,
    );
    final transparentBefore = _snapshotFiles(transparent);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: transparent,
          through: 'task10',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('el_selbrume_marais_cabane_paludier'),
            contains('no visible pixels'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(transparent), transparentBefore);

    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    final check = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task10'),
    );
    expect(check.exitCode, selbrumeGeneratorDivergenceExitCode);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task10',
        write: true,
      ),
    );
    final firstWrite = _snapshotFiles(fixture);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task10',
        write: true,
      ),
    );
    expect(_snapshotFiles(fixture), firstWrite);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task10'),
      ))
          .exitCode,
      0,
    );
    for (final lower in const <String>[
      'task9',
      'task8',
      'task7',
      'task6',
      'task5',
      'task4',
    ]) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lower,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('task10'), contains(lower), contains('downgrade')),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), firstWrite);
    }
  });

  test('task10 map marker survives a manifest-last interruption', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task9',
        write: true,
      ),
    );
    final task9ProjectSource = projectFile.readAsStringSync();
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task10',
        write: true,
      ),
    );
    expect(
      _readJson(
        File(p.join(fixture.path, 'maps', 'map_marais_salants.json')),
      )['properties']['selbrumeGeneratorBoundary'],
      'task10',
    );
    projectFile.writeAsStringSync(task9ProjectSource);
    final before = _snapshotFiles(fixture);

    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: fixture,
          through: 'task9',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('task10'), contains('task9'), contains('downgrade')),
        ),
      ),
    );
    expect(_snapshotFiles(fixture), before);
  });

  test('task11 registers the passage atlas and builds Passage des Dames',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    _writeSyntheticPassageAtlas(fixture);

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task11',
        write: true,
      ),
    );

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    final folders = manifest.tilesetFolders.where(
      (entry) => entry.id == 'tsf_selbrume_beta_passage',
    );
    expect(folders, hasLength(1));
    expect(folders.single.parentFolderId, 'tsf_selbrume_beta');
    final categories = manifest.elementCategories.where(
      (entry) => entry.id == 'cat_selbrume_passage',
    );
    expect(categories, hasLength(1));
    expect(categories.single.parentCategoryId, 'environnement');
    final tilesets = manifest.tilesets.where(
      (entry) => entry.id == 'ts_selbrume_passage_props',
    );
    expect(tilesets, hasLength(1));
    expect(
      tilesets.single.relativePath,
      'assets/tilesets/selbrume_passage_props.png',
    );
    expect(tilesets.single.folderId, 'tsf_selbrume_beta_passage');

    final passageElements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_passage_props')
          element.id: element,
    };
    expect(
      passageElements.keys,
      unorderedEquals(_passageElementContracts.keys),
    );
    for (final contract in _passageElementContracts.entries) {
      final element = passageElements[contract.key]!;
      expect(element.categoryId, 'cat_selbrume_passage');
      expect(element.frames, hasLength(1));
      expect(element.frames.single.source, contract.value.source);
      expect(element.recommendedLayerId, contract.value.layerId);
      expect(
        element.tags,
        containsAll(<String>[
          'environment',
          'passage',
          'map_passage_dames',
          'beta',
          contract.value.isStateVariant ? 'state_variant' : 'static',
        ]),
      );
      final profile = element.collisionProfile;
      if (contract.value.collisionCells.isEmpty) {
        expect(profile, isNull, reason: contract.key);
        continue;
      }
      expect(profile, isNotNull, reason: contract.key);
      expect(profile!.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, unorderedEquals(contract.value.collisionCells));
      expect(profile.shapeCells, profile.cells);
      expect(profile.visualMask, isNotNull);
      expect(profile.collisionMask, isNotNull);
      expect(profile.occlusionMask, isNull);
      expect(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 32,
          tileHeight: 32,
          sourceWidthInTiles: contract.value.source.width,
          sourceHeightInTiles: contract.value.source.height,
        ),
        unorderedEquals(contract.value.collisionCells),
      );
    }

    final passage = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_passage_dames.json'))),
    );
    expect(
      () => MapValidator.validate(passage, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(passage.size, const GridSize(width: 60, height: 24));
    expect(passage.tilesetId, isEmpty);
    expect(passage.properties['selbrumeGeneratorBoundary'], 'task11');
    expect(passage.mapMetadata.mapType, MapType.route);
    expect(passage.mapMetadata.weather, MapWeather.fog);
    expect(passage.mapMetadata.isIndoor, isFalse);
    expect(
      passage.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_path_primary',
        'l_path_secondary',
        'l_tile_ground',
        'l_tile_structures',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    for (final layer in passage.layers.whereType<TileLayer>()) {
      expect(layer.tilesetId, 'ts_selbrume_passage_props');
    }
    expect(
      passage.connections,
      unorderedEquals(<MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.north,
          targetMapId: 'map_marais_salants',
        ),
        const MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'map_phare_exterieur',
        ),
      ]),
    );
    expect(passage.warps, isEmpty);
    expect(passage.events, isEmpty);
    expect(passage.entities, isEmpty);
    expect(passage.gameplayZones, hasLength(1));
    final entryZone = passage.gameplayZones.single;
    expect(entryZone.id, 'zone_passage_entry');
    expect(entryZone.kind, GameplayZoneKind.special);
    expect(
      entryZone.area,
      const MapRect(
        pos: GridPos(x: 28, y: 0),
        size: GridSize(width: 9, height: 5),
      ),
    );
    expect(entryZone.special?.properties, <String, String>{
      'contractRole': 'navigation_anchor',
      'inert': 'true',
    });
    expect(passage.triggers, hasLength(1));
    final entryTrigger = passage.triggers.single;
    expect(entryTrigger.id, 'zone_passage_entry');
    expect(entryTrigger.type, TriggerType.custom);
    expect(entryTrigger.area, entryZone.area);
    expect(entryTrigger.properties, <String, String>{
      'eventId': 'event_enter_passage_dames',
      'reservedForNarrative': 'true',
    });

    const placedContracts =
        <String, ({String elementId, String layer, GridPos pos})>{
      'pe_passage_barriere': (
        elementId: 'el_selbrume_passage_barriere_fermee',
        layer: 'l_tile_structures',
        pos: GridPos(x: 32, y: 3),
      ),
      'pe_passage_marches': (
        elementId: 'el_selbrume_passage_marches',
        layer: 'l_tile_ground',
        pos: GridPos(x: 56, y: 13),
      ),
      'pe_passage_flaques': (
        elementId: 'el_selbrume_passage_flaques',
        layer: 'l_tile_ground',
        pos: GridPos(x: 49, y: 9),
      ),
      'pe_passage_banc_brume': (
        elementId: 'el_selbrume_passage_banc_brume',
        layer: 'l_tile_fx',
        pos: GridPos(x: 42, y: 10),
      ),
    };
    for (final contract in placedContracts.entries) {
      _expectPlacedElement(
        passage,
        id: contract.key,
        elementId: contract.value.elementId,
        layerId: contract.value.layer,
        pos: contract.value.pos,
      );
    }
    final expectedUsedElementIds = _passageElementContracts.keys
        .where((id) => id != 'el_selbrume_passage_barriere_ouverte')
        .toSet();
    expect(passage.placedElements, hasLength(expectedUsedElementIds.length));
    expect(
      passage.placedElements.map((placed) => placed.elementId).toSet(),
      expectedUsedElementIds,
    );

    final primary = passage.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_primary');
    final sea = passage.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_secondary');
    final blocked = _mapBlockedCells(passage, manifest);
    expect(primary.presetId, 'pavement_path');
    expect(sea.presetId, 'nouveau-chemin');
    for (var index = 0; index < primary.cells.length; index++) {
      expect(primary.cells[index] || sea.cells[index], isTrue);
      expect(primary.cells[index] && sea.cells[index], isFalse);
    }
    final reached = _reachableUnblockedCells(
      passage,
      blocked,
      primary.cells,
      const GridPos(x: 32, y: 0),
    );
    for (var x = 30; x <= 34; x++) {
      final index = x;
      expect(primary.cells[index], isTrue);
      expect(blocked[index], isFalse);
      expect(reached, contains(index));
    }
    for (var y = 12; y <= 16; y++) {
      final index = y * passage.size.width + 59;
      expect(primary.cells[index], isTrue);
      expect(blocked[index], isFalse);
      expect(reached, contains(index));
    }
    for (var y = 9; y <= 11; y++) {
      for (var x = 49; x <= 51; x++) {
        final index = y * passage.size.width + x;
        expect(primary.cells[index], isTrue, reason: 'shortcut ($x,$y)');
        expect(blocked[index], isFalse, reason: 'shortcut ($x,$y)');
        expect(reached, contains(index), reason: 'shortcut ($x,$y)');
      }
    }
    for (final x in const <int>[28, 29, 30, 31]) {
      final index = 4 * passage.size.width + x;
      expect(primary.cells[index], isTrue, reason: 'barrier detour x=$x');
      expect(blocked[index], isFalse, reason: 'barrier detour x=$x');
      expect(reached, contains(index), reason: 'barrier detour x=$x');
    }
    for (var x = 32; x <= 35; x++) {
      expect(blocked[4 * passage.size.width + x], isTrue);
    }
    for (final seaCell in const <GridPos>[
      GridPos(x: 29, y: 8),
      GridPos(x: 35, y: 8),
      GridPos(x: 40, y: 11),
      GridPos(x: 40, y: 17),
    ]) {
      final index = seaCell.y * passage.size.width + seaCell.x;
      expect(sea.cells[index], isTrue, reason: '$seaCell');
      expect(blocked[index], isTrue, reason: '$seaCell');
    }
    for (final passableVisual in const <GridPos>[
      GridPos(x: 44, y: 12),
      GridPos(x: 50, y: 10),
      GridPos(x: 57, y: 13),
    ]) {
      final index = passableVisual.y * passage.size.width + passableVisual.x;
      expect(blocked[index], isFalse, reason: '$passableVisual');
      expect(reached, contains(index), reason: '$passableVisual');
    }
  });

  test('task11 is idempotent preflighted and downgrade-safe', () async {
    void writeEarlierAtlases(Directory fixture) {
      _writeSyntheticPortAtlas(fixture);
      _writeSyntheticCabinAtlas(fixture);
      _writeSyntheticForestAtlas(fixture);
      _writeSyntheticMarshAtlas(fixture);
    }

    final missing = _copySelbrumeFixture();
    addTearDown(() => missing.parent.delete(recursive: true));
    writeEarlierAtlases(missing);
    final missingBefore = _snapshotFiles(missing);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: missing,
          through: 'task11',
          write: true,
        ),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.path,
          'path',
          endsWith('selbrume_passage_props.png'),
        ),
      ),
    );
    expect(_snapshotFiles(missing), missingBefore);

    final malformed = _copySelbrumeFixture();
    addTearDown(() => malformed.parent.delete(recursive: true));
    writeEarlierAtlases(malformed);
    _writeSyntheticPassageAtlas(malformed, width: 32, height: 32);
    final malformedBefore = _snapshotFiles(malformed);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: malformed,
          through: 'task11',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('selbrume_passage_props.png'), contains('512x512')),
        ),
      ),
    );
    expect(_snapshotFiles(malformed), malformedBefore);

    final rgb = _copySelbrumeFixture();
    addTearDown(() => rgb.parent.delete(recursive: true));
    writeEarlierAtlases(rgb);
    _writeSyntheticPassageAtlas(rgb, numChannels: 3);
    final rgbBefore = _snapshotFiles(rgb);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: rgb,
          through: 'task11',
          write: true,
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('selbrume_passage_props.png'),
            contains('8-bit RGBA'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(rgb), rgbBefore);

    final transparent = _copySelbrumeFixture();
    addTearDown(() => transparent.parent.delete(recursive: true));
    writeEarlierAtlases(transparent);
    _writeSyntheticPassageAtlas(transparent);
    _clearPassageAtlasPixels(
      transparent,
      x: 0,
      y: 0,
      width: 4 * 32,
      height: 3 * 32,
    );
    final transparentBefore = _snapshotFiles(transparent);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: transparent,
          through: 'task11',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('el_selbrume_passage_barriere_fermee'),
            contains('no visible pixels'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(transparent), transparentBefore);

    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    writeEarlierAtlases(fixture);
    _writeSyntheticPassageAtlas(fixture);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task11'),
      ))
          .exitCode,
      selbrumeGeneratorDivergenceExitCode,
    );
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task11',
        write: true,
      ),
    );
    final firstWrite = _snapshotFiles(fixture);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task11',
        write: true,
      ),
    );
    expect(_snapshotFiles(fixture), firstWrite);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task11'),
      ))
          .exitCode,
      0,
    );
    for (final lower in const <String>[
      'task10',
      'task9',
      'task8',
      'task7',
      'task6',
      'task5',
      'task4',
    ]) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lower,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('task11'), contains(lower), contains('downgrade')),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), firstWrite);
    }
  });

  test('task11 map marker survives a manifest-last interruption', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    _writeSyntheticPassageAtlas(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task10',
        write: true,
      ),
    );
    final task10ProjectSource = projectFile.readAsStringSync();
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task11',
        write: true,
      ),
    );
    expect(
      _readJson(
        File(p.join(fixture.path, 'maps', 'map_passage_dames.json')),
      )['properties']['selbrumeGeneratorBoundary'],
      'task11',
    );
    projectFile.writeAsStringSync(task10ProjectSource);
    final before = _snapshotFiles(fixture);

    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: fixture,
          through: 'task10',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('task11'), contains('task10'), contains('downgrade')),
        ),
      ),
    );
    expect(_snapshotFiles(fixture), before);
  });

  test('task12 registers the lighthouse atlas and builds its exterior',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    _writeSyntheticPassageAtlas(fixture);
    _writeSyntheticLighthouseExteriorAtlas(fixture);

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task12',
        write: true,
      ),
    );

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    final folders = manifest.tilesetFolders.where(
      (entry) => entry.id == 'tsf_selbrume_beta_lighthouse',
    );
    expect(folders, hasLength(1));
    expect(folders.single.parentFolderId, 'tsf_selbrume_beta');
    final categories = manifest.elementCategories.where(
      (entry) => entry.id == 'cat_selbrume_lighthouse',
    );
    expect(categories, hasLength(1));
    expect(categories.single.parentCategoryId, 'batiments');
    final tilesets = manifest.tilesets.where(
      (entry) => entry.id == 'ts_selbrume_lighthouse_exterior',
    );
    expect(tilesets, hasLength(1));
    expect(
      tilesets.single.relativePath,
      'assets/tilesets/selbrume_lighthouse_exterior.png',
    );
    expect(tilesets.single.folderId, 'tsf_selbrume_beta_lighthouse');

    final lighthouseElements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_lighthouse_exterior')
          element.id: element,
    };
    expect(
      lighthouseElements.keys,
      unorderedEquals(_lighthouseExteriorElementContracts.keys),
    );
    for (final contract in _lighthouseExteriorElementContracts.entries) {
      final element = lighthouseElements[contract.key]!;
      expect(element.categoryId, 'cat_selbrume_lighthouse');
      expect(element.frames, hasLength(1));
      expect(element.frames.single.source, contract.value.source);
      expect(element.recommendedLayerId, contract.value.layerId);
      expect(
        element.tags,
        containsAll(<String>[
          'lighthouse',
          'map_phare_exterieur',
          'beta',
          contract.value.isStateVariant ? 'state_variant' : 'static',
        ]),
      );
      final profile = element.collisionProfile;
      if (contract.value.collisionCells.isEmpty &&
          !contract.value.requiresOcclusion) {
        expect(profile, isNull, reason: contract.key);
        continue;
      }
      expect(profile, isNotNull, reason: contract.key);
      expect(profile!.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, unorderedEquals(contract.value.collisionCells));
      expect(profile.shapeCells, profile.cells);
      expect(profile.visualMask, isNotNull);
      if (contract.value.collisionCells.isEmpty) {
        expect(profile.collisionMask, isNull, reason: contract.key);
      } else {
        expect(profile.collisionMask, isNotNull, reason: contract.key);
        expect(
          ElementCollisionMaskCodec.cellsFromPixelMask(
            mask: profile.collisionMask!,
            tileWidth: 32,
            tileHeight: 32,
            sourceWidthInTiles: contract.value.source.width,
            sourceHeightInTiles: contract.value.source.height,
          ),
          unorderedEquals(contract.value.collisionCells),
          reason: contract.key,
        );
      }
      if (contract.value.requiresOcclusion) {
        expect(profile.occlusionMask, isNotNull, reason: contract.key);
        expect(
          ElementCollisionMaskCodec.cellsFromPixelMask(
            mask: profile.occlusionMask!,
            tileWidth: 32,
            tileHeight: 32,
            sourceWidthInTiles: contract.value.source.width,
            sourceHeightInTiles: contract.value.source.height,
          ),
          unorderedEquals(contract.value.occlusionCells),
          reason: contract.key,
        );
      } else {
        expect(profile.occlusionMask, isNull, reason: contract.key);
      }
    }

    final exterior = MapData.fromJson(
      _readJson(File(
        p.join(fixture.path, 'maps', 'map_phare_exterieur.json'),
      )),
    );
    expect(
      () => MapValidator.validate(exterior, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(exterior.size, const GridSize(width: 45, height: 45));
    expect(exterior.tilesetId, isEmpty);
    expect(exterior.properties['selbrumeGeneratorBoundary'], 'task12');
    expect(exterior.mapMetadata.mapType, MapType.building);
    expect(exterior.mapMetadata.weather, MapWeather.fog);
    expect(exterior.mapMetadata.isIndoor, isFalse);
    expect(
      exterior.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_path_primary',
        'l_path_secondary',
        'l_tile_ground',
        'l_tile_structures',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    for (final layer in exterior.layers.whereType<TileLayer>()) {
      expect(layer.tilesetId, 'ts_selbrume_lighthouse_exterior');
    }
    expect(
      exterior.connections,
      const <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'map_passage_dames',
        ),
      ],
    );
    expect(exterior.events, isEmpty);
    expect(exterior.entities, isEmpty);
    _expectSpecialZone(exterior, 'zone_lighthouse_entry', 0, 10, 8, 8);
    _expectReservedTrigger(
      exterior,
      'zone_lighthouse_entry',
      'event_lighthouse_exterior_arrival',
      0,
      10,
      8,
      8,
    );
    expect(
      exterior.warps,
      unorderedEquals(const <MapWarp>[
        MapWarp(
          id: 'warp_phare_ext_to_interieur',
          pos: GridPos(x: 23, y: 18),
          targetMapId: 'map_phare_interieur',
          targetPos: GridPos(x: 18, y: 42),
        ),
        MapWarp(
          id: 'warp_phare_ext_to_cabane',
          pos: GridPos(x: 8, y: 33),
          targetMapId: 'map_cabane_gardien',
          targetPos: GridPos(x: 10, y: 13),
        ),
      ]),
    );

    const placedContracts =
        <String, ({String elementId, String layer, GridPos pos})>{
      'pe_phare_batiment': (
        elementId: 'el_selbrume_phare_batiment',
        layer: 'l_tile_structures',
        pos: GridPos(x: 19, y: 8),
      ),
      'pe_phare_cabane_facade': (
        elementId: 'el_selbrume_cabane_facade',
        layer: 'l_tile_structures',
        pos: GridPos(x: 6, y: 28),
      ),
      'pe_phare_porte_ouverte': (
        elementId: 'el_selbrume_phare_porte_ouverte',
        layer: 'l_tile_structures',
        pos: GridPos(x: 22, y: 16),
      ),
      'pe_phare_cabane_porte_ouverte': (
        elementId: 'el_selbrume_cabane_porte_ouverte',
        layer: 'l_tile_structures',
        pos: GridPos(x: 7, y: 32),
      ),
      'pe_phare_fenetre_sombre': (
        elementId: 'el_selbrume_phare_fenetre_sombre',
        layer: 'l_tile_structures',
        pos: GridPos(x: 21, y: 11),
      ),
      'pe_phare_rambarde': (
        elementId: 'el_selbrume_phare_rambarde',
        layer: 'l_tile_structures',
        pos: GridPos(x: 29, y: 19),
      ),
      'pe_phare_fondation': (
        elementId: 'el_selbrume_phare_fondation',
        layer: 'l_tile_ground',
        pos: GridPos(x: 19, y: 17),
      ),
      'pe_phare_panneau': (
        elementId: 'el_selbrume_phare_panneau',
        layer: 'l_tile_structures',
        pos: GridPos(x: 2, y: 18),
      ),
      'pe_phare_debris': (
        elementId: 'el_selbrume_phare_debris',
        layer: 'l_tile_structures',
        pos: GridPos(x: 28, y: 27),
      ),
      'pe_phare_marches': (
        elementId: 'el_selbrume_phare_marches',
        layer: 'l_tile_ground',
        pos: GridPos(x: 22, y: 18),
      ),
    };
    for (final contract in placedContracts.entries) {
      _expectPlacedElement(
        exterior,
        id: contract.key,
        elementId: contract.value.elementId,
        layerId: contract.value.layer,
        pos: contract.value.pos,
      );
    }
    final expectedUsedIds = _lighthouseExteriorElementContracts.keys
        .where(
          (id) =>
              id != 'el_selbrume_phare_porte_fermee' &&
              id != 'el_selbrume_cabane_porte_fermee' &&
              id != 'el_selbrume_phare_fenetre_lumineuse',
        )
        .toSet();
    expect(exterior.placedElements, hasLength(expectedUsedIds.length));
    expect(
      exterior.placedElements.map((placed) => placed.elementId).toSet(),
      expectedUsedIds,
    );

    final primary = exterior.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_primary');
    final secondary = exterior.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_secondary');
    expect(primary.presetId, 'pavement_path');
    expect(secondary.presetId, 'dirth_path');
    for (var index = 0; index < primary.cells.length; index++) {
      expect(primary.cells[index] && secondary.cells[index], isFalse);
    }
    final blocked = _mapBlockedCells(exterior, manifest);
    final allowed = <bool>[
      for (var index = 0; index < primary.cells.length; index++)
        primary.cells[index] || secondary.cells[index],
    ];
    final staticCollisions =
        exterior.layers.whereType<CollisionLayer>().single.collisions;
    for (var index = 0; index < allowed.length; index++) {
      expect(staticCollisions[index], !allowed[index], reason: 'cell $index');
    }
    final reached = _reachableUnblockedCells(
      exterior,
      blocked,
      allowed,
      const GridPos(x: 0, y: 14),
    );
    for (var y = 12; y <= 16; y++) {
      final index = y * exterior.size.width;
      expect(primary.cells[index], isTrue, reason: 'west approach y=$y');
      expect(blocked[index], isFalse, reason: 'west approach y=$y');
      expect(reached, contains(index), reason: 'west approach y=$y');
    }
    for (final target in const <GridPos>[
      GridPos(x: 23, y: 18),
      GridPos(x: 23, y: 19),
      GridPos(x: 8, y: 33),
      GridPos(x: 8, y: 34),
    ]) {
      final index = target.y * exterior.size.width + target.x;
      expect(blocked[index], isFalse, reason: '$target');
      expect(reached, contains(index), reason: '$target');
    }
    for (final seaOrCliff in const <GridPos>[
      GridPos(x: 40, y: 5),
      GridPos(x: 42, y: 40),
      GridPos(x: 2, y: 42),
    ]) {
      expect(
        blocked[seaOrCliff.y * exterior.size.width + seaOrCliff.x],
        isTrue,
        reason: '$seaOrCliff',
      );
    }
    for (final wall in const <GridPos>[
      GridPos(x: 22, y: 8),
      GridPos(x: 24, y: 12),
      GridPos(x: 22, y: 17),
      GridPos(x: 6, y: 28),
      GridPos(x: 10, y: 31),
      GridPos(x: 7, y: 32),
    ]) {
      expect(
        blocked[wall.y * exterior.size.width + wall.x],
        isTrue,
        reason: '$wall',
      );
    }
  });

  test('task12 is idempotent preflighted and downgrade-safe', () async {
    void writeEarlierAtlases(Directory fixture) {
      _writeSyntheticPortAtlas(fixture);
      _writeSyntheticCabinAtlas(fixture);
      _writeSyntheticForestAtlas(fixture);
      _writeSyntheticMarshAtlas(fixture);
      _writeSyntheticPassageAtlas(fixture);
    }

    final missing = _copySelbrumeFixture();
    addTearDown(() => missing.parent.delete(recursive: true));
    writeEarlierAtlases(missing);
    final missingBefore = _snapshotFiles(missing);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: missing,
          through: 'task12',
          write: true,
        ),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.path,
          'path',
          endsWith('selbrume_lighthouse_exterior.png'),
        ),
      ),
    );
    expect(_snapshotFiles(missing), missingBefore);

    final malformed = _copySelbrumeFixture();
    addTearDown(() => malformed.parent.delete(recursive: true));
    writeEarlierAtlases(malformed);
    _writeSyntheticLighthouseExteriorAtlas(malformed, width: 32, height: 32);
    final malformedBefore = _snapshotFiles(malformed);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: malformed,
          through: 'task12',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('selbrume_lighthouse_exterior.png'),
            contains('512x512'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(malformed), malformedBefore);

    final rgb = _copySelbrumeFixture();
    addTearDown(() => rgb.parent.delete(recursive: true));
    writeEarlierAtlases(rgb);
    _writeSyntheticLighthouseExteriorAtlas(rgb, numChannels: 3);
    final rgbBefore = _snapshotFiles(rgb);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: rgb,
          through: 'task12',
          write: true,
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('selbrume_lighthouse_exterior.png'),
            contains('8-bit RGBA'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(rgb), rgbBefore);

    final transparent = _copySelbrumeFixture();
    addTearDown(() => transparent.parent.delete(recursive: true));
    writeEarlierAtlases(transparent);
    _writeSyntheticLighthouseExteriorAtlas(transparent);
    _clearLighthouseExteriorAtlasPixels(
      transparent,
      x: 0,
      y: 0,
      width: 8 * 32,
      height: 10 * 32,
    );
    final transparentBefore = _snapshotFiles(transparent);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: transparent,
          through: 'task12',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('el_selbrume_phare_batiment'),
            contains('no visible pixels'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(transparent), transparentBefore);

    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    writeEarlierAtlases(fixture);
    _writeSyntheticLighthouseExteriorAtlas(fixture);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task12'),
      ))
          .exitCode,
      selbrumeGeneratorDivergenceExitCode,
    );
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task12',
        write: true,
      ),
    );
    final firstWrite = _snapshotFiles(fixture);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task12',
        write: true,
      ),
    );
    expect(_snapshotFiles(fixture), firstWrite);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task12'),
      ))
          .exitCode,
      0,
    );
    for (final lower in const <String>[
      'task11',
      'task10',
      'task9',
      'task8',
      'task7',
      'task6',
      'task5',
      'task4',
    ]) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lower,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('task12'), contains(lower), contains('downgrade')),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), firstWrite);
    }
  });

  test('task12 map marker survives a manifest-last interruption', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    _writeSyntheticPassageAtlas(fixture);
    _writeSyntheticLighthouseExteriorAtlas(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task11',
        write: true,
      ),
    );
    final task11ProjectSource = projectFile.readAsStringSync();
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task12',
        write: true,
      ),
    );
    expect(
      _readJson(
        File(p.join(fixture.path, 'maps', 'map_phare_exterieur.json')),
      )['properties']['selbrumeGeneratorBoundary'],
      'task12',
    );
    projectFile.writeAsStringSync(task11ProjectSource);
    final before = _snapshotFiles(fixture);

    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: fixture,
          through: 'task11',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('task12'), contains('task11'), contains('downgrade')),
        ),
      ),
    );
    expect(_snapshotFiles(fixture), before);
  });

  test('task13 registers the interior atlas and builds the lighthouse dungeon',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    _writeSyntheticPassageAtlas(fixture);
    _writeSyntheticLighthouseExteriorAtlas(fixture);
    _writeSyntheticLighthouseInteriorAtlas(fixture);

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task13',
        write: true,
      ),
    );

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    expect(
      manifest.tilesetFolders
          .where((entry) => entry.id == 'tsf_selbrume_beta_lighthouse'),
      hasLength(1),
    );
    expect(
      manifest.elementCategories
          .where((entry) => entry.id == 'cat_selbrume_lighthouse'),
      hasLength(1),
    );
    final tilesets = manifest.tilesets.where(
      (entry) => entry.id == 'ts_selbrume_lighthouse_interior',
    );
    expect(tilesets, hasLength(1));
    expect(
      tilesets.single.relativePath,
      'assets/tilesets/selbrume_lighthouse_interior.png',
    );
    expect(tilesets.single.folderId, 'tsf_selbrume_beta_lighthouse');

    final elements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_lighthouse_interior')
          element.id: element,
    };
    expect(
      elements.keys,
      unorderedEquals(_lighthouseInteriorElementContracts.keys),
    );
    for (final contract in _lighthouseInteriorElementContracts.entries) {
      final element = elements[contract.key]!;
      expect(element.categoryId, 'cat_selbrume_lighthouse');
      expect(element.frames, hasLength(1));
      expect(element.frames.single.source, contract.value.source);
      expect(element.recommendedLayerId, contract.value.layerId);
      expect(
        element.tags,
        containsAll(<String>[
          'lighthouse',
          'interior',
          contract.value.mapTag,
          'beta',
          'static',
        ]),
      );
      final profile = element.collisionProfile;
      if (contract.value.collisionCells.isEmpty) {
        expect(profile, isNull, reason: contract.key);
        continue;
      }
      expect(profile, isNotNull, reason: contract.key);
      expect(profile!.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, unorderedEquals(contract.value.collisionCells));
      expect(profile.shapeCells, profile.cells);
      expect(profile.visualMask, isNotNull);
      expect(profile.collisionMask, isNotNull);
      expect(profile.occlusionMask, isNull);
      expect(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 32,
          tileHeight: 32,
          sourceWidthInTiles: contract.value.source.width,
          sourceHeightInTiles: contract.value.source.height,
        ),
        unorderedEquals(contract.value.collisionCells),
        reason: contract.key,
      );
    }

    final interior = MapData.fromJson(
      _readJson(File(
        p.join(fixture.path, 'maps', 'map_phare_interieur.json'),
      )),
    );
    expect(
      () => MapValidator.validate(interior, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(interior.size, const GridSize(width: 36, height: 45));
    expect(interior.tilesetId, isEmpty);
    expect(interior.properties['selbrumeGeneratorBoundary'], 'task13');
    expect(interior.mapMetadata.mapType, MapType.interior);
    expect(interior.mapMetadata.isIndoor, isTrue);
    expect(
      interior.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_tile_floor',
        'l_tile_walls',
        'l_tile_furniture',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    for (final layer in interior.layers.whereType<TileLayer>()) {
      expect(
        layer.tilesetId,
        layer.id == 'l_tile_fx'
            ? 'ts_selbrume_lighthouse_fx'
            : 'ts_selbrume_lighthouse_interior',
        reason: layer.id,
      );
    }
    expect(
      interior.layers.whereType<CollisionLayer>().single.collisions,
      everyElement(isFalse),
      reason: 'Task13 has no invisible/static collision cells.',
    );
    expect(interior.events, isEmpty);
    expect(interior.entities, isEmpty);
    expect(
      interior.warps,
      unorderedEquals(const <MapWarp>[
        MapWarp(
          id: 'warp_phare_interieur_to_exterieur',
          pos: GridPos(x: 18, y: 44),
          targetMapId: 'map_phare_exterieur',
          targetPos: GridPos(x: 23, y: 19),
        ),
        MapWarp(
          id: 'warp_phare_interieur_to_sommet',
          pos: GridPos(x: 18, y: 1),
          targetMapId: 'map_sommet_phare',
          targetPos: GridPos(x: 12, y: 22),
        ),
      ]),
    );
    _expectSpecialZone(interior, 'zone_lighthouse_floor_1', 6, 32, 24, 11);
    _expectSpecialZone(interior, 'zone_lighthouse_top_access', 14, 0, 8, 4);
    _expectReservedTrigger(
      interior,
      'tr_phare_note',
      'event_selbrume_phare_note_ancien_gardien',
      10,
      24,
      2,
      2,
    );
    expect(interior.gameplayZones, hasLength(2));
    expect(interior.triggers, hasLength(1));

    const keyPlacements =
        <String, ({String elementId, String layer, GridPos pos})>{
      'pe_phare_escalier_haut': (
        elementId: 'el_selbrume_phare_escalier_haut',
        layer: 'l_tile_floor',
        pos: GridPos(x: 17, y: 0),
      ),
      'pe_phare_escalier_bas': (
        elementId: 'el_selbrume_phare_escalier_bas',
        layer: 'l_tile_floor',
        pos: GridPos(x: 17, y: 42),
      ),
      'pe_phare_note_ancien_gardien': (
        elementId: 'el_selbrume_phare_bureau_note',
        layer: 'l_tile_furniture',
        pos: GridPos(x: 10, y: 24),
      ),
      'pe_phare_mecanisme': (
        elementId: 'el_selbrume_phare_mecanisme',
        layer: 'l_tile_furniture',
        pos: GridPos(x: 25, y: 23),
      ),
      'pe_phare_trappe': (
        elementId: 'el_selbrume_phare_trappe',
        layer: 'l_tile_floor',
        pos: GridPos(x: 28, y: 29),
      ),
    };
    for (final contract in keyPlacements.entries) {
      _expectPlacedElement(
        interior,
        id: contract.key,
        elementId: contract.value.elementId,
        layerId: contract.value.layer,
        pos: contract.value.pos,
      );
    }
    final expectedUsedIds = _lighthouseInteriorElementContracts.entries
        .where((entry) => entry.value.mapTag == 'map_phare_interieur')
        .map((entry) => entry.key)
        .toSet();
    expect(
      interior.placedElements.map((placed) => placed.elementId).toSet(),
      expectedUsedIds,
    );
    expect(
      interior.placedElements.map((placed) => placed.elementId),
      isNot(contains(anyOf(
        'el_selbrume_sommet_plateforme',
        'el_selbrume_sommet_parapet_h',
        'el_selbrume_sommet_parapet_v',
        'el_selbrume_sommet_lanterne',
      ))),
    );

    final blocked = _mapBlockedCells(interior, manifest);
    final reached = _reachableUnblockedCells(
      interior,
      blocked,
      List<bool>.filled(36 * 45, true),
      const GridPos(x: 18, y: 42),
    );
    for (final target in const <GridPos>[
      GridPos(x: 18, y: 44),
      GridPos(x: 18, y: 42),
      GridPos(x: 10, y: 24),
      GridPos(x: 10, y: 26),
      GridPos(x: 18, y: 2),
      GridPos(x: 18, y: 1),
      GridPos(x: 26, y: 28),
      GridPos(x: 27, y: 28),
      GridPos(x: 28, y: 28),
      GridPos(x: 28, y: 29),
      GridPos(x: 29, y: 30),
    ]) {
      final index = target.y * interior.size.width + target.x;
      expect(blocked[index], isFalse, reason: '$target');
      expect(reached, contains(index), reason: '$target');
    }
    for (final wall in const <GridPos>[
      GridPos(x: 0, y: 10),
      GridPos(x: 35, y: 10),
      GridPos(x: 2, y: 31),
      GridPos(x: 14, y: 20),
      GridPos(x: 22, y: 25),
      GridPos(x: 25, y: 23),
      GridPos(x: 27, y: 8),
    ]) {
      expect(
        blocked[wall.y * interior.size.width + wall.x],
        isTrue,
        reason: '$wall',
      );
    }
    for (final gap in const <GridPos>[
      GridPos(x: 18, y: 31),
      GridPos(x: 19, y: 31),
      GridPos(x: 10, y: 20),
      GridPos(x: 11, y: 20),
      GridPos(x: 26, y: 20),
      GridPos(x: 27, y: 20),
    ]) {
      final index = gap.y * interior.size.width + gap.x;
      expect(blocked[index], isFalse, reason: '$gap');
      expect(reached, contains(index), reason: '$gap');
    }

    final exterior = MapData.fromJson(
      _readJson(File(
        p.join(fixture.path, 'maps', 'map_phare_exterieur.json'),
      )),
    );
    expect(
      exterior.warps.where(
        (warp) =>
            warp.id == 'warp_phare_ext_to_interieur' &&
            warp.targetMapId == interior.id &&
            warp.targetPos == const GridPos(x: 18, y: 42),
      ),
      hasLength(1),
    );
    final top = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_sommet_phare.json'))),
    );
    expect(
      top.warps.where(
        (warp) =>
            warp.id == 'warp_sommet_to_phare_interieur' &&
            warp.targetMapId == interior.id &&
            warp.targetPos == const GridPos(x: 18, y: 2),
      ),
      hasLength(1),
    );
  });

  test('task13 is idempotent preflighted and downgrade-safe', () async {
    void writeEarlierAtlases(Directory fixture) {
      _writeSyntheticPortAtlas(fixture);
      _writeSyntheticCabinAtlas(fixture);
      _writeSyntheticForestAtlas(fixture);
      _writeSyntheticMarshAtlas(fixture);
      _writeSyntheticPassageAtlas(fixture);
      _writeSyntheticLighthouseExteriorAtlas(fixture);
    }

    final missing = _copySelbrumeFixture();
    addTearDown(() => missing.parent.delete(recursive: true));
    writeEarlierAtlases(missing);
    final missingBefore = _snapshotFiles(missing);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: missing,
          through: 'task13',
          write: true,
        ),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.path,
          'path',
          endsWith('selbrume_lighthouse_interior.png'),
        ),
      ),
    );
    expect(_snapshotFiles(missing), missingBefore);

    final malformed = _copySelbrumeFixture();
    addTearDown(() => malformed.parent.delete(recursive: true));
    writeEarlierAtlases(malformed);
    _writeSyntheticLighthouseInteriorAtlas(
      malformed,
      width: 32,
      height: 32,
    );
    final malformedBefore = _snapshotFiles(malformed);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: malformed,
          through: 'task13',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('selbrume_lighthouse_interior.png'),
            contains('1024x1024'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(malformed), malformedBefore);

    final rgb = _copySelbrumeFixture();
    addTearDown(() => rgb.parent.delete(recursive: true));
    writeEarlierAtlases(rgb);
    _writeSyntheticLighthouseInteriorAtlas(rgb, numChannels: 3);
    final rgbBefore = _snapshotFiles(rgb);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: rgb,
          through: 'task13',
          write: true,
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('selbrume_lighthouse_interior.png'),
            contains('8-bit RGBA'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(rgb), rgbBefore);

    final transparent = _copySelbrumeFixture();
    addTearDown(() => transparent.parent.delete(recursive: true));
    writeEarlierAtlases(transparent);
    _writeSyntheticLighthouseInteriorAtlas(transparent);
    _clearLighthouseInteriorAtlasPixels(
      transparent,
      x: 22 * 32,
      y: 4 * 32,
      width: 5 * 32,
      height: 5 * 32,
    );
    final transparentBefore = _snapshotFiles(transparent);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: transparent,
          through: 'task13',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('el_selbrume_phare_mecanisme'),
            contains('no visible pixels'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(transparent), transparentBefore);

    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    writeEarlierAtlases(fixture);
    _writeSyntheticLighthouseInteriorAtlas(fixture);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task13'),
      ))
          .exitCode,
      selbrumeGeneratorDivergenceExitCode,
    );
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task13',
        write: true,
      ),
    );
    final firstWrite = _snapshotFiles(fixture);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task13',
        write: true,
      ),
    );
    expect(_snapshotFiles(fixture), firstWrite);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task13'),
      ))
          .exitCode,
      0,
    );
    for (final lower in const <String>[
      'task12',
      'task11',
      'task10',
      'task9',
      'task8',
      'task7',
      'task6',
      'task5',
      'task4',
    ]) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lower,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('task13'), contains(lower), contains('downgrade')),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), firstWrite);
    }
  });

  test('task13 map marker survives a manifest-last interruption', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    _writeSyntheticPassageAtlas(fixture);
    _writeSyntheticLighthouseExteriorAtlas(fixture);
    _writeSyntheticLighthouseInteriorAtlas(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task12',
        write: true,
      ),
    );
    final task12ProjectSource = projectFile.readAsStringSync();
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task13',
        write: true,
      ),
    );
    expect(
      _readJson(
        File(p.join(fixture.path, 'maps', 'map_phare_interieur.json')),
      )['properties']['selbrumeGeneratorBoundary'],
      'task13',
    );
    projectFile.writeAsStringSync(task12ProjectSource);
    final before = _snapshotFiles(fixture);

    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: fixture,
          through: 'task12',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('task13'), contains('task12'), contains('downgrade')),
        ),
      ),
    );
    expect(_snapshotFiles(fixture), before);
  });

  test('task14 registers exact FX animations and builds the readable summit',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    _writeSyntheticPassageAtlas(fixture);
    _writeSyntheticLighthouseExteriorAtlas(fixture);
    _writeSyntheticLighthouseInteriorAtlas(fixture);
    _writeSyntheticLighthouseFxAtlas(fixture);

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task14',
        write: true,
      ),
    );

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    final fxFolders = manifest.tilesetFolders.where(
      (entry) => entry.id == 'tsf_selbrume_beta_fx',
    );
    expect(fxFolders, hasLength(1));
    expect(fxFolders.single.parentFolderId, 'tsf_selbrume_beta');
    final fxCategories = manifest.elementCategories.where(
      (entry) => entry.id == 'cat_selbrume_fx',
    );
    expect(fxCategories, hasLength(1));
    expect(fxCategories.single.parentCategoryId, 'environnement');
    final fxTilesets = manifest.tilesets.where(
      (entry) => entry.id == 'ts_selbrume_lighthouse_fx',
    );
    expect(fxTilesets, hasLength(1));
    expect(
      fxTilesets.single.relativePath,
      'assets/tilesets/selbrume_lighthouse_fx.png',
    );
    expect(fxTilesets.single.folderId, 'tsf_selbrume_beta_fx');

    final atlas = img.decodePng(
      File(
        p.join(
          fixture.path,
          'assets',
          'tilesets',
          'selbrume_lighthouse_fx.png',
        ),
      ).readAsBytesSync(),
    )!;
    expect((atlas.width, atlas.height, atlas.numChannels), (512, 512, 4));
    expect(atlas.hasAlpha, isTrue);

    final fxElements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_lighthouse_fx')
          element.id: element,
    };
    expect(
        fxElements.keys, unorderedEquals(_lighthouseFxElementContracts.keys));
    for (final contract in _lighthouseFxElementContracts.entries) {
      final element = fxElements[contract.key]!;
      expect(element.categoryId, 'cat_selbrume_fx', reason: contract.key);
      expect(element.frames, contract.value.frames, reason: contract.key);
      expect(
        element.recommendedLayerId,
        'l_tile_fx',
        reason: contract.key,
      );
      expect(element.collisionProfile, isNull, reason: contract.key);
      expect(
        element.tags,
        containsAll(<String>[
          'environment',
          'lighthouse',
          'fx',
          'map_sommet_phare',
          'beta',
          if (contract.value.stateVariant) 'state_variant',
          if (contract.value.animated)
            'animated'
          else if (!contract.value.stateVariant)
            'static',
        ]),
        reason: contract.key,
      );
      final firstSource = element.frames.first.source;
      for (var frameIndex = 0;
          frameIndex < element.frames.length;
          frameIndex++) {
        final frame = element.frames[frameIndex];
        expect(
          (frame.source.width, frame.source.height),
          (firstSource.width, firstSource.height),
          reason: '${contract.key} frame ${frameIndex + 1} footprint',
        );
        var visiblePixels = 0;
        for (var y = frame.source.y * 32;
            y < (frame.source.y + frame.source.height) * 32;
            y++) {
          for (var x = frame.source.x * 32;
              x < (frame.source.x + frame.source.width) * 32;
              x++) {
            if (atlas.getPixel(x, y).a.toInt() > 24) visiblePixels++;
          }
        }
        expect(
          visiblePixels,
          greaterThan(0),
          reason: '${contract.key} frame ${frameIndex + 1}',
        );
      }
    }

    final top = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_sommet_phare.json'))),
    );
    expect(
      () => MapValidator.validate(top, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(top.size, const GridSize(width: 24, height: 24));
    expect(top.tilesetId, isEmpty);
    expect(top.properties['selbrumeGeneratorBoundary'], 'task14');
    expect(top.mapMetadata.mapType, MapType.interior);
    expect(top.mapMetadata.isIndoor, isTrue);
    expect(
      top.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_tile_floor',
        'l_tile_walls',
        'l_tile_furniture',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    final tileLayers = <String, TileLayer>{
      for (final layer in top.layers.whereType<TileLayer>()) layer.id: layer,
    };
    expect(
      tileLayers['l_tile_floor']?.tilesetId,
      'ts_selbrume_lighthouse_interior',
    );
    expect(
      tileLayers['l_tile_walls']?.tilesetId,
      'ts_selbrume_lighthouse_interior',
    );
    expect(
      tileLayers['l_tile_furniture']?.tilesetId,
      'ts_selbrume_lighthouse_interior',
    );
    expect(
      tileLayers['l_tile_overhead']?.tilesetId,
      'ts_selbrume_lighthouse_interior',
    );
    expect(
      tileLayers['l_tile_fx']?.tilesetId,
      'ts_selbrume_lighthouse_fx',
    );
    for (final layer in tileLayers.values) {
      expect(layer.tiles, everyElement(0), reason: layer.id);
    }
    expect(
      top.layers.whereType<CollisionLayer>().single.collisions,
      everyElement(isFalse),
      reason: 'Task14 has no invisible/static collision cells.',
    );
    expect(top.connections, isEmpty);
    expect(top.events, isEmpty);
    expect(top.entities, isEmpty);
    expect(
      top.warps,
      const <MapWarp>[
        MapWarp(
          id: 'warp_sommet_to_phare_interieur',
          pos: GridPos(x: 12, y: 23),
          targetMapId: 'map_phare_interieur',
          targetPos: GridPos(x: 18, y: 2),
        ),
      ],
    );
    _expectSpecialZone(top, 'zone_lighthouse_top', 7, 5, 10, 10);
    expect(top.gameplayZones, hasLength(1));
    _expectReservedTrigger(
      top,
      'tr_sommet_confrontation',
      'event_selbrume_sommet_confrontation',
      12,
      10,
      1,
      1,
    );
    _expectReservedTrigger(
      top,
      'tr_lighthouse_top',
      'event_final_pokemon_scene',
      7,
      5,
      10,
      10,
    );
    expect(top.triggers, hasLength(2));

    const keyPlacements = <String,
        ({String elementId, String layerId, GridPos pos, bool collision})>{
      'pe_sommet_plateforme': (
        elementId: 'el_selbrume_sommet_plateforme',
        layerId: 'l_tile_floor',
        pos: GridPos(x: 9, y: 7),
        collision: false,
      ),
      'pe_sommet_lanterne': (
        elementId: 'el_selbrume_sommet_lanterne',
        layerId: 'l_tile_furniture',
        pos: GridPos(x: 10, y: 0),
        collision: true,
      ),
      'pe_sommet_trappe': (
        elementId: 'el_selbrume_phare_trappe',
        layerId: 'l_tile_floor',
        pos: GridPos(x: 11, y: 22),
        collision: false,
      ),
      'pe_sommet_mecanisme': (
        elementId: 'el_selbrume_phare_mecanisme',
        layerId: 'l_tile_furniture',
        pos: GridPos(x: 17, y: 15),
        collision: true,
      ),
      'pe_sommet_lumiere_eteinte': (
        elementId: 'el_selbrume_fx_lumiere_eteinte',
        layerId: 'l_tile_fx',
        pos: GridPos(x: 10, y: 0),
        collision: false,
      ),
    };
    for (final contract in keyPlacements.entries) {
      final placed = _expectPlacedElement(
        top,
        id: contract.key,
        elementId: contract.value.elementId,
        layerId: contract.value.layerId,
        pos: contract.value.pos,
      );
      expect(
        placed.applyCollision,
        contract.value.collision,
        reason: contract.key,
      );
    }
    expect(
      top.placedElements.where(
        (placed) => placed.elementId == 'el_selbrume_sommet_parapet_h',
      ),
      hasLength(8),
    );
    expect(
      top.placedElements.where(
        (placed) => placed.elementId == 'el_selbrume_sommet_parapet_v',
      ),
      hasLength(10),
    );
    expect(
      top.placedElements
          .where((placed) => placed.elementId.startsWith('el_selbrume_fx_'))
          .map((placed) => placed.elementId),
      <String>['el_selbrume_fx_lumiere_eteinte'],
      reason: 'Off is the only initially rendered light state.',
    );
    for (final placed in top.placedElements.where(
      (placed) => placed.elementId.startsWith('el_selbrume_fx_'),
    )) {
      expect(placed.layerId, 'l_tile_fx');
      expect(placed.applyCollision, isFalse);
    }

    final elementsById = <String, ProjectElementEntry>{
      for (final element in manifest.elements) element.id: element,
    };
    for (final placed in top.placedElements) {
      final element = elementsById[placed.elementId]!;
      final source = element.frames.first.source;
      expect(placed.pos.x + source.width, lessThanOrEqualTo(top.size.width));
      expect(placed.pos.y + source.height, lessThanOrEqualTo(top.size.height));
    }
    final blocked = _mapBlockedCells(top, manifest);
    for (var y = 5; y < 15; y++) {
      for (var x = 7; x < 17; x++) {
        expect(
          blocked[y * top.size.width + x],
          isFalse,
          reason: 'zone_lighthouse_top must stay free at ($x,$y)',
        );
      }
    }
    final reached = _reachableUnblockedCells(
      top,
      blocked,
      List<bool>.filled(24 * 24, true),
      const GridPos(x: 12, y: 22),
    );
    for (final target in const <GridPos>[
      GridPos(x: 12, y: 22),
      GridPos(x: 12, y: 23),
      GridPos(x: 12, y: 10),
    ]) {
      final index = target.y * top.size.width + target.x;
      expect(blocked[index], isFalse, reason: '$target');
      expect(reached, contains(index), reason: '$target');
    }
    for (final placed in top.placedElements.where(
      (placed) => placed.elementId.startsWith('el_selbrume_sommet_parapet_'),
    )) {
      final cells = elementsById[placed.elementId]!.collisionProfile!.cells;
      for (final cell in cells) {
        final x = placed.pos.x + cell.x;
        final y = placed.pos.y + cell.y;
        expect(blocked[y * top.size.width + x], isTrue, reason: placed.id);
      }
    }
    expect(
      manifest.groups
          .singleWhere((group) => group.id == 'group_selbrume_bourg')
          .properties['selbrumeGeneratorBoundary'],
      'task14',
    );
  });

  test('task14 is idempotent preflighted and downgrade-safe', () async {
    void writeEarlierAtlases(Directory fixture) {
      _writeSyntheticPortAtlas(fixture);
      _writeSyntheticCabinAtlas(fixture);
      _writeSyntheticForestAtlas(fixture);
      _writeSyntheticMarshAtlas(fixture);
      _writeSyntheticPassageAtlas(fixture);
      _writeSyntheticLighthouseExteriorAtlas(fixture);
      _writeSyntheticLighthouseInteriorAtlas(fixture);
    }

    final missing = _copySelbrumeFixture();
    addTearDown(() => missing.parent.delete(recursive: true));
    writeEarlierAtlases(missing);
    final missingBefore = _snapshotFiles(missing);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: missing,
          through: 'task14',
          write: true,
        ),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.path,
          'path',
          endsWith('selbrume_lighthouse_fx.png'),
        ),
      ),
    );
    expect(_snapshotFiles(missing), missingBefore);

    final malformed = _copySelbrumeFixture();
    addTearDown(() => malformed.parent.delete(recursive: true));
    writeEarlierAtlases(malformed);
    _writeSyntheticLighthouseFxAtlas(malformed, width: 32, height: 32);
    final malformedBefore = _snapshotFiles(malformed);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: malformed,
          through: 'task14',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('selbrume_lighthouse_fx.png'), contains('512x512')),
        ),
      ),
    );
    expect(_snapshotFiles(malformed), malformedBefore);

    final rgb = _copySelbrumeFixture();
    addTearDown(() => rgb.parent.delete(recursive: true));
    writeEarlierAtlases(rgb);
    _writeSyntheticLighthouseFxAtlas(rgb, numChannels: 3);
    final rgbBefore = _snapshotFiles(rgb);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: rgb,
          through: 'task14',
          write: true,
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('selbrume_lighthouse_fx.png'),
            contains('8-bit RGBA'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(rgb), rgbBefore);

    final transparent = _copySelbrumeFixture();
    addTearDown(() => transparent.parent.delete(recursive: true));
    writeEarlierAtlases(transparent);
    _writeSyntheticLighthouseFxAtlas(transparent);
    _clearLighthouseFxAtlasPixels(
      transparent,
      x: 8 * 32,
      y: 10 * 32,
      width: 4 * 32,
      height: 4 * 32,
    );
    final transparentBefore = _snapshotFiles(transparent);
    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: transparent,
          through: 'task14',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(
            contains('el_selbrume_fx_lumiere_instable'),
            contains('frame 3'),
            contains('no visible pixels'),
          ),
        ),
      ),
    );
    expect(_snapshotFiles(transparent), transparentBefore);

    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    writeEarlierAtlases(fixture);
    _writeSyntheticLighthouseFxAtlas(fixture);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task14'),
      ))
          .exitCode,
      selbrumeGeneratorDivergenceExitCode,
    );
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task14',
        write: true,
      ),
    );
    final firstWrite = _snapshotFiles(fixture);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task14',
        write: true,
      ),
    );
    expect(_snapshotFiles(fixture), firstWrite);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task14'),
      ))
          .exitCode,
      0,
    );
    for (final lower in const <String>[
      'task13',
      'task12',
      'task11',
      'task10',
      'task9',
      'task8',
      'task7',
      'task6',
      'task5',
      'task4',
    ]) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lower,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('task14'), contains(lower), contains('downgrade')),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), firstWrite);
    }
  });

  test('task14 summit marker survives a manifest-last interruption', () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    _writeSyntheticPassageAtlas(fixture);
    _writeSyntheticLighthouseExteriorAtlas(fixture);
    _writeSyntheticLighthouseInteriorAtlas(fixture);
    _writeSyntheticLighthouseFxAtlas(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task13',
        write: true,
      ),
    );
    final task13ProjectSource = projectFile.readAsStringSync();
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task14',
        write: true,
      ),
    );
    expect(
      _readJson(
        File(p.join(fixture.path, 'maps', 'map_sommet_phare.json')),
      )['properties']['selbrumeGeneratorBoundary'],
      'task14',
    );
    projectFile.writeAsStringSync(task13ProjectSource);
    final before = _snapshotFiles(fixture);

    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: fixture,
          through: 'task13',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('task14'), contains('task13'), contains('downgrade')),
        ),
      ),
    );
    expect(_snapshotFiles(fixture), before);
  });

  test('every task14 manifest and summit sentinel blocks task13 downgrade',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticPortAtlas(fixture);
    _writeSyntheticCabinAtlas(fixture);
    _writeSyntheticForestAtlas(fixture);
    _writeSyntheticMarshAtlas(fixture);
    _writeSyntheticPassageAtlas(fixture);
    _writeSyntheticLighthouseExteriorAtlas(fixture);
    _writeSyntheticLighthouseInteriorAtlas(fixture);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task13',
        write: true,
      ),
    );
    final projectFile = File(p.join(fixture.path, 'project.json'));
    final topFile = File(
      p.join(fixture.path, 'maps', 'map_sommet_phare.json'),
    );
    final task13ProjectSource = projectFile.readAsStringSync();
    final task13TopSource = topFile.readAsStringSync();

    void writeJson(File file, Map<String, dynamic> value) {
      file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(value)}\n',
      );
    }

    Future<void> expectSentinelBlocks(
      String label,
      void Function() materializeSentinel,
    ) async {
      projectFile.writeAsStringSync(task13ProjectSource);
      topFile.writeAsStringSync(task13TopSource);
      materializeSentinel();
      final before = _snapshotFiles(fixture);
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: 'task13',
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(
                contains('task14'), contains('task13'), contains('downgrade')),
          ),
        ),
        reason: label,
      );
      expect(_snapshotFiles(fixture), before, reason: label);
    }

    await expectSentinelBlocks('FX tileset', () {
      final project = _readJson(projectFile);
      (project['tilesets'] as List<dynamic>).add(
        <String, dynamic>{'id': 'ts_selbrume_lighthouse_fx'},
      );
      writeJson(projectFile, project);
    });
    await expectSentinelBlocks('FX logical element', () {
      final project = _readJson(projectFile);
      (project['elements'] as List<dynamic>).add(
        <String, dynamic>{'id': 'el_selbrume_fx_halo'},
      );
      writeJson(projectFile, project);
    });
    await expectSentinelBlocks('FX folder', () {
      final project = _readJson(projectFile);
      (project['tilesetFolders'] as List<dynamic>).add(
        <String, dynamic>{'id': 'tsf_selbrume_beta_fx'},
      );
      writeJson(projectFile, project);
    });
    await expectSentinelBlocks('FX category', () {
      final project = _readJson(projectFile);
      (project['elementCategories'] as List<dynamic>).add(
        <String, dynamic>{'id': 'cat_selbrume_fx'},
      );
      writeJson(projectFile, project);
    });
    await expectSentinelBlocks('manifest marker', () {
      final project = _readJson(projectFile);
      final group = (project['groups'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere((entry) => entry['id'] == 'group_selbrume_bourg');
      group['properties'] = <String, dynamic>{
        'selbrumeGeneratorBoundary': 'task14',
      };
      writeJson(projectFile, project);
    });
    await expectSentinelBlocks('summit marker', () {
      final top = _readJson(topFile);
      top['properties'] = <String, dynamic>{
        'selbrumeGeneratorBoundary': 'task14',
      };
      writeJson(topFile, top);
    });
    await expectSentinelBlocks('summit structural fallback', () {
      final top = _readJson(topFile);
      top['tilesetId'] = '';
      top['properties'] = <String, dynamic>{};
      top['layers'] = <Map<String, dynamic>>[
        <String, dynamic>{'id': 'l_terrain'},
        <String, dynamic>{'id': 'l_host_selbrume_lighthouse_interior'},
        <String, dynamic>{'id': 'l_host_selbrume_lighthouse_fx'},
        <String, dynamic>{'id': 'l_collisions'},
      ];
      top['placedElements'] = <Map<String, dynamic>>[
        <String, dynamic>{'id': 'pe_sommet_plateforme'},
        <String, dynamic>{'id': 'pe_sommet_lanterne'},
        <String, dynamic>{'id': 'pe_sommet_lumiere_eteinte'},
      ];
      writeJson(topFile, top);
    });
  });

  test('task15 builds only the canonical keeper cabin on the existing host',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticTask15Prerequisites(fixture);

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task14',
        write: true,
      ),
    );
    final houseFile =
        File(p.join(fixture.path, 'maps', 'map_maison_joueur.json'));
    final cabinAtlasFile = File(
      p.join(
        fixture.path,
        'assets',
        'tilesets',
        'selbrume_cabin_interior.png',
      ),
    );
    final houseBefore = houseFile.readAsBytesSync();
    final cabinAtlasBefore = cabinAtlasFile.readAsBytesSync();
    final task14Manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    final cabinCatalogBefore = <ProjectElementEntry>[
      for (final element in task14Manifest.elements)
        if (element.tilesetId == 'ts_selbrume_cabin_interior') element,
    ];

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task15',
        write: true,
      ),
    );

    expect(houseFile.readAsBytesSync(), houseBefore);
    expect(cabinAtlasFile.readAsBytesSync(), cabinAtlasBefore);
    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    expect(
      <ProjectElementEntry>[
        for (final element in manifest.elements)
          if (element.tilesetId == 'ts_selbrume_cabin_interior') element,
      ],
      cabinCatalogBefore,
      reason: 'Task15 reuses the exact Task8 cabin atlas/catalog.',
    );

    final cabin = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_cabane_gardien.json'))),
    );
    expect(
      () => MapValidator.validate(cabin, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(cabin.size, const GridSize(width: 20, height: 16));
    expect(cabin.tilesetId, isEmpty);
    expect(cabin.properties['selbrumeGeneratorBoundary'], 'task15');
    expect(cabin.mapMetadata.mapType, MapType.interior);
    expect(cabin.mapMetadata.isIndoor, isTrue);
    expect(
      cabin.layers.map((layer) => layer.id),
      const <String>[
        'l_terrain',
        'l_tile_floor',
        'l_tile_walls',
        'l_tile_furniture',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    final tileLayers = cabin.layers.whereType<TileLayer>().toList();
    expect(tileLayers, hasLength(5));
    for (final layer in tileLayers) {
      expect(layer.tilesetId, 'ts_selbrume_cabin_interior', reason: layer.id);
      expect(layer.tiles, hasLength(20 * 16), reason: layer.id);
      expect(layer.tiles, everyElement(0), reason: layer.id);
    }
    expect(
      cabin.layers.whereType<CollisionLayer>().single.collisions,
      everyElement(isFalse),
      reason: 'Task15 must not hide static collisions under its furniture.',
    );
    expect(cabin.connections, isEmpty);
    expect(cabin.entities, isEmpty);
    expect(cabin.events, isEmpty);
    expect(cabin.gameplayZones, isEmpty);
    expect(cabin.placedElements, hasLength(50));
    final elementsById = <String, ProjectElementEntry>{
      for (final element in manifest.elements) element.id: element,
    };
    expect(
      cabin.placedElements.map((placed) => placed.layerId).toSet(),
      <String>{
        'l_tile_floor',
        'l_tile_walls',
        'l_tile_furniture',
        'l_tile_overhead',
      },
    );
    for (final placed in cabin.placedElements) {
      expect(
        placed.layerId,
        elementsById[placed.elementId]?.recommendedLayerId,
        reason: placed.id,
      );
    }
    expect(
      cabin.placedElements.map((placed) => placed.elementId),
      isNot(contains(anyOf(
        'el_selbrume_maison_lit',
        'el_selbrume_maison_bureau',
        'el_selbrume_maison_tapis',
      ))),
    );

    final placedById = <String, MapPlacedElement>{
      for (final placed in cabin.placedElements) placed.id: placed,
    };
    final table = placedById['pe_cabane_table']!;
    expect(table.elementId, 'el_selbrume_cabane_table_carnet_ferme');
    expect(table.layerId, 'l_tile_furniture');
    expect(table.pos, const GridPos(x: 6, y: 5));
    expect(table.opacity, 1);
    expect(table.applyCollision, isTrue);
    expect(table.behaviors, isEmpty);
    expect(table.properties, isEmpty);
    final journal = placedById['pe_cabane_journal']!;
    expect(journal.elementId, 'el_selbrume_cabane_table_carnet_ouvert');
    expect(journal.layerId, 'l_tile_furniture');
    expect(journal.pos, table.pos);
    expect(journal.opacity, 0);
    expect(journal.applyCollision, isFalse);
    expect(journal.behaviors, isEmpty);
    expect(journal.properties, isEmpty);
    final key = placedById['pe_cabane_cle']!;
    expect(key.elementId, 'el_selbrume_cabane_cle');
    expect(key.layerId, 'l_tile_floor');
    expect(key.pos, const GridPos(x: 14, y: 9));
    expect(key.applyCollision, isFalse);
    final secondaryDoor = placedById['pe_cabane_porte_secondaire']!;
    expect(
      secondaryDoor.elementId,
      'el_selbrume_cabane_porte_secondaire_fermee',
    );
    expect(secondaryDoor.layerId, 'l_tile_walls');
    expect(secondaryDoor.pos, const GridPos(x: 18, y: 6));
    expect(secondaryDoor.opacity, 1);
    expect(secondaryDoor.applyCollision, isFalse);
    expect(
      cabin.placedElements.where(
        (placed) =>
            placed.elementId == 'el_selbrume_cabane_porte_secondaire_ouverte',
      ),
      isEmpty,
      reason: 'The open secondary door remains a catalog-only alternative.',
    );
    expect(
      cabin.warps,
      const <MapWarp>[
        MapWarp(
          id: 'warp_cabane_to_phare_exterieur',
          pos: GridPos(x: 10, y: 15),
          targetMapId: 'map_phare_exterieur',
          targetPos: GridPos(x: 8, y: 34),
        ),
        MapWarp(
          id: 'warp_cabane_to_passage',
          pos: GridPos(x: 19, y: 8),
          targetMapId: 'map_passage_dames',
          targetPos: GridPos(x: 50, y: 10),
        ),
      ],
    );
    _expectReservedTrigger(
      cabin,
      'tr_cabane_journal',
      'event_selbrume_cabane_journal',
      6,
      5,
      2,
      2,
    );
    _expectReservedTrigger(
      cabin,
      'tr_cabane_cle',
      'event_selbrume_cabane_cle',
      14,
      9,
      1,
      1,
    );
    expect(cabin.triggers, hasLength(2));

    final blocked = _mapBlockedCells(cabin, manifest);
    final reached = _reachableUnblockedCells(
      cabin,
      blocked,
      List<bool>.filled(20 * 16, true),
      const GridPos(x: 10, y: 13),
    );
    for (final target in const <GridPos>[
      GridPos(x: 10, y: 13),
      GridPos(x: 10, y: 15),
      GridPos(x: 19, y: 8),
      GridPos(x: 6, y: 5),
      GridPos(x: 7, y: 5),
      GridPos(x: 14, y: 9),
    ]) {
      final index = target.y * cabin.size.width + target.x;
      expect(blocked[index], isFalse, reason: '$target must remain passable');
      expect(reached, contains(index), reason: '$target must remain reachable');
    }
    for (final solid in const <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 19, y: 5),
      GridPos(x: 2, y: 3),
      GridPos(x: 6, y: 6),
      GridPos(x: 10, y: 4),
      GridPos(x: 16, y: 2),
      GridPos(x: 2, y: 10),
      GridPos(x: 5, y: 7),
      GridPos(x: 8, y: 7),
    ]) {
      expect(blocked[solid.y * cabin.size.width + solid.x], isTrue,
          reason: '$solid must keep its authored collision');
    }

    final exterior = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_phare_exterieur.json'))),
    );
    final passage = MapData.fromJson(
      _readJson(File(p.join(fixture.path, 'maps', 'map_passage_dames.json'))),
    );
    final exteriorBlocked = _mapBlockedCells(exterior, manifest);
    final passageBlocked = _mapBlockedCells(passage, manifest);
    expect(exteriorBlocked[34 * exterior.size.width + 8], isFalse);
    expect(passageBlocked[10 * passage.size.width + 50], isFalse);
    expect(
      manifest.groups
          .singleWhere((group) => group.id == 'group_selbrume_bourg')
          .properties['selbrumeGeneratorBoundary'],
      'task15',
    );
  });

  test('task15 is idempotent and every lower boundary is downgrade-safe',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticTask15Prerequisites(fixture);

    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task15'),
      ))
          .exitCode,
      selbrumeGeneratorDivergenceExitCode,
    );
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task15',
        write: true,
      ),
    );
    final firstWrite = _snapshotFiles(fixture);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task15',
        write: true,
      ),
    );
    expect(_snapshotFiles(fixture), firstWrite);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task15'),
      ))
          .exitCode,
      0,
    );
    for (final lower in const <String>[
      'task14',
      'task13',
      'task12',
      'task11',
      'task10',
      'task9',
      'task8',
      'task7',
      'task6',
      'task5',
      'task4',
    ]) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lower,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('task15'), contains(lower), contains('downgrade')),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), firstWrite);
    }
  });

  test('task15 cabin marker and structure survive manifest-last interruption',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticTask15Prerequisites(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    final cabinFile =
        File(p.join(fixture.path, 'maps', 'map_cabane_gardien.json'));
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task14',
        write: true,
      ),
    );
    final task14ProjectSource = projectFile.readAsStringSync();
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task15',
        write: true,
      ),
    );
    final task15Cabin = _readJson(cabinFile);

    Future<void> expectCabinSentinelBlocks(
      String label,
      Map<String, dynamic> cabin,
    ) async {
      projectFile.writeAsStringSync(task14ProjectSource);
      cabinFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(cabin)}\n',
      );
      final before = _snapshotFiles(fixture);
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: 'task14',
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(
                contains('task15'), contains('task14'), contains('downgrade')),
          ),
        ),
        reason: label,
      );
      expect(_snapshotFiles(fixture), before, reason: label);
    }

    await expectCabinSentinelBlocks('map marker', task15Cabin);
    final structuralFallback = Map<String, dynamic>.from(task15Cabin);
    structuralFallback['properties'] = <String, dynamic>{};
    await expectCabinSentinelBlocks('structural fallback', structuralFallback);
  });

  test(
      'task16 cuts the active manifest over to the exact canonical map catalog',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticTask15Prerequisites(fixture);
    final sourceMaps =
        Directory(p.join(_findRepositoryRoot().path, 'selbrume', 'maps'));
    final fixtureMaps = Directory(p.join(fixture.path, 'maps'));
    const legacyMapFiles = <String>[
      'Selbrume.json',
      'route 1.json',
      'house 1.json',
      'house 2.json',
      'house 3.json',
      'house 4.json',
      'house 5.json',
      'pokémon center.json',
      'pub.json',
      'lab.json',
    ];
    for (final fileName in legacyMapFiles) {
      File(p.join(sourceMaps.path, fileName))
          .copySync(p.join(fixtureMaps.path, fileName));
    }
    final legacyBefore = <String, List<int>>{
      for (final fileName in legacyMapFiles)
        fileName: File(p.join(fixtureMaps.path, fileName)).readAsBytesSync(),
    };

    final projectFile = File(p.join(fixture.path, 'project.json'));

    final result = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task16',
        write: true,
      ),
    );
    expect(result.exitCode, 0);

    final cutoverJson = _readJson(projectFile);
    final manifest = ProjectManifest.fromJson(cutoverJson);
    expect(cutoverJson['name'], 'Selbrume');
    expect(
      manifest.tilesets.where((tileset) => tileset.name == 'route 1'),
      hasLength(1),
      reason: 'Display labels are not active map bindings.',
    );
    expect(manifest.maps.map((entry) => entry.id), canonicalSelbrumeMapIds);
    expect(manifest.groups.map((group) => group.id), canonicalSelbrumeGroupIds);
    expect(
      manifest.groups
          .singleWhere((group) => group.id == 'group_selbrume_bourg')
          .properties['selbrumeGeneratorBoundary'],
      'task16',
    );
    expect(
      manifest.scenarios
          .expand((scenario) => scenario.nodes)
          .map((node) => node.binding.mapId)
          .whereType<String>(),
      const <String>['map_bourg_selbrume', 'map_bourg_selbrume'],
    );
    expect(manifest.cinematics.single.mapId, 'map_bourg_selbrume');

    final canonicalIds = canonicalSelbrumeMapIds.toSet();
    for (final file in _canonicalMapFiles(fixture)) {
      final map = MapData.fromJson(_readJson(file));
      expect(
        map.connections.map((connection) => connection.targetMapId),
        everyElement(isIn(canonicalIds)),
      );
      expect(
        map.warps.map((warp) => warp.targetMapId),
        everyElement(isIn(canonicalIds)),
      );
    }
    for (final entry in legacyBefore.entries) {
      expect(
        File(p.join(fixtureMaps.path, entry.key)).readAsBytesSync(),
        entry.value,
        reason: '${entry.key} must remain byte-identical after cutover.',
      );
    }
  });

  test('task16 check is read-only, write is idempotent, and cannot downgrade',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticTask15Prerequisites(fixture);
    final before = _snapshotFiles(fixture);

    final divergent = await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task16'),
    );
    expect(divergent.exitCode, selbrumeGeneratorDivergenceExitCode);
    expect(_snapshotFiles(fixture), before);

    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task16',
        write: true,
      ),
    );
    final firstWrite = _snapshotFiles(fixture);
    await generateSelbrumeCanonicalMaps(
      SelbrumeGeneratorOptions(
        projectRoot: fixture,
        through: 'task16',
        write: true,
      ),
    );
    expect(_snapshotFiles(fixture), firstWrite);
    expect(
      (await generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(projectRoot: fixture, through: 'task16'),
      ))
          .exitCode,
      0,
    );

    for (final lower in const <String>['task15', 'task4']) {
      await expectLater(
        () => generateSelbrumeCanonicalMaps(
          SelbrumeGeneratorOptions(
            projectRoot: fixture,
            through: lower,
            write: true,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('task16'), contains(lower), contains('downgrade')),
          ),
        ),
      );
      expect(_snapshotFiles(fixture), firstWrite);
    }
  });

  test('task16 preflights an unmappable retired cinematic map binding',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    _writeSyntheticTask15Prerequisites(fixture);
    final projectFile = File(p.join(fixture.path, 'project.json'));
    final project = _readJson(projectFile);
    final cinematic = (project['cinematics'] as List<dynamic>).single as Map;
    cinematic['mapId'] = 'house 1';
    projectFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(project)}\n',
    );
    final before = _snapshotFiles(fixture);

    await expectLater(
      () => generateSelbrumeCanonicalMaps(
        SelbrumeGeneratorOptions(
          projectRoot: fixture,
          through: 'task16',
          write: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('Task 16 cinematic'), contains('house 1')),
        ),
      ),
    );
    expect(_snapshotFiles(fixture), before);
  });
}

final class _ForestElementContract {
  const _ForestElementContract(
    this.source,
    this.layerId, {
    this.collisionCells = const <GridPos>[],
    this.requiresOcclusion = false,
  });

  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
  final bool requiresOcclusion;
}

final Map<String, _ForestElementContract> _forestElementContracts =
    <String, _ForestElementContract>{
  'el_selbrume_bois_pin_grand': const _ForestElementContract(
    TilesetSourceRect(x: 0, y: 0, width: 6, height: 8),
    'l_tile_overhead',
    collisionCells: <GridPos>[
      GridPos(x: 2, y: 6),
      GridPos(x: 3, y: 6),
      GridPos(x: 2, y: 7),
      GridPos(x: 3, y: 7),
    ],
    requiresOcclusion: true,
  ),
  'el_selbrume_bois_pin_moyen': const _ForestElementContract(
    TilesetSourceRect(x: 6, y: 0, width: 5, height: 7),
    'l_tile_overhead',
    collisionCells: <GridPos>[
      GridPos(x: 2, y: 5),
      GridPos(x: 2, y: 6),
    ],
    requiresOcclusion: true,
  ),
  'el_selbrume_bois_pin_petit': const _ForestElementContract(
    TilesetSourceRect(x: 11, y: 0, width: 4, height: 6),
    'l_tile_overhead',
    collisionCells: <GridPos>[GridPos(x: 1, y: 5)],
    requiresOcclusion: true,
  ),
  'el_selbrume_bois_buisson_1': const _ForestElementContract(
    TilesetSourceRect(x: 0, y: 8, width: 3, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_bois_buisson_2': const _ForestElementContract(
    TilesetSourceRect(x: 3, y: 8, width: 3, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_bois_fougere': const _ForestElementContract(
    TilesetSourceRect(x: 6, y: 8, width: 2, height: 1),
    'l_tile_ground',
  ),
  'el_selbrume_bois_souche': const _ForestElementContract(
    TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  'el_selbrume_bois_tronc_tombe': const _ForestElementContract(
    TilesetSourceRect(x: 10, y: 8, width: 4, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
      GridPos(x: 3, y: 1),
    ],
  ),
  'el_selbrume_bois_ronces': const _ForestElementContract(
    TilesetSourceRect(x: 0, y: 10, width: 3, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
    ],
  ),
  'el_selbrume_bois_aiguilles_sol': const _ForestElementContract(
    TilesetSourceRect(x: 3, y: 10, width: 2, height: 1),
    'l_tile_ground',
  ),
  'el_selbrume_bois_banc': const _ForestElementContract(
    TilesetSourceRect(x: 5, y: 10, width: 3, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
    ],
  ),
  'el_selbrume_bois_panneau': const _ForestElementContract(
    TilesetSourceRect(x: 8, y: 10, width: 2, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
};

final class _MarshElementContract {
  const _MarshElementContract(
    this.source,
    this.layerId, {
    this.collisionCells = const <GridPos>[],
    this.requiresOcclusion = false,
    this.isStateVariant = false,
  });

  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
  final bool requiresOcclusion;
  final bool isStateVariant;
}

final Map<String, _MarshElementContract> _marshElementContracts =
    <String, _MarshElementContract>{
  'el_selbrume_marais_cabane_paludier': const _MarshElementContract(
    TilesetSourceRect(x: 0, y: 0, width: 5, height: 5),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
      GridPos(x: 2, y: 0),
      GridPos(x: 3, y: 0),
      GridPos(x: 4, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 4, y: 1),
      GridPos(x: 0, y: 2),
      GridPos(x: 4, y: 2),
      GridPos(x: 0, y: 3),
      GridPos(x: 4, y: 3),
      GridPos(x: 0, y: 4),
      GridPos(x: 1, y: 4),
      GridPos(x: 3, y: 4),
      GridPos(x: 4, y: 4),
    ],
    requiresOcclusion: true,
  ),
  'el_selbrume_marais_passerelle_h': const _MarshElementContract(
    TilesetSourceRect(x: 5, y: 0, width: 4, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_marais_passerelle_v': const _MarshElementContract(
    TilesetSourceRect(x: 9, y: 0, width: 2, height: 4),
    'l_tile_ground',
  ),
  'el_selbrume_marais_passerelle_angle': const _MarshElementContract(
    TilesetSourceRect(x: 11, y: 0, width: 3, height: 3),
    'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
    ],
  ),
  'el_selbrume_marais_ecluse_fermee': const _MarshElementContract(
    TilesetSourceRect(x: 5, y: 3, width: 3, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
      GridPos(x: 2, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
    ],
    isStateVariant: true,
  ),
  'el_selbrume_marais_ecluse_ouverte': const _MarshElementContract(
    TilesetSourceRect(x: 8, y: 4, width: 3, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 2, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 2, y: 1),
    ],
    isStateVariant: true,
  ),
  'el_selbrume_marais_roseaux_1': const _MarshElementContract(
    TilesetSourceRect(x: 11, y: 3, width: 2, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_marais_roseaux_2': const _MarshElementContract(
    TilesetSourceRect(x: 13, y: 3, width: 3, height: 3),
    'l_tile_ground',
  ),
  'el_selbrume_marais_roseaux_3': const _MarshElementContract(
    TilesetSourceRect(x: 0, y: 5, width: 2, height: 3),
    'l_tile_ground',
  ),
  'el_selbrume_marais_sel_petit': const _MarshElementContract(
    TilesetSourceRect(x: 2, y: 5),
    'l_tile_ground',
  ),
  'el_selbrume_marais_sel_moyen': const _MarshElementContract(
    TilesetSourceRect(x: 3, y: 5, width: 2, height: 1),
    'l_tile_ground',
  ),
  'el_selbrume_marais_sel_grand': const _MarshElementContract(
    TilesetSourceRect(x: 5, y: 6, width: 3, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  'el_selbrume_marais_rateau': const _MarshElementContract(
    TilesetSourceRect(x: 8, y: 6, width: 2, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_indice_verre': const _MarshElementContract(
    TilesetSourceRect(x: 10, y: 6),
    'l_tile_ground',
  ),
  'el_selbrume_indice_traces_electriques': const _MarshElementContract(
    TilesetSourceRect(x: 11, y: 6, width: 2, height: 1),
    'l_tile_fx',
  ),
  'el_selbrume_indice_repere_lentille': const _MarshElementContract(
    TilesetSourceRect(x: 13, y: 6),
    'l_tile_ground',
  ),
  'el_selbrume_cristal_1': const _MarshElementContract(
    TilesetSourceRect(x: 10, y: 7),
    'l_tile_fx',
  ),
  'el_selbrume_cristal_2': const _MarshElementContract(
    TilesetSourceRect(x: 11, y: 7),
    'l_tile_fx',
  ),
  'el_selbrume_cristal_3': const _MarshElementContract(
    TilesetSourceRect(x: 12, y: 7),
    'l_tile_fx',
  ),
  'el_selbrume_marais_passerelle_t': const _MarshElementContract(
    TilesetSourceRect(x: 0, y: 8, width: 4, height: 3),
    'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 3, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 3, y: 1),
    ],
  ),
  'el_selbrume_marais_roseaux_4': const _MarshElementContract(
    TilesetSourceRect(x: 4, y: 8, width: 2, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_marais_roseaux_5': const _MarshElementContract(
    TilesetSourceRect(x: 6, y: 8, width: 3, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_marais_roseaux_6': const _MarshElementContract(
    TilesetSourceRect(x: 9, y: 8, width: 2, height: 3),
    'l_tile_ground',
  ),
};

final class _PassageElementContract {
  const _PassageElementContract(
    this.source,
    this.layerId, {
    this.collisionCells = const <GridPos>[],
    this.isStateVariant = false,
  });

  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
  final bool isStateVariant;
}

final Map<String, _PassageElementContract> _passageElementContracts =
    <String, _PassageElementContract>{
  'el_selbrume_passage_barriere_fermee': const _PassageElementContract(
    TilesetSourceRect(x: 0, y: 0, width: 4, height: 3),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
      GridPos(x: 2, y: 0),
      GridPos(x: 3, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
      GridPos(x: 3, y: 1),
      GridPos(x: 0, y: 2),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
      GridPos(x: 3, y: 2),
    ],
    isStateVariant: true,
  ),
  'el_selbrume_passage_barriere_ouverte': const _PassageElementContract(
    TilesetSourceRect(x: 4, y: 0, width: 4, height: 3),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 2),
      GridPos(x: 3, y: 2),
    ],
    isStateVariant: true,
  ),
  'el_selbrume_passage_borne': const _PassageElementContract(
    TilesetSourceRect(x: 8, y: 0, width: 1, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
  'el_selbrume_passage_panneau': const _PassageElementContract(
    TilesetSourceRect(x: 9, y: 0, width: 2, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
  'el_selbrume_passage_chaussee_humide': const _PassageElementContract(
    TilesetSourceRect(x: 11, y: 0, width: 4, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_passage_ecume_h': const _PassageElementContract(
    TilesetSourceRect(x: 0, y: 3, width: 4, height: 1),
    'l_tile_fx',
  ),
  'el_selbrume_passage_ecume_v': const _PassageElementContract(
    TilesetSourceRect(x: 4, y: 3, width: 1, height: 4),
    'l_tile_fx',
  ),
  'el_selbrume_passage_algues': const _PassageElementContract(
    TilesetSourceRect(x: 5, y: 3, width: 3, height: 1),
    'l_tile_ground',
  ),
  'el_selbrume_passage_balanes': const _PassageElementContract(
    TilesetSourceRect(x: 8, y: 3, width: 2, height: 1),
    'l_tile_ground',
  ),
  'el_selbrume_passage_bois_flotte': const _PassageElementContract(
    TilesetSourceRect(x: 10, y: 3, width: 3, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_passage_marches': const _PassageElementContract(
    TilesetSourceRect(x: 13, y: 3, width: 3, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_passage_chaussee_seche': const _PassageElementContract(
    TilesetSourceRect(x: 5, y: 5, width: 6, height: 3),
    'l_tile_ground',
  ),
  'el_selbrume_passage_flaques': const _PassageElementContract(
    TilesetSourceRect(x: 11, y: 5, width: 3, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_passage_banc_brume': const _PassageElementContract(
    TilesetSourceRect(x: 0, y: 8, width: 8, height: 4),
    'l_tile_fx',
  ),
};

final class _LighthouseExteriorElementContract {
  const _LighthouseExteriorElementContract(
    this.source,
    this.layerId, {
    this.collisionCells = const <GridPos>[],
    this.occlusionCells = const <GridPos>[],
    this.requiresOcclusion = false,
    this.isStateVariant = false,
  });

  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
  final List<GridPos> occlusionCells;
  final bool requiresOcclusion;
  final bool isStateVariant;
}

final Map<String, _LighthouseExteriorElementContract>
    _lighthouseExteriorElementContracts =
    <String, _LighthouseExteriorElementContract>{
  'el_selbrume_phare_batiment': const _LighthouseExteriorElementContract(
    TilesetSourceRect(x: 0, y: 0, width: 8, height: 10),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 3, y: 0),
      GridPos(x: 4, y: 0),
      GridPos(x: 5, y: 0),
      GridPos(x: 3, y: 1),
      GridPos(x: 5, y: 1),
      GridPos(x: 2, y: 2),
      GridPos(x: 5, y: 2),
      GridPos(x: 2, y: 3),
      GridPos(x: 5, y: 3),
      GridPos(x: 2, y: 4),
      GridPos(x: 5, y: 4),
      GridPos(x: 1, y: 5),
      GridPos(x: 5, y: 5),
      GridPos(x: 1, y: 6),
      GridPos(x: 5, y: 6),
      GridPos(x: 1, y: 7),
      GridPos(x: 6, y: 7),
      GridPos(x: 1, y: 8),
      GridPos(x: 6, y: 8),
      GridPos(x: 1, y: 9),
      GridPos(x: 2, y: 9),
      GridPos(x: 3, y: 9),
      GridPos(x: 5, y: 9),
      GridPos(x: 6, y: 9),
    ],
    occlusionCells: <GridPos>[
      GridPos(x: 3, y: 0),
      GridPos(x: 4, y: 0),
      GridPos(x: 5, y: 0),
      GridPos(x: 3, y: 1),
      GridPos(x: 4, y: 1),
      GridPos(x: 5, y: 1),
      GridPos(x: 2, y: 2),
      GridPos(x: 3, y: 2),
      GridPos(x: 4, y: 2),
      GridPos(x: 5, y: 2),
      GridPos(x: 2, y: 3),
      GridPos(x: 3, y: 3),
      GridPos(x: 4, y: 3),
      GridPos(x: 5, y: 3),
      GridPos(x: 2, y: 4),
      GridPos(x: 3, y: 4),
      GridPos(x: 4, y: 4),
      GridPos(x: 5, y: 4),
      GridPos(x: 1, y: 5),
      GridPos(x: 2, y: 5),
      GridPos(x: 3, y: 5),
      GridPos(x: 4, y: 5),
      GridPos(x: 5, y: 5),
      GridPos(x: 1, y: 6),
      GridPos(x: 2, y: 6),
      GridPos(x: 3, y: 6),
      GridPos(x: 4, y: 6),
      GridPos(x: 5, y: 6),
      GridPos(x: 1, y: 7),
      GridPos(x: 2, y: 7),
      GridPos(x: 3, y: 7),
      GridPos(x: 4, y: 7),
      GridPos(x: 5, y: 7),
      GridPos(x: 6, y: 7),
    ],
    requiresOcclusion: true,
  ),
  'el_selbrume_cabane_facade': _LighthouseExteriorElementContract(
    const TilesetSourceRect(x: 8, y: 0, width: 5, height: 5),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
      GridPos(x: 2, y: 0),
      GridPos(x: 3, y: 0),
      GridPos(x: 4, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 4, y: 1),
      GridPos(x: 0, y: 2),
      GridPos(x: 4, y: 2),
      GridPos(x: 0, y: 3),
      GridPos(x: 4, y: 3),
      GridPos(x: 0, y: 4),
      GridPos(x: 1, y: 4),
      GridPos(x: 3, y: 4),
      GridPos(x: 4, y: 4),
    ],
    occlusionCells: <GridPos>[
      for (var y = 0; y < 4; y++)
        for (var x = 0; x < 5; x++) GridPos(x: x, y: y),
    ],
    requiresOcclusion: true,
  ),
  'el_selbrume_phare_porte_fermee': _LighthouseExteriorElementContract(
    const TilesetSourceRect(x: 8, y: 5, width: 2, height: 3),
    'l_tile_structures',
    collisionCells: <GridPos>[
      for (var y = 0; y < 3; y++)
        for (var x = 0; x < 2; x++) GridPos(x: x, y: y),
    ],
    isStateVariant: true,
  ),
  'el_selbrume_phare_porte_ouverte': const _LighthouseExteriorElementContract(
    TilesetSourceRect(x: 10, y: 5, width: 2, height: 3),
    'l_tile_structures',
    isStateVariant: true,
  ),
  'el_selbrume_cabane_porte_fermee': _LighthouseExteriorElementContract(
    const TilesetSourceRect(x: 12, y: 5, width: 2, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      for (var y = 0; y < 2; y++)
        for (var x = 0; x < 2; x++) GridPos(x: x, y: y),
    ],
    isStateVariant: true,
  ),
  'el_selbrume_cabane_porte_ouverte': const _LighthouseExteriorElementContract(
    TilesetSourceRect(x: 14, y: 5, width: 2, height: 2),
    'l_tile_structures',
    isStateVariant: true,
  ),
  'el_selbrume_phare_fenetre_sombre': const _LighthouseExteriorElementContract(
    TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
    'l_tile_structures',
    isStateVariant: true,
  ),
  'el_selbrume_phare_fenetre_lumineuse':
      const _LighthouseExteriorElementContract(
    TilesetSourceRect(x: 10, y: 8, width: 2, height: 2),
    'l_tile_fx',
    isStateVariant: true,
  ),
  'el_selbrume_phare_rambarde': _LighthouseExteriorElementContract(
    const TilesetSourceRect(x: 12, y: 8, width: 4, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      for (var y = 0; y < 2; y++)
        for (var x = 0; x < 4; x++) GridPos(x: x, y: y),
    ],
  ),
  'el_selbrume_phare_fondation': const _LighthouseExteriorElementContract(
    TilesetSourceRect(x: 0, y: 10, width: 8, height: 2),
    'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 1, y: 0),
      GridPos(x: 6, y: 0),
      GridPos(x: 1, y: 1),
      GridPos(x: 6, y: 1),
    ],
  ),
  'el_selbrume_phare_panneau': const _LighthouseExteriorElementContract(
    TilesetSourceRect(x: 8, y: 10, width: 2, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
  'el_selbrume_phare_debris': const _LighthouseExteriorElementContract(
    TilesetSourceRect(x: 10, y: 10, width: 3, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  'el_selbrume_phare_marches': const _LighthouseExteriorElementContract(
    TilesetSourceRect(x: 13, y: 10, width: 3, height: 2),
    'l_tile_ground',
  ),
};

final class _LighthouseInteriorElementContract {
  const _LighthouseInteriorElementContract(
    this.source,
    this.layerId,
    this.mapTag, {
    this.collisionCells = const <GridPos>[],
  });

  final TilesetSourceRect source;
  final String layerId;
  final String mapTag;
  final List<GridPos> collisionCells;
}

final Map<String, _LighthouseInteriorElementContract>
    _lighthouseInteriorElementContracts =
    <String, _LighthouseInteriorElementContract>{
  'el_selbrume_phare_sol_pierre': const _LighthouseInteriorElementContract(
    TilesetSourceRect(x: 0, y: 0, width: 4, height: 4),
    'l_tile_floor',
    'map_phare_interieur',
  ),
  'el_selbrume_phare_sol_bois': const _LighthouseInteriorElementContract(
    TilesetSourceRect(x: 4, y: 0, width: 4, height: 4),
    'l_tile_floor',
    'map_phare_interieur',
  ),
  'el_selbrume_phare_mur_n': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 8, y: 0, width: 4, height: 2),
    'l_tile_walls',
    'map_phare_interieur',
    collisionCells: <GridPos>[
      for (var y = 0; y < 2; y++)
        for (var x = 0; x < 4; x++) GridPos(x: x, y: y),
    ],
  ),
  'el_selbrume_phare_mur_s': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 12, y: 0, width: 4, height: 2),
    'l_tile_walls',
    'map_phare_interieur',
    collisionCells: <GridPos>[
      for (var y = 0; y < 2; y++)
        for (var x = 0; x < 4; x++) GridPos(x: x, y: y),
    ],
  ),
  'el_selbrume_phare_mur_e': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 16, y: 0, width: 2, height: 4),
    'l_tile_walls',
    'map_phare_interieur',
    collisionCells: <GridPos>[
      for (var y = 0; y < 4; y++)
        for (var x = 0; x < 2; x++) GridPos(x: x, y: y),
    ],
  ),
  'el_selbrume_phare_mur_o': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 18, y: 0, width: 2, height: 4),
    'l_tile_walls',
    'map_phare_interieur',
    collisionCells: <GridPos>[
      for (var y = 0; y < 4; y++)
        for (var x = 0; x < 2; x++) GridPos(x: x, y: y),
    ],
  ),
  for (final contract in const <(String, int)>[
    ('el_selbrume_phare_coin_no', 20),
    ('el_selbrume_phare_coin_ne', 22),
    ('el_selbrume_phare_coin_so', 24),
    ('el_selbrume_phare_coin_se', 26),
  ])
    contract.$1: _LighthouseInteriorElementContract(
      TilesetSourceRect(x: contract.$2, y: 0, width: 2, height: 2),
      'l_tile_walls',
      'map_phare_interieur',
      collisionCells: <GridPos>[
        for (var y = 0; y < 2; y++)
          for (var x = 0; x < 2; x++) GridPos(x: x, y: y),
      ],
    ),
  'el_selbrume_phare_escalier_haut': const _LighthouseInteriorElementContract(
    TilesetSourceRect(x: 8, y: 4, width: 3, height: 3),
    'l_tile_floor',
    'map_phare_interieur',
  ),
  'el_selbrume_phare_escalier_bas': const _LighthouseInteriorElementContract(
    TilesetSourceRect(x: 11, y: 4, width: 3, height: 3),
    'l_tile_floor',
    'map_phare_interieur',
  ),
  'el_selbrume_phare_rambarde_h': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 14, y: 4, width: 4, height: 1),
    'l_tile_walls',
    'map_phare_interieur',
    collisionCells: <GridPos>[
      for (var x = 0; x < 4; x++) GridPos(x: x, y: 0),
    ],
  ),
  'el_selbrume_phare_rambarde_v': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 18, y: 4, width: 1, height: 4),
    'l_tile_walls',
    'map_phare_interieur',
    collisionCells: <GridPos>[
      for (var y = 0; y < 4; y++) GridPos(x: 0, y: y),
    ],
  ),
  'el_selbrume_phare_plancher_brise': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 19, y: 4, width: 3, height: 3),
    'l_tile_furniture',
    'map_phare_interieur',
    collisionCells: <GridPos>[
      for (var y = 0; y < 3; y++)
        for (var x = 0; x < 3; x++) GridPos(x: x, y: y),
    ],
  ),
  'el_selbrume_phare_mecanisme': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 22, y: 4, width: 5, height: 5),
    'l_tile_furniture',
    'map_phare_interieur',
    collisionCells: <GridPos>[
      for (var y = 0; y < 5; y++)
        for (var x = 0; x < 5; x++) GridPos(x: x, y: y),
    ],
  ),
  'el_selbrume_phare_machinerie': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 0, y: 8, width: 3, height: 3),
    'l_tile_furniture',
    'map_phare_interieur',
    collisionCells: <GridPos>[
      for (var y = 0; y < 3; y++)
        for (var x = 0; x < 3; x++) GridPos(x: x, y: y),
    ],
  ),
  'el_selbrume_phare_bureau_note': const _LighthouseInteriorElementContract(
    TilesetSourceRect(x: 3, y: 8, width: 2, height: 2),
    'l_tile_furniture',
    'map_phare_interieur',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  'el_selbrume_phare_caisses_debris': const _LighthouseInteriorElementContract(
    TilesetSourceRect(x: 5, y: 8, width: 3, height: 2),
    'l_tile_furniture',
    'map_phare_interieur',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
    ],
  ),
  'el_selbrume_phare_fenetre_interieure':
      const _LighthouseInteriorElementContract(
    TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
    'l_tile_walls',
    'map_phare_interieur',
  ),
  'el_selbrume_phare_trappe': const _LighthouseInteriorElementContract(
    TilesetSourceRect(x: 10, y: 8, width: 2, height: 2),
    'l_tile_floor',
    'map_phare_interieur',
  ),
  'el_selbrume_sommet_plateforme': const _LighthouseInteriorElementContract(
    TilesetSourceRect(x: 0, y: 12, width: 6, height: 6),
    'l_tile_floor',
    'map_sommet_phare',
  ),
  'el_selbrume_sommet_parapet_h': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 6, y: 12, width: 4, height: 2),
    'l_tile_walls',
    'map_sommet_phare',
    collisionCells: const <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
      GridPos(x: 3, y: 1),
    ],
  ),
  'el_selbrume_sommet_parapet_v': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 10, y: 12, width: 2, height: 4),
    'l_tile_walls',
    'map_sommet_phare',
    collisionCells: <GridPos>[
      for (var y = 0; y < 4; y++)
        for (var x = 0; x < 2; x++) GridPos(x: x, y: y),
    ],
  ),
  'el_selbrume_sommet_lanterne': _LighthouseInteriorElementContract(
    const TilesetSourceRect(x: 12, y: 12, width: 5, height: 5),
    'l_tile_furniture',
    'map_sommet_phare',
    collisionCells: <GridPos>[
      for (var y = 0; y < 5; y++)
        for (var x = 0; x < 5; x++)
          if (y != 0 || (x != 0 && x != 4)) GridPos(x: x, y: y),
    ],
  ),
};

final class _LighthouseFxElementContract {
  const _LighthouseFxElementContract(
    this.frames, {
    this.stateVariant = false,
    this.animated = false,
  });

  final List<TilesetVisualFrame> frames;
  final bool stateVariant;
  final bool animated;
}

final Map<String, _LighthouseFxElementContract> _lighthouseFxElementContracts =
    <String, _LighthouseFxElementContract>{
  'el_selbrume_fx_brume_basse': const _LighthouseFxElementContract(
    <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: 8, height: 4),
      ),
    ],
  ),
  'el_selbrume_fx_banc_brume': const _LighthouseFxElementContract(
    <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 8, y: 0, width: 8, height: 4),
      ),
    ],
  ),
  'el_selbrume_fx_faisceau': const _LighthouseFxElementContract(
    <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 4, width: 8, height: 2),
      ),
    ],
  ),
  'el_selbrume_fx_fenetre_lumineuse': const _LighthouseFxElementContract(
    <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 8, y: 4, width: 2, height: 2),
      ),
    ],
  ),
  'el_selbrume_fx_halo': const _LighthouseFxElementContract(
    <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 10, y: 4, width: 4, height: 4),
      ),
    ],
  ),
  'el_selbrume_fx_lumiere_eteinte': const _LighthouseFxElementContract(
    <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 6, width: 4, height: 4),
      ),
    ],
    stateVariant: true,
  ),
  'el_selbrume_fx_lumiere_stabilisee': const _LighthouseFxElementContract(
    <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 4, y: 6, width: 4, height: 4),
      ),
    ],
    stateVariant: true,
  ),
  'el_selbrume_fx_lumiere_instable': const _LighthouseFxElementContract(
    <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 10, width: 4, height: 4),
        durationMs: 160,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 4, y: 10, width: 4, height: 4),
        durationMs: 160,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 8, y: 10, width: 4, height: 4),
        durationMs: 160,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 12, y: 10, width: 4, height: 4),
        durationMs: 160,
      ),
    ],
    stateVariant: true,
    animated: true,
  ),
  'el_selbrume_fx_etincelles': const _LighthouseFxElementContract(
    <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 14, width: 2, height: 2),
        durationMs: 120,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 2, y: 14, width: 2, height: 2),
        durationMs: 120,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 4, y: 14, width: 2, height: 2),
        durationMs: 120,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 6, y: 14, width: 2, height: 2),
        durationMs: 120,
      ),
    ],
    stateVariant: true,
    animated: true,
  ),
};

final class _PortElementContract {
  const _PortElementContract(
    this.source,
    this.layerId, {
    this.collisionCells = const <GridPos>[],
    this.requiresOcclusion = false,
  });

  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
  final bool requiresOcclusion;
}

final Map<String, _PortElementContract> _portElementContracts =
    <String, _PortElementContract>{
  'el_selbrume_port_quai_droit': const _PortElementContract(
    TilesetSourceRect(x: 0, y: 0, width: 4, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_port_quai_angle': const _PortElementContract(
    TilesetSourceRect(x: 4, y: 0, width: 3, height: 3),
    'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 0, y: 2),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
    ],
  ),
  'el_selbrume_port_quai_t': const _PortElementContract(
    TilesetSourceRect(x: 7, y: 0, width: 4, height: 3),
    'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 2),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
      GridPos(x: 3, y: 2),
    ],
  ),
  'el_selbrume_port_quai_fin': const _PortElementContract(
    TilesetSourceRect(x: 11, y: 0, width: 3, height: 3),
    'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
      GridPos(x: 2, y: 0),
      GridPos(x: 2, y: 1),
      GridPos(x: 0, y: 2),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
    ],
  ),
  'el_selbrume_port_escalier_quai': const _PortElementContract(
    TilesetSourceRect(x: 0, y: 3, width: 3, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_port_brise_lames': _PortElementContract(
    const TilesetSourceRect(x: 3, y: 3, width: 6, height: 3),
    'l_tile_structures',
    collisionCells: <GridPos>[
      for (var y = 1; y < 3; y += 1)
        for (var x = 0; x < 6; x += 1) GridPos(x: x, y: y),
    ],
  ),
  'el_selbrume_port_hangar': _PortElementContract(
    const TilesetSourceRect(x: 9, y: 3, width: 6, height: 5),
    'l_tile_structures',
    collisionCells: <GridPos>[
      for (var x = 1; x < 5; x += 1) GridPos(x: x, y: 0),
      for (var y = 1; y < 5; y += 1)
        for (var x = 0; x < 6; x += 1) GridPos(x: x, y: y),
    ],
    requiresOcclusion: true,
  ),
  'el_selbrume_port_bollard': const _PortElementContract(
    TilesetSourceRect(x: 0, y: 6, width: 1, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
  'el_selbrume_port_corde': const _PortElementContract(
    TilesetSourceRect(x: 1, y: 6, width: 2, height: 1),
    'l_tile_ground',
  ),
  'el_selbrume_port_filets': const _PortElementContract(
    TilesetSourceRect(x: 3, y: 6, width: 3, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
    requiresOcclusion: true,
  ),
  'el_selbrume_port_caisses': const _PortElementContract(
    TilesetSourceRect(x: 6, y: 6, width: 3, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
    ],
    requiresOcclusion: true,
  ),
  'el_selbrume_port_tonneaux': const _PortElementContract(
    TilesetSourceRect(x: 0, y: 8, width: 2, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
    requiresOcclusion: true,
  ),
  'el_selbrume_port_bouees': const _PortElementContract(
    TilesetSourceRect(x: 2, y: 8, width: 2, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_port_nid_vide': const _PortElementContract(
    TilesetSourceRect(x: 4, y: 8, width: 2, height: 2),
    'l_tile_ground',
  ),
  'el_selbrume_port_nid_brillant': const _PortElementContract(
    TilesetSourceRect(x: 6, y: 8, width: 2, height: 2),
    'l_tile_fx',
  ),
  'el_selbrume_port_panneau': const _PortElementContract(
    TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
    'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
    requiresOcclusion: true,
  ),
};

final class _CabinElementContract {
  const _CabinElementContract(
    this.source,
    this.layerId, {
    this.collisionCells = const <GridPos>[],
  });

  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
}

final Map<String, _CabinElementContract> _cabinElementContracts =
    <String, _CabinElementContract>{
  'el_selbrume_cabane_sol_bois': const _CabinElementContract(
    TilesetSourceRect(x: 0, y: 0, width: 4, height: 4),
    'l_tile_floor',
  ),
  'el_selbrume_cabane_mur_n': _CabinElementContract(
    const TilesetSourceRect(x: 4, y: 0, width: 4, height: 2),
    'l_tile_walls',
    collisionCells: _fullFootprint(4, 2),
  ),
  'el_selbrume_cabane_mur_cote': _CabinElementContract(
    const TilesetSourceRect(x: 8, y: 0, width: 2, height: 4),
    'l_tile_walls',
    collisionCells: _fullFootprint(2, 4),
  ),
  'el_selbrume_cabane_lit': _CabinElementContract(
    const TilesetSourceRect(x: 10, y: 0, width: 2, height: 3),
    'l_tile_furniture',
    collisionCells: _fullFootprint(2, 3),
  ),
  'el_selbrume_cabane_table_carnet_ferme': const _CabinElementContract(
    TilesetSourceRect(x: 0, y: 4, width: 2, height: 2),
    'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1), GridPos(x: 1, y: 1)],
  ),
  'el_selbrume_cabane_table_carnet_ouvert': const _CabinElementContract(
    TilesetSourceRect(x: 2, y: 4, width: 2, height: 2),
    'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1), GridPos(x: 1, y: 1)],
  ),
  'el_selbrume_cabane_poele': const _CabinElementContract(
    TilesetSourceRect(x: 4, y: 4, width: 2, height: 3),
    'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 2), GridPos(x: 1, y: 2)],
  ),
  'el_selbrume_cabane_etagere': _CabinElementContract(
    const TilesetSourceRect(x: 6, y: 4, width: 2, height: 3),
    'l_tile_furniture',
    collisionCells: _fullFootprint(2, 3),
  ),
  'el_selbrume_cabane_coffre': const _CabinElementContract(
    TilesetSourceRect(x: 8, y: 4, width: 2, height: 2),
    'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1), GridPos(x: 1, y: 1)],
  ),
  'el_selbrume_cabane_carte': const _CabinElementContract(
    TilesetSourceRect(x: 10, y: 4, width: 2, height: 2),
    'l_tile_walls',
  ),
  'el_selbrume_cabane_cle': const _CabinElementContract(
    TilesetSourceRect(x: 12, y: 4),
    'l_tile_floor',
  ),
  'el_selbrume_cabane_outils': const _CabinElementContract(
    TilesetSourceRect(x: 13, y: 4, width: 2, height: 2),
    'l_tile_furniture',
  ),
  'el_selbrume_cabane_lanterne': const _CabinElementContract(
    TilesetSourceRect(x: 0, y: 7, width: 1, height: 2),
    'l_tile_overhead',
  ),
  'el_selbrume_cabane_porte_secondaire_fermee': _CabinElementContract(
    const TilesetSourceRect(x: 1, y: 7, width: 2, height: 3),
    'l_tile_walls',
    collisionCells: _fullFootprint(2, 3),
  ),
  'el_selbrume_cabane_porte_secondaire_ouverte': const _CabinElementContract(
    TilesetSourceRect(x: 3, y: 7, width: 2, height: 3),
    'l_tile_walls',
  ),
  'el_selbrume_maison_lit': _CabinElementContract(
    const TilesetSourceRect(x: 5, y: 7, width: 2, height: 3),
    'l_tile_furniture',
    collisionCells: _fullFootprint(2, 3),
  ),
  'el_selbrume_maison_bureau': const _CabinElementContract(
    TilesetSourceRect(x: 7, y: 7, width: 2, height: 2),
    'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1), GridPos(x: 1, y: 1)],
  ),
  'el_selbrume_maison_tapis': const _CabinElementContract(
    TilesetSourceRect(x: 9, y: 7, width: 3, height: 2),
    'l_tile_floor',
  ),
  'el_selbrume_cabane_porte_principale': const _CabinElementContract(
    TilesetSourceRect(x: 12, y: 7, width: 2, height: 3),
    'l_tile_walls',
  ),
  'el_selbrume_cabane_chaise': const _CabinElementContract(
    TilesetSourceRect(x: 14, y: 7, width: 1, height: 2),
    'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
};

List<GridPos> _fullFootprint(int width, int height) => <GridPos>[
      for (var y = 0; y < height; y += 1)
        for (var x = 0; x < width; x += 1) GridPos(x: x, y: y),
    ];

void _writeSyntheticPortAtlas(
  Directory projectRoot, {
  int width = 512,
  int height = 512,
  int numChannels = 4,
}) {
  final atlas = img.Image(
    width: width,
    height: height,
    numChannels: numChannels,
  );
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      atlas.setPixelRgba(
        x,
        y,
        40 + (x ~/ 32) % 160,
        60 + (y ~/ 32) % 140,
        120,
        255,
      );
    }
  }
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_port_props.png',
    ),
  );
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _writeSyntheticCabinAtlas(
  Directory projectRoot, {
  int width = 512,
  int height = 512,
  int numChannels = 4,
}) {
  final atlas = img.Image(
    width: width,
    height: height,
    numChannels: numChannels,
  );
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      atlas.setPixelRgba(
        x,
        y,
        70 + (x ~/ 32) % 120,
        45 + (y ~/ 32) % 130,
        25 + ((x + y) ~/ 32) % 100,
        255,
      );
    }
  }
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_cabin_interior.png',
    ),
  );
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _writeSyntheticTask15Prerequisites(Directory projectRoot) {
  _writeSyntheticPortAtlas(projectRoot);
  _writeSyntheticCabinAtlas(projectRoot);
  _writeSyntheticForestAtlas(projectRoot);
  _writeSyntheticMarshAtlas(projectRoot);
  _writeSyntheticPassageAtlas(projectRoot);
  _writeSyntheticLighthouseExteriorAtlas(projectRoot);
  _writeSyntheticLighthouseInteriorAtlas(projectRoot);
  _writeSyntheticLighthouseFxAtlas(projectRoot);
}

void _writeSyntheticForestAtlas(
  Directory projectRoot, {
  int width = 512,
  int height = 512,
  int numChannels = 4,
}) {
  final atlas = img.Image(
    width: width,
    height: height,
    numChannels: numChannels,
  );
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      atlas.setPixelRgba(
        x,
        y,
        18 + (x ~/ 32) % 90,
        65 + (y ~/ 32) % 145,
        35 + ((x + y) ~/ 32) % 80,
        255,
      );
    }
  }
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_forest_props.png',
    ),
  );
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _writeSyntheticMarshAtlas(
  Directory projectRoot, {
  int width = 512,
  int height = 512,
  int numChannels = 4,
}) {
  final atlas = img.Image(
    width: width,
    height: height,
    numChannels: numChannels,
  );
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      atlas.setPixelRgba(
        x,
        y,
        85 + (x ~/ 32) % 110,
        95 + (y ~/ 32) % 100,
        70 + ((x + y) ~/ 32) % 95,
        255,
      );
    }
  }
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_marsh_props.png',
    ),
  );
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _writeSyntheticPassageAtlas(
  Directory projectRoot, {
  int width = 512,
  int height = 512,
  int numChannels = 4,
}) {
  final atlas = img.Image(
    width: width,
    height: height,
    numChannels: numChannels,
  );
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      atlas.setPixelRgba(
        x,
        y,
        75 + (x ~/ 32) % 120,
        90 + (y ~/ 32) % 110,
        105 + ((x + y) ~/ 32) % 100,
        255,
      );
    }
  }
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_passage_props.png',
    ),
  );
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _writeSyntheticLighthouseExteriorAtlas(
  Directory projectRoot, {
  int width = 512,
  int height = 512,
  int numChannels = 4,
}) {
  final atlas = img.Image(
    width: width,
    height: height,
    numChannels: numChannels,
  );
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      atlas.setPixelRgba(
        x,
        y,
        90 + (x ~/ 32) % 105,
        80 + (y ~/ 32) % 105,
        75 + ((x + y) ~/ 32) % 115,
        255,
      );
    }
  }
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_lighthouse_exterior.png',
    ),
  );
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _writeSyntheticLighthouseInteriorAtlas(
  Directory projectRoot, {
  int width = 1024,
  int height = 1024,
  int numChannels = 4,
}) {
  final atlas = img.Image(
    width: width,
    height: height,
    numChannels: numChannels,
  );
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      atlas.setPixelRgba(
        x,
        y,
        70 + (x ~/ 32) % 125,
        65 + (y ~/ 32) % 120,
        55 + ((x + y) ~/ 32) % 135,
        255,
      );
    }
  }
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_lighthouse_interior.png',
    ),
  );
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _writeSyntheticLighthouseFxAtlas(
  Directory projectRoot, {
  int width = 512,
  int height = 512,
  int numChannels = 4,
}) {
  final atlas = img.Image(
    width: width,
    height: height,
    numChannels: numChannels,
  );
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      atlas.setPixelRgba(
        x,
        y,
        75 + (x ~/ 32) % 120,
        105 + (y ~/ 32) % 100,
        145 + ((x + y) ~/ 32) % 95,
        255,
      );
    }
  }
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_lighthouse_fx.png',
    ),
  );
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _clearPortAtlasPixels(
  Directory projectRoot, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_port_props.png',
    ),
  );
  final atlas = img.decodePng(file.readAsBytesSync())!;
  for (var pixelY = y; pixelY < y + height; pixelY += 1) {
    for (var pixelX = x; pixelX < x + width; pixelX += 1) {
      atlas.setPixelRgba(pixelX, pixelY, 0, 0, 0, 0);
    }
  }
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _clearCabinAtlasPixels(
  Directory projectRoot, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_cabin_interior.png',
    ),
  );
  final atlas = img.decodePng(file.readAsBytesSync())!;
  for (var pixelY = y; pixelY < y + height; pixelY += 1) {
    for (var pixelX = x; pixelX < x + width; pixelX += 1) {
      atlas.setPixelRgba(pixelX, pixelY, 0, 0, 0, 0);
    }
  }
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _clearForestAtlasPixels(
  Directory projectRoot, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_forest_props.png',
    ),
  );
  final atlas = img.decodePng(file.readAsBytesSync())!;
  for (var pixelY = y; pixelY < y + height; pixelY += 1) {
    for (var pixelX = x; pixelX < x + width; pixelX += 1) {
      atlas.setPixelRgba(pixelX, pixelY, 0, 0, 0, 0);
    }
  }
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _clearMarshAtlasPixels(
  Directory projectRoot, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_marsh_props.png',
    ),
  );
  final atlas = img.decodePng(file.readAsBytesSync())!;
  for (var pixelY = y; pixelY < y + height; pixelY += 1) {
    for (var pixelX = x; pixelX < x + width; pixelX += 1) {
      atlas.setPixelRgba(pixelX, pixelY, 0, 0, 0, 0);
    }
  }
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _clearPassageAtlasPixels(
  Directory projectRoot, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_passage_props.png',
    ),
  );
  final atlas = img.decodePng(file.readAsBytesSync())!;
  for (var pixelY = y; pixelY < y + height; pixelY += 1) {
    for (var pixelX = x; pixelX < x + width; pixelX += 1) {
      atlas.setPixelRgba(pixelX, pixelY, 0, 0, 0, 0);
    }
  }
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _clearLighthouseExteriorAtlasPixels(
  Directory projectRoot, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_lighthouse_exterior.png',
    ),
  );
  final atlas = img.decodePng(file.readAsBytesSync())!;
  for (var pixelY = y; pixelY < y + height; pixelY += 1) {
    for (var pixelX = x; pixelX < x + width; pixelX += 1) {
      atlas.setPixelRgba(pixelX, pixelY, 0, 0, 0, 0);
    }
  }
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _clearLighthouseInteriorAtlasPixels(
  Directory projectRoot, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_lighthouse_interior.png',
    ),
  );
  final atlas = img.decodePng(file.readAsBytesSync())!;
  for (var pixelY = y; pixelY < y + height; pixelY++) {
    for (var pixelX = x; pixelX < x + width; pixelX++) {
      atlas.setPixelRgba(pixelX, pixelY, 0, 0, 0, 0);
    }
  }
  file.writeAsBytesSync(img.encodePng(atlas));
}

void _clearLighthouseFxAtlasPixels(
  Directory projectRoot, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  final file = File(
    p.join(
      projectRoot.path,
      'assets',
      'tilesets',
      'selbrume_lighthouse_fx.png',
    ),
  );
  final atlas = img.decodePng(file.readAsBytesSync())!;
  for (var pixelY = y; pixelY < y + height; pixelY++) {
    for (var pixelX = x; pixelX < x + width; pixelX++) {
      atlas.setPixelRgba(pixelX, pixelY, 0, 0, 0, 0);
    }
  }
  file.writeAsBytesSync(img.encodePng(atlas));
}

List<bool> _mapBlockedCells(MapData map, ProjectManifest manifest) {
  final blocked = List<bool>.from(
    map.layers.whereType<CollisionLayer>().single.collisions,
  );
  final elementsById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final placed in map.placedElements) {
    if (!placed.applyCollision) continue;
    final cells = elementsById[placed.elementId]?.collisionProfile?.cells;
    if (cells == null) continue;
    for (final cell in cells) {
      final x = placed.pos.x + cell.x;
      final y = placed.pos.y + cell.y;
      if (x >= 0 && y >= 0 && x < map.size.width && y < map.size.height) {
        blocked[y * map.size.width + x] = true;
      }
    }
  }
  for (final entity in map.entities) {
    if (!entity.blocksMovement) continue;
    for (var y = entity.pos.y; y < entity.pos.y + entity.size.height; y += 1) {
      for (var x = entity.pos.x; x < entity.pos.x + entity.size.width; x += 1) {
        blocked[y * map.size.width + x] = true;
      }
    }
  }
  return blocked;
}

Set<int> _reachableUnblockedCells(
  MapData map,
  List<bool> blocked,
  List<bool> allowed,
  GridPos start, {
  Set<int> excluded = const <int>{},
}) {
  final startIndex = start.y * map.size.width + start.x;
  if (!allowed[startIndex] ||
      blocked[startIndex] ||
      excluded.contains(startIndex)) {
    return <int>{};
  }
  final reached = <int>{startIndex};
  final queue = <GridPos>[start];
  var cursor = 0;
  while (cursor < queue.length) {
    final current = queue[cursor++];
    for (final next in <GridPos>[
      GridPos(x: current.x, y: current.y - 1),
      GridPos(x: current.x + 1, y: current.y),
      GridPos(x: current.x, y: current.y + 1),
      GridPos(x: current.x - 1, y: current.y),
    ]) {
      if (next.x < 0 ||
          next.y < 0 ||
          next.x >= map.size.width ||
          next.y >= map.size.height) {
        continue;
      }
      final index = next.y * map.size.width + next.x;
      if (!allowed[index] ||
          blocked[index] ||
          excluded.contains(index) ||
          !reached.add(index)) {
        continue;
      }
      queue.add(next);
    }
  }
  return reached;
}

void _expectSpecialZone(
  MapData map,
  String id,
  int x,
  int y,
  int width,
  int height,
) {
  final matches = map.gameplayZones.where((zone) => zone.id == id);
  expect(matches, hasLength(1));
  final zone = matches.single;
  expect(zone.kind, GameplayZoneKind.special);
  expect(
    zone.area,
    MapRect(
      pos: GridPos(x: x, y: y),
      size: GridSize(width: width, height: height),
    ),
  );
  expect(zone.special?.scriptKey, isNull);
  expect(zone.special?.properties, <String, String>{
    'contractRole': 'navigation_anchor',
    'inert': 'true',
  });
}

void _expectReservedTrigger(
  MapData map,
  String id,
  String eventId,
  int x,
  int y,
  int width,
  int height,
) {
  final matches = map.triggers.where((trigger) => trigger.id == id);
  expect(matches, hasLength(1));
  final trigger = matches.single;
  expect(trigger.type, TriggerType.custom);
  expect(
    trigger.area,
    MapRect(
      pos: GridPos(x: x, y: y),
      size: GridSize(width: width, height: height),
    ),
  );
  expect(trigger.properties, <String, String>{
    'eventId': eventId,
    'reservedForNarrative': 'true',
  });
}

MapPlacedElement _expectPlacedElement(
  MapData map, {
  required String id,
  required String elementId,
  required String layerId,
  required GridPos pos,
}) {
  final matches = map.placedElements.where((placed) => placed.id == id);
  expect(matches, hasLength(1));
  final placed = matches.single;
  expect(placed.elementId, elementId);
  expect(placed.layerId, layerId);
  expect(placed.pos, pos);
  return placed;
}

void _expectStructuralAnchor(
  MapData map,
  String id,
  int x,
  int y,
) {
  final matches = map.entities.where((entity) => entity.id == id);
  expect(matches, hasLength(1));
  final entity = matches.single;
  expect(entity.kind, MapEntityKind.custom);
  expect(entity.pos, GridPos(x: x, y: y));
  expect(entity.blocksMovement, isFalse);
  expect(entity.npc, isNull);
  expect(entity.sign, isNull);
  expect(entity.item, isNull);
  expect(entity.spawn, isNull);
  expect(entity.properties, <String, String>{
    'contractRole': 'reserved_character_anchor',
    'inert': 'true',
  });
}

bool _rectanglesOverlap(MapRect left, MapRect right) {
  final leftRight = left.pos.x + left.size.width;
  final leftBottom = left.pos.y + left.size.height;
  final rightRight = right.pos.x + right.size.width;
  final rightBottom = right.pos.y + right.size.height;
  return left.pos.x < rightRight &&
      leftRight > right.pos.x &&
      left.pos.y < rightBottom &&
      leftBottom > right.pos.y;
}

void _expectLayerContract(MapData map, {required bool exterior}) {
  final expectedIds = exterior
      ? <String>[
          'l_terrain',
          'l_path_primary',
          'l_path_secondary',
          'l_tile_ground',
          'l_tile_structures',
          'l_tile_overhead',
          'l_tile_fx',
          'l_collisions',
        ]
      : <String>[
          'l_terrain',
          'l_tile_floor',
          'l_tile_walls',
          'l_tile_furniture',
          'l_tile_overhead',
          'l_tile_fx',
          'l_collisions',
        ];
  expect(map.layers.map((layer) => layer.id), expectedIds);
  final cellCount = map.size.width * map.size.height;
  for (final layer in map.layers) {
    final length = switch (layer) {
      TerrainLayer(:final terrains) => terrains.length,
      PathLayer(:final cells) => cells.length,
      TileLayer(:final tiles) => tiles.length,
      CollisionLayer(:final collisions) => collisions.length,
      _ => -1,
    };
    expect(length, cellCount, reason: '${map.id}/${layer.id}');
  }
  expect(
    map.layers.whereType<TerrainLayer>().single.terrains,
    contains(isNot(TerrainType.none)),
  );
  if (exterior) {
    expect(
      map.layers.whereType<PathLayer>().expand((layer) => layer.cells),
      contains(true),
    );
  }
}

Map<String, dynamic> _seedFingerprint(Map<String, dynamic> map) =>
    <String, dynamic>{
      'size': map['size'],
      'tilesetId': map['tilesetId'],
      'layers': map['layers'],
      'placedElements': map['placedElements'],
      'entities': map['entities'],
      'triggers': map['triggers'],
      'gameplayZones': map['gameplayZones'],
      'events': map['events'],
    };

Map<String, dynamic> _placedElementSeedSemantics(MapPlacedElement placed) {
  final json =
      (jsonDecode(jsonEncode(placed.toJson())) as Map).cast<String, dynamic>();
  json.remove('id');
  json.remove('layerId');
  return json;
}

Directory _copySelbrumeFixture() {
  final repositoryRoot = _findRepositoryRoot();
  final source = Directory(p.join(repositoryRoot.path, 'selbrume'));
  final parent = Directory.systemTemp.createTempSync('selbrume_task4_');
  final target = Directory(p.join(parent.path, 'selbrume'))..createSync();
  final targetMaps = Directory(p.join(target.path, 'maps'))..createSync();
  final targetTilesets = Directory(p.join(target.path, 'assets', 'tilesets'))
    ..createSync(recursive: true);
  final targetProject = File(p.join(target.path, 'project.json'));
  File(p.join(source.path, 'project.json')).copySync(targetProject.path);
  final projectJson = _readJson(targetProject);
  projectJson['maps'] = (projectJson['maps'] as List<dynamic>)
      .where(
        (entry) => !canonicalSelbrumeMapIds.contains(
          (entry as Map<String, dynamic>)['id'],
        ),
      )
      .toList(growable: false);
  projectJson['groups'] = (projectJson['groups'] as List<dynamic>)
      .where(
        (entry) => !canonicalSelbrumeGroupIds.contains(
          (entry as Map<String, dynamic>)['id'],
        ),
      )
      .toList(growable: false);
  projectJson['tilesetFolders'] =
      (projectJson['tilesetFolders'] as List<dynamic>)
          .where(
            (entry) => !const <String>{
              'tsf_selbrume_beta',
              'tsf_selbrume_beta_port',
              'tsf_selbrume_beta_interiors',
              'tsf_selbrume_beta_forest',
              'tsf_selbrume_beta_marsh',
              'tsf_selbrume_beta_passage',
              'tsf_selbrume_beta_lighthouse',
              'tsf_selbrume_beta_fx',
            }.contains((entry as Map<String, dynamic>)['id']),
          )
          .toList(growable: false);
  projectJson['tilesets'] = (projectJson['tilesets'] as List<dynamic>)
      .where(
        (entry) => !const <String>{
          'ts_selbrume_boat',
          'ts_selbrume_open_sea_loop',
          'ts_selbrume_port_props',
          'ts_selbrume_cabin_interior',
          'ts_selbrume_forest_props',
          'ts_selbrume_marsh_props',
          'ts_selbrume_passage_props',
          'ts_selbrume_lighthouse_exterior',
          'ts_selbrume_lighthouse_interior',
          'ts_selbrume_lighthouse_fx',
        }.contains((entry as Map<String, dynamic>)['id']),
      )
      .toList(growable: false);
  projectJson['elementCategories'] =
      (projectJson['elementCategories'] as List<dynamic>)
          .where(
            (entry) => !const <String>{
              'cat_selbrume_port_props',
              'cat_selbrume_interiors',
              'cat_selbrume_forest',
              'cat_selbrume_marsh',
              'cat_selbrume_passage',
              'cat_selbrume_lighthouse',
              'cat_selbrume_fx',
            }.contains((entry as Map<String, dynamic>)['id']),
          )
          .toList(growable: false);
  projectJson['elements'] =
      (projectJson['elements'] as List<dynamic>).where((entry) {
    final id = (entry as Map<String, dynamic>)['id'].toString();
    return !id.startsWith('el_selbrume_port_') &&
        !_cabinElementContracts.containsKey(id) &&
        !_forestElementContracts.containsKey(id) &&
        !_marshElementContracts.containsKey(id) &&
        !_passageElementContracts.containsKey(id) &&
        !_lighthouseExteriorElementContracts.containsKey(id) &&
        !_lighthouseInteriorElementContracts.containsKey(id) &&
        !_lighthouseFxElementContracts.containsKey(id);
  }).toList(growable: false);
  projectJson['pathPatternPresets'] = <Map<String, dynamic>>[
    for (final entry in projectJson['pathPatternPresets'] as List<dynamic>)
      if ((entry as Map<String, dynamic>)['basePathPresetId'] !=
              'nouveau-chemin' &&
          entry['id'] != 'pp_selbrume_open_sea_loop')
        entry,
    _legacyNouveauCheminPattern('nouveau-chemin-pattern'),
    _legacyNouveauCheminPattern('nouveau-chemin-pattern-duplicate'),
  ];
  targetProject.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(projectJson)}\n',
  );
  for (final fileName in <String>['Selbrume.json', 'route 1.json']) {
    File(p.join(source.path, 'maps', fileName))
        .copySync(p.join(targetMaps.path, fileName));
  }
  for (final fileName in <String>[
    'selbrume_boat.png',
    'selbrume_open_sea_loop.png',
  ]) {
    File(p.join(source.path, 'assets', 'tilesets', fileName))
        .copySync(p.join(targetTilesets.path, fileName));
  }
  return target;
}

Map<String, dynamic> _legacyNouveauCheminPattern(String id) =>
    <String, dynamic>{
      'id': id,
      'name': id,
      'basePathPresetId': 'nouveau-chemin',
      'centerPattern': <String, dynamic>{
        'size': <String, dynamic>{'width': 2, 'height': 2},
        'cells': <Map<String, dynamic>>[
          for (var localY = 0; localY < 2; localY += 1)
            for (var localX = 0; localX < 2; localX += 1)
              <String, dynamic>{
                'localX': localX,
                'localY': localY,
                'frames': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'tilesetId': 'deep_water',
                    'source': <String, dynamic>{
                      'x': localX,
                      'y': localY,
                      'width': 1,
                      'height': 1,
                    },
                    'durationMs': 100,
                  },
                ],
              },
        ],
      },
      'sortOrder': 0,
    };

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    final parent = current.parent.absolute;
    if (parent.path == current.path) {
      throw StateError('Could not locate repository root.');
    }
    current = parent;
  }
}

List<File> _canonicalMapFiles(Directory projectRoot) {
  final maps = Directory(p.join(projectRoot.path, 'maps'));
  return canonicalSelbrumeMapIds
      .map((id) => File(p.join(maps.path, '$id.json')))
      .where((file) => file.existsSync())
      .toList(growable: false);
}

Map<String, dynamic> _readJson(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();

String _maskManifestArrays(String source) {
  var masked = _replaceTopLevelArray(source, 'groups', '<GROUPS>');
  masked = _replaceTopLevelArray(masked, 'maps', '<MAPS>');
  return masked;
}

String _maskTask5ManifestArrays(String source) {
  var masked = source;
  for (final key in const <String>[
    'groups',
    'maps',
    'tilesets',
    'elements',
    'pathPatternPresets',
  ]) {
    masked = _replaceTopLevelArray(masked, key, '<${key.toUpperCase()}>');
  }
  return masked;
}

String _maskTask6ManifestArrays(String source) {
  var masked = source;
  for (final key in const <String>[
    'groups',
    'maps',
    'tilesetFolders',
    'tilesets',
    'elementCategories',
    'elements',
    'pathPatternPresets',
  ]) {
    masked = _replaceTopLevelArray(masked, key, '<${key.toUpperCase()}>');
  }
  return masked;
}

Map<String, List<int>> _snapshotFiles(Directory root) => <String, List<int>>{
      for (final file in root
          .listSync(recursive: true, followLinks: false)
          .whereType<File>())
        p.relative(file.path, from: root.path): file.readAsBytesSync(),
    };

String _replaceTopLevelArray(String source, String key, String replacement) {
  final marker = '"$key"';
  final keyIndex = source.indexOf(marker);
  if (keyIndex < 0) throw StateError('Missing manifest key: $key');
  final start = source.indexOf('[', keyIndex + marker.length);
  if (start < 0) throw StateError('Missing array for manifest key: $key');
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var index = start; index < source.length; index++) {
    final code = source.codeUnitAt(index);
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (code == 0x5c) {
        escaped = true;
      } else if (code == 0x22) {
        inString = false;
      }
      continue;
    }
    if (code == 0x22) {
      inString = true;
    } else if (code == 0x5b) {
      depth++;
    } else if (code == 0x5d) {
      depth--;
      if (depth == 0) {
        return source.replaceRange(start, index + 1, replacement);
      }
    }
  }
  throw StateError('Unterminated array for manifest key: $key');
}
