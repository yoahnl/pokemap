import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final animatedBackground in [false, true]) {
  test('requires source-program capabilities for an exported game: animated=$animatedBackground', () async {
    final root = await _fixture();
    final png = spatialPayload()['project/assets/hero.png']!;
    final pngHash = sha256.convert(png).toString();
    final recipe = utf8.encode(jsonEncode({
      'schemaVersion': 2, 'recipeId': 'source', 'revision': '1',
      'moveSourceId': 'source', 'variant': 'Tackle',
      'requiredCapabilities': ['gen5SourceProgram', 'audioSelectionV2',
        if (animatedBackground) 'gen5SourceBackground',
        if (animatedBackground) 'gen5SourceBackgroundAnimation'],
      'provenance': {'source': 'synthetic', 'sourceRevision': '1', 'sourcePaths': [], 'converter': 'test'},
      'resources': [if (animatedBackground) {
        'id': 'bg', 'role': 'texture', 'mediaType': 'image/png',
        'sizeBytes': png.length, 'sha256': pngHash,
      }], 'audio': {'kind': 'none'},
      'program': {'kind': 'gen5SourceProgram', 'sourceProgram': {
        'kind': 'gen5SourceProgram', 'timebaseHz': 60, 'conversion': 'supported',
        'variant': 'Tackle', 'variants': ['Tackle'],
        'labels': [{'name': 'Tackle', 'instructionIndex': 0}], 'entryIndex': 0,
        'instructions': [{'op': 'end', 'args': {}, 'source': {}}],
      }, 'particleBindings': [],
        if (animatedBackground) 'backgroundBindings': [{'background': 1, 'resourceId': 'bg'}],
        if (animatedBackground) 'backgroundAnimationBindings': [
          {'animation': 2, 'background': 1, 'frames': ['bg'], 'durations': [3]},
        ]},
    }));
    final digest = sha256.convert(recipe).toString();
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1, 'projectMoveId': 'custom', 'sourceMoveId': 'source',
      'catalogReleaseId': 'test', 'recipeId': 'source', 'variant': 'Tackle',
      'revision': '1', 'recipeSha256': digest,
    });
    await _write(root, battleRecipeBindingPath('custom'), BattleRecipeProjectBinding(binding: binding).toJson());
    await _write(root, battleRecipeBlobPath(digest, 'application/vnd.avelune.battle-recipe+json', projectMoveId: 'custom'), recipe);
    if (animatedBackground) {
      await _write(root, battleRecipeBlobPath(pngHash, 'image/png', projectMoveId: 'custom'), png);
    }
    late GamePackageBuildResult built;
    final service = CanonicalGamePackageExportService(
      packageArchiveBuilder: ({required manifest, required payloadFiles}) {
        built = const GamePackageBuilder().build(manifest: manifest, payloadFiles: payloadFiles);
        return built;
      },
    );
    await service.build(projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest);
    final inspection = const GamePackageInspector().inspect(built.packageBytes);
    final capability = animatedBackground
        ? BattleMoveAnimationRecipe.gen5SourceBackgroundAnimationRuntimeCapability
        : BattleMoveAnimationRecipe.gen5SourceRuntimeCapability;
    expect(inspection.manifest.compatibility.requiredCapabilities, contains(capability));
    final current = AveluneRuntimeCompatibility.host();
    expect(current.capabilities, contains(capability));
    final older = GamePackageHostCompatibility(
      hubVersion: current.hubVersion, runtimeApiVersion: current.runtimeApiVersion,
      supportedRuntimeApiVersions: current.supportedRuntimeApiVersions,
      capabilities: {...current.capabilities}..remove(capability),
      supportedProjectFormats: current.supportedProjectFormats,
      currentProjectFormat: current.currentProjectFormat,
      currentProjectFormats: current.currentProjectFormats,
      supportedSaveFormats: current.supportedSaveFormats,
    );
    final compatibility = const GamePackageCompatibilityEvaluator()
        .evaluate(inspection.manifest, older);
    expect(compatibility.decision, GamePackageCompatibilityDecision.reject);
    expect(compatibility.missingCapabilities, contains(capability));
    final manifest = inspection.manifest.toJson();
    (manifest['compatibility'] as Map)['requiredCapabilities'] = inspection.manifest.compatibility.requiredCapabilities
        .where((value) => value != capability).toList();
    final stripped = const GamePackageManifestCodec().decodeJson(manifest);
    final archive = ZipDecoder().decodeBytes(built.packageBytes);
    final files = {for (final file in archive.files) file.name: file.content as List<int>};
    expect(() => const GamePackageProjectValidator(GamePackageSecurityPolicy()).validate(
      stripped, Uint8List.fromList(files['project/project.json']!),
      payloadPaths: files.keys.toSet(), readPayload: (path) => files[path],
    ), throwsA(isA<GamePackageFormatException>().having((error) => error.message, 'message', contains(capability))));
  });
  }

  test('declares and enforces the Player capability for Gen 5 combatant motion', () async {
    final root = await _fixture();
    final recipe = utf8.encode(jsonEncode({
      'schemaVersion': 2, 'recipeId': 'motion', 'revision': '1',
      'moveSourceId': 'source', 'variant': 'default',
      'requiredCapabilities': ['gen5Swing', 'audioSelectionV2'],
      'provenance': {'source': 'synthetic', 'sourceRevision': '1', 'sourcePaths': [], 'converter': 'test'},
      'resources': [], 'audio': {'kind': 'none'},
      'program': {'kind': 'gen5Swing', 'target': 'user', 'channel': 'position',
        'x': 4096, 'y': 0, 'frames': 4, 'wait': 1, 'count': 1},
    }));
    final digest = sha256.convert(recipe).toString();
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1, 'projectMoveId': 'custom', 'sourceMoveId': 'source',
      'catalogReleaseId': 'test', 'recipeId': 'motion', 'variant': 'default',
      'revision': '1', 'recipeSha256': digest,
    });
    await _write(root, battleRecipeBindingPath('custom'), BattleRecipeProjectBinding(binding: binding).toJson());
    await _write(root, battleRecipeBlobPath(digest, 'application/vnd.avelune.battle-recipe+json', projectMoveId: 'custom'), recipe);
    final exported = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final inspection = const GamePackageInspector().inspect(exported.packageBytes);
    const capability = BattleMoveAnimationRecipe.gen5MotionRuntimeCapability;
    expect(inspection.manifest.compatibility.requiredCapabilities, contains(capability));
    final current = AveluneRuntimeCompatibility.host();
    expect(current.capabilities, contains(capability));
    final older = GamePackageHostCompatibility(
      hubVersion: current.hubVersion, runtimeApiVersion: current.runtimeApiVersion,
      supportedRuntimeApiVersions: current.supportedRuntimeApiVersions,
      capabilities: {...current.capabilities}..remove(capability),
      supportedProjectFormats: current.supportedProjectFormats,
      currentProjectFormat: current.currentProjectFormat,
      currentProjectFormats: current.currentProjectFormats,
      supportedSaveFormats: current.supportedSaveFormats,
    );
    final compatibility = const GamePackageCompatibilityEvaluator().evaluate(inspection.manifest, older);
    expect(compatibility.decision, GamePackageCompatibilityDecision.reject);
    expect(compatibility.missingCapabilities, contains(capability));
    final manifest = inspection.manifest.toJson();
    (manifest['compatibility'] as Map)['requiredCapabilities'] = inspection.manifest.compatibility.requiredCapabilities
        .where((value) => value != capability).toList();
    final stripped = const GamePackageManifestCodec().decodeJson(manifest);
    final archive = ZipDecoder().decodeBytes(exported.packageBytes);
    final files = {for (final file in archive.files) file.name: file.content as List<int>};
    expect(() => const GamePackageProjectValidator(GamePackageSecurityPolicy()).validate(
      stripped, Uint8List.fromList(files['project/project.json']!),
      payloadPaths: files.keys.toSet(), readPayload: (path) => files[path],
    ), throwsA(isA<GamePackageFormatException>().having((error) => error.message, 'message', contains(capability))));
  });
  for (final splVersion in [3, 4]) {
  test('declares the Player capability required by SPL v$splVersion', () async {
    final root = await _fixture();
    final png = spatialPayload()['project/assets/hero.png']!;
    final definition = jsonDecode(await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString()) as Map<String, dynamic>;
    definition['schemaVersion'] = splVersion;
    (((definition['emitters'] as List).single as Map)['emission'] as Map)['positionVelocity'] = 914;
    if (splVersion == 4) {
      (((definition['emitters'] as List).single as Map)['motion'] as Map)['magnet'] = {'target': {'x': 0, 'y': -19033, 'z': 0}, 'force': 761};
    }
    final particle = utf8.encode(jsonEncode(definition));
    final particleHash = sha256.convert(particle).toString();
    final textureHash = sha256.convert(png).toString();
    final recipe = utf8.encode(jsonEncode({
      'schemaVersion': 1, 'recipeId': 'radial', 'revision': '1',
      'moveSourceId': 'source', 'variant': 'default',
      'requiredCapabilities': ['startParticle', 'splParticleV$splVersion'],
      'provenance': {'source': 'synthetic', 'sourceRevision': '1', 'sourcePaths': [], 'converter': 'test'},
      'resources': [
        {'id': 'tex', 'role': 'texture', 'mediaType': 'image/png', 'sizeBytes': png.length, 'sha256': textureHash},
        {'id': 'particle', 'role': 'particleDefinition', 'mediaType': 'application/vnd.avelune.particle+json', 'sizeBytes': particle.length, 'sha256': particleHash, 'definitionVersion': splVersion, 'dependencies': ['tex']},
      ],
      'program': {'kind': 'startParticle', 'resourceId': 'particle', 'from': 'userMouth', 'to': 'targetImpact'},
    }));
    final recipeHash = sha256.convert(recipe).toString();
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1, 'projectMoveId': 'custom', 'sourceMoveId': 'source',
      'catalogReleaseId': 'test', 'recipeId': 'radial', 'variant': 'default',
      'revision': '1', 'recipeSha256': recipeHash,
    });
    await _write(root, battleRecipeBindingPath('custom'), BattleRecipeProjectBinding(binding: binding).toJson());
    await _write(root, battleRecipeBlobPath(recipeHash, 'application/vnd.avelune.battle-recipe+json', projectMoveId: 'custom'), recipe);
    await _write(root, battleRecipeBlobPath(particleHash, 'application/vnd.avelune.particle+json', projectMoveId: 'custom'), particle);
    await _write(root, battleRecipeBlobPath(textureHash, 'image/png', projectMoveId: 'custom'), png);
    final exported = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final inspection = const GamePackageInspector().inspect(exported.packageBytes);
    final capability = 'battle.spl-particle-v$splVersion@1';
    expect(inspection.manifest.compatibility.requiredCapabilities, contains(capability));
    final current = AveluneRuntimeCompatibility.host();
    expect(current.capabilities, contains(capability));
    final older = GamePackageHostCompatibility(
      hubVersion: current.hubVersion, runtimeApiVersion: current.runtimeApiVersion,
      supportedRuntimeApiVersions: current.supportedRuntimeApiVersions,
      capabilities: {...current.capabilities}..remove(capability),
      supportedProjectFormats: current.supportedProjectFormats,
      currentProjectFormat: current.currentProjectFormat,
      currentProjectFormats: current.currentProjectFormats,
      supportedSaveFormats: current.supportedSaveFormats,
    );
    final compatibility = const GamePackageCompatibilityEvaluator().evaluate(inspection.manifest, older);
    expect(compatibility.decision, GamePackageCompatibilityDecision.reject);
    expect(compatibility.missingCapabilities, contains(capability));
    final manifestJson = inspection.manifest.toJson();
    (manifestJson['compatibility'] as Map)['requiredCapabilities'] = inspection
        .manifest.compatibility.requiredCapabilities
        .where((value) => value != capability)
        .toList();
    final stripped = const GamePackageManifestCodec().decodeJson(manifestJson);
    final archive = ZipDecoder().decodeBytes(exported.packageBytes);
    final files = {for (final file in archive.files) file.name: file.content as List<int>};
    expect(
      () => const GamePackageProjectValidator(GamePackageSecurityPolicy()).validate(
        stripped,
        Uint8List.fromList(files['project/project.json']!),
        payloadPaths: files.keys.toSet(),
        readPayload: (path) => files[path],
      ),
      throwsA(isA<GamePackageFormatException>().having((error) => error.message, 'message', contains(capability))),
    );
  });
  }

  test('exports a bound battle recipe without changing its exact bytes', () async {
    final root = await _fixture();
    final bytes = utf8.encode('''{
  "schemaVersion":1,"recipeId":"synthetic","revision":"1",
  "moveSourceId":"source","variant":"default","requiredCapabilities":["wait"],
  "provenance":{"source":"synthetic","sourceRevision":"1","sourcePaths":[],"converter":"test"},
  "resources":[],"program":{"kind":"wait","durationMs":100}
}''');
    final digest = sha256.convert(bytes).toString();
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1, 'projectMoveId': 'custom', 'sourceMoveId': 'source',
      'catalogReleaseId': 'test', 'recipeId': 'synthetic', 'variant': 'default',
      'revision': '1', 'recipeSha256': digest,
    });
    final recipePath = battleRecipeBlobPath(digest, 'application/vnd.avelune.battle-recipe+json', projectMoveId: 'custom');
    final bindingPath = battleRecipeBindingPath('custom');
    await _write(root, recipePath, bytes);
    await _write(root, bindingPath, BattleRecipeProjectBinding(binding: binding, catalogMoveId: 'catalog-move', recipeMediaId: 'recipe-file').toJson());
    final result = await _build(root);
    expect(result.payloadFiles['project/$recipePath'], bytes);
    final restored = BattleRecipeProjectBinding.fromJson(
      jsonDecode(utf8.decode(result.payloadFiles['project/$bindingPath']!)) as Map<String, dynamic>,
    );
    final outputBinding = restored.binding;
    expect((restored.catalogMoveId, restored.recipeMediaId), ('catalog-move', 'recipe-file'));
    expect(
      () => outputBinding.resolve(result.payloadFiles['project/$recipePath']!, const {}, availableCapabilities: {'wait'}),
      returnsNormally,
    );
    final exported = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final archive = ZipDecoder().decodeBytes(exported.packageBytes, verify: true);
    final archivedBytes = archive.findFile('project/$recipePath')!.content as List<int>;
    expect(archivedBytes, bytes);
    expect(
      () => outputBinding.resolve(archivedBytes, const {}, availableCapabilities: {'wait'}),
      returnsNormally,
    );
  });

  test('rejects changed bytes at a content-addressed battle recipe path', () async {
    final root = await _fixture();
    final path = battleRecipeBlobPath('a' * 64, 'application/vnd.avelune.battle-recipe+json', projectMoveId: 'custom');
    await _write(root, battleRecipeBindingPath('custom'), _bindingFor('a' * 64).toJson());
    await _write(root, path, utf8.encode('{"schemaVersion":1}'));
    await expectLater(
      _build(root),
      throwsA(isA<GamePackageExportException>().having((e) => e.code, 'code', 'battle_recipe.digest_mismatch')),
    );
  });

  test('exports a complete particle closure and rejects a missing texture', () async {
    final root = await _fixture();
    final png = spatialPayload()['project/assets/hero.png']!;
    final textureHash = sha256.convert(png).toString();
    final particle = utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'emitters': [{
        'textureId': 'tex', 'emissionDurationMs': 10, 'emissionIntervalMs': 10,
        'particleLifetimeMs': 10, 'particlesPerEmission': 1,
      }],
    }));
    final particleHash = sha256.convert(particle).toString();
    final recipe = utf8.encode(jsonEncode({
      'schemaVersion': 1, 'recipeId': 'synthetic', 'revision': '1',
      'moveSourceId': 'source', 'variant': 'default',
      'requiredCapabilities': ['startParticle'],
      'provenance': {'source': 'synthetic', 'sourceRevision': '1', 'sourcePaths': [], 'converter': 'test'},
      'resources': [
        {'id': 'tex', 'role': 'texture', 'mediaType': 'image/png', 'sizeBytes': png.length, 'sha256': textureHash},
        {'id': 'particle', 'role': 'particleDefinition', 'mediaType': 'application/vnd.avelune.particle+json', 'sizeBytes': particle.length, 'sha256': particleHash, 'definitionVersion': 1, 'dependencies': ['tex']},
      ],
      'program': {'kind': 'startParticle', 'resourceId': 'particle', 'from': 'userMouth', 'to': 'targetImpact'},
    }));
    final recipeHash = sha256.convert(recipe).toString();
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1, 'projectMoveId': 'custom', 'sourceMoveId': 'source',
      'catalogReleaseId': 'test', 'recipeId': 'synthetic', 'variant': 'default',
      'revision': '1', 'recipeSha256': recipeHash,
    });
    final recipePath = battleRecipeBlobPath(recipeHash, 'application/vnd.avelune.battle-recipe+json', projectMoveId: 'custom');
    final particlePath = battleRecipeBlobPath(particleHash, 'application/vnd.avelune.particle+json', projectMoveId: 'custom');
    final texturePath = battleRecipeBlobPath(textureHash, 'image/png', projectMoveId: 'custom');
    await _write(root, battleRecipeBindingPath('custom'), BattleRecipeProjectBinding(binding: binding).toJson());
    await _write(root, recipePath, recipe);
    await _write(root, particlePath, particle);
    await expectLater(_build(root), throwsA(isA<GamePackageExportException>().having((e) => e.code, 'code', 'battle_recipe.invalid_bundle')));
    await _write(root, texturePath, png);
    final exported = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final archive = ZipDecoder().decodeBytes(exported.packageBytes, verify: true);
    expect(archive.findFile('project/$recipePath')!.content, recipe);
    expect(archive.findFile('project/$particlePath')!.content, particle);
    expect(archive.findFile('project/$texturePath')!.content, png);
  });

  test('keeps unmarked projects on their existing JSON export path', () async {
    final root = await _fixture();
    final path = battleRecipeBlobPath('a' * 64, 'application/vnd.avelune.battle-recipe+json', projectMoveId: 'custom');
    await _write(root, path, utf8.encode('{"schemaVersion":1}'));
    final result = await _build(root);
    expect(result.payloadFiles, contains('project/$path'));
  });

  test('keeps unrelated legacy JSON at a battle binding path', () async {
    final root = await _fixture();
    await _write(root, battleRecipeBindingPath('legacy'), {'custom': true});
    final exported = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final inspection = const GamePackageInspector().inspect(exported.packageBytes);
    expect(inspection.manifest.compatibility.requiredCapabilities, isNot(contains('battle.spl-particle-v3@1')));
  });

  test('rejects an explicitly unsupported battle recipe binding', () async {
    final root = await _fixture();
    await _write(root, battleRecipeBindingPath('custom'), {
      ..._bindingFor('a' * 64).toJson(), 'schemaVersion': 2,
    });
    await expectLater(_build(root),
      throwsA(isA<GamePackageExportException>().having((e) => e.code, 'code', 'battle_recipe.invalid_binding')));
  });

  test('omits superseded battle recipe blobs while preserving project files', () async {
    final root = await _fixture();
    final bytes = utf8.encode('{"schemaVersion":1}');
    final path = battleRecipeBlobPath(sha256.convert(bytes).toString(),
        'application/vnd.avelune.battle-recipe+json', projectMoveId: 'custom');
    final recipe = utf8.encode(jsonEncode({
      'schemaVersion': 1, 'recipeId': 'synthetic', 'revision': '1',
      'moveSourceId': 'source', 'variant': 'default', 'requiredCapabilities': ['wait'],
      'provenance': {'source':'synthetic','sourceRevision':'1','sourcePaths':[],'converter':'test'},
      'resources': [], 'program': {'kind':'wait','durationMs':10},
    }));
    final recipeHash = sha256.convert(recipe).toString();
    await _write(root, battleRecipeBindingPath('custom'), _bindingFor(recipeHash).toJson());
    await _write(root, battleRecipeBlobPath(recipeHash,
      'application/vnd.avelune.battle-recipe+json', projectMoveId: 'custom'), recipe);
    await _write(root, path, bytes);
    final projected = await _build(root);
    expect(projected.payloadFiles, isNot(contains('project/$path')));
    expect(await File('${root.path}/$path').readAsBytes(), bytes);
    final current = battleRecipeBlobPath(recipeHash,
        'application/vnd.avelune.battle-recipe+json', projectMoveId: 'custom');
    expect(projected.payloadFiles['project/$current'], recipe);
  });

  test('each move owns its binding and recipe even for identical bytes', () async {
    final root = await _fixture();
    final recipe = utf8.encode(jsonEncode({
      'schemaVersion': 1, 'recipeId': 'synthetic', 'revision': '1',
      'moveSourceId': 'source', 'variant': 'default', 'requiredCapabilities': ['wait'],
      'provenance': {'source':'synthetic','sourceRevision':'1','sourcePaths':[],'converter':'test'},
      'resources': [], 'program': {'kind':'wait','durationMs':10},
    }));
    final hash = sha256.convert(recipe).toString();
    for (final move in ['custom', 'other']) {
      final binding = BattleMoveRecipeBinding.fromJson({
        ..._bindingFor(hash).binding.toJson(), 'projectMoveId': move,
      });
      await _write(root, battleRecipeBindingPath(move), BattleRecipeProjectBinding(binding: binding).toJson());
      await _write(root, battleRecipeBlobPath(hash,
        'application/vnd.avelune.battle-recipe+json', projectMoveId: move), recipe);
    }
    final first = battleRecipeBlobPath(hash, 'application/vnd.avelune.battle-recipe+json', projectMoveId: 'custom');
    final second = battleRecipeBlobPath(hash, 'application/vnd.avelune.battle-recipe+json', projectMoveId: 'other');
    expect(first, isNot(second));
    await File('${root.path}/${battleRecipeBindingPath('custom')}').delete();
    await File('${root.path}/$first').delete();
    final exported = await _build(root);
    expect(exported.payloadFiles['project/$second'], recipe);
  });
  test('Pokemon media excludes unused provenance and preserves author bytes', () async {
    final root = await _fixture();
    final record = await _catalogJson(root, 'source-proof',
        'data/pokemon/assets/items/source.json', {'romPath': '/author/source/game.nds'});
    final proof = await File('${root.path}/${assetBlobStorageKey(record.artifact)}').readAsBytes();
    await _write(root, record.logicalPath, proof);
    final catalogBefore = await File('${root.path}/$assetCatalogStorageKey').readAsBytes();
    final result = await const CanonicalGamePackageExportService().build(
        projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest);
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    expect(archive.findFile('project/${record.logicalPath}'), isNull);
    expect(archive.findFile('project/${assetBlobStorageKey(record.artifact)}'), isNull);
    final catalog = AssetCatalog.fromJson(jsonDecode(utf8.decode(
        archive.findFile('project/$assetCatalogStorageKey')!.content)));
    expect(catalog.find(record.id), isNull);
    expect(await File('${root.path}/$assetCatalogStorageKey').readAsBytes(), catalogBefore);
    expect(await File('${root.path}/${record.logicalPath}').readAsBytes(), proof);
    expect(await File('${root.path}/${assetBlobStorageKey(record.artifact)}').readAsBytes(), proof);
  });

  test('Pokemon media keeps referenced JSON while excluding its orphan sibling', () async {
    final root = await _fixture();
    final retained = await _catalogJson(root, 'runtime-options',
        'data/pokemon/assets/items/options.json', {'value': 1});
    final orphan = await _catalogJson(root, 'orphan-proof',
        'data/pokemon/assets/items/proof.json', {'romPath': '/author/source/game.nds'});
    await _runtimeReference(root, retained.logicalPath);
    final projection = await _build(root);
    final catalog = AssetCatalog.fromJson(jsonDecode(utf8.decode(
        projection.payloadFiles['project/$assetCatalogStorageKey']!)));
    expect(projection.payloadFiles, contains('project/${retained.logicalPath}'));
    expect(catalog.require(retained.id).toJson(), retained.toJson());
    expect(projection.payloadFiles, isNot(contains('project/${orphan.logicalPath}')));
    expect(catalog.find(orphan.id), isNull);
  });

  test('Pokemon media referenced JSON still rejects absolute source paths', () async {
    final root = await _fixture();
    final record = await _catalogJson(root, 'runtime-options',
        'data/pokemon/assets/items/options.json', {'romPath': '/author/source/game.nds'});
    await _runtimeReference(root, record.logicalPath);
    final before = await File('${root.path}/${assetBlobStorageKey(record.artifact)}').readAsBytes();
    await expectLater(const CanonicalGamePackageExportService().build(
        projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest),
        throwsA(isA<GamePackageExportException>()
            .having((error) => error.code, 'code', 'referenceEscapesRoot')));
    expect(await File('${root.path}/${assetBlobStorageKey(record.artifact)}').readAsBytes(), before);
  });

  test('Pokemon media keeps PNG images and their portable catalog records', () async {
    final root = await _fixture();
    final file = File('${root.path}/$assetCatalogStorageKey');
    final catalog = AssetCatalog.fromJson(jsonDecode(await file.readAsString()));
    final record = AssetRecord(id: 'item-icon',
        logicalPath: 'data/pokemon/assets/items/icon.png',
        artifact: catalog.require('hero-source').artifact);
    await _write(root, assetCatalogStorageKey,
        AssetCatalog(records: [...catalog.records, record]).toJson());
    final pixels = await File('${root.path}/assets/hero.png').readAsBytes();
    await _write(root, record.logicalPath, pixels);
    final result = await const CanonicalGamePackageExportService().build(
        projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest);
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    expect(archive.findFile('project/${record.logicalPath}')!.content, pixels);
    final portable = AssetCatalog.fromJson(jsonDecode(utf8.decode(
        archive.findFile('project/$assetCatalogStorageKey')!.content)));
    expect(portable.require(record.id).toJson(), record.toJson());
    expect(await File('${root.path}/${record.logicalPath}').readAsBytes(), pixels);
  });

  test('exports GIF bytes unchanged with their Pokemon media reference', () async {
    final root = await _fixture();
    const gifPath = 'assets/pokemon/oshawott/front.gif';
    const mediaPath = 'data/pokemon/media/oshawott.json';
    final gif = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    );
    await _write(root, gifPath, gif);
    await _write(root, mediaPath, {
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': {'frontAnimated': gifPath}},
    });
    final projection = await _build(root);
    expect(projection.payloadFiles['project/$gifPath'], gif);
    final media = jsonDecode(utf8.decode(projection.payloadFiles['project/$mediaPath']!));
    expect(media['variants']['base']['frontAnimated'], gifPath);
    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root,
      profile: _profile(),
      mode: GamePackageExportMode.localTest,
    );
    final inspection = const GamePackageInspector().inspect(result.packageBytes);
    final entry = inspection.manifest.content.files.singleWhere(
      (item) => item.path == 'project/$gifPath',
    );
    expect(entry.sha256, sha256.convert(gif).toString());
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    expect(archive.findFile('project/$gifPath')!.content, gif);
    expect(await File('${root.path}/$gifPath').readAsBytes(), gif);
  });

  test('exports a catalogued Pokemon GIF from its canonical blob', () async {
    final root = await _fixture();
    const gifPath = 'assets/pokemon/oshawott/front.gif';
    const mediaPath = 'data/pokemon/media/oshawott.json';
    final gif = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    );
    final artifact = ContentArtifactRef.fromBytes(gif, mediaType: 'image/gif');
    final record = AssetRecord(
      id: 'oshawott-front-animation',
      logicalPath: gifPath,
      artifact: artifact,
    );
    final catalogFile = File('${root.path}/$assetCatalogStorageKey');
    final catalog = AssetCatalog.fromJson(jsonDecode(await catalogFile.readAsString()));
    await _write(root, assetCatalogStorageKey,
        AssetCatalog(records: [...catalog.records, record]).toJson());
    final catalogBefore = await catalogFile.readAsBytes();
    final blobPath = assetBlobStorageKey(artifact);
    await _write(root, blobPath, gif);
    await _write(root, mediaPath, {
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': {'frontAnimated': gifPath}},
    });

    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root,
      profile: _profile(),
      mode: GamePackageExportMode.localTest,
    );
    final inspection = const GamePackageInspector().inspect(result.packageBytes);
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    for (final path in ['project/$gifPath', 'project/$blobPath']) {
      expect(archive.findFile(path)!.content, gif);
      expect(
        inspection.manifest.content.files.singleWhere((item) => item.path == path).sha256,
        sha256.convert(gif).toString(),
      );
    }
    final portable = AssetCatalog.fromJson(jsonDecode(utf8.decode(
      archive.findFile('project/$assetCatalogStorageKey')!.content,
    )));
    expect(portable.require(record.id).toJson(), record.toJson());
    final media = jsonDecode(utf8.decode(archive.findFile('project/$mediaPath')!.content));
    expect(media['variants']['base']['frontAnimated'], gifPath);
    expect(await catalogFile.readAsBytes(), catalogBefore);
    expect(await File('${root.path}/$blobPath').readAsBytes(), gif);
    expect(await File('${root.path}/$gifPath').exists(), isFalse);
  });

  test('keeps a Pokemon GIF shared with an unused presentation asset', () async {
    final root = await _fixture();
    const gifPath = 'assets/pokemon/oshawott/front.gif';
    final gif = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    );
    final artifact = ContentArtifactRef.fromBytes(gif, mediaType: 'image/gif');
    final record = AssetRecord(id: 'shared-gif', logicalPath: gifPath, artifact: artifact);
    final catalogFile = File('${root.path}/$assetCatalogStorageKey');
    final catalog = AssetCatalog.fromJson(jsonDecode(await catalogFile.readAsString()));
    await _write(root, assetCatalogStorageKey,
        AssetCatalog(records: [...catalog.records, record]).toJson());
    await _write(root, assetBlobStorageKey(artifact), gif);
    await _write(root, projectMediaCatalogStorageKey,
        encodeProjectMediaCatalogBytes(ProjectMediaCatalog(entries: [
          ProjectMediaAsset(id: 'unused-shared', label: 'Unused',
              kind: ProjectMediaKind.image, sourceAssetId: record.id),
        ])));
    await _write(root, 'data/pokemon/media/oshawott.json', {
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': {'frontAnimated': gifPath}},
    });

    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    final portable = AssetCatalog.fromJson(jsonDecode(utf8.decode(
      archive.findFile('project/$assetCatalogStorageKey')!.content,
    )));
    expect(portable.require(record.id).toJson(), record.toJson());
    expect(archive.findFile('project/$gifPath')!.content, gif);
    expect(archive.findFile('project/${assetBlobStorageKey(artifact)}')!.content, gif);
  });

  test('rejects a direct GIF blob with an incorrect digest', () async {
    final root = await _fixture();
    final gif = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    );
    final blobPath = 'assets/.pokemap-store/${'a' * 64}.blob';
    await _write(root, blobPath, gif);
    await _write(root, 'data/pokemon/media/oshawott.json', {
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': {'frontAnimated': blobPath}},
    });
    await expectLater(
      const CanonicalGamePackageExportService().build(
        projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
      ),
      throwsA(isA<GamePackageExportException>().having(
        (error) => error.code, 'code', 'pokemon.animated_blob_digest_mismatch',
      )),
    );
    expect(await File('${root.path}/$blobPath').readAsBytes(), gif);
  });

  test('rejects a direct animated blob containing a PNG', () async {
    final root = await _fixture();
    final png = spatialPayload()['project/assets/hero.png']!;
    final artifact = ContentArtifactRef.fromBytes(png, mediaType: 'image/png');
    final blobPath = assetBlobStorageKey(artifact);
    await _write(root, 'data/pokemon/media/oshawott.json', {
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': {'frontAnimated': blobPath}},
    });
    await expectLater(
      const CanonicalGamePackageExportService().build(
        projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
      ),
      throwsA(isA<GamePackageExportException>().having(
        (error) => error.code, 'code', 'pokemon.animated_media_invalid',
      )),
    );
  });

  test('rejects an oversized direct animated blob before loading it', () async {
    final root = await _fixture();
    final blobPath = 'assets/.pokemap-store/${'b' * 64}.blob';
    final file = File('${root.path}/$blobPath');
    await file.parent.create(recursive: true);
    final handle = await file.open(mode: FileMode.write);
    await handle.truncate(PokemonGifInspector.maxEncodedBytes + 1);
    await handle.close();
    await _write(root, 'data/pokemon/media/oshawott.json', {
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': {'frontAnimated': blobPath}},
    });
    await expectLater(
      const CanonicalGamePackageExportService().build(
        projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
      ),
      throwsA(isA<GamePackageExportException>().having(
        (error) => error.code, 'code', 'authoringFileTooLarge',
      )),
    );
    expect(await file.length(), PokemonGifInspector.maxEncodedBytes + 1);
  });

  test('shares an animated GIF blob between direct and catalogued references', () async {
    final root = await _fixture();
    const gifPath = 'assets/pokemon/oshawott/back.gif';
    final gif = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    );
    final artifact = ContentArtifactRef.fromBytes(gif, mediaType: 'image/gif');
    final blobPath = assetBlobStorageKey(artifact);
    final record = AssetRecord(id: 'shared-pokemon-gif', logicalPath: gifPath, artifact: artifact);
    final catalogFile = File('${root.path}/$assetCatalogStorageKey');
    final catalog = AssetCatalog.fromJson(jsonDecode(await catalogFile.readAsString()));
    await _write(root, assetCatalogStorageKey,
        AssetCatalog(records: [...catalog.records, record]).toJson());
    await _write(root, blobPath, gif);
    await _write(root, 'data/pokemon/media/oshawott.json', {
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': {'frontAnimated': blobPath, 'backAnimated': gifPath}},
    });
    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    expect(archive.findFile('project/$blobPath')!.content, gif);
    expect(archive.findFile('project/$gifPath')!.content, gif);
    expect(archive.files.where((entry) => entry.name == 'project/$blobPath'), hasLength(1));
  });

  test('excludes unreferenced GIF files and catalogued GIF blobs', () async {
    final root = await _fixture();
    final invalid = utf8.encode('unused invalid GIF');
    const loosePath = 'assets/old/unused.gif';
    const catalogPath = 'data/old/unused.gif';
    await _write(root, loosePath, invalid);
    final artifact = ContentArtifactRef.fromBytes(invalid, mediaType: 'image/gif');
    final record = AssetRecord(id: 'unused-gif', logicalPath: catalogPath, artifact: artifact);
    final catalogFile = File('${root.path}/$assetCatalogStorageKey');
    final catalog = AssetCatalog.fromJson(jsonDecode(await catalogFile.readAsString()));
    await _write(root, assetCatalogStorageKey,
        AssetCatalog(records: [...catalog.records, record]).toJson());
    await _write(root, assetBlobStorageKey(artifact), invalid);
    final catalogBefore = await catalogFile.readAsBytes();

    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    expect(archive.findFile('project/$loosePath'), isNull);
    expect(archive.findFile('project/$catalogPath'), isNull);
    expect(archive.findFile('project/${assetBlobStorageKey(artifact)}'), isNull);
    final portable = AssetCatalog.fromJson(jsonDecode(utf8.decode(
      archive.findFile('project/$assetCatalogStorageKey')!.content,
    )));
    expect(portable.find(record.id), isNull);
    expect(await catalogFile.readAsBytes(), catalogBefore);
    expect(await File('${root.path}/$loosePath').readAsBytes(), invalid);
    expect(await File('${root.path}/${assetBlobStorageKey(artifact)}').readAsBytes(), invalid);
  });

  test('keeps a GIF asset referenced by another runtime document', () async {
    final root = await _fixture();
    final gif = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    );
    final artifact = ContentArtifactRef.fromBytes(gif, mediaType: 'image/gif');
    final record = AssetRecord(id: 'used-gif', logicalPath: 'assets/used.gif', artifact: artifact);
    final catalogFile = File('${root.path}/$assetCatalogStorageKey');
    final catalog = AssetCatalog.fromJson(jsonDecode(await catalogFile.readAsString()));
    await _write(root, assetCatalogStorageKey,
        AssetCatalog(records: [...catalog.records, record]).toJson());
    await _write(root, assetBlobStorageKey(artifact), gif);
    await _runtimeReference(root, 'config/gif-user.json');
    await _write(root, 'config/gif-user.json', {'sourceAssetId': record.id});

    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    final portable = AssetCatalog.fromJson(jsonDecode(utf8.decode(
      archive.findFile('project/$assetCatalogStorageKey')!.content,
    )));
    expect(portable.require(record.id).toJson(), record.toJson());
    expect(archive.findFile('project/${assetBlobStorageKey(artifact)}')!.content, gif);
  });

  test('exports 338-frame Pokemon GIFs and rejects more than 500', () async {
    final root = await _fixture();
    const gifPath = 'sprites/seedot/back.gif';
    final frame = image.Image(width: 2, height: 2);
    List<int> gif(int count) {
      final encoder = image.GifEncoder();
      for (var i = 0; i < count; i++) {
        encoder.addFrame(frame);
      }
      return encoder.finish()!;
    }
    final supported = gif(338);
    final blob = ContentArtifactRef.fromBytes(supported, mediaType: 'image/gif');
    final blobPath = assetBlobStorageKey(blob);
    await _write(root, 'data/pokemon/media/seedot.json', {
      'schemaVersion': 2,
      'speciesId': 'seedot',
      'defaultFormId': 'base',
      'variants': {'base': {'backAnimated': gifPath, 'frontAnimated': blobPath}},
    });
    await _write(root, gifPath, supported);
    await _write(root, blobPath, supported);
    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    expect(const GamePackageInspector().inspect(result.packageBytes).payloadPaths,
        contains('project/$gifPath'));
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    expect(archive.findFile('project/$gifPath')!.content, supported);
    expect(archive.findFile('project/$blobPath')!.content, supported);

    await _write(root, gifPath, gif(501));
    await expectLater(
      const CanonicalGamePackageExportService().build(
        projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
      ),
      throwsA(isA<GamePackageExportException>().having(
        (error) => error.code, 'code', 'pokemon.animated_media_invalid',
      )),
    );
  });

  test('exports referenced GIFs outside asset roots at their exact paths', () async {
    final root = await _fixture();
    const loosePath = 'sprites/oshawott/front.gif';
    const catalogPath = 'sprites/oshawott/back.gif';
    const mediaPath = 'data/pokemon/media/oshawott.json';
    final gif = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    );
    await _write(root, loosePath, gif);
    final artifact = ContentArtifactRef.fromBytes(gif, mediaType: 'image/gif');
    final record = AssetRecord(id: 'oshawott-back-animation', logicalPath: catalogPath, artifact: artifact);
    final catalogFile = File('${root.path}/$assetCatalogStorageKey');
    final catalog = AssetCatalog.fromJson(jsonDecode(await catalogFile.readAsString()));
    await _write(root, assetCatalogStorageKey,
        AssetCatalog(records: [...catalog.records, record]).toJson());
    await _write(root, assetBlobStorageKey(artifact), gif);
    await _write(root, mediaPath, {
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': {'frontAnimated': loosePath, 'backAnimated': catalogPath}},
    });

    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final inspection = const GamePackageInspector().inspect(result.packageBytes);
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    for (final path in [loosePath, catalogPath, assetBlobStorageKey(artifact)]) {
      expect(archive.findFile('project/$path')!.content, gif);
      expect(inspection.manifest.content.files.singleWhere((item) => item.path == 'project/$path').sha256,
          sha256.convert(gif).toString());
    }
    final media = jsonDecode(utf8.decode(archive.findFile('project/$mediaPath')!.content));
    expect(media['variants']['base']['frontAnimated'], loosePath);
    expect(media['variants']['base']['backAnimated'], catalogPath);
    final portable = AssetCatalog.fromJson(jsonDecode(utf8.decode(
      archive.findFile('project/$assetCatalogStorageKey')!.content,
    )));
    expect(portable.require(record.id).logicalPath, catalogPath);
    expect(archive.findFile('project/assets/runtime-media/$catalogPath'), isNull);
  });

  test('does not interpret unknown GIF fields in Pokemon media schema v1', () async {
    final root = await _fixture();
    const mediaPath = 'data/pokemon/media/oshawott.json';
    await _write(root, mediaPath, {
      'schemaVersion': 1,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': {'frontAnimated': 'missing/unknown.gif'}},
    });
    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    expect(archive.findFile('project/missing/unknown.gif'), isNull);
    final media = jsonDecode(utf8.decode(archive.findFile('project/$mediaPath')!.content));
    expect(media['variants']['base']['frontAnimated'], 'missing/unknown.gif');
  });

  test('exports all eight schema v2 animated Pokemon variants', () async {
    final root = await _fixture();
    final gif = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    );
    const keys = [
      'frontAnimated', 'backAnimated', 'frontShinyAnimated', 'backShinyAnimated',
      'frontFemaleAnimated', 'backFemaleAnimated',
      'frontShinyFemaleAnimated', 'backShinyFemaleAnimated',
    ];
    final variants = <String, String>{};
    for (final key in keys) {
      final path = 'sprites/oshawott/$key.gif';
      variants[key] = path;
      await _write(root, path, gif);
    }
    await _write(root, 'data/pokemon/media/oshawott.json', {
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': variants},
    });
    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
    );
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    for (final path in variants.values) {
      expect(archive.findFile('project/$path')!.content, gif);
    }
  });

  test('rejects a missing schema v2 animated Pokemon reference', () async {
    final root = await _fixture();
    await _write(root, 'data/pokemon/media/oshawott.json', {
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': {'frontAnimated': 'sprites/missing.gif'}},
    });
    await expectLater(
      const CanonicalGamePackageExportService().build(
        projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
      ),
      throwsA(isA<GamePackageExportException>()),
    );
  });

  test('projects animated media from a configured Pokemon media directory', () async {
    for (final mediaDir in ['metadata/pokemon-media', 'assets/pokemon-media', '.', '']) {
      final root = await _fixture();
      final projectFile = File('${root.path}/project.json');
      final project = ProjectManifest.fromJson(jsonDecode(await projectFile.readAsString()));
      await _write(root, 'project.json', project.copyWith(
        pokemon: project.pokemon.copyWith(enabled: true, mediaDir: mediaDir),
      ).toJson());
      const gifPath = 'sprites/oshawott/front.gif';
      final gif = base64Decode(
        'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
      );
      await _write(root, gifPath, gif);
      const mediaFile = 'oshawott.JSON';
      final mediaPath = mediaDir == '.' || mediaDir.isEmpty
          ? mediaFile
          : '$mediaDir/$mediaFile';
      await _write(root, mediaPath, {
        'schemaVersion': 2,
        'speciesId': 'oshawott',
        'defaultFormId': 'base',
        'variants': {'base': {'frontAnimated': gifPath}},
      });
      final projection = await _build(root);
      expect(projection.payloadFiles, contains('project/$mediaPath'));
      expect(projection.payloadFiles['project/$gifPath'], gif);
    }
  });

  test('ignores an empty media directory when Pokemon is disabled', () async {
    final root = await _fixture();
    final projectFile = File('${root.path}/project.json');
    final project = ProjectManifest.fromJson(jsonDecode(await projectFile.readAsString()));
    await _write(root, 'project.json', project.copyWith(
      pokemon: project.pokemon.copyWith(enabled: false, mediaDir: ''),
    ).toJson());
    expect((await _build(root)).payloadFiles, contains('project/project.json'));
  });

  test('does not interpret unrelated nested JSON when the media directory is the root', () async {
    for (final mediaDir in ['.', '']) {
      final root = await _fixture();
      final projectFile = File('${root.path}/project.json');
      final project = ProjectManifest.fromJson(jsonDecode(await projectFile.readAsString()));
      await _write(root, 'project.json', project.copyWith(
        pokemon: project.pokemon.copyWith(enabled: false, mediaDir: mediaDir),
      ).toJson());
      const path = 'data/custom/unrelated.json';
      await _write(root, path, {
        'schemaVersion': 2,
        'speciesId': 'unrelated',
        'variants': {'base': {'frontAnimated': '../independent.gif'}},
      });
      final result = await const CanonicalGamePackageExportService().build(
        projectRoot: root, profile: _profile(), mode: GamePackageExportMode.localTest,
      );
      final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
      expect(archive.findFile('project/$path'), isNotNull);
    }
  });

  test('Pokemon media filtering preserves ID addressed gameplay JSON', () async {
    final root = await _fixture();
    final paths = ['data/pokemon/catalogs/items.json',
      'data/pokemon/species/native.json', 'data/pokemon/learnsets/native.json'];
    for (final path in paths) {
      await _write(root, path, {'entries': [], 'id': 'native'});
    }
    final before = {for (final path in paths)
      path: await File('${root.path}/$path').readAsBytes()};
    final result = await _build(root);
    for (final path in paths) {
      expect(result.payloadFiles, contains('project/$path'));
      expect(await File('${root.path}/$path').readAsBytes(), before[path]);
    }
  });

  test('unused presentation media cannot remove a distinct character portrait',
      () async {
    final root = await _fixture();
    final catalogFile = File('${root.path}/$assetCatalogStorageKey');
    final catalog = AssetCatalog.fromJson(
        jsonDecode(await catalogFile.readAsString()));
    final portrait = AssetRecord(
        id: 'portrait-source',
        logicalPath: 'assets/portrait.png',
        artifact: catalog.require('hero-source').artifact);
    await _write(root, assetCatalogStorageKey,
        AssetCatalog(records: [...catalog.records, portrait]).toJson());
    await _write(root, portrait.logicalPath,
        await File('${root.path}/assets/hero.png').readAsBytes());
    final projectFile = File('${root.path}/project.json');
    final project = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()));
    await _write(root, 'project.json', project.copyWith(
        characterStudioCatalog: project.characterStudioCatalog.copyWith(
            portraitStates: [
              const CharacterPortraitStateDefinition(
                  id: 'neutral', displayName: 'Neutral'),
            ]),
        characters: [
      for (final character in project.characters)
        character.copyWith(portraits: [
          const CharacterPortraitVariant(
              portraitStateId: 'neutral', assetId: 'portrait-source'),
        ]),
    ]).toJson());
    await _write(root, projectMediaCatalogStorageKey,
        encodeProjectMediaCatalogBytes(ProjectMediaCatalog(entries: [
          ProjectMediaAsset(id: 'unused-portrait', label: 'Unused portrait',
              kind: ProjectMediaKind.image, sourceAssetId: portrait.id),
        ])));
    final projection = await _build(root);
    final retained = AssetCatalog.fromJson(jsonDecode(utf8.decode(
        projection.payloadFiles['project/$assetCatalogStorageKey']!)));
    expect(retained.find(portrait.id), isNotNull);
    expect(projection.payloadFiles,
        contains('project/${portrait.logicalPath}'));
  });

  test('unused presentation media cannot remove a character source', () async {
    final root = await _fixture();
    await _write(
        root,
        projectMediaCatalogStorageKey,
        encodeProjectMediaCatalogBytes(ProjectMediaCatalog(entries: [
          ProjectMediaAsset(
              id: 'unused-portrait',
              label: 'Unused portrait',
              kind: ProjectMediaKind.image,
              sourceAssetId: 'hero-source'),
        ])));
    final projection = await _build(root);
    final catalog = AssetCatalog.fromJson(jsonDecode(utf8.decode(
        projection.payloadFiles['project/$assetCatalogStorageKey']!)));
    expect(catalog.find('hero-source'), isNotNull);
    expect(projection.payloadFiles, contains('project/assets/hero.png'));
    final media = decodeProjectMediaCatalogBytes(
        projection.payloadFiles['project/$projectMediaCatalogStorageKey']!);
    expect(media.entries, isEmpty);
  });

  test('runtime JSON closure excludes orphan and nested project documents',
      () async {
    final root = await _fixture();
    final projectFile = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await projectFile.readAsString()));
    await projectFile.writeAsString(jsonEncode(project.copyWith(
      globalProperties: {'runtimeConfigPath': 'config/runtime.json'},
      dialogues: [
        const ProjectDialogueEntry(
            id: 'intro', name: 'Intro', relativePath: 'dialogues/intro.yarn')
      ],
    ).toJson()));
    await _write(root, 'config/runtime.json', {
      'nextPath': 'config/nested/child.json',
      'profile': 'a-literal.json',
      'conditionSource': {
        'sourceKind': 'factLikeStoryFlag',
        'sourceId': 'semantic-id.json'
      },
      'runtimeFiles': {'named': 'config/dictionary.json'},
      'dependencyPaths': ['config/array.json'],
    });
    await _write(root, 'config/array.json', {'value': 'array dependency'});
    await _write(
        root, 'config/dictionary.json', {'value': 'dictionary dependency'});
    await _write(root, 'config/nested/child.json', {
      'returnPath': 'config/runtime.json',
      'dialoguePath': 'dialogues/intro.json',
      'mediaPath': 'data/runtime/marker.png'
    });
    await _write(root, 'data/runtime/by-id.json', {
      'entries': [
        {'id': 'native-item'}
      ]
    });
    await _write(root, 'copies/other/project.json', project.toJson());
    await _write(
        root, 'copies/other/maps/unrelated.json', {'id': 'orphan-map'});
    await _write(root, 'notes/orphan.json', {'notRuntime': true});
    await _write(
        root, 'dialogues/intro.yarn', 'title: Start\n---\nBonjour !\n===\n');
    await _write(root, 'data/runtime/marker.png',
        spatialPayload()['project/assets/hero.png']!);
    final before = await projectFile.readAsBytes();
    final result = await _build(root);
    expect(
        result.payloadFiles.keys,
        containsAll([
          'project/maps/map.json',
          'project/config/runtime.json',
          'project/config/nested/child.json',
          'project/config/array.json',
          'project/config/dictionary.json',
          'project/dialogues/intro.json',
          'project/data/runtime/by-id.json',
          'project/data/runtime/marker.png',
        ]));
    expect(result.payloadFiles,
        isNot(contains('project/copies/other/project.json')));
    expect(result.payloadFiles,
        isNot(contains('project/copies/other/maps/unrelated.json')));
    expect(result.payloadFiles, isNot(contains('project/notes/orphan.json')));
    expect(await projectFile.readAsBytes(), before);
  });

  test(
      'runtime JSON references retain nested assets JSON without its orphan siblings',
      () async {
    final root = await _fixture();
    final file = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
    await file.writeAsString(jsonEncode(project.copyWith(globalProperties: {
      'runtimeConfigPath': 'assets/runtime/options.json',
    }).toJson()));
    await _write(root, 'assets/runtime/options.json', {'value': 1});
    await _write(
        root, 'assets/runtime/provenance.json', {'source': '/author/only'});
    final result = await _build(root);
    expect(
        result.payloadFiles, contains('project/assets/runtime/options.json'));
    expect(result.payloadFiles,
        isNot(contains('project/assets/runtime/provenance.json')));
  });

  test('catalog closure excludes authoring JSON records and their blobs',
      () async {
    final root = await _fixture();
    final record = await _catalogJson(root, 'provenance',
        'assets/converter/provenance.json', {'file': 'shard:private-proof'},
        tags: ['runtime'], usages: ['runtime']);
    final before =
        await File('${root.path}/$assetCatalogStorageKey').readAsBytes();
    final projection = await _build(root);
    final catalog = AssetCatalog.fromJson(jsonDecode(utf8
        .decode(projection.payloadFiles['project/$assetCatalogStorageKey']!)));
    expect(catalog.find(record.id), isNull);
    expect(
        projection.payloadFiles,
        isNot(contains(
            PackagePathPolicy.normalizeNfc('project/${record.logicalPath}'))));
    expect(projection.payloadFiles,
        isNot(contains('project/${assetBlobStorageKey(record.artifact)}')));
    final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: _profile(),
        mode: GamePackageExportMode.localTest);
    final inspected =
        const GamePackageInspector().inspect(artifact.packageBytes);
    expect(inspected.manifest.gameId, _profile().gameId);
    expect(inspected.manifest.content.files.map((file) => file.path),
        isNot(contains('project/${assetBlobStorageKey(record.artifact)}')));
    expect(await File('${root.path}/$assetCatalogStorageKey').readAsBytes(),
        before);
  });

  test('referenced catalog JSON survives misleading provenance labels',
      () async {
    final root = await _fixture();
    final record = await _catalogJson(root, 'native-encounter-release',
        'assets/converter/runtime-e\u0301.json', {
      'catalog': 'moves',
      'entries': [
        PokemonMove(
                id: 'tackle',
                name: 'Tackle',
                names: {'en': 'Tackle'},
                generation: 1,
                source: 'test',
                type: 'normal',
                category: PokemonMoveCategory.physical,
                target: PokemonMoveTarget.normal,
                basePower: 40,
                accuracy: const PokemonMoveAccuracy.percent(value: 100),
                pp: 35)
            .toJson()
      ]
    },
        tags: [
          'preserved-native-provenance'
        ],
        usages: [
          'converter.sourceEventBytes'
        ]);
    final file = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
    await file.writeAsString(jsonEncode(project
        .copyWith(
            pokemon: project.pokemon
                .copyWith(catalogFiles: {'moves': record.logicalPath}))
        .toJson()));
    final projection = await _build(root);
    final catalog = AssetCatalog.fromJson(jsonDecode(utf8
        .decode(projection.payloadFiles['project/$assetCatalogStorageKey']!)));
    expect(
        catalog.require(record.id).toJson(),
        record
            .copyWith(
                logicalPath: PackagePathPolicy.normalizeNfc(record.logicalPath))
            .toJson());
    expect(
        projection.payloadFiles,
        contains(
            PackagePathPolicy.normalizeNfc('project/${record.logicalPath}')));
    expect(projection.payloadFiles,
        contains('project/${assetBlobStorageKey(record.artifact)}'));
    final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: _profile(),
        mode: GamePackageExportMode.localTest);
    expect(
        const GamePackageInspector()
            .inspect(artifact.packageBytes)
            .manifest
            .gameId,
        _profile().gameId);
    final exported = ZipDecoder().decodeBytes(artifact.packageBytes).findFile(
        PackagePathPolicy.normalizeNfc('project/${record.logicalPath}'))!;
    final decoded =
        jsonDecode(utf8.decode(exported.content)) as Map<String, dynamic>;
    final move = PokemonMove.fromJson(
        Map<String, dynamic>.from((decoded['entries'] as List).single as Map));
    expect(move.id, 'tackle');
    expect(move.pp, 35);
  });

  test('admitted catalog JSON retains its nested reference closure', () async {
    final root = await _fixture();
    final record = await _catalogJson(root, 'config', 'config/runtime.json',
        {'dependencyPath': 'config/child.json'});
    await _write(root, 'config/child.json', {'value': 1});
    final projection = await _build(root);
    expect(projection.payloadFiles, contains('project/${record.logicalPath}'));
    expect(projection.payloadFiles, contains('project/config/child.json'));
  });

  test('runtime character image survives misleading provenance tags', () async {
    final root = await _fixture();
    final file = File('${root.path}/$assetCatalogStorageKey');
    final catalog =
        AssetCatalog.fromJson(jsonDecode(await file.readAsString()));
    await _write(
        root,
        assetCatalogStorageKey,
        AssetCatalog(records: [
          for (final record in catalog.records)
            record.copyWith(
                tags: ['preserved-native-provenance'],
                usages: ['converter.sourceEventBytes'])
        ]).toJson());
    final projection = await _build(root);
    final retained = AssetCatalog.fromJson(jsonDecode(utf8
        .decode(projection.payloadFiles['project/$assetCatalogStorageKey']!)));
    expect(retained.require('hero-source').logicalPath, 'assets/hero.png');
    expect(projection.payloadFiles, contains('project/assets/hero.png'));
    expect(
        projection.payloadFiles,
        contains(
            'project/${assetBlobStorageKey(retained.require('hero-source').artifact)}'));
  });

  for (final sceneOnly in [false, true]) {
    test(
        'Presentation media retain their referenced opaque source blobs sceneOnly=$sceneOnly',
        () async {
      final root = await _fixture();
      final bytes = spatialPayload()['project/assets/hero.png']!;
      final artifact =
          ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
      const path = 'assets/presentation/opening.bin';
      final file = File('${root.path}/$assetCatalogStorageKey');
      final catalog =
          AssetCatalog.fromJson(jsonDecode(await file.readAsString()));
      final record = AssetRecord(
          id: 'opening-source', logicalPath: path, artifact: artifact);
      await _write(root, assetCatalogStorageKey,
          AssetCatalog(records: [...catalog.records, record]).toJson());
      await _write(root, assetBlobStorageKey(artifact), bytes);
      await _write(
          root,
          projectMediaCatalogStorageKey,
          encodeProjectMediaCatalogBytes(ProjectMediaCatalog(entries: [
            ProjectMediaAsset(
                id: 'opening',
                label: 'Opening',
                kind: ProjectMediaKind.image,
                sourceAssetId: record.id,
                provenance: ProjectMediaProvenance(source: 'Fixture'),
                license:
                    ProjectMediaLicense(identifier: 'CC0-1.0', name: 'CC0'),
                technicalMetadata: ProjectMediaTechnicalMetadata(
                    mediaType: 'image/png',
                    container: 'png',
                    codec: 'png',
                    sizeBytes: bytes.length,
                    width: 32,
                    height: 32))
          ])));
      final projectFile = File('${root.path}/project.json');
      final project = ProjectManifest.fromJson(
          jsonDecode(await projectFile.readAsString()));
      await _write(
          root,
          'maps/map.json',
          MapData(
                  id: 'map',
                  name: 'Map',
                size: const GridSize(width: 8, height: 8),
                entities: const [MapEntity(id: 'spawn', name: 'Spawn',
                  kind: MapEntityKind.spawn, pos: GridPos(x: 1, y: 1),
                  spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart))])
              .toJson());
      await projectFile.writeAsString(jsonEncode(project
          .copyWith(
              version: ProjectVersion.v8,
              models3d: [],
            newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'map', startSpawnId: 'spawn', playerName: 'Player'),
              settings:
                project.settings.copyWith(dimension: ProjectDimension.twoD, spatialCamera: null),
              scenes: sceneOnly
                  ? [
                      SceneAsset(
                          id: 'picture',
                          name: 'Picture',
                          graph: SceneGraph(startNodeId: 'start', nodes: [
                            SceneNode(id: 'start', kind: SceneNodeKind.start),
                            SceneNode(
                                id: 'show',
                                kind: SceneNodeKind.action,
                                payload: SceneActionPayload.interactive(
                                    SceneInteractiveCommand.worldPresentation(
                                        operation:
                                            SceneWorldPresentationOperation
                                                .showPicture,
                                        slotId: 1,
                                        mediaAssetId: 'opening',
                                        referenceWidth: 512,
                                        referenceHeight: 384,
                                        x: 0,
                                        y: 0))),
                            SceneNode(id: 'end', kind: SceneNodeKind.end),
                          ], edges: [
                            SceneEdge(
                                id: 'start_show',
                                fromNodeId: 'start',
                                fromPortId: 'completed',
                                toNodeId: 'show',
                                kind: SceneEdgeKind.defaultFlow),
                            SceneEdge(
                                id: 'show_end',
                                fromNodeId: 'show',
                                fromPortId: 'completed',
                                toNodeId: 'end',
                                kind: SceneEdgeKind.actionCompleted),
                          ]))
                    ]
                  : const [],
              presentationCinematics: [
                if (!sceneOnly)
                  PresentationCinematicAsset(
                      id: 'opening',
                      title: 'Opening',
                      durationUs: 1000000,
                      layers: [
                        PresentationLayer(
                            id: 'background', label: 'Background', zIndex: 0)
                      ],
                      tracks: [
                        PresentationTrack(
                            id: 'visual',
                            label: 'Visual',
                            kind: PresentationTrackKind.visual,
                            clips: [
                              PresentationVisualClip(
                                  id: 'image',
                                  startUs: 0,
                                  durationUs: 1000000,
                                  layerId: 'background',
                                  resourceId: 'opening')
                            ])
                      ])
              ])
          .toJson()));
      final projection = await _build(root);
      final retained = AssetCatalog.fromJson(jsonDecode(utf8.decode(
          projection.payloadFiles['project/$assetCatalogStorageKey']!)));
      expect(retained.require(record.id).toJson(), record.toJson());
      expect(
          projection.payloadFiles['project/${assetBlobStorageKey(artifact)}'],
          bytes);
      final projectedMedia = decodeProjectMediaCatalogBytes(
          projection.payloadFiles['project/$projectMediaCatalogStorageKey']!);
      expect(projectedMedia.find('opening'), isNotNull);
      if (sceneOnly) {
        final artifact = await const CanonicalGamePackageExportService().build(
            projectRoot: root,
            profile: _profile(),
            mode: GamePackageExportMode.localTest);
        final archive =
            ZipDecoder().decodeBytes(artifact.packageBytes, verify: true);
        expect(
            archive
                .findFile('project/${assetBlobStorageKey(record.artifact)}')!
                .content,
            bytes);
        expect(
            decodeProjectMediaCatalogBytes(archive
                    .findFile('project/$projectMediaCatalogStorageKey')!
                    .content)
                .find('opening'),
            isNotNull);
        expect(artifact.inspection.payloadPaths,
            contains('project/$projectMediaCatalogStorageKey'));
      }
    });
  }

  for (final entry in <String, Map<String, Object>>{
    'referenceEscapesRoot': {'file': 'shard:outside-runtime'},
    'probableSecret': {'privateKey': '-----BEGIN PRIVATE KEY-----'},
  }.entries) {
    test('referenced catalog JSON still rejects ${entry.key}', () async {
      final root = await _fixture();
      final record = await _catalogJson(
          root, 'provenance', 'assets/converter/runtime.json', entry.value,
          tags: ['preserved-native-provenance']);
      await _runtimeReference(root, record.logicalPath);
      await expectLater(
          const CanonicalGamePackageExportService().build(
              projectRoot: root,
              profile: _profile(),
              mode: GamePackageExportMode.localTest),
          throwsA(isA<GamePackageExportException>()
              .having((error) => error.code, 'code', entry.key)));
    });
  }

  test('ID addressed data survives with optional Pokemon catalog defaults',
      () async {
    final root = await _fixture();
    final file = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
    await file.writeAsString(jsonEncode(project
        .copyWith(
          pokemon: const ProjectPokemonConfig(
              ruleset: PokemonRulesetProfile.pokeMapBetaV1),
        )
        .toJson()));
    await _write(root, 'data/pokemon/catalogs/moves.json', {'entries': []});
    await _write(root, 'data/pokemon/species/native-id.json', {'id': 'native'});
    await _write(root, 'data/runtime/project.json', {'id': 'project'});
    await _write(root, 'data/runtime/sibling.json', {'id': 'sibling'});
    final result = await _build(root);
    expect(result.payloadFiles,
        contains('project/data/pokemon/catalogs/moves.json'));
    expect(result.payloadFiles,
        contains('project/data/pokemon/species/native-id.json'));
    expect(result.payloadFiles, contains('project/data/runtime/project.json'));
    expect(result.payloadFiles, contains('project/data/runtime/sibling.json'));
  });

  test('a dangling nested runtime JSON reference is rejected', () async {
    final root = await _fixture();
    final file = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
    await file.writeAsString(jsonEncode(project.copyWith(globalProperties: {
      'runtimeConfigPath': 'config/runtime.json'
    }).toJson()));
    for (final reference in [
      {'nextPath': 'config/missing.json'},
      {
        'sourceItem': {'sourcePath': 'config/missing.json'}
      },
    ]) {
      await _write(root, 'config/runtime.json', reference);
      await expectLater(
          _build(root),
          throwsA(isA<GamePackageExportException>()
              .having((error) => error.code, 'code', 'missingProjectFile')
              .having((error) => error.path, 'path', 'config/missing.json')));
    }
  });

  test('unreferenced malformed JSON is excluded without being decoded',
      () async {
    final root = await _fixture();
    await _write(root, 'old/project.json', '{broken');
    await _write(root, 'old/maps/corrupt.json', '{broken');
    final result = await _build(root);
    expect(
        result.payloadFiles.keys.any((path) => path.startsWith('project/old/')),
        isFalse);
  });
}

BattleRecipeProjectBinding _bindingFor(String digest) => BattleRecipeProjectBinding(
  binding: BattleMoveRecipeBinding.fromJson({
    'schemaVersion': 1, 'projectMoveId': 'custom', 'sourceMoveId': 'source',
    'catalogReleaseId': 'test', 'recipeId': 'synthetic', 'variant': 'default',
    'revision': '1', 'recipeSha256': digest,
  }),
);

Future<Directory> _fixture() async {
  final root =
      await Directory.systemTemp.createTemp('runtime-reference-closure-');
  addTearDown(() => root.delete(recursive: true));
  for (final entry in spatialPayload().entries) {
    await _write(root, entry.key.substring('project/'.length), entry.value);
  }
  return root;
}

Future<void> _write(Directory root, String path, Object value) async {
  final file = File('${root.path}/$path');
  await file.parent.create(recursive: true);
  if (value is List<int>) {
    await file.writeAsBytes(value);
  } else {
    await file.writeAsString(value is String ? value : jsonEncode(value));
  }
}

Future<RuntimeProjectProjection> _build(Directory root) =>
    const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: GamePackageExportProfile(
          gameId: 'games.example.closure',
          gameVersion: '0.1.0',
          title: 'Closure',
          authorName: 'Yoahn',
          defaultLocale: 'fr',
          supportedLocales: ['fr']),
    );

Future<AssetRecord> _catalogJson(
    Directory root, String id, String path, Map<String, Object> value,
    {List<String> tags = const [], List<String> usages = const []}) async {
  final bytes = utf8.encode(jsonEncode(value));
  final artifact =
      ContentArtifactRef.fromBytes(bytes, mediaType: 'application/json');
  final record = AssetRecord(
      id: id,
      logicalPath: path,
      artifact: artifact,
      tags: tags,
      usages: usages);
  final file = File('${root.path}/$assetCatalogStorageKey');
  final catalog = AssetCatalog.fromJson(jsonDecode(await file.readAsString()));
  await _write(root, assetCatalogStorageKey,
      AssetCatalog(records: [...catalog.records, record]).toJson());
  await _write(root, assetBlobStorageKey(artifact), bytes);
  return record;
}

Future<void> _runtimeReference(Directory root, String path) async {
  final file = File('${root.path}/project.json');
  final project =
      ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
  await file.writeAsString(jsonEncode(project
      .copyWith(globalProperties: {'runtimeConfigPath': path}).toJson()));
}

GamePackageExportProfile _profile() => GamePackageExportProfile(
    gameId: 'games.example.closure',
    gameVersion: '0.1.0',
    title: 'Closure',
    authorName: 'Yoahn',
    defaultLocale: 'fr',
    supportedLocales: ['fr']);
