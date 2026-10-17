import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_project_smoke.dart';
import 'package:pokemap_hub/features/saves/data/repositories/game_save_update_preparation.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';

import '../../../../packages/map_authoring/test/domains/assets/resource_pack_export_test.dart'
    as original;
import '../../../../packages/map_authoring/test/domains/assets/resource_pack_import_fixture.dart';
import '../../../../packages/map_authoring/test/support/glb_fixture.dart'
    as helper;

final class InstalledResourcePackFixture {
  InstalledResourcePackFixture._({
    required this.root,
    required this.dimension,
    required this.retainTrace,
    required this.gameId,
    required this.mapId,
    required this.elementId,
    required this.characterId,
    required this.modelIds,
    required this.modelHashes,
    required this.pngHash,
  });

  final Directory root;
  final ProjectDimension dimension;
  final bool retainTrace;
  final String gameId;
  final String mapId;
  final String elementId;
  final String characterId;
  final List<String> modelIds;
  final Map<String, String> modelHashes;
  final String pngHash;
  Directory get supportRoot => Directory('${root.path}/installed');
  File get _package => File('${root.path}/packages/game.avelunegame');
  Iterable<Directory> get _sources => [
    for (final name in [
      'authors',
      'without-trace',
      'inputs',
      'packages',
      'owned-stages',
    ])
      Directory('${root.path}/$name'),
  ];

  static Future<InstalledResourcePackFixture> create({
    required ProjectDimension dimension,
    required bool retainTrace,
  }) async {
    final created = await Directory.systemTemp.createTemp(
      'p12-installed-resources-',
    );
    final root = Directory(await created.resolveSymbolicLinks());
    try {
      final stages = await Directory('${root.path}/owned-stages').create();
      final input = File('${root.path}/inputs/original.aveluneassets');
      await input.parent.create();
      await Directory('${root.path}/authors').create();
      final spatial = dimension == ProjectDimension.threeD;
      final label = spatial ? '3d' : '2d';
      late String pngHash;
      late Map<String, Object?> prepared;
      await IOOverrides.runZoned(() async {
        pngHash = await _writeOriginalPack(input);
        prepared = await _prepareProject(root, input, spatial);
        expect(await inventory(stages), isEmpty);
      }, getSystemTempDirectory: () => stages);
      final author = Directory('${root.path}/authors/$label');
      final clean = Directory('${root.path}/without-trace/$label');
      await cloneOwned(author, clean);
      final manifestFile = File('${clean.path}/project.json');
      final before = ProjectManifest.fromJson(await loadJson(manifestFile));
      final after = before.copyWith(
        resourcePackInstallations:
            const ResourcePackInstallationCatalog.empty(),
      );
      expect(
        before.toJson()..remove('resourcePackInstallations'),
        after.toJson()..remove('resourcePackInstallations'),
      );
      final beforeFiles = await inventory(clean);
      await saveJson(manifestFile, after.toJson());
      final afterFiles = await inventory(clean);
      expect(
        beforeFiles..remove('project.json'),
        afterFiles..remove('project.json'),
      );
      final gameId =
          'original.p12.installed.scene-$label-${retainTrace ? 'trace' : 'plain'}';
      final package = File('${root.path}/packages/game.avelunegame');
      await package.parent.create();
      final artifact = await IOOverrides.runZoned(
        () => const CanonicalGamePackageExportService().exportToFile(
          projectRoot: retainTrace ? author : clean,
          outputFile: package,
          mode: GamePackageExportMode.localTest,
          profile: GamePackageExportProfile(
            gameId: gameId,
            gameVersion: '1.0.0',
            title: 'Installed original $label',
            authorName: 'Atelier original QA',
            defaultLocale: 'fr',
            supportedLocales: ['fr'],
          ),
        ),
        getSystemTempDirectory: () => stages,
      );
      expect(await inventory(stages), isEmpty);
      expect(artifact.certification.isExportable, isTrue);
      expect(artifact.certification.isCertified, isFalse);
      return InstalledResourcePackFixture._(
        root: root,
        dimension: dimension,
        retainTrace: retainTrace,
        gameId: gameId,
        mapId: prepared['mapId']! as String,
        elementId: prepared['elementId']! as String,
        characterId: prepared['characterId']! as String,
        modelIds: List<String>.from(prepared['modelIds']! as List),
        modelHashes: Map<String, String>.from(prepared['modelHashes']! as Map),
        pngHash: pngHash,
      );
    } on Object {
      await root.delete(recursive: true);
      rethrow;
    }
  }

  GamePackageInstaller _installer() => GamePackageInstaller(
    supportRoot: supportRoot,
    inspector: GamePackageInspector(
      hostCompatibility: aveluneHostCompatibility(),
    ),
    availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
    loadSmoke: loadInstalledProjectSmoke,
    prepareSavesForUpdate: GameSaveUpdatePreparation(supportRoot: supportRoot)
        .call,
  );

  Future<void> install() async {
    final result = await _installer().install(
      _package,
      source: GamePackageInstallSource.localFile,
    );
    expect(result.game.gameId, gameId);
    expect(result.alreadyInstalled, isFalse);
    await assertInstalledClosure();
  }

  Future<InstalledGame> readInstalledGame() async {
    final rebuilt = await _installer().rebuildLibrary();
    return rebuilt.game(gameId) ?? (throw StateError('Installed game missing'));
  }

  InstalledGameLaunchResolver newResolver() => InstalledGameLaunchResolver(
    supportRoot: supportRoot,
    hostCompatibility: aveluneHostCompatibility(),
  );

  Future<void> assertInstalledClosure() async {
    final launch = await newResolver().resolve(await readInstalledGame());
    final project = await launch.assets.resolveReference(launch.project);
    final installedRoot = p.dirname(p.dirname(project.path));
    final hashes = <String>{};
    for (final entry in launch.manifest.content.files) {
      final file = await launch.assets.resolveFile(entry.path);
      expect(
        p.isWithin(installedRoot, await file.resolveSymbolicLinks()),
        isTrue,
      );
      expect(await file.length(), entry.size);
      final actual = await hashFile(file);
      expect(actual, entry.sha256);
      hashes.add(actual);
    }
    expect(
      hashes,
      containsAll([
        pngHash,
        if (dimension == ProjectDimension.threeD) ...modelHashes.values,
      ]),
    );
    assertRuntimeManifest(ProjectManifest.fromJson(await loadJson(project)));
  }

  void assertRuntimeProjectRoot(String path) {
    expect(p.isWithin(supportRoot.path, path), isTrue);
    expect(p.isWithin('${root.path}/authors', path), isFalse);
  }

  void assertRuntimeManifest(ProjectManifest manifest) {
    expect(manifest.settings.dimension, dimension);
    expect(
      manifest.resourcePackInstallations.entries,
      hasLength(retainTrace ? 1 : 0),
    );
    if (retainTrace) {
      final installed = manifest.resourcePackInstallations.entries.single;
      expect(installed.resources, hasLength(9));
      expect(installed.supports, hasLength(13));
    }
    expect(manifest.newGame.enabled, isTrue);
    expect(manifest.newGame.startMapId, mapId);
    expect(manifest.newGame.startSpawnId, 'player-start');
    expect(manifest.newGame.playerAvatarCharacterIds, contains(characterId));
    final element = manifest.elements.singleWhere(
      (entry) => entry.id == elementId,
    );
    expect(element.frames, hasLength(2));
    expect(element.collisionProfile!.cells, isNotEmpty);
    expect(
      manifest.characters
          .singleWhere((entry) => entry.id == characterId)
          .animations
          .where((entry) => entry.state == CharacterAnimationState.walk)
          .every((entry) => entry.frames.length == 2),
      isTrue,
    );
    if (dimension == ProjectDimension.threeD) {
      expect(manifest.models3d.map((entry) => entry.id), containsAll(modelIds));
    }
    expect(manifest.smartTileCatalog.presets, isNotEmpty);
    expect(manifest.environmentPresets, isNotEmpty);
    final border =
        manifest.borderCatalog.records.single.latestPublished!.definition;
    expect(border.primitives.map((entry) => entry.role).toSet(), {
      BorderPrimitiveRole.lineCap,
      BorderPrimitiveRole.lineStraight,
      BorderPrimitiveRole.lineCorner,
    });
    if (dimension == ProjectDimension.threeD) {
      expect(
        manifest.models3d
            .singleWhere((entry) => entry.id == modelIds.first)
            .collisionBounds!
            .size
            .y,
        greaterThan(0),
      );
      expect(
        manifest.models3d
            .singleWhere((entry) => entry.id == modelIds.last)
            .inspection
            .animations
            .single
            .durationSeconds,
        2,
      );
    }
  }

  void assertModelBytes(String id, List<int> bytes) {
    expect(sha256.convert(bytes).toString(), modelHashes[id]);
    expect(
      GlbModel3dInspector().inspect(Uint8List.fromList(bytes)).triangleCount,
      12,
    );
  }

  Future<void> retireSources() async {
    for (final directory in _sources) {
      if (await directory.exists()) {
        expect(
          await directory.resolveSymbolicLinks(),
          p.join(await root.resolveSymbolicLinks(), p.basename(directory.path)),
        );
        await directory.delete(recursive: true);
      }
    }
    await assertSourcesAbsent();
  }

  Future<void> assertSourcesAbsent() async {
    for (final directory in _sources) {
      expect(
        await FileSystemEntity.type(directory.path, followLinks: false),
        FileSystemEntityType.notFound,
      );
    }
  }

  Future<void> assertMissingPayloadRejected(String extension) async {
    final game = await readInstalledGame();
    final launch = await newResolver().resolve(game);
    final hash = extension == '.png' ? pngHash : modelHashes.values.first;
    final entry = launch.manifest.content.files.firstWhere(
      (entry) => entry.sha256 == hash,
    );
    final file = await launch.assets.resolveFile(entry.path);
    final bytes = await file.readAsBytes();
    await file.delete();
    try {
      await expectLater(
        newResolver().resolve(game),
        throwsA(
          isA<InstalledGameLaunchException>().having(
            (error) => error.code,
            'code',
            InstalledGameLaunchErrorCode.installationUnhealthy,
          ),
        ),
      );
      await assertSourcesAbsent();
    } finally {
      await file.writeAsBytes(bytes, flush: true);
    }
    await newResolver().resolve(game);
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Future<String> _writeOriginalPack(File output) async {
  final volumeBytes = <String, Uint8List>{};
  final models = <ProjectModel3dEntry>[];
  for (final animated in [false, true]) {
    final id = animated ? 'animated_model' : 'model';
    final asset = animated ? 'animated_glb' : 'glb';
    final bytes = generate(animated);
    final inspection = GlbModel3dInspector().inspect(bytes);
    models.add(
      ProjectModel3dEntry(
        id: id,
        name: animated ? 'Original animated volume' : 'Original static volume',
        sourceAssetId: asset,
        relativePath: 'assets/models3d/$id.glb',
        inspection: inspection,
        pivot: Model3dVector3.zero,
        collisionBounds: animated ? null : inspection.bounds,
      ),
    );
    volumeBytes[asset] = bytes;
  }
  final (base, oldFiles) = original.mixedFixture();
  final image = img.Image(width: 32, height: 32, numChannels: 4);
  for (var y = 0; y < 32; y++) {
    for (var x = 0; x < 32; x++) {
      final right = x >= 16, bottom = y >= 16;
      image.setPixelRgba(
        x,
        y,
        bottom
            ? 220
            : right
            ? 205
            : 35,
        bottom
            ? right
                  ? 75
                  : 195
            : right
            ? 125
            : 145,
        bottom
            ? 75
            : right
            ? 55
            : 195,
        255,
      );
    }
  }
  final png = Uint8List.fromList(img.encodePng(image));
  final oldBorder =
      base.borderCatalog.records.single.latestPublished!.definition;
  final borderDefinition = BorderBlueprintPublishedDefinition(
    name: 'Original P12 complete border',
    previewSeed: oldBorder.previewSeed,
    template: oldBorder.template,
    primitives: [
      for (final role in [
        BorderPrimitiveRole.lineCap,
        BorderPrimitiveRole.lineStraight,
        BorderPrimitiveRole.lineCorner,
      ])
        BorderPublishedPrimitive(
          id: 'original-${role.name}',
          sourceModelId: 'model',
          role: role,
          weight: 1,
          anchorWorld: Model3dVector3.zero,
          transforms: BorderTransformPolicy(
            allowFlipX: false,
            allowedQuarterTurns: [0, 1, 2, 3],
          ),
        ),
    ],
    defaults: oldBorder.defaults,
    sortOrder: 0,
  );
  final borderPublication = BorderBlueprintRevision(
    revision: 1,
    definition: borderDefinition,
  );
  final manifest = base.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
      records: [
        BorderBlueprintRecord(
          id: 'border',
          latestPublished: borderPublication,
          draft: reconstructResourcePackBorderDraft(borderPublication),
        ),
      ],
    ),
    name: 'Atelier original P12 — volumes cohérents',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    tilesets: [
      base.tilesets.single.copyWith(
        source: ProjectTilesetSource.regularAtlas(
          assetId: 'image',
          pixelWidth: 32,
          pixelHeight: 32,
          tileWidth: 16,
          tileHeight: 16,
        ),
      ),
    ],
    elements: [
      for (final element in base.elements)
        element.copyWith(
          frames: [
            const TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0),
              durationMs: 200,
            ),
            const TilesetVisualFrame(
              source: TilesetSourceRect(x: 1, y: 0),
              durationMs: 200,
            ),
          ],
        ),
    ],
    models3d: models,
    resourceLibraryCatalog: ResourceLibraryCatalog(
      families: base.resourceLibraryCatalog.families,
      entries: [
        ...base.resourceLibraryCatalog.entries,
        ResourceLibraryEntry(
          resourceKind: 'model3d',
          resourceId: 'animated_model',
          familyId: 'family',
          placementContext: ResourcePlacementContext.exterior,
        ),
      ],
    ),
    characters: [
      base.characters.single.copyWith(
        frameWidth: 1,
        frameHeight: 1,
        animations: [
          for (final state in [
            CharacterAnimationState.idle,
            CharacterAnimationState.walk,
          ])
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                state: state,
                direction: direction,
                sourceAssetId: 'image',
                frames: [
                  const CharacterAnimationFrame(
                    source: TilesetSourceRect(
                      x: 0,
                      y: 16,
                      width: 16,
                      height: 16,
                    ),
                    durationMs: 200,
                  ),
                  if (state == CharacterAnimationState.walk)
                    const CharacterAnimationFrame(
                      source: TilesetSourceRect(
                        x: 16,
                        y: 16,
                        width: 16,
                        height: 16,
                      ),
                      durationMs: 200,
                    ),
                ],
              ),
        ],
        customAnimations: [
          base.characters.single.customAnimations.single.copyWith(
            frames: [
              const CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 16, width: 16, height: 16),
              ),
              const CharacterAnimationFrame(
                source: TilesetSourceRect(x: 16, y: 16, width: 16, height: 16),
              ),
            ],
          ),
        ],
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      categories: base.smartTileCatalog.categories,
      materials: base.smartTileCatalog.materials,
      animations: base.smartTileCatalog.animations,
      presets: base.smartTileCatalog.presets,
      patterns: base.smartTileCatalog.patterns,
      drafts: base.smartTileCatalog.drafts,
      atlases: [
        base.smartTileCatalog.atlases.single.copyWith(
          cellWidth: 16,
          cellHeight: 16,
          columns: 2,
          rows: 2,
        ),
      ],
    ),
  );
  final files = <NativeResourcePackFile>[
    for (final file in oldFiles)
      if (file.mediaType == 'image/png')
        original.fileOf(file.id, file.logicalPath, png)
      else if (file.id == 'glb')
        NativeResourcePackFile(
          id: 'glb',
          logicalPath: models.first.relativePath,
          byteLength: volumeBytes['glb']!.length,
          rawSha256: sha256.convert(volumeBytes['glb']!).toString(),
          mediaType: 'model/gltf-binary',
          openRead: () => Stream.value(volumeBytes['glb']!),
        )
      else
        file,
    NativeResourcePackFile(
      id: 'animated_glb',
      logicalPath: models.last.relativePath,
      byteLength: volumeBytes['animated_glb']!.length,
      rawSha256: sha256.convert(volumeBytes['animated_glb']!).toString(),
      mediaType: 'model/gltf-binary',
      openRead: () => Stream.value(volumeBytes['animated_glb']!),
    ),
  ];
  final fixture = await ResourcePackImportFixture.create(
    sourceManifest: manifest,
    sourceFiles: files,
    roots: [
      for (final (kind, id) in [
        (ResourcePackKind.element, 'decor'),
        (ResourcePackKind.model3d, 'model'),
        (ResourcePackKind.model3d, 'animated_model'),
        (ResourcePackKind.smartTilePreset, 'sol'),
        (ResourcePackKind.tileset, 'atlas'),
        (ResourcePackKind.borderBlueprint, 'border'),
        (ResourcePackKind.environmentPreset, 'environment'),
        (ResourcePackKind.character, 'person'),
      ])
        NativeResourcePackRef(kind: kind, id: id),
    ],
    metadata: ResourcePackMetadata(
      id: 'original.p12.native',
      version: '1.1.0',
      name: 'Atelier original · 2D et 3D',
      description: 'Fixture QA originale pour les sept types natifs.',
      universeId: 'original',
      authors: ['Atelier Avelune QA'],
      provenance: 'Création synthétique originale pour P12',
    ),
  );
  try {
    expect(fixture.archive.inspection.resourceCount, 9);
    expect(fixture.archive.inspection.supportCount, 13);
    final sink = output.openWrite();
    try {
      await fixture.archive.withSource(
        (source) => sink.addStream(sourceChunks(source)),
      );
      await sink.flush();
    } finally {
      await sink.close();
    }
    return sha256.convert(png).toString();
  } finally {
    await fixture.dispose();
  }
}

Future<Map<String, Object?>> _prepareProject(
  Directory fixture,
  File input,
  bool spatial,
) async {
  final label = spatial ? '3d' : '2d';
  const reader = LocalProjectFileReader();
  final parents = Directory('${fixture.path}/authors');
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [parents.path],
    fileReader: reader,
  );
  final creation = ProjectCreationBootstrapApi(
    policy: policy,
    creation: const LocalProjectCreationService(),
  );
  final camera = SpatialCameraProfile();
  final request = <String, dynamic>{
    'name': 'P12 original Player $label',
    'folderName': label,
    'parentPath': parents.path,
    'template': spatial ? 'empty' : 'playable',
    'dimension': spatial ? 'threeD' : 'twoD',
    'tileSize': 16,
    'mapWidth': 16,
    'mapHeight': 12,
    if (spatial) 'spatialCamera': camera.toJson(),
  };
  final preview = await creation.preview(request);
  final created = await creation.create(
    request,
    confirmation: preview['confirmation']! as String,
  );
  final root = Directory(created['projectPath']! as String);
  final session = await QaSession.open(root, input.parent);
  try {
    await session.importPack(input);
    var snapshot = await session.snapshot();
    final manifest = snapshot.manifest;
    final installations = manifest.resourcePackInstallations.entries;
    if (installations.length != 1 ||
        installations.single.resources.length != 9) {
      throw StateError('Exact nine-resource installation expected');
    }
    final installation = installations.single;
    final importedIds = installation.resources.map((e) => e.targetId).toSet();
    final character = manifest.characters
        .where((e) => importedIds.contains(e.id))
        .single;
    final element = manifest.elements.singleWhere(
      (e) => e.name == 'Original decor' && importedIds.contains(e.id),
    );
    final preset = manifest.smartTileCatalog.presets.singleWhere(
      (e) => importedIds.contains(e.id),
    );
    final environment = manifest.environmentPresets.singleWhere(
      (e) => importedIds.contains(e.id),
    );
    final staticModel = manifest.models3d.singleWhere(
      (e) => e.name == 'Original static volume' && importedIds.contains(e.id),
    );
    final animatedModel = manifest.models3d.singleWhere(
      (e) => e.name == 'Original animated volume' && importedIds.contains(e.id),
    );
    final border = manifest.borderCatalog.records.singleWhere(
      (e) => importedIds.contains(e.id),
    );
    if (character.animations
        .where((e) => e.state == CharacterAnimationState.walk)
        .any((e) => e.frames.length != 2)) {
      throw StateError('Two authored walk frames required');
    }
    if (element.frames.length != 2 ||
        element.collisionProfile?.cells.isEmpty != false) {
      throw StateError('Animated colliding imported element required');
    }
    final mapId = manifest.maps.single.id;
    await session.mutate('entity.upsert', {
      'mapId': mapId,
      'entity': MapEntity(
        id: 'player-start',
        name: 'Départ QA',
        kind: MapEntityKind.spawn,
        pos: const GridPos(x: 2, y: 7),
        blocksMovement: false,
        spawn: const MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ).toJson(),
    });
    await session.mutate('characterStudio.character.setDefault', {
      'characterId': character.id,
    });
    await session.mutate('campaign.new_game.update', {
      'newGame': ProjectNewGameConfig(
        enabled: true,
        startMapId: mapId,
        startSpawnId: 'player-start',
        playerName: 'Joueur QA',
        playerAvatarCharacterIds: [character.id],
      ).toJson(),
    });
    if (spatial) {
      final bounds = staticModel.collisionBounds;
      if (bounds == null ||
          bounds.size.x <= 0 ||
          bounds.size.y <= 0 ||
          bounds.size.z <= 0) {
        throw StateError('Nondegenerate collision volume required');
      }
      final clip = animatedModel.inspection.animations.single;
      await session.mutate('map3d.navigation.configure', {
        'mapId': mapId,
        'navigation': SpatialNavigationProfile(
          spawn: SpatialSpawn(x: 2.5, z: 7.5),
          allowDiagonalMovement: false,
        ).toJson(),
      });
      await session.mutate('map3d.terrain.set_levels', {
        'mapId': mapId,
        'cells': [
          for (var y = 0; y < 12; y++)
            for (var x = 0; x < 16; x++)
              {'x': x, 'z': y, 'level': y >= 10 && x >= 12 ? 1 : 0},
        ],
      });
      await session.mutate('map3d.instance.upsert_batch', {
        'mapId': mapId,
        'instances': [
          SpatialModelInstance(
            id: 'p12-solid-volume',
            modelId: staticModel.id,
            position: Model3dVector3(x: 5.5, y: 0, z: 7.5),
            blocksMovement: true,
          ).toJson(),
          SpatialModelInstance(
            id: 'p12-animated-volume',
            modelId: animatedModel.id,
            position: Model3dVector3(x: 8.5, y: 0, z: 4.5),
            blocksMovement: false,
            animationIndex: clip.index,
            animationLoop: true,
          ).toJson(),
        ],
      });
      await session.mutate('map.apply_operations', {
        'mapId': mapId,
        'operations': [
          {
            'kind': 'layer.add',
            'layerKind': 'border',
            'layerId': 'p12-border',
            'name': 'Bordure QA',
          },
        ],
      });
      await session.mutate('border_layer.feature_create', {
        'mapId': mapId,
        'layerId': 'p12-border',
        'featureId': 'p12-line',
        'name': 'Bordure originale',
        'blueprintId': border.id,
        'seed': '42',
        'geometry': {'kind': 'stroke', 'strokes': []},
      });
      await session.mutate('border_layer.stroke_add', {
        'mapId': mapId,
        'layerId': 'p12-border',
        'featureId': 'p12-line',
        'strokeId': 'p12-stroke',
        'points': [
          for (var x = 3; x <= 10; x++) {'x': x, 'y': 2},
        ],
        'closed': false,
      });
      await session.mutate('border_layer.materialize_apply', {
        'mapId': mapId,
        'layerId': 'p12-border',
        'featureId': 'p12-line',
      });
    } else {
      await session.mutate('placed_element.place', {
        'mapId': mapId,
        'instance': MapPlacedElement(
          id: 'p12-solid-decor',
          layerId: 'decor',
          elementId: element.id,
          pos: const GridPos(x: 5, y: 7),
          applyCollision: true,
          animation: const MapPlacedElementAnimation(
            enabled: true,
            mode: MapPlacedElementAnimationMode.loop,
          ),
        ).toJson(),
      });
      await session.mutate('smart_tile.layer.create', {
        'mapId': mapId,
        'presetId': preset.id,
        'layerId': 'p12-ground',
        'name': 'Terrain importé',
        'insertIndex': 0,
      });
      await session.mutate('smart_tile.cell.paint', {
        'mapId': mapId,
        'layerId': 'p12-ground',
        'materialId': preset.defaultMaterialId,
        'cells': [
          for (var y = 6; y <= 8; y++)
            for (var x = 1; x <= 11; x++) {'x': x, 'y': y},
        ],
      });
      await session.mutate('map.apply_operations', {
        'mapId': mapId,
        'operations': [
          {
            'kind': 'layer.add',
            'layerKind': 'environment',
            'layerId': 'p12-environment',
            'name': 'Environnement importé',
          },
        ],
      });
      await session.mutate('environment.attach_to_tile_layer', {
        'mapId': mapId,
        'layerId': 'p12-environment',
        'targetTileLayerId': 'ground',
      });
      await session.mutate('environment.area_create', {
        'mapId': mapId,
        'layerId': 'p12-environment',
        'areaId': 'p12-area',
        'name': 'Zone hors passage',
        'presetId': environment.id,
        'seed': 42,
      });
      await session.mutate('environment.mask_paint', {
        'mapId': mapId,
        'layerId': 'p12-environment',
        'areaId': 'p12-area',
        'x': 10,
        'y': 2,
        'width': 3,
        'height': 2,
      });
      await session.mutate('environment.generate_apply', {
        'mapId': mapId,
        'layerId': 'p12-environment',
        'areaId': 'p12-area',
      });
    }
    snapshot = await session.snapshot();
    if (spatial &&
        (snapshot.maps.single.spatialScene!.camera !=
                snapshot.manifest.settings.spatialCamera ||
            snapshot.maps.single.spatialScene!.heightLevels.length != 192)) {
      throw StateError('Project/scene camera or height inventory inconsistent');
    }
    final validation = await session.reads.validateProject(
      session.opened.projectHandle,
    );
    if ((validation.toJson()['structure']! as Map)['valid'] != true) {
      throw StateError('Imported project structure is invalid');
    }
    if (installation.supports.length != 13) {
      throw StateError('Exact thirteen-support installation expected');
    }
    return {
      'mapId': mapId,
      'elementId': element.id,
      'characterId': character.id,
      'modelIds': [staticModel.id, animatedModel.id],
      'modelHashes': {
        for (final model in [staticModel, animatedModel])
          model.id: await hashFile(File('${root.path}/${model.relativePath}')),
      },
    };
  } finally {
    await session.close();
  }
}

class QaSession {
  QaSession(
    this.root,
    this.handles,
    this.loader,
    this.reads,
    this.mutations,
    this.transfer,
    this.opened,
  );
  final Directory root;
  final WorkspaceHandleStore handles;
  final ProjectSnapshotLoader loader;
  final AuthoringReadApi reads;
  final LocalMapAuthoringMutationApi mutations;
  final LocalResourcePackTransferApi transfer;
  final OpenedProject opened;
  var sequence = 0;

  static Future<QaSession> open(Directory root, Directory inputRoot) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(handles: handles);
    final reads = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: loader,
    );
    final opened = await reads.openProject(root.path);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: loader,
      resourcePackSourceRoots: [inputRoot.path],
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final transfer = LocalResourcePackTransferApi(
      mutations: mutations,
      snapshotLoader: loader,
    );
    return QaSession(root, handles, loader, reads, mutations, transfer, opened);
  }

  Future<ProjectSnapshot> snapshot() => loader.load(opened.projectHandle);
  Future<Map<String, Object?>> run(
    String verb,
    Map<String, Object?> input,
  ) async => transfer.transfer(opened.projectHandle, verb: verb, input: input);
  Future<Map<String, Object?>> job(
    String verb,
    Map<String, Object?> input,
  ) async {
    final started = await run(verb, input);
    final id = started['jobId']! as String;
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    while (DateTime.now().isBefore(deadline)) {
      final result = await run('get', {'jobId': id});
      final state = (result['snapshot']! as Map)['state'];
      if (state == 'succeeded') {
        return Map<String, Object?>.from(result['result']! as Map);
      }
      if (state == 'failed' || state == 'cancelled') {
        throw StateError(jsonEncode(result));
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await run('cancel', {'jobId': id});
    throw StateError('Owned job timeout; close awaits settlement');
  }

  Future<void> mutate(
    String id,
    Map<String, Object?> parameters, {
    bool packImport = false,
  }) async {
    final descriptor = mutations
        .describeMutationContracts()
        .actions
        .singleWhere((e) => e.id == id && e.version == 1);
    final key = 'p12-${sequence++}';
    final plan = await mutations.planMutation(
      opened.projectHandle,
      AuthoringRequest(
        requestId: key,
        actionId: descriptor.id,
        actionVersion: descriptor.version,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: (await snapshot()).revision,
        idempotencyKey: key,
        parameters: parameters,
      ),
    );
    if (!plan.applicable) {
      throw StateError('Nonapplicable $id: ${plan.toJson()}');
    }
    final confirmation = await mutations.confirmMutation(
      opened.projectHandle,
      planId: plan.planId,
    );
    if (packImport) {
      await job('start_apply', {
        'planId': plan.planId,
        'operationId': '$key-apply',
        'confirmationToken': confirmation.confirmationToken,
      });
    } else {
      final result = await mutations.applyMutation(
        opened.projectHandle,
        planId: plan.planId,
        operationId: '$key-apply',
        confirmationToken: confirmation.confirmationToken,
      );
      if (result.receipt.status != AuthoringReceiptStatus.applied) {
        throw StateError(jsonEncode(result.toJson()));
      }
    }
  }

  Future<Map<String, Object?>> importPack(File file) async {
    final staged = await job('stage', {'sourcePath': file.path});
    final effectiveStageRoot = Directory.systemTemp;
    final stageFiles = await inventory(effectiveStageRoot);
    if (stageFiles.isEmpty ||
        stageFiles.keys.any(
          (key) => !key.startsWith('pokemap-authoring-projections/'),
        )) {
      throw StateError(
        'Owned pack stage directory not observed under scoped temporary root',
      );
    }
    final inspected = await job('inspect', {
      'archiveHandle': staged['archiveHandle'],
    });
    final selection = await run('selection.create', {
      'mode': 'archive',
      'inspectionHandle': inspected['inspectionHandle'],
    });
    final selected = await run('selection.select_filtered', {
      'selectionHandle': selection['selectionHandle'],
      'revision': selection['revision'],
      'filter': <String, Object?>{},
    });
    final prepared = await job('prepare', {
      'selectionHandle': selected['selectionHandle'],
      'revision': selected['revision'],
      'expectedRevision': (await snapshot()).revision,
      'conflictPolicy': 'preserveProject',
    });
    if (prepared['status'] != 'ready') throw StateError(jsonEncode(prepared));
    await mutate('resource_pack.import', {
      'preparedImportHandle': prepared['preparedImportHandle'],
    }, packImport: true);
    return {
      'effectiveStageRoot': effectiveStageRoot.path,
      'stageFilesAfterStage': stageFiles,
      'staged': staged,
      'inspected': inspected,
      'selection': selected,
      'prepared': prepared,
    };
  }

  Future<void> close() async {
    await transfer.closeTransferWorkspace(opened.workspaceHandle);
    await mutations.detachWorkspace(opened.workspaceHandle);
    await reads.closeWorkspace(opened.workspaceHandle);
  }
}

Future<Map<String, dynamic>> loadJson(File file) async =>
    Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map);
Future<void> saveJson(File file, Map value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
    flush: true,
  );
}

Future<String> hashFile(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

Future<Map<String, String>> inventory(Directory root) async {
  final files = <String, String>{};
  await for (final e in root.list(recursive: true, followLinks: false)) {
    if (e is Link) throw StateError('Symlink refused: ${e.path}');
    if (e is File) {
      files[p.relative(e.path, from: root.path)] = await hashFile(e);
    }
  }
  return Map.fromEntries(
    files.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

Future<void> cloneOwned(Directory source, Directory destination) async {
  if (await destination.exists()) throw StateError('Existing clone refused');
  await destination.create(recursive: true);
  await for (final e in source.list(recursive: true, followLinks: false)) {
    final target = p.join(
      destination.path,
      p.relative(e.path, from: source.path),
    );
    if (e is Link) throw StateError('Symlink refused');
    if (e is Directory) await Directory(target).create(recursive: true);
    if (e is File) {
      await File(target).parent.create(recursive: true);
      await e.copy(target);
    }
  }
}

final class Binary {
  final BytesBuilder bytes = BytesBuilder(copy: false);
  final List<Map<String, Object?>> views = [];
  int add(Uint8List data, {int? target}) {
    while (bytes.length % 4 != 0) {
      bytes.addByte(0);
    }
    final index = views.length;
    views.add({
      'buffer': 0,
      'byteOffset': bytes.length,
      'byteLength': data.length,
      'target': ?target,
    });
    bytes.add(data);
    return index;
  }
}

Uint8List floats(List<double> values) {
  final data = ByteData(values.length * 4);
  for (var i = 0; i < values.length; i++) {
    data.setFloat32(i * 4, values[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

Uint8List integers(List<int> values) {
  final data = ByteData(values.length * 2);
  for (var i = 0; i < values.length; i++) {
    data.setUint16(i * 2, values[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

Uint8List texture(bool animated) {
  final image = img.Image(width: 16, height: 16);
  for (var y = 0; y < 16; y++) {
    for (var x = 0; x < 16; x++) {
      final seam =
          x == 0 || y == 0 || x == 15 || y == 15 || x == y || x + y == 15;
      final stripe = (x ~/ 4 + y ~/ 4) % 2 == 0;
      image.setPixelRgba(
        x,
        y,
        seam
            ? 32
            : animated
            ? 70
            : stripe
            ? 190
            : 150,
        seam
            ? 36
            : animated
            ? stripe
                  ? 180
                  : 130
            : 115,
        seam
            ? 44
            : animated
            ? 210
            : 65,
        255,
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List generate(bool animated) {
  final half = animated ? .375 : .5;
  final height = animated ? 1.0 : 1.5;
  final faces = <(List<List<double>>, List<double>)>[
    (
      [
        [-half, 0, half],
        [half, 0, half],
        [half, height, half],
        [-half, height, half],
      ],
      [0, 0, 1],
    ),
    (
      [
        [half, 0, -half],
        [-half, 0, -half],
        [-half, height, -half],
        [half, height, -half],
      ],
      [0, 0, -1],
    ),
    (
      [
        [half, 0, half],
        [half, 0, -half],
        [half, height, -half],
        [half, height, half],
      ],
      [1, 0, 0],
    ),
    (
      [
        [-half, 0, -half],
        [-half, 0, half],
        [-half, height, half],
        [-half, height, -half],
      ],
      [-1, 0, 0],
    ),
    (
      [
        [-half, height, half],
        [half, height, half],
        [half, height, -half],
        [-half, height, -half],
      ],
      [0, 1, 0],
    ),
    (
      [
        [-half, 0, -half],
        [half, 0, -half],
        [half, 0, half],
        [-half, 0, half],
      ],
      [0, -1, 0],
    ),
  ];
  final positions = <double>[];
  final normals = <double>[];
  final uvs = <double>[];
  final indices = <int>[];
  for (final (points, normal) in faces) {
    final start = positions.length ~/ 3;
    for (final point in points) {
      positions.addAll(point);
      normals.addAll(normal);
    }
    uvs.addAll([0, 1, 1, 1, 1, 0, 0, 0]);
    indices.addAll([start, start + 1, start + 2, start, start + 2, start + 3]);
  }
  final binary = Binary();
  final positionView = binary.add(floats(positions), target: 34962);
  final normalView = binary.add(floats(normals), target: 34962);
  final uvView = binary.add(floats(uvs), target: 34962);
  final indexView = binary.add(integers(indices), target: 34963);
  final pngView = binary.add(texture(animated));
  final accessors = <Map<String, Object?>>[
    {
      'bufferView': positionView,
      'componentType': 5126,
      'count': 24,
      'type': 'VEC3',
      'min': [-half, 0, -half],
      'max': [half, height, half],
    },
    {
      'bufferView': normalView,
      'componentType': 5126,
      'count': 24,
      'type': 'VEC3',
    },
    {
      'bufferView': uvView,
      'componentType': 5126,
      'count': 24,
      'type': 'VEC2',
      'min': [0, 0],
      'max': [1, 1],
    },
    {
      'bufferView': indexView,
      'componentType': 5123,
      'count': 36,
      'type': 'SCALAR',
      'min': [0],
      'max': [23],
    },
  ];
  final document = <String, dynamic>{
    'asset': {
      'version': '2.0',
      'generator': 'Avelune original P12 bounded QA volume generator',
    },
    'scene': 0,
    'scenes': [
      {
        'nodes': [0],
      },
    ],
    'nodes': [
      {
        'name': animated ? 'Original bob volume' : 'Original static volume',
        'mesh': 0,
        'translation': [0, 0, 0],
        'scale': [1, 1, 1],
      },
    ],
    'meshes': [
      {
        'name': 'Closed six-face box',
        'primitives': [
          {
            'attributes': {'POSITION': 0, 'NORMAL': 1, 'TEXCOORD_0': 2},
            'indices': 3,
            'material': 0,
            'mode': 4,
          },
        ],
      },
    ],
    'bufferViews': binary.views,
    'accessors': accessors,
    'images': [
      {
        'bufferView': pngView,
        'mimeType': 'image/png',
        'name': 'Original 16px texture',
      },
    ],
    'samplers': [
      {'magFilter': 9728, 'minFilter': 9728, 'wrapS': 33071, 'wrapT': 33071},
    ],
    'textures': [
      {'source': 0, 'sampler': 0},
    ],
    'materials': [
      {
        'name': animated ? 'Original blue bob' : 'Original ochre crate',
        'pbrMetallicRoughness': {
          'baseColorTexture': {'index': 0, 'texCoord': 0},
        },
        'alphaMode': 'OPAQUE',
        'doubleSided': false,
      },
    ],
  };
  if (animated) {
    final times = [0.0, .25, .5, .75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final elevations = [
      0.0,
      .03125,
      .125,
      .21875,
      .25,
      .21875,
      .125,
      .03125,
      0.0,
    ];
    final input = accessors.length;
    accessors.add({
      'bufferView': binary.add(floats(times)),
      'componentType': 5126,
      'count': times.length,
      'type': 'SCALAR',
      'min': [0],
      'max': [2],
    });
    accessors.add({
      'bufferView': binary.add(
        floats([
          for (final y in elevations) ...[0.0, y, 0.0],
        ]),
      ),
      'componentType': 5126,
      'count': elevations.length,
      'type': 'VEC3',
    });
    document['animations'] = [
      {
        'name': 'P12_Bob_2s',
        'samplers': [
          {'input': input, 'output': input + 1, 'interpolation': 'LINEAR'},
        ],
        'channels': [
          {
            'sampler': 0,
            'target': {'node': 0, 'path': 'translation'},
          },
        ],
      },
    ];
  }
  final bin = binary.bytes.toBytes();
  document['buffers'] = [
    {'byteLength': bin.length},
  ];
  return Uint8List.fromList(helper.encodeGlb(document, bin));
}
