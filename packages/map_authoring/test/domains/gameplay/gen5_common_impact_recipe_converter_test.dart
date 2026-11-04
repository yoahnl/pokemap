import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
const soundRoot =
    '/Users/karim/Downloads/DS _ DSi - Pokemon Black _ White - Miscellaneous - Attack Move Sound Effects';

class _Transport implements PokemonBoundedExternalHttpTransport {
  _Transport(this.body);
  final Uint8List body;

  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
          {required Map<String, String> headers,
          required int maximumBytes,
          required Duration timeout}) async =>
      PokemonExternalHttpResponse(
          statusCode: 200,
          headers: const {'x-source-revision': revision},
          body: '',
          bodyBytes: body);
}

Future<Uint8List> _fetch(HttpClient client, String path) async {
  final request = await client.getUrl(Uri.https(
      'raw.githubusercontent.com', '/fuddlesworth/pokebw2/$revision/$path'));
  request.followRedirects = false;
  final response = await request.close();
  if (response.statusCode != 200) {
    throw StateError('HTTP ${response.statusCode}: $path');
  }
  final bytes = BytesBuilder();
  await for (final chunk in response) {
    bytes.add(chunk);
    if (bytes.length > 262144) throw StateError('Source too large');
  }
  return bytes.takeBytes();
}

Map<String, Object> _asset(String path, Uint8List bytes) => {
      'path': path,
      'size': bytes.length,
      'sha256': sha256.convert(bytes).toString(),
      'encoding': 'base64',
      'data': base64.encode(bytes),
    };

void main() {
  test('rejects an empty batch', () {
    expect(() => Gen5CommonImpactRecipeConverter.convertBatch([]),
        throwsArgumentError);
  });
  test('converts a mixed batch of verified BW2 sources', () async {
    final inputs = <Gen5ImpactBatchInput>[];
    for (final move in [
      (
        id: 1,
        name: 'pound',
        title: 'Pound',
        particle: 165,
        scriptHash:
            'b35c998a2418f20b992c88948eec4c3d45e946eea0ce17af76c6f1f1369c298f',
        particleHash:
            '118d37a95332a56c4e5231e41dacef8840ab419a3039011165c7ad8ced3fbf1a',
        swings: 1,
        textures: 3,
        unsupported: true
      ),
      (
        id: 21,
        name: 'slam',
        title: 'Slam',
        particle: 187,
        scriptHash:
            '62ad743f1f4c2d458e75fa5151a4481806d213493a06675aacfc150d05978d7f',
        particleHash:
            'd643c63593104ba16b7885dbd12b660fdbea754df57aef0aa44797d05eff30b7',
        swings: 2,
        textures: 3,
        unsupported: true
      ),
      (
        id: 2,
        name: 'karate-chop',
        title: 'Karate Chop',
        particle: 166,
        scriptHash:
            '1e17a2d6cfb536a5531d267ab80f28f58b75c9c9991903e7192588771e043012',
        particleHash:
            'b66ec0dfb7a83987a5a8eb0237f2f768d66575aa4e6ee837754cc2e81e51bb21',
        swings: 1,
        textures: 4,
        unsupported: false
      ),
      (
        id: 398,
        name: 'poison-jab',
        title: 'Poison Jab',
        particle: 577,
        scriptHash:
            '9c776959829b90112cefc614fafe5a8171c36010d6e8194876aeea0acf5eaaf4',
        particleHash:
            '0a28ab2f578f8c63bc5ce46134dc76ffb88363bae3f01c0437bdecfca3cdc64b',
        swings: 1,
        textures: 3,
        unsupported: false
      ),
      (
        id: 33,
        name: 'tackle',
        title: 'Tackle',
        particle: 199,
        scriptHash:
            '7e4efb20a66db06afb4611900c65796e60401d02cd49e5d9e7a35fa6e40d441c',
        particleHash:
            '0a2edc30e578f3f9d7650d6f3b6916fb673b8a494547d22557e2c5a34915955e',
        swings: 2,
        textures: 5,
        unsupported: false
      ),
    ]) {
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final scriptPath =
          'res/battle/animations/moves/${move.name.replaceAll('-', '_')}.s';
      final particleRoot =
          'res/particles/btlv_effvm_particles/${move.particle}';
      final script = await _fetch(client, scriptPath);
      final definition = await _fetch(client, '$particleRoot/particles.json');
      expect(sha256.convert(script).toString(), move.scriptHash);
      expect(sha256.convert(definition).toString(), move.particleHash);
      final textures = <Map<String, Object>>[];
      for (var i = 0; i < move.textures; i++) {
        final name = 'texture0$i';
        final path = '$particleRoot/$name.png';
        textures
            .add({'name': name, ..._asset(path, await _fetch(client, path))});
      }
      final document = {
        'release': 'draft',
        'format': 'gen5-move-source-v2',
        'game': 'black2-white2',
        'move': {'id': move.name, 'sourceId': move.id},
        'source': {
          'repository': 'fuddlesworth/pokebw2',
          'revision': revision,
          'redistributionStatus': 'unverified'
        },
        'completeness': {
          'audio': 'missing-sequences-banks-and-commands',
          'playback': 'not-supported',
          'dependencies': {
            'status': 'complete',
            'missingParticleIds': [],
            'missingTextures': []
          }
        },
        'script': _asset(scriptPath, script),
        'particles': [
          {
            'id': move.particle,
            'definition': _asset('$particleRoot/particles.json', definition),
            'textures': textures
          }
        ],
      };
      final fixturePath = switch (move.name) {
        'karate-chop' =>
          Platform.environment['AVELUNE_BW2_KARATE_QA_RESPONSE_PATH'],
        'poison-jab' =>
          Platform.environment['AVELUNE_BW2_POISON_QA_RESPONSE_PATH'],
        _ => null,
      };
      if (fixturePath != null) {
        if (!fixturePath.startsWith(
            '/Users/karim/Library/Caches/AveluneQA/bw2-poison-jab/')) {
          throw StateError('Invalid QA fixture path');
        }
        await File(fixturePath)
            .writeAsString(jsonEncode(document), flush: true);
      }
      final source = AveluneGen5MoveSource(
          client:
              _Transport(Uint8List.fromList(utf8.encode(jsonEncode(document)))),
          release: 'draft');
      final snapshot =
          (await source.fetch(moveId: move.name, sourceMoveId: move.id))!;
      if (move.name == 'karate-chop') {
        final particle = snapshot.particles[move.particle]!;
        final converted = Gen5SplParticleConverter.convert(
          particle.definitionBytes,
          particleId: move.particle,
          sourceRevision: revision,
          sourcePath: '$particleRoot/particles.json',
          expectedSha256: move.particleHash,
          textureResourceIds: {
            for (final name in particle.textureBytes.keys) name: name
          },
        );
        expect(converted.definition.schemaVersion, 4);
        final first =
            (converted.definition.toJson()['emitters'] as List).first as Map;
        final magnet = (first['motion'] as Map)['magnet'] as Map;
        expect(magnet['force'], 761);
        expect(magnet['target'], {'x': 0, 'y': -19033, 'z': 0});
        final color = (first['appearance'] as Map)['color'] as Map;
        expect(color['start'], color['middle']);
        expect(color['end'], color['middle']);
        final second =
            (converted.definition.toJson()['emitters'] as List).last as Map;
        expect((second['child'] as Map)['scaleEnd'], 0);
      }
      if (move.name == 'poison-jab') {
        final particle = snapshot.particles[move.particle]!;
        final converted = Gen5SplParticleConverter.convert(
          particle.definitionBytes,
          particleId: move.particle,
          sourceRevision: revision,
          sourcePath: '$particleRoot/particles.json',
          expectedSha256: move.particleHash,
          textureResourceIds: {
            for (final name in particle.textureBytes.keys) name: name
          },
        );
        final emitters = converted.definition.toJson()['emitters'] as List;
        final first = emitters.first as Map;
        final second = emitters.last as Map;
        expect(((first['motion'] as Map)['magnet'] as Map)['force'], 152);
        expect((first['child'] as Map)['inheritBehaviors'], isTrue);
        expect((first['child'] as Map)['draw'], 'directionalBillboard');
        expect((second['child'] as Map)['scaleEnd'], 10622);
      }
      final sound = await File('$soundRoot/${move.title}.mp3').readAsBytes();
      final input = Gen5ImpactBatchInput(
          snapshot: snapshot,
          projectMoveId: move.name,
          soundBytes: sound,
          soundMediaType: 'audio/mpeg');
      inputs.add(input);
      final invalid = Gen5ImpactBatchInput(
          snapshot: snapshot,
          projectMoveId: '${move.name}-invalid',
          soundBytes: sound,
          soundMediaType: 'audio/invalid');
      final batch =
          Gen5CommonImpactRecipeConverter.convertBatch([invalid, input]);
      expect(batch, hasLength(2));
      expect(batch.first.recipe, isNull);
      expect(batch.first.failureReason, isNotEmpty);
      expect(() => Gen5CommonImpactRecipeConverter.convertBatch([input, input]),
          throwsArgumentError);
      if (move.unsupported) {
        expect(batch.last.recipe, isNull);
        expect(batch.last.failureReason, isNotEmpty);
        continue;
      }
      final result = batch.last.recipe!;
      final bundleRoot = Platform.environment['AVELUNE_BW2_BUNDLE_QA_DIR'];
      if (bundleRoot != null) {
        if (bundleRoot != '/Users/karim/Library/Caches/AveluneQA/bw2-pilot-api' &&
            await Directory(bundleRoot).resolveSymbolicLinks() !=
                await Directory.systemTemp.resolveSymbolicLinks()) {
          throw StateError('Invalid bundle QA directory');
        }
        final bundle = {
          'recipe': base64.encode(result.bundle.recipeBytes),
          'media': {for (final entry in result.bundle.media.entries) entry.key: base64.encode(entry.value)},
        };
        await File('$bundleRoot/${move.name}.json').writeAsString(jsonEncode(bundle), flush: true);
      }
      expect(result.binding.sourceMoveId, move.name);
      final steps =
          (result.bundle.recipe.toJson()['program'] as Map)['steps'] as List;
      expect(
          ((steps[2] as Map)['steps'] as List)
              .where((step) => (step as Map)['kind'] == 'gen5Swing'),
          hasLength(move.swings));
      expect(result.limitations, isNotEmpty);
    }
    final all = Gen5CommonImpactRecipeConverter.convertBatch(inputs);
    expect(all.map((item) => item.projectMoveId),
        ['pound', 'slam', 'karate-chop', 'poison-jab', 'tackle']);
    expect(all.map((item) => item.recipe != null),
        [false, false, true, true, true]);
  }, skip: Platform.environment['AVELUNE_BW2_COMMON_SOURCE_TEST'] != '1');
}
