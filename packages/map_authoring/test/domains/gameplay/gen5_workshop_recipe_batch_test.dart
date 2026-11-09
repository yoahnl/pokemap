import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  test('converts workshop programs and their media while reporting failures',
      () async {
    final temp = await Directory.systemTemp.createTemp('workshop-recipe-test-');
    try {
      final input = await Directory('${temp.path}/input').create();
      final sounds = await Directory('${temp.path}/sounds').create();
      final output = '${temp.path}/output';
      final source =
          Directory('../../tools/avelune_attack_comparator/assets/bw2/batch');
      final entries = <Map<String, String>>[];
      for (final move in ['hyper-beam', 'fissure', 'present']) {
        await File('${source.path}/$move.json')
            .copy('${input.path}/$move.json');
        entries.add({'id': move, 'bundleAsset': 'assets/bw2/batch/$move.json'});
      }
      await File('${source.path}/ally-switch.json')
          .copy('${input.path}/ally-switch.json');
      await File('../map_runtime/assets/audio/battle/se/stat_rise_up.mp3')
          .copy('${sounds.path}/Present damage.mp3');
      await File('../map_runtime/assets/audio/battle/se/stat_fall_down.mp3')
          .copy('${sounds.path}/Present heal.mp3');
      entries.add(
          {'id': 'missing', 'bundleAsset': 'assets/bw2/batch/missing.json'});
      await File('${input.path}/index.json').writeAsString(jsonEncode(entries));
      final moves = File('${temp.path}/moves.json');
      await moves.writeAsString(jsonEncode(
          ['hyper-beam', 'fissure', 'present', 'ally-switch', 'missing']));
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'tool/gen5_workshop_recipe_batch.dart',
        input.path,
        sounds.path,
        output,
        moves.path
      ]);
      expect(result.exitCode, 1, reason: result.stderr.toString());
      final report = jsonDecode(result.stdout as String) as Map;
      expect(report['requested'], 5);
      expect(report['converted'], 4);
      expect((report['failures'] as List).single['move'], 'missing');
      for (final move in ['hyper-beam', 'fissure', 'present', 'ally-switch']) {
        final digest = sha256.convert(utf8.encode(move)).toString();
        final binding = jsonDecode(
            await File('$output/bindings/$digest.json').readAsString()) as Map;
        final recipeHash = (binding['binding'] as Map)['recipeSha256'];
        final recipe = jsonDecode(
            await File('$output/blobs/$digest/$recipeHash.json')
                .readAsString()) as Map;
        final workshop =
            jsonDecode(await File('${input.path}/$move.json').readAsString())
                as Map;
        expect(
            (recipe['program'] as Map)['sourceProgram'], workshop['program']);
        expect((recipe['audio'] as Map)['kind'],
            move == 'present' ? 'clip' : 'none');
        if (move == 'hyper-beam' || move == 'fissure') {
          expect((recipe['program'] as Map)['backgroundBindings'], isNotEmpty);
        }
        for (final resource in recipe['resources'] as List) {
          final item = resource as Map;
          final ext = item['role'] == 'texture'
              ? 'png'
              : item['role'] == 'sound'
                  ? 'mp3'
                  : 'json';
          final bytes =
              await File('$output/blobs/$digest/${item['sha256']}.$ext')
                  .readAsBytes();
          expect(sha256.convert(bytes).toString(), item['sha256']);
        }
        if (move == 'present') {
          final sound = (recipe['resources'] as List)
              .singleWhere((value) => value['role'] == 'sound') as Map;
          final expected =
              await File('${sounds.path}/Present damage.mp3').readAsBytes();
          expect(sound['sha256'], sha256.convert(expected).toString());
        }
        if (move == 'fissure') {
          expect(((recipe['program'] as Map)['particleBindings'] as List),
              hasLength(2));
          final textures = (recipe['resources'] as List)
              .where((value) => value['role'] == 'texture')
              .map((value) => value['id'])
              .toList();
          expect(textures.toSet(), hasLength(textures.length));
        }
      }
    } finally {
      await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
