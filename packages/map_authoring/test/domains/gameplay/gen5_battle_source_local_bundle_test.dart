import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../../../../../tools/gen5_battle_sprite/source_view.dart';

const _revision = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _species = 'syntheticmon';
const _dex = 25;
const _release = 'synthetic-release';

void main() {
  test('carries verified API assets into an offline decodable bundle',
      () async {
    final assets = _assets();
    final transport = _Transport(_document(assets));
    final snapshot = await AveluneGen5BattleSource(
      client: transport,
      release: _release,
    ).fetch(species: _species, nationalDex: _dex);
    expect(transport.uri!.path, '/v1/snapshots/$_release/gen5-battle/$_dex');

    final encoded = gen5BattleSourceBundleFromSnapshot(snapshot!).encode();
    expect(encoded, isNotEmpty);
    final digest = sha256.convert(encoded).toString();
    final staged = MemoryArtifactStore(maximumArtifactBytes: 20 * 1024 * 1024);
    final stagedRef =
        await staged.put(encoded, declaredMediaType: 'application/json');
    final stagedBytes = await staged.read(stagedRef.reference.handle);
    expect(
        ContentArtifactRef.fromBytes(stagedBytes,
            mediaType: 'application/json'),
        stagedRef.reference);
    const bundlePath =
        'project/data/pokemon/battle_sources/bundles/synthetic.json';
    final built = const GamePackageBuilder().build(
      manifest: _manifest(),
      payloadFiles: {
        'project/project.json': utf8.encode(jsonEncode({
          'name': 'Synthetic',
          'version': 'v8',
          'maps': [],
          'tilesets': [],
          'pokemon': const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          ).toJson(),
        })),
        bundlePath: stagedBytes,
      },
    );
    final inspected = const GamePackageInspector().inspect(built.packageBytes);
    final inventory = inspected.manifest.content.files
        .singleWhere((file) => file.path == bundlePath);
    expect(inventory.sha256, digest);
    final archive = ZipDecoder().decodeBytes(built.packageBytes, verify: true);
    final archived =
        Uint8List.fromList(archive.findFile(bundlePath)!.content as List<int>);
    expect(archived, encoded);
    final restored = Gen5BattleSourceBundle.decode(
      archived,
      expectedSha256: inventory.sha256,
      expectedSpecies: _species,
      expectedNationalDex: _dex,
      expectedRelease: _release,
      expectedSourceRevision: _revision,
    );

    expect(restored.species, _species);
    expect(restored.nationalDex, _dex);
    expect(restored.release, _release);
    expect(restored.sourceRevision, _revision);
    expect(restored.redistributionStatus, 'unverified');
    expect(restored.encode(), encoded);
    expect(restored.assets.keys, unorderedEquals(assets.keys));
    for (final name in assets.keys) {
      expect(sha256.convert(restored.assets[name]!).toString(),
          sha256.convert(assets[name]!).toString());
    }
    for (final side in ['front', 'back']) {
      final view =
          decodeGen5SourceView(restored.assets, view: side, shiny: false);
      expect(view.indexedAtlas.indices.first, 1);
      expect(view.info.cells.single.primary.width, 4096);
      expect(view.timelines.single.frames.single.targetIndex, 0);
    }
    expect(() => restored.assets['front.png']![0] = 0, throwsUnsupportedError);
    expect(() => restored.assets.clear(), throwsUnsupportedError);
  });

  test('refuses damaged bundles and mismatched identities offline', () async {
    final snapshot = await AveluneGen5BattleSource(
      client: _Transport(_document(_assets())),
      release: _release,
    ).fetch(species: _species, nationalDex: _dex);
    final encoded = gen5BattleSourceBundleFromSnapshot(snapshot!).encode();
    final digest = sha256.convert(encoded).toString();
    Gen5BattleSourceBundle read(Uint8List bytes, String hash,
            {String species = _species,
            int nationalDex = _dex,
            String release = _release,
            String revision = _revision}) =>
        Gen5BattleSourceBundle.decode(bytes,
            expectedSha256: hash,
            expectedSpecies: species,
            expectedNationalDex: nationalDex,
            expectedRelease: release,
            expectedSourceRevision: revision);
    expect(() => read(encoded, '0' * 64), throwsFormatException);
    expect(
        () => read(encoded, digest, species: 'another'), throwsFormatException);
    expect(() => read(encoded, digest, nationalDex: 26), throwsFormatException);
    expect(() => read(encoded, digest, release: 'other-release'),
        throwsFormatException);
    expect(
        () => read(encoded, digest, revision: 'b' * 40), throwsFormatException);
    for (final name in gen5BattleBundleAssetNames) {
      final damaged = jsonDecode(utf8.decode(encoded)) as Map<String, dynamic>;
      final asset = (damaged['assets'] as Map<String, dynamic>)[name]
          as Map<String, dynamic>;
      final original = base64.decode(asset['data'] as String);
      original[original.length - 1] ^= 1;
      asset['data'] = base64.encode(original);
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(damaged)));
      expect(() => read(bytes, sha256.convert(bytes).toString()),
          throwsFormatException,
          reason: name);
    }
    final future = jsonDecode(utf8.decode(encoded)) as Map<String, dynamic>;
    future['schemaVersion'] = 2;
    final futureBytes = Uint8List.fromList(utf8.encode(jsonEncode(future)));
    expect(() => read(futureBytes, sha256.convert(futureBytes).toString()),
        throwsFormatException);
    final incomplete = jsonDecode(utf8.decode(encoded)) as Map<String, dynamic>;
    (incomplete['assets'] as Map<String, dynamic>).remove('back.png');
    final incompleteBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(incomplete)));
    expect(
        () => read(incompleteBytes, sha256.convert(incompleteBytes).toString()),
        throwsFormatException);
    final duplicate = utf8.decode(encoded).replaceFirst(
          '"schemaVersion":1',
          '"schemaVersion":1,"schemaVersion":1',
        );
    final duplicateBytes = Uint8List.fromList(utf8.encode(duplicate));
    expect(
        () => read(duplicateBytes, sha256.convert(duplicateBytes).toString()),
        throwsFormatException);
  });

  test('detaches bundle data from mutable source buffers', () {
    final input = _assets();
    final bundle = Gen5BattleSourceBundle(
      species: _species,
      nationalDex: _dex,
      release: _release,
      sourceRepository: 'fuddlesworth/pokebw2',
      sourceRevision: _revision,
      sourceDirectory: 'res/pokemon/$_species',
      reconstruction: 'not-yet-validated',
      redistributionStatus: 'unverified',
      assets: input,
    );
    final first = bundle.assets['front.png']![0];
    input['front.png']![0] = 0;
    input.clear();
    expect(bundle.assets['front.png']![0], first);
    expect(bundle.assets, hasLength(14));
  });

  test('binds exact Unicode bytes and rejects a corrupted source bundle',
      () async {
    const projectSpecies = 'pokemon-e\u0301';
    const reconstruction = 'a\u0300 verifier';
    final document = _document(_assets())..['reconstruction'] = reconstruction;
    final snapshot = await AveluneGen5BattleSource(
      client: _Transport(document),
      release: _release,
    ).fetch(species: _species, nationalDex: _dex);
    final bundle = gen5BattleSourceBundleFromSnapshot(snapshot!);
    final bytes = bundle.encode();
    final binding = Gen5BattleSourceBinding.fromBundle(
      projectSpeciesId: projectSpecies,
      projectNationalDex: _dex,
      bundle: bundle,
    );
    expect(
        () => Gen5BattleSourceBinding.fromBundle(
              projectSpeciesId: projectSpecies,
              projectNationalDex: 26,
              bundle: bundle,
            ),
        throwsFormatException);
    final bindingBytes = binding.encode();
    expect(bindingBytes, isNotEmpty);
    final built = const GamePackageBuilder().build(
      manifest: _manifest(),
      payloadFiles: {
        'project/project.json': utf8.encode(jsonEncode({
          'name': 'Synthetic',
          'version': 'v8',
          'maps': [],
          'tilesets': [],
          'pokemon': const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          ).toJson(),
        })),
        'project/${binding.bindingPath}': bindingBytes,
        'project/${binding.bundlePath}': bytes,
      },
    );
    final inspected = const GamePackageInspector().inspect(built.packageBytes);
    final archive = ZipDecoder().decodeBytes(built.packageBytes, verify: true);
    Uint8List file(String path) => Uint8List.fromList(
          archive.findFile('project/$path')!.content as List<int>,
        );
    final storedBinding = file(binding.bindingPath);
    final storedBundle = file(binding.bundlePath);
    expect(storedBinding, bindingBytes);
    expect(storedBundle, bytes);
    final bindingEntry = inspected.manifest.content.files.singleWhere(
      (entry) => entry.path == 'project/${binding.bindingPath}',
    );
    final restored = Gen5BattleSourceBinding.decode(
      storedBinding,
      expectedSha256: bindingEntry.sha256,
      expectedProjectSpeciesId: projectSpecies,
      expectedProjectNationalDex: _dex,
    );
    expect(restored.projectSpeciesId, projectSpecies);
    expect(restored.bundleSha256, sha256.convert(bytes).toString());
    final decoded = restored.resolve(storedBundle,
        expectedProjectSpeciesId: projectSpecies,
        expectedProjectNationalDex: _dex);
    expect(decoded.reconstruction, reconstruction);
    expect(decoded.encode(), bytes);
    final corrupt = Uint8List.fromList(storedBundle)
      ..[storedBundle.length - 1] ^= 1;
    expect(
        () => restored.resolve(corrupt,
            expectedProjectSpeciesId: projectSpecies,
            expectedProjectNationalDex: _dex),
        throwsFormatException);
    expect(
        () => restored.resolve(storedBundle,
            expectedProjectSpeciesId: 'other',
            expectedProjectNationalDex: _dex),
        throwsFormatException);
    expect(
        () => restored.resolve(storedBundle,
            expectedProjectSpeciesId: projectSpecies,
            expectedProjectNationalDex: 26),
        throwsFormatException);
    expect(
      () => Gen5BattleSourceBinding.decode(
        storedBinding,
        expectedSha256: bindingEntry.sha256,
        expectedProjectSpeciesId: 'pokemon-é',
        expectedProjectNationalDex: _dex,
      ),
      throwsFormatException,
    );
    expect(
      () => Gen5BattleSourceBinding.decode(
        storedBinding,
        expectedSha256: bindingEntry.sha256,
        expectedProjectSpeciesId: projectSpecies,
        expectedProjectNationalDex: 26,
      ),
      throwsFormatException,
    );
  });
}

GamePackageManifest _manifest() => const GamePackageManifestCodec().decodeJson({
      'packageFormat': 1,
      'gameId': 'games.example.synthetic',
      'gameVersion': '1.0.0',
      'title': 'Synthetic',
      'author': {'name': 'Example'},
      'compatibility': {
        'minHubVersion': '1.0.0',
        'runtimeApi': '>=1.0.0 <2.0.0',
        'projectFormat': 'v8',
        'saveFormat': 1,
        'compatibilityId': 'main',
        'requiredCapabilities': <String>[],
      },
      'locales': {
        'default': 'fr',
        'supported': ['fr']
      },
      'content': {
        'fileCount': 1,
        'totalBytes': 24,
        'treeSha256':
            'e21fddff269f718118bf1bda81c75726b57a9a34a9fd74497b53517069862a3b',
        'files': [
          {
            'path': 'project/project.json',
            'size': 24,
            'sha256':
                '1bcbf797acc5b8dc08dcba7f4da52a7d7b09f97cc5ec1905b8093d6f0faa097a'
          }
        ],
      },
    });

final class _Transport implements PokemonBoundedExternalHttpTransport {
  _Transport(this.document);
  final Map<String, Object?> document;
  Uri? uri;

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    this.uri = uri;
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: {'x-source-revision': _revision},
      body: '',
      bodyBytes: Uint8List.fromList(utf8.encode(jsonEncode(document))),
    );
  }
}

Map<String, Object?> _document(Map<String, Uint8List> assets) => {
      'format': 'gen5-battle-source-v1',
      'game': 'black2-white2',
      'scope': 'default-form',
      'species': _species,
      'nationalDex': _dex,
      'reconstruction': 'not-yet-validated',
      'source': {
        'repository': 'fuddlesworth/pokebw2',
        'revision': _revision,
        'directory': 'res/pokemon/$_species',
        'redistributionStatus': 'unverified',
      },
      'assets': {
        for (final entry in assets.entries)
          entry.key: {
            'encoding': 'base64',
            'size': entry.value.length,
            'sha256': sha256.convert(entry.value).toString(),
            'data': base64.encode(entry.value),
          },
      },
    };

Map<String, Uint8List> _assets() {
  final png = _png();
  final cells = _cells();
  final animation = _literalLz11(_animation());
  final maps = _maps();
  final timeline = _animation(timeline: true);
  final info = Uint8List(62);
  final data = ByteData.sublistView(info);
  data.setUint32(0, 1, Endian.little);
  data.setUint16(4, 8, Endian.little);
  data.setUint16(6, 8, Endian.little);
  data.setInt32(20, 4096, Endian.little);
  data.setInt32(24, 4096, Endian.little);
  final palette = Uint8List.fromList(ascii.encode(
    'JASC-PAL\n0100\n16\n${List.generate(16, (i) => '$i $i $i').join('\n')}\n',
  ));
  return {
    for (final side in ['front', 'back']) ...{
      '$side.png': png,
      '${side}_cells.ncer': cells,
      '${side}_animations.nanr.lz11': animation,
      '${side}_multi_cells.nmcr': maps,
      '${side}_multi_animations.nmar': timeline,
      '${side}_info.bin': info,
    },
    'normal.pal': palette,
    'shiny.pal': palette,
  };
}

Uint8List _png() {
  final header = ByteData(13)
    ..setUint32(0, 256)
    ..setUint32(4, 128)
    ..setUint8(8, 8)
    ..setUint8(9, 3);
  final raw = Uint8List(257 * 128)..[1] = 1;
  return Uint8List.fromList([
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    ..._pngChunk('IHDR', header.buffer.asUint8List()),
    ..._pngChunk('PLTE', List.filled(48, 0)),
    ..._pngChunk('tRNS', [0]),
    ..._pngChunk('IDAT', zlib.encode(raw)),
    ..._pngChunk('IEND', []),
  ]);
}

List<int> _pngChunk(String name, List<int> data) {
  final type = ascii.encode(name);
  var crc = 0xffffffff;
  for (final byte in [...type, ...data]) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      crc = crc & 1 == 0 ? crc >> 1 : (crc >> 1) ^ 0xedb88320;
    }
  }
  final length = ByteData(4)..setUint32(0, data.length);
  final checksum = ByteData(4)..setUint32(0, (crc ^ 0xffffffff) & 0xffffffff);
  return [
    ...length.buffer.asUint8List(),
    ...type,
    ...data,
    ...checksum.buffer.asUint8List()
  ];
}

Uint8List _nitro(int size, String magic, String section) {
  final bytes = Uint8List(size);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode(magic));
  data.setUint16(4, 0xfeff, Endian.little);
  data.setUint16(6, 0x0100, Endian.little);
  data.setUint32(8, size, Endian.little);
  data.setUint16(12, 16, Endian.little);
  data.setUint16(14, 1, Endian.little);
  bytes.setRange(16, 20, ascii.encode(section));
  data.setUint32(20, size - 16, Endian.little);
  data.setUint16(24, 1, Endian.little);
  data.setUint32(28, 24, Endian.little);
  return bytes;
}

Uint8List _cells() {
  final bytes = _nitro(62, 'RECN', 'KBEC');
  ByteData.sublistView(bytes).setUint16(48, 1, Endian.little);
  return bytes;
}

Uint8List _maps() {
  final bytes = _nitro(64, 'RCMN', 'KBCM');
  final data = ByteData.sublistView(bytes);
  data.setUint16(48, 1, Endian.little);
  data.setUint16(50, 1, Endian.little);
  return bytes;
}

Uint8List _animation({bool timeline = false}) {
  final bytes = _nitro(96, timeline ? 'RAMN' : 'RNAN', 'KNBA');
  final data = ByteData.sublistView(bytes);
  data.setUint16(26, 1, Endian.little);
  data.setUint32(32, 40, Endian.little);
  data.setUint32(36, 48, Endian.little);
  data.setUint16(48, 1, Endian.little);
  data.setUint16(52, 1, Endian.little);
  data.setUint32(56, 2, Endian.little);
  data.setUint16(68, 3, Endian.little);
  data.setInt32(76, 4096, Endian.little);
  data.setInt32(80, 4096, Endian.little);
  return bytes;
}

Uint8List _literalLz11(Uint8List bytes) => Uint8List.fromList([
      0x11,
      bytes.length & 255,
      (bytes.length >> 8) & 255,
      (bytes.length >> 16) & 255,
      for (var offset = 0; offset < bytes.length; offset += 8) ...[
        0,
        ...bytes.skip(offset).take(8),
      ],
    ]);
