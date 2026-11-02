import 'dart:convert';
import 'dart:io';

import 'package:map_battle/src/data/psdk_source_locator.dart';
import 'package:test/test.dart';

import '../../tool/generate_psdk_move_flags.dart' as generator;

void main() {
  test('native boolean flags override category and normalize source identities',
      () {
    final generated = generator.renderPsdkMoveFlags({
      'physical.json': jsonEncode({
        'dbSymbol': 'Thunder Fang',
        'category': 'physical',
        'isKingRockUtility': false,
      }),
      'status.json': jsonEncode({
        'dbSymbol': 'custom-source',
        'category': 'status',
        'isKingRockUtility': true,
      }),
    });
    expect(generated, contains("'thunderfang': false,"));
    expect(generated, contains("'customsource': true,"));
  });

  test('generation is byte-identical after source enumeration order changes',
      () {
    final first = jsonEncode({'dbSymbol': 'first', 'isKingRockUtility': true});
    final second =
        jsonEncode({'dbSymbol': 'second', 'isKingRockUtility': false});
    expect(generator.renderPsdkMoveFlags({'z.json': second, 'a.json': first}),
        generator.renderPsdkMoveFlags({'a.json': first, 'z.json': second}));
  });

  test('rejects absent or nonboolean flags and ambiguous compact identities',
      () {
    for (final value in [null, 'true', 1]) {
      expect(
          () => generator.renderPsdkMoveFlags({
                'bad.json': jsonEncode(
                    {'dbSymbol': 'tackle', 'isKingRockUtility': value}),
              }),
          throwsFormatException);
    }
    expect(
        () => generator.renderPsdkMoveFlags({
              'one.json': jsonEncode(
                  {'dbSymbol': 'one_two', 'isKingRockUtility': true}),
              'two.json': jsonEncode(
                  {'dbSymbol': 'onetwo', 'isKingRockUtility': false}),
            }),
        throwsFormatException);
    expect(() => generator.renderPsdkMoveFlags({}), throwsFormatException);
  });

  test('committed move flags are reproducible from native Studio source', () {
    final source = resolvePsdkSourceDirectories().movesDirectory;
    final result = Process.runSync(Platform.resolvedExecutable, [
      'run',
      'tool/generate_psdk_move_flags.dart',
      '--source-directory',
      source.path,
      '--check',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  }, skip: psdkSourcesAvailable() ? false : 'Local native PSDK sources absent');
}
