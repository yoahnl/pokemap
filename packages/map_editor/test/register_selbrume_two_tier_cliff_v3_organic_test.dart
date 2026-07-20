import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

const _atlasRelativePath =
    'assets/tilesets/falaises_selbrume_deux_etages_v3_organic.png';
const _provenanceRelativePath =
    'assets/provenance/selbrume_two_tier_cliff_v3_organic.json';
const _tilesetId = 'ts_selbrume_cliff_two_tier_v3_organic';
const _blueprintId = 'border-blueprint-5';
const _elementPrefix = 'el_selbrume_cliff_v3_';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'registers the standalone idempotent 80-piece pack without touching maps',
    () async {
      final fixture = await _createFixture(withAtlas: true);
      addTearDown(() => fixture.root.delete(recursive: true));

      final beforeJson = _readJson(fixture.projectFile);
      final protectedMaps = utf8.encode(jsonEncode(beforeJson['maps']));
      final mapBytes = <String, List<int>>{
        for (final file in fixture.mapFiles) file.path: file.readAsBytesSync(),
      };

      final first = await _runTool(fixture.root);
      expect(first.exitCode, 0, reason: '${first.stdout}\n${first.stderr}');
      final firstBytes = fixture.projectFile.readAsBytesSync();
      final registeredJson = _readJson(fixture.projectFile);
      final manifest = ProjectManifest.fromJson(registeredJson);
      ProjectValidator.validate(manifest);

      final tilesets = (registeredJson['tilesets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final tileset = tilesets.singleWhere((item) => item['id'] == _tilesetId);
      expect(tileset['relativePath'], _atlasRelativePath);
      expect(tileset['folderId'], 'tsf_selbrume_beta_borders');
      expect(tileset['isWorldTileset'], isFalse);

      final elements = (registeredJson['elements'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((item) => (item['id'] as String).startsWith(_elementPrefix))
          .toList(growable: false);
      expect(elements, hasLength(80));
      expect(elements.map((item) => item['id']).toSet(), hasLength(80));
      expect(
        elements.map((item) => item['tilesetId']).toSet(),
        <Object?>{_tilesetId},
      );
      expect(
        elements.map((item) => item['categoryId']).toSet(),
        <Object?>{'cat_selbrume_borders'},
      );
      expect(
        elements.map((item) => item['presetKind']).toSet(),
        <Object?>{'cliff'},
      );
      expect(
        elements.map((item) => item['collisionProfile']).toSet(),
        <Object?>{null},
      );
      expect(
        elements.map((item) {
          final frame =
              (item['frames'] as List<dynamic>).single as Map<String, dynamic>;
          final source = frame['source'] as Map<String, dynamic>;
          return (source['x'], source['y']);
        }).toSet(),
        hasLength(80),
      );

      final catalog = registeredJson['borderCatalog'] as Map<String, dynamic>;
      final records =
          (catalog['records'] as List<dynamic>).cast<Map<String, dynamic>>();
      final record = records.singleWhere((item) => item['id'] == _blueprintId);
      expect(record.containsKey('latestPublished'), isFalse);
      final draft = record['draft'] as Map<String, dynamic>;
      expect(draft['baseRevision'], 0);
      final definition = draft['definition'] as Map<String, dynamic>;
      expect(definition['template'], 'stoneChainLine');
      expect(definition['defaults'], <String, Object?>{
        'irregularityPermille': 280,
        'detailDensityPermille': 0,
        'variationPermille': 1000,
        'maxOverlapPx': 9,
        'gapTolerancePx': 0,
        'depthRows': 2,
        'allowAutoRotation': false,
      });
      final primitives = (definition['primitives'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(primitives, hasLength(80));
      expect(primitives.map((item) => item['id']).toSet(), hasLength(80));
      expect(
        _frequencies(primitives, 'role'),
        <Object?, int>{
          'structureLarge': 24,
          'structureMedium': 24,
          'lineCorner': 24,
          'lineCap': 8,
        },
      );
      expect(
        _frequencies(primitives, 'authoredOrientation'),
        <Object?, int>{'north': 20, 'east': 20, 'south': 20, 'west': 20},
      );

      final provenance = _readJson(File(p.joinAll(<String>[
        fixture.root.path,
        ..._provenanceRelativePath.split('/'),
      ])));
      expect(provenance['atlasGrid'], <String, int>{'columns': 10, 'rows': 8});
      final provenanceEntries =
          (provenance['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(provenanceEntries, hasLength(80));
      for (final entry in provenanceEntries) {
        final primitiveId = entry['id'] as String;
        final primitive =
            primitives.singleWhere((item) => item['id'] == primitiveId);
        final fileStem =
            p.basenameWithoutExtension(entry['fileName'] as String);
        expect(
          primitive['sourceElementId'],
          '$_elementPrefix$fileStem',
          reason: primitiveId,
        );
        expect(
          primitive['role'],
          switch (entry['role']) {
            'top' => 'structureLarge',
            'face' => 'structureMedium',
            'lineCorner' => 'lineCorner',
            'lineCap' => 'lineCap',
            final role => fail('Unexpected provenance role: $role'),
          },
          reason: primitiveId,
        );
        expect(
          primitive['weight'],
          primitiveId.contains('-top-') && primitiveId.endsWith('-06')
              ? 1
              : 1000,
          reason: '$primitiveId topology readiness weight',
        );
        expect(
          primitive['authoredOrientation'],
          entry['authoredOrientation'],
          reason: primitiveId,
        );
        expect(primitive['anchorPx'], entry['anchorPx'], reason: primitiveId);
        expect(
          primitive['transforms'],
          <String, Object?>{
            'allowFlipX': false,
            'allowedQuarterTurns': <int>[0, 1, 2, 3],
          },
          reason: primitiveId,
        );
        final sourceElement = elements.singleWhere(
          (item) => item['id'] == primitive['sourceElementId'],
        );
        final frame = (sourceElement['frames'] as List<dynamic>).single
            as Map<String, dynamic>;
        final source = frame['source'] as Map<String, dynamic>;
        final atlasCell = entry['atlasCell'] as Map<String, dynamic>;
        expect(
          <String, Object?>{'x': source['x'], 'y': source['y']},
          <String, Object?>{
            'x': atlasCell['column'],
            'y': atlasCell['row'],
          },
          reason: primitiveId,
        );
        final metrics = primitive['currentMetrics'] as Map<String, dynamic>;
        expect(
          metrics['assetFingerprint'],
          matches(RegExp(r'^sha256:[0-9a-f]{64}$')),
          reason: primitiveId,
        );
        expect(
          metrics['pixelSize'],
          <String, int>{'width': 32, 'height': 32},
          reason: primitiveId,
        );
        expect(
          (metrics['opaqueBounds'] as Map<String, dynamic>)['width'],
          greaterThan(0),
          reason: primitiveId,
        );
        expect(
          metrics['occupancyMaskRle'],
          startsWith('border-rle-v1:1024:'),
          reason: primitiveId,
        );
      }

      expect(utf8.encode(jsonEncode(registeredJson['maps'])), protectedMaps);
      for (final entry in mapBytes.entries) {
        expect(File(entry.key).readAsBytesSync(), entry.value);
      }

      final second = await _runTool(fixture.root);
      expect(second.exitCode, 0, reason: '${second.stdout}\n${second.stderr}');
      expect(fixture.projectFile.readAsBytesSync(), firstBytes);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('refuses a missing atlas before changing the project', () async {
    final fixture = await _createFixture(withAtlas: false);
    addTearDown(() => fixture.root.delete(recursive: true));
    final projectBytes = fixture.projectFile.readAsBytesSync();
    final mapBytes = <String, List<int>>{
      for (final file in fixture.mapFiles) file.path: file.readAsBytesSync(),
    };

    final result = await _runTool(fixture.root);

    expect(result.exitCode, isNot(0));
    expect('${result.stdout}\n${result.stderr}',
        contains('Missing V3 organic atlas'));
    expect(fixture.projectFile.readAsBytesSync(), projectBytes);
    for (final entry in mapBytes.entries) {
      expect(File(entry.key).readAsBytesSync(), entry.value);
    }
  });
}

Future<_Fixture> _createFixture({required bool withAtlas}) async {
  final root = await Directory.systemTemp.createTemp('selbrume_v3_register_');
  final sourceProject = File(
    p.normalize(
      p.absolute(p.join(
          Directory.current.path, '..', '..', 'selbrume', 'project.json')),
    ),
  );
  final raw = _readJson(sourceProject);
  (raw['tilesets'] as List<dynamic>).removeWhere(
    (item) {
      final id = (item as Map<String, dynamic>)['id'];
      return id == _tilesetId || id == 'ts_selbrume_cliff_two_tier_v2';
    },
  );
  (raw['elements'] as List<dynamic>).removeWhere(
    (item) {
      final id = (item as Map<String, dynamic>)['id'] as String;
      return id.startsWith(_elementPrefix) ||
          id.startsWith('el_selbrume_cliff_top_') ||
          id.startsWith('el_selbrume_cliff_face_');
    },
  );
  final catalog = raw['borderCatalog'] as Map<String, dynamic>;
  (catalog['records'] as List<dynamic>).removeWhere(
    (item) {
      final id = (item as Map<String, dynamic>)['id'];
      return id == _blueprintId || id == 'border-blueprint-4';
    },
  );
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(raw)}\n',
    flush: true,
  );

  final mapFiles = <File>[
    File(p.join(root.path, 'maps', 'coast.json')),
    File(p.join(root.path, 'maps', 'nested', 'harbour.json')),
  ];
  await mapFiles[0].parent.create(recursive: true);
  await mapFiles[1].parent.create(recursive: true);
  await mapFiles[0].writeAsString('{"sentinel":"coast"}\n', flush: true);
  await mapFiles[1].writeAsString('{"sentinel":"harbour"}\n', flush: true);

  final sourceProvenance = File(
    p.normalize(
      p.absolute(p.joinAll(<String>[
        Directory.current.path,
        '..',
        '..',
        'selbrume',
        ..._provenanceRelativePath.split('/'),
      ])),
    ),
  );
  final fixtureProvenance = File(p.joinAll(<String>[
    root.path,
    ..._provenanceRelativePath.split('/'),
  ]));
  await fixtureProvenance.parent.create(recursive: true);
  await sourceProvenance.copy(fixtureProvenance.path);

  if (withAtlas) {
    final atlasFile = File(p.joinAll(<String>[
      root.path,
      ..._atlasRelativePath.split('/'),
    ]));
    await atlasFile.parent.create(recursive: true);
    final atlas = img.Image(width: 320, height: 256, numChannels: 4);
    for (var index = 0; index < 80; index += 1) {
      final cellX = (index % 10) * 32;
      final cellY = (index ~/ 10) * 32;
      final left = cellX + 4 + index % 4;
      final top = cellY + 3 + index % 5;
      final width = 9 + index % 7;
      final height = 8 + index % 11;
      for (var y = top; y < top + height; y += 1) {
        for (var x = left; x < left + width; x += 1) {
          atlas.setPixelRgba(
            x,
            y,
            75 + index * 3,
            70 + index * 2,
            60 + index,
            255,
          );
        }
      }
    }
    await atlasFile.writeAsBytes(img.encodePng(atlas), flush: true);
  }

  return _Fixture(root: root, projectFile: projectFile, mapFiles: mapFiles);
}

Future<ProcessResult> _runTool(Directory projectRoot) => Process.run(
      'dart',
      <String>[
        'run',
        'tool/register_selbrume_two_tier_cliff_v3_organic.dart',
        '--project-root',
        projectRoot.path,
      ],
      workingDirectory: Directory.current.path,
    );

Map<String, dynamic> _readJson(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

Map<Object?, int> _frequencies(
  Iterable<Map<String, dynamic>> values,
  String key,
) {
  final result = <Object?, int>{};
  for (final value in values) {
    result.update(value[key], (count) => count + 1, ifAbsent: () => 1);
  }
  return result;
}

final class _Fixture {
  const _Fixture({
    required this.root,
    required this.projectFile,
    required this.mapFiles,
  });

  final Directory root;
  final File projectFile;
  final List<File> mapFiles;
}
