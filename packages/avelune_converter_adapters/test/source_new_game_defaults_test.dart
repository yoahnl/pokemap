import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_new_game_defaults.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

const _reader = SourceNewGameDefaultsReader();
final _oracleRoot = Platform.environment['AVELUNE_NEW_GAME_DEFAULTS_SOURCE'];

Future<LiteralTileFixture> _fixture({bool oracle = false,
  bool reverseScripts = false, bool changePlayerMethod = false,
  bool duplicateLibrary = false, bool addLibrary = false,
  Map<String, List<int>> overrides = const {}}) async {
  final files = <String, List<int>>{};
  if (oracle) {
    for (final path in ['Data/Scripts.rxdata', 'Data/metadata.dat',
      'Data/player_metadata.dat', 'Data/trainer_types.dat',
      'Data/PluginScripts.rxdata', 'PBS/metadata.txt']) {
      files[path] = await File('$_oracleRoot/$path').readAsBytes();
    }
    if (reverseScripts || changePlayerMethod || duplicateLibrary || addLibrary) {
      final document = const MarshalDecoder().decode(files['Data/Scripts.rxdata']!);
      final rows = <Object?>[];
      for (final id in document.node(document.rootId).elements) {
        final row = document.node(id).elements;
        var compressed = document.node(row[2]).bytes!;
        final name = document.node(row[1]).text().text!;
        if (changePlayerMethod && name == 'Player') {
          final decoded = const BoundedZlibDecoder().decode(compressed);
          final text = utf8.decode(decoded).replaceFirst('@outfit', '@outfix');
          compressed = zlib.encode(utf8.encode(text));
        }
        rows.add([document.node(row[0]).integerValue!.toInt(), name, compressed]);
      }
      if (duplicateLibrary) rows.add(rows.first);
      if (addLibrary) rows.add([9999, 'OriginalUnknownHook', zlib.encode(utf8.encode('ORIGINAL_HOOK = 1'))]);
      files['Data/Scripts.rxdata'] = literalFixtureMarshal(
          reverseScripts ? rows.reversed.toList() : rows);
    }
  }
  files.addAll(overrides);
  return LiteralTileFixture.create(
    scriptsBytes: files.remove('Data/Scripts.rxdata') ?? literalFixtureMarshal([]),
    extraFiles: files,
  );
}

Matcher _error(String code) => isA<ContractError>()
    .having((error) => error.code, 'code', code);

void main() {
  test('defaults refuses an unknown source library', () async {
    final fixture = await _fixture();
    expect(await _reader.read(source: fixture.source, files: fixture.files), isNull);
  });

  test('defaults honors cancellation before any source read', () async {
    final fixture = await _fixture();
    final cancellation = ScanCancellation()..cancel();
    await expectLater(_reader.read(source: fixture.source, files: fixture.files,
        cancellation: cancellation), throwsA(_error('source.cancelled')));
    expect(fixture.files.reads, isEmpty);
  });

  test('defaults rejects source byte changes against the snapshot', () async {
    final fixture = await _fixture();
    fixture.files.overrides['Data/Scripts.rxdata'] = [4, 8, 0];
    await expectLater(_reader.read(source: fixture.source, files: fixture.files),
        throwsA(_error('source.snapshot_changed')));
  });

  test('defaults rejects source bytes exceeding caller quota before reading', () async {
    final fixture = await _fixture();
    await expectLater(_reader.read(source: fixture.source, files: fixture.files,
        limits: const NativeWriteLimits(maxArtifactBytes: 1)),
        throwsA(_error('source.new_game.quota')));
    expect(fixture.files.reads, isEmpty);
  });

  test('defaults honors cancellation after the source read', () async {
    final fixture = await _fixture();
    final cancellation = ScanCancellation();
    fixture.files.onRead = (_) => cancellation.cancel();
    await expectLater(_reader.read(source: fixture.source, files: fixture.files,
        cancellation: cancellation), throwsA(_error('source.cancelled')));
  });

  group('attested source defaults', () {
    test('known libraries bind real compiled defaults without initial bag grants', () async {
      final fixture = await _fixture(oracle: true);
      final result = await _reader.read(source: fixture.source, files: fixture.files);
      expect(result, isNotNull);
      expect(result!.playerName, 'Unnamed');
      expect(result.money, 3000);
      expect(result.avatarHeaderId, 1);
      expect(result.outfit, 0);
      expect(result.facing, EntityFacing.south);
      expect(result.pcItems, ['POTION']);
      expect(result.evidence['party'], 'empty');
      expect(result.evidence['bag'], 'empty');
      expect(result.evidence['recoveryPointInferred'], isFalse);
      expect(result.evidence['sourceScriptsExecuted'], 0);
      expect(() => result.pcItems.add('ORIGINAL'), throwsUnsupportedError);
      expect(() => result.evidence['bag'] = 'changed', throwsUnsupportedError);
    });

    test('known defaults survive reordering of archive sections', () async {
      final fixture = await _fixture(oracle: true, reverseScripts: true);
      final result = await _reader.read(source: fixture.source, files: fixture.files);
      expect(result?.avatarHeaderId, 1);
      expect(result?.money, 3000);
    });

    test('known defaults reject a changed initializer even in a fresh snapshot', () async {
      final fixture = await _fixture(oracle: true, changePlayerMethod: true);
      expect(await _reader.read(source: fixture.source, files: fixture.files), isNull);
    });

    test('known defaults refuse a duplicated library', () async {
      final fixture = await _fixture(oracle: true, duplicateLibrary: true);
      expect(await _reader.read(source: fixture.source, files: fixture.files), isNull);
    });

    test('known defaults refuse an added startup library', () async {
      final fixture = await _fixture(oracle: true, addLibrary: true);
      expect(await _reader.read(source: fixture.source, files: fixture.files), isNull);
    });

    test('known defaults reject compiled and PBS money divergence', () async {
      final metadata = await File('$_oracleRoot/PBS/metadata.txt').readAsString();
      final fixture = await _fixture(oracle: true, overrides: {
        'PBS/metadata.txt': utf8.encode(metadata.replaceFirst('3000', '3001')),
      });
      await expectLater(_reader.read(source: fixture.source, files: fixture.files),
          throwsA(_error('source.new_game.metadata_mismatch')));
    });

    test('known defaults reject compiled and PBS charset divergence', () async {
      final metadata = await File('$_oracleRoot/PBS/metadata.txt').readAsString();
      final fixture = await _fixture(oracle: true, overrides: {
        'PBS/metadata.txt': utf8.encode(metadata.replaceFirst(
            'WalkCharset = player_M', 'WalkCharset = ORIGINAL_DIFFERENT')),
      });
      await expectLater(_reader.read(source: fixture.source, files: fixture.files),
          throwsA(_error('source.new_game.metadata_mismatch')));
    });
  }, skip: _oracleRoot == null ? 'Explicit source library oracle required' : false);
}
