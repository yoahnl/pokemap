import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../tool/generate_synthetic_catalog_project.dart' as generator;

void main() {
  late Directory temporary;
  late Directory source;
  late File profile;
  late File receipt;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('synthetic-catalog-');
    source = Directory(p.join(temporary.path, 'source'));
    profile = File(p.join(temporary.path, 'profile.json'));
    receipt = File(p.join(temporary.path, 'fixture.json'));
  });
  tearDown(() => temporary.delete(recursive: true));

  Future<Map<String, Object?>> generate() =>
      generator.generateSyntheticCatalogProject(
          projectRoot: source, profileFile: profile, receiptFile: receipt);

  test('generates a closed playable synthetic corpus with valid PNGs',
      () async {
    final report = await generate();
    expect(await File(p.join(source.path, 'project.json')).exists(), isTrue);
    final project = await _project(source);
    expect(report['kind'], 'syntheticCatalogQualification');
    expect(project.maps, hasLength(3));
    expect(project.elements, hasLength(32));
    expect(project.newGame.enabled, isTrue);
    expect(project.newGame.startMapId, 'synthetic-map-0000');
    expect(project.settings.defaultPlayerCharacterId, 'synthetic-player');
    expect(project.characters.single.animations.map((a) => a.direction).toSet(),
        EntityFacing.values.toSet());
    expect(project.dialogues, hasLength(1));
    expect(project.facts.single.id, 'fact.synthetic-conversation');
    final records = AssetCatalog.fromJson(jsonDecode(
        await File(p.join(source.path, assetCatalogStorageKey))
            .readAsString()));
    expect(records.records, hasLength(5));
    final identities = <String>{};
    for (final asset in records.records) {
      final file =
          File(p.join(source.path, assetBlobStorageKey(asset.artifact)));
      final bytes = await file.readAsBytes();
      expect(ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png'),
          asset.artifact);
      identities.add(asset.artifact.hexDigest);
      final decoded = image.decodePng(bytes)!;
      expect(decoded.width, asset.id == 'synthetic-player-image' ? 128 : 256);
      expect(decoded.height, decoded.width);
      expect(await File(p.join(source.path, asset.logicalPath)).readAsBytes(),
          bytes);
    }
    expect(identities, hasLength(5));
    for (final entry in project.maps) {
      final map = MapData.fromJson(jsonDecode(
          await File(p.join(source.path, entry.relativePath)).readAsString()));
      expect(map.id, entry.id);
      expect(map.size, const GridSize(width: 16, height: 16));
      for (final warp in map.warps) {
        expect(
            project.maps.map((entry) => entry.id), contains(warp.targetMapId));
      }
      for (final placed in map.placedElements) {
        expect(project.elements.map((entry) => entry.id),
            contains(placed.elementId));
      }
    }
    expect(await _files(source), report['files']);
  });

  test('is byte deterministic across independent output roots', () async {
    final first = await generate();
    expect(await source.exists(), isTrue);
    final other = Directory(p.join(temporary.path, 'other'));
    final otherProfile = File(p.join(temporary.path, 'other-profile.json'));
    final second = await generator.generateSyntheticCatalogProject(
        projectRoot: other,
        profileFile: otherProfile,
        receiptFile: File(p.join(temporary.path, 'other-fixture.json')));
    expect(await _files(other), await _files(source));
    expect(second['sourceIdentitySha256'], first['sourceIdentitySha256']);
    expect(await otherProfile.readAsBytes(), await profile.readAsBytes());
  });

  test('canonical publication keeps unused definitions and compiles dialogue',
      () async {
    await generate();
    expect(await File(p.join(source.path, 'project.json')).exists(), isTrue);
    final before = await _files(source);
    final artifact = await const CanonicalGamePackageExportService()
        .exportToFile(
            projectRoot: source,
            profile: GamePackageExportProfile.decodeUtf8(
                await profile.readAsBytes()),
            outputFile: File(p.join(temporary.path, 'synthetic.avelunegame')));
    expect(artifact.certification.isCertified, isTrue);
    final archive =
        ZipDecoder().decodeBytes(artifact.packageBytes, verify: true);
    final descriptor = jsonDecode(
            utf8.decode(archive.findFile('project/project.json')!.content))
        as Map<String, Object?>;
    expect(descriptor.keys.toSet(), {'format', 'version', 'kind', 'root'});
    expect(descriptor['format'], 'avelune.portable-catalog');
    expect(descriptor['version'], 2);
    expect(utf8.encode(jsonEncode(descriptor)).length, lessThan(4096));
    final published = PortableCatalogPublication.decodeProjectSync(descriptor,
        readObject: (reference) => archive
            .findFile(
                'project/${PortableCatalogPublication.objectPath(reference)}')!
            .content);
    expect(published.elements, hasLength(32));
    expect(published.maps, hasLength(3));
    expect(published.dialogues.single.relativePath, endsWith('.json'));
    expect(archive.findFile('project/dialogues/welcome.yarn'), isNull);
    final compiled =
        archive.findFile('project/${published.dialogues.single.relativePath}')!;
    expect(
        const RuntimeDialogueDocumentCodec().decodeUtf8(compiled.content).nodes,
        isNotEmpty);
    expect(await _files(source), before);
  });

  test('refuses unreasonable parameters before creating any files', () async {
    for (final parameters in [(0, 32, 4), (3, 40000, 4), (3, 32, 0)]) {
      await expectLater(
          generator.generateSyntheticCatalogProject(
              projectRoot: source,
              profileFile: profile,
              receiptFile: receipt,
              mapCount: parameters.$1,
              definitionCount: parameters.$2,
              atlasCount: parameters.$3),
          throwsArgumentError);
      expect(await source.exists(), isFalse);
      expect(await profile.exists(), isFalse);
      expect(await receipt.exists(), isFalse);
    }
  });

  test('refuses an existing source without replacing its contents', () async {
    await source.create();
    final marker = File(p.join(source.path, 'keep.txt'));
    await marker.writeAsString('keep');
    await expectLater(generate(), throwsA(isA<FileSystemException>()));
    expect(await marker.readAsString(), 'keep');
    expect(await profile.exists(), isFalse);
    expect(await receipt.exists(), isFalse);
  });

  test('refuses aliased profile and receipt before creating any output',
      () async {
    final parent = await Directory(p.join(temporary.path, 'outputs')).create();
    final alias =
        await Link(p.join(temporary.path, 'alias')).create(parent.path);
    profile = File(p.join(parent.path, 'result.json'));
    receipt = File(p.join(alias.path, 'result.json'));

    await expectLater(generate(), throwsArgumentError);

    expect(await source.exists(), isFalse);
    expect(await profile.exists(), isFalse);
    expect(await receipt.exists(), isFalse);
    expect(await parent.list().toList(), isEmpty);
  });

  test('refuses an aliased receipt inside the future project before creation',
      () async {
    final parent = await Directory(p.join(temporary.path, 'outputs')).create();
    final alias =
        await Link(p.join(temporary.path, 'alias')).create(parent.path);
    source = Directory(p.join(parent.path, 'source'));
    receipt = File(p.join(alias.path, 'source', 'receipt.json'));

    await expectLater(generate(), throwsArgumentError);

    expect(await source.exists(), isFalse);
    expect(await profile.exists(), isFalse);
    expect(await receipt.exists(), isFalse);
    expect(await parent.list().toList(), isEmpty);
  });
}

Future<ProjectManifest> _project(Directory root) async =>
    ProjectManifest.fromJson(jsonDecode(
        await File(p.join(root.path, 'project.json')).readAsString()));

Future<List<Map<String, Object?>>> _files(Directory root) async {
  final result = <Map<String, Object?>>[];
  await for (final entry in root.list(recursive: true, followLinks: false)) {
    if (entry is File) {
      result.add({
        'path': p.relative(entry.path, from: root.path),
        'bytes': await entry.length(),
        'sha256': (await sha256.bind(entry.openRead()).first).toString(),
      });
    }
  }
  return result
    ..sort((a, b) => (a['path'] as String).compareTo(b['path'] as String));
}
