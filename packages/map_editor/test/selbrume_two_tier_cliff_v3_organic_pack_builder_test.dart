import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../tool/build_selbrume_two_tier_cliff_v3_organic_pack.dart';

const _topTangentSpans = <int>[18, 19, 20, 21, 22, 32];
const _topVisibleNormalSpans = <int>[11, 12, 11, 12, 12, 13];
const _topLandwardProtrusionPx = 3;
const _topNormalSpans = <int>[14, 15, 14, 15, 15, 16];
const _topVisibleTangentSpans = <int>[14, 15, 16, 17, 18, 24];
const _faceTangentSpans = <int>[18, 19, 20, 20, 21, 22];
const _faceNormalSpans = <int>[25, 26, 25, 27, 28, 29];
const _faceFrontGaps = <int>[2, 2, 2, 2, 3, 3];
const _cornerTangentSpans = <int>[14, 16, 15, 17, 16, 18];
const _cornerNormalSpans = <int>[12, 14, 13, 15, 14, 16];
const _cornerVisibleTangentSpans = <int>[10, 12, 11, 13, 12, 14];
const _capTangentSpans = <int>[16, 18];
const _capNormalSpans = <int>[9, 11];
const _capVisibleTangentSpans = <int>[12, 14];
const _topLandwardOverlapPx = 4;
const _topLandwardSealDepthPx = 4;
const _cornerAnchorNormalSpans = <int>[9, 10, 9, 10, 10, 11];
const _topSourceColumns = <int>[0, 1, 2, 3, 4, 5];
const _faceSourceColumns = <int>[0, 1, 2, 3, 4, 6];
const _cornerSourceColumns = <int>[0, 1, 2, 3, 4, 5];
const _capSourceColumns = <int>[1, 3];
const _orientations = <String>['n', 'e', 's', 'w'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds the deterministic 80-asset V3 organic pack', () async {
    final sheets = _checkedInSheets();
    final firstRoot = await Directory.systemTemp.createTemp(
      'selbrume_two_tier_v3_organic_first_',
    );
    final secondRoot = await Directory.systemTemp.createTemp(
      'selbrume_two_tier_v3_organic_second_',
    );
    addTearDown(() => firstRoot.delete(recursive: true));
    addTearDown(() => secondRoot.delete(recursive: true));

    final first = await _build(sheets, firstRoot);
    final second = await _build(sheets, secondRoot);

    expect(first.sourceFiles, hasLength(80));
    expect(
      first.sourceFiles.map((file) => p.basename(file.path)).toSet(),
      _expectedSourceNames(),
    );
    expect(first.atlasSha256, second.atlasSha256);
    expect(
      first.outputAtlas.readAsBytesSync(),
      orderedEquals(second.outputAtlas.readAsBytesSync()),
    );
    expect(
      first.provenance.readAsBytesSync(),
      orderedEquals(second.provenance.readAsBytesSync()),
    );
    for (var index = 0; index < first.sourceFiles.length; index += 1) {
      expect(
        first.sourceFiles[index].readAsBytesSync(),
        orderedEquals(second.sourceFiles[index].readAsBytesSync()),
        reason: p.basename(first.sourceFiles[index].path),
      );
    }

    final alphaFingerprints = <String>{};
    final sourceHashes = <String>{};
    for (final file in first.sourceFiles) {
      final name = p.basename(file.path);
      final sprite = _decode(file.readAsBytesSync());
      expect((sprite.width, sprite.height), (32, 32), reason: name);
      expect(_alphaValues(sprite), <int>{0, 255}, reason: name);
      expect(_opaqueComponentCount(sprite), 1, reason: name);
      expect(
        alphaFingerprints.add(_alphaFingerprint(sprite)),
        isTrue,
        reason: '$name must have a unique silhouette.',
      );
      expect(
        sourceHashes.add(sha256.convert(file.readAsBytesSync()).toString()),
        isTrue,
        reason: '$name must have unique PNG bytes.',
      );
      final parsed = _parseName(name);
      final expectedTangent = _expectedTangentSpan(parsed);
      final expectedNormal = _expectedNormalSpan(parsed);
      final bounds = _opaqueBounds(sprite);
      final actualTangent =
          parsed.orientation == 'n' || parsed.orientation == 's'
              ? bounds.$3
              : bounds.$4;
      final actualNormal =
          parsed.orientation == 'n' || parsed.orientation == 's'
              ? bounds.$4
              : bounds.$3;
      expect(actualTangent, expectedTangent, reason: name);
      expect(actualNormal, expectedNormal, reason: name);
      if (parsed.role == 'corner') {
        expect(bounds.$3, lessThanOrEqualTo(18), reason: name);
        expect(bounds.$4, lessThanOrEqualTo(18), reason: name);
      }
      if (parsed.role != 'top') {
        expect(
          _rearContactRun(sprite, parsed.orientation),
          greaterThanOrEqualTo(10),
          reason: '$name needs a ten-pixel organic rear interlock.',
        );
      }
      if (parsed.role == 'top') {
        expect(
          expectedNormal - _expectedVisibleNormalSpan(parsed),
          _topLandwardProtrusionPx,
          reason:
              '$name must reserve only the three terrain protrusion pixels.',
        );
        expect(
          _topSealLandwardEdge(bounds, parsed.orientation),
          _topPathCoordinate(
            _expectedAnchor(parsed),
            parsed.orientation,
          ),
          reason: '$name must keep the continuous seal on the authored path.',
        );
        expect(
          _landwardSealPixelCount(
            sprite,
            parsed.orientation,
            depthPx: _topLandwardSealDepthPx,
            protrusionPx: _topLandwardProtrusionPx,
          ),
          expectedTangent * _topLandwardSealDepthPx,
          reason:
              '$name must keep ocean pixels away from the terrain-facing edge.',
        );
        expect(
          _landwardSealColorCount(
            sprite,
            parsed.orientation,
            depthPx: _topLandwardSealDepthPx,
            protrusionPx: _topLandwardProtrusionPx,
          ),
          greaterThanOrEqualTo(4),
          reason:
              '$name must read as textured stone caps instead of a flat bar.',
        );
        final protrusionDepths = _landwardProtrusionDepths(
          sprite,
          parsed.orientation,
          protrusionPx: _topLandwardProtrusionPx,
        );
        expect(protrusionDepths, contains(0), reason: name);
        expect(protrusionDepths, contains(_topLandwardProtrusionPx),
            reason: name);
        expect(
          protrusionDepths.any(
            (depth) => depth > 0 && depth < _topLandwardProtrusionPx,
          ),
          isTrue,
          reason: '$name needs an irregular terrain-facing stone silhouette.',
        );
        expect(
          _rearContactRun(sprite, parsed.orientation),
          lessThan(expectedTangent),
          reason: '$name must not expose a straight outer terrain edge.',
        );
      }
      if (parsed.role == 'top' ||
          parsed.role == 'corner' ||
          parsed.role == 'cap') {
        expect(
          _tangentStartContactRun(sprite, parsed.orientation),
          greaterThanOrEqualTo(2),
          reason: '$name needs a robust start contact.',
        );
        expect(
          _tangentEndContactRun(sprite, parsed.orientation),
          greaterThanOrEqualTo(2),
          reason: '$name needs a robust end contact.',
        );
      }
      expect(
        _averageLuminance(sprite, upperLeft: true),
        greaterThan(_averageLuminance(sprite, upperLeft: false)),
        reason: '$name must retain a brighter upper-left world light.',
      );
    }
    expect(alphaFingerprints, hasLength(80));
    expect(sourceHashes, hasLength(80));

    final atlas = _decode(first.outputAtlas.readAsBytesSync());
    expect((atlas.width, atlas.height), (320, 256));
    expect(_alphaValues(atlas), <int>{0, 255});
    expect(
      first.atlasSha256,
      sha256.convert(first.outputAtlas.readAsBytesSync()).toString(),
    );

    final provenance =
        jsonDecode(first.provenance.readAsStringSync()) as Map<String, dynamic>;
    expect(provenance['schemaVersion'], 1);
    expect(provenance['packVersion'], 3);
    expect(provenance['packId'], 'selbrume_two_tier_cliff_v3_organic');
    expect(provenance['status'], 'candidate');
    expect(provenance['collisionIntent'], 'visual_only_no_collision');
    expect(
      provenance['normalizationPolicy'],
      'nearest_palette_compact_visible_stone_v10_diverse',
    );
    expect(provenance['usesToneRedistribution'], isFalse);
    expect(provenance['atlasSha256'], first.atlasSha256);
    expect(
      provenance['atlasGrid'],
      <String, int>{'columns': 10, 'rows': 8},
    );
    final rawSheets = provenance['rawSheets'] as Map<String, dynamic>;
    expect(rawSheets.keys.toSet(), <String>{'top', 'face', 'corner'});
    expect(
      (rawSheets['top'] as Map<String, dynamic>)['sha256'],
      sha256.convert(sheets.top.readAsBytesSync()).toString(),
    );
    expect(
      (rawSheets['face'] as Map<String, dynamic>)['sha256'],
      sha256.convert(sheets.face.readAsBytesSync()).toString(),
    );
    expect(
      (rawSheets['corner'] as Map<String, dynamic>)['sha256'],
      sha256.convert(sheets.corner.readAsBytesSync()).toString(),
    );
    expect(
      (rawSheets['face'] as Map<String, dynamic>)['grid'],
      <String, int>{'columns': 7, 'rows': 4},
    );
    expect(
      (rawSheets['corner'] as Map<String, dynamic>)['selectedColumns'],
      _cornerSourceColumns,
    );

    final entries =
        (provenance['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(entries, hasLength(80));
    expect(
      <String, int>{
        for (final role in <String>['top', 'face', 'lineCorner', 'lineCap'])
          role: entries.where((entry) => entry['role'] == role).length,
      },
      <String, int>{
        'top': 24,
        'face': 24,
        'lineCorner': 24,
        'lineCap': 8,
      },
    );
    expect(
      entries.take(24).map((entry) => entry['assetFamily']).toSet(),
      <Object?>{'top'},
    );
    expect(
      entries.skip(24).take(24).map((entry) => entry['assetFamily']).toSet(),
      <Object?>{'face'},
    );
    expect(
      entries.skip(48).take(24).map((entry) => entry['assetFamily']).toSet(),
      <Object?>{'corner'},
    );
    expect(
      entries.skip(72).take(8).map((entry) => entry['assetFamily']).toSet(),
      <Object?>{'cap'},
    );
    final rebuiltAtlas = img.Image(width: 320, height: 256, numChannels: 4);
    for (var index = 0; index < entries.length; index += 1) {
      final entry = entries[index];
      final name = entry['fileName'] as String;
      final parsed = _parseName(name);
      final sourceFile = first.sourceFiles.singleWhere(
        (file) => p.basename(file.path) == name,
      );
      final sourceBytes = sourceFile.readAsBytesSync();
      final atlasCell = entry['atlasCell'] as Map<String, dynamic>;
      final selectedCell = entry['selectedSourceCell'] as Map<String, dynamic>;
      final expectedSourceColumn = _expectedSourceColumn(parsed);

      expect(
          entry['id'],
          'selbrume-cliff-v3-organic-${parsed.role}-'
          '${parsed.orientation}-${parsed.variant.toString().padLeft(2, '0')}');
      expect(
        entry['sourceRelativePath'],
        'assets/sources/border_studio/two_tier_cliff_v3_organic/$name',
      );
      expect(entry['sha256'], sha256.convert(sourceBytes).toString());
      expect(entry['role'], _expectedProvenanceRole(parsed.role));
      expect(entry['assetFamily'], parsed.role);
      expect(entry['sourceStoneCount'], 1);
      expect(entry.containsKey('composedSourceCells'), isFalse);
      expect(
          entry['authoredOrientation'], _orientationName(parsed.orientation));
      expect(entry['anchorPx'], _expectedAnchor(parsed));
      expect(
        entry['frontGapPx'],
        parsed.role == 'face' ? _faceFrontGaps[parsed.variant - 1] : 0,
      );
      expect(
        entry['landwardOverlapPx'],
        parsed.role == 'top' ? _topLandwardOverlapPx : 0,
      );
      expect(
        entry['landwardSealDepthPx'],
        parsed.role == 'top' ? _topLandwardSealDepthPx : 0,
      );
      expect(
        entry['landwardSealStyle'],
        parsed.role == 'top' ? 'nearest_original_stone_shadow' : 'none',
      );
      expect(
        entry['landwardProtrusionPx'],
        parsed.role == 'top' ? _topLandwardProtrusionPx : 0,
      );
      expect(entry['tangentSpanPx'], _expectedTangentSpan(parsed));
      expect(
        entry['visibleTangentSpanPx'],
        _expectedVisibleTangentSpan(parsed),
      );
      expect(entry['normalSpanPx'], _expectedNormalSpan(parsed));
      expect(
        entry['visibleNormalSpanPx'],
        _expectedVisibleNormalSpan(parsed),
      );
      expect(
        entry['selectedSourceSheet'],
        parsed.role == 'cap' ? 'top' : parsed.role,
      );
      final sprite = _decode(sourceBytes);
      expect(
        entry['rearContactRunPx'],
        _rearContactRun(sprite, parsed.orientation),
      );
      expect(
        entry['tangentStartContactRunPx'],
        _tangentStartContactRun(sprite, parsed.orientation),
      );
      expect(
        entry['tangentEndContactRunPx'],
        _tangentEndContactRun(sprite, parsed.orientation),
      );
      expect(
        selectedCell,
        <String, int>{
          'column': expectedSourceColumn,
          'row': _orientations.indexOf(parsed.orientation),
        },
      );
      expect(
        atlasCell,
        <String, int>{'column': index % 10, 'row': index ~/ 10},
      );
      expect(entry['alphaMaskSha256'], _alphaFingerprint(_decode(sourceBytes)));
      img.compositeImage(
        rebuiltAtlas,
        _decode(sourceBytes),
        dstX: (atlasCell['column'] as int) * 32,
        dstY: (atlasCell['row'] as int) * 32,
      );
    }
    expect(
      img.encodePng(rebuiltAtlas),
      orderedEquals(first.outputAtlas.readAsBytesSync()),
    );
  });

  test('rejects an incomplete raw sheet before replacing any V3 output',
      () async {
    final sheets = _checkedInSheets();
    final fixtureRoot = await Directory.systemTemp.createTemp(
      'selbrume_two_tier_v3_organic_incomplete_',
    );
    final projectRoot = await Directory.systemTemp.createTemp(
      'selbrume_two_tier_v3_organic_atomic_',
    );
    addTearDown(() => fixtureRoot.delete(recursive: true));
    addTearDown(() => projectRoot.delete(recursive: true));
    final incompleteTop = File(p.join(fixtureRoot.path, 'top.png'));
    final raw = _decode(sheets.top.readAsBytesSync());
    for (var y = 0; y < raw.height ~/ 4; y += 1) {
      for (var x = 0; x < raw.width ~/ 6; x += 1) {
        raw.setPixelRgba(x, y, 255, 0, 255, 255);
      }
    }
    incompleteTop.writeAsBytesSync(img.encodePng(raw));
    final atlas = File(
      p.join(projectRoot.path, selbrumeTwoTierCliffV3OrganicAtlasRelativePath),
    )
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3]);
    final provenance = File(
      p.join(
        projectRoot.path,
        selbrumeTwoTierCliffV3OrganicProvenanceRelativePath,
      ),
    )
      ..createSync(recursive: true)
      ..writeAsStringSync('sentinel');

    await expectLater(
      buildSelbrumeTwoTierCliffV3OrganicPack(
        _options(
          sheets: (
            top: incompleteTop,
            face: sheets.face,
            corner: sheets.corner,
          ),
          projectRoot: projectRoot,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('exactly 24'),
        ),
      ),
    );

    expect(atlas.readAsBytesSync(), <int>[1, 2, 3]);
    expect(provenance.readAsStringSync(), 'sentinel');
    final sourceDirectory = Directory(
      p.join(
        projectRoot.path,
        selbrumeTwoTierCliffV3OrganicSourceRelativePath,
      ),
    );
    expect(sourceDirectory.existsSync(), isFalse);
  });

  test('rolls back every V3 artifact when a destination is invalid', () async {
    final sheets = _checkedInSheets();
    final projectRoot = await Directory.systemTemp.createTemp(
      'selbrume_two_tier_v3_organic_rollback_',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    final sourceDirectory = Directory(
      p.join(
        projectRoot.path,
        selbrumeTwoTierCliffV3OrganicSourceRelativePath,
      ),
    )..createSync(recursive: true);
    final sentinelSource = File(p.join(sourceDirectory.path, 'top_n_01.png'))
      ..writeAsBytesSync(<int>[9, 8, 7]);
    final provenance = File(
      p.join(
        projectRoot.path,
        selbrumeTwoTierCliffV3OrganicProvenanceRelativePath,
      ),
    )
      ..createSync(recursive: true)
      ..writeAsStringSync('provenance-sentinel');
    final atlasDirectory = Directory(
      p.join(projectRoot.path, selbrumeTwoTierCliffV3OrganicAtlasRelativePath),
    )..createSync(recursive: true);

    await expectLater(
      buildSelbrumeTwoTierCliffV3OrganicPack(
        _options(sheets: sheets, projectRoot: projectRoot),
      ),
      throwsA(anything),
    );

    expect(sentinelSource.readAsBytesSync(), <int>[9, 8, 7]);
    expect(
      sourceDirectory.listSync().map((entry) => p.basename(entry.path)),
      orderedEquals(<String>['top_n_01.png']),
    );
    expect(provenance.readAsStringSync(), 'provenance-sentinel');
    expect(atlasDirectory.existsSync(), isTrue);
  });
}

({File top, File face, File corner}) _checkedInSheets() {
  final projectRoot = p.normalize(
    p.absolute(p.join(Directory.current.path, '..', '..', 'selbrume')),
  );
  final rawRoot = p.join(
    projectRoot,
    'assets',
    'sources',
    'border_studio',
    'two_tier_cliff_v3_organic',
    'raw',
  );
  final sheets = (
    top: File(p.join(rawRoot, 'top_lip_stones_6x4.png')),
    face: File(p.join(rawRoot, 'individual_face_stones_7x4.png')),
    corner: File(p.join(rawRoot, 'individual_turn_stones_6x4.png')),
  );
  expect(sheets.top.existsSync(), isTrue);
  expect(sheets.face.existsSync(), isTrue);
  expect(sheets.corner.existsSync(), isTrue);
  return sheets;
}

Future<SelbrumeTwoTierCliffV3OrganicPackBuildResult> _build(
  ({File top, File face, File corner}) sheets,
  Directory projectRoot,
) =>
    buildSelbrumeTwoTierCliffV3OrganicPack(
      _options(sheets: sheets, projectRoot: projectRoot),
    );

SelbrumeTwoTierCliffV3OrganicPackOptions _options({
  required ({File top, File face, File corner}) sheets,
  required Directory projectRoot,
}) =>
    SelbrumeTwoTierCliffV3OrganicPackOptions(
      topSheet: sheets.top,
      faceSheet: sheets.face,
      cornerSheet: sheets.corner,
      projectRoot: projectRoot,
      outputAtlas: File(
        p.join(
          projectRoot.path,
          selbrumeTwoTierCliffV3OrganicAtlasRelativePath,
        ),
      ),
      provenance: File(
        p.join(
          projectRoot.path,
          selbrumeTwoTierCliffV3OrganicProvenanceRelativePath,
        ),
      ),
    );

Set<String> _expectedSourceNames() => <String>{
      for (final role in const <String>['top', 'face'])
        for (final orientation in _orientations)
          for (var variant = 1; variant <= 6; variant += 1)
            '${role}_${orientation}_${variant.toString().padLeft(2, '0')}.png',
      for (final role in const <String>['corner'])
        for (final orientation in _orientations)
          for (var variant = 1; variant <= 6; variant += 1)
            '${role}_${orientation}_${variant.toString().padLeft(2, '0')}.png',
      for (final role in const <String>['cap'])
        for (final orientation in _orientations)
          for (var variant = 1; variant <= 2; variant += 1)
            '${role}_${orientation}_${variant.toString().padLeft(2, '0')}.png',
    };

int _expectedTangentSpan(
  ({String role, String orientation, int variant}) parsed,
) =>
    switch (parsed.role) {
      'top' => _topTangentSpans[parsed.variant - 1],
      'face' => _faceTangentSpans[parsed.variant - 1],
      'corner' => _cornerTangentSpans[parsed.variant - 1],
      'cap' => _capTangentSpans[parsed.variant - 1],
      _ => throw ArgumentError.value(parsed.role),
    };

int _expectedVisibleTangentSpan(
  ({String role, String orientation, int variant}) parsed,
) =>
    switch (parsed.role) {
      'top' => _topVisibleTangentSpans[parsed.variant - 1],
      'face' => _faceTangentSpans[parsed.variant - 1],
      'corner' => _cornerVisibleTangentSpans[parsed.variant - 1],
      'cap' => _capVisibleTangentSpans[parsed.variant - 1],
      _ => throw ArgumentError.value(parsed.role),
    };

int _expectedNormalSpan(
  ({String role, String orientation, int variant}) parsed,
) =>
    switch (parsed.role) {
      'top' => _topNormalSpans[parsed.variant - 1],
      'face' => _faceNormalSpans[parsed.variant - 1],
      'corner' => _cornerNormalSpans[parsed.variant - 1],
      'cap' => _capNormalSpans[parsed.variant - 1],
      _ => throw ArgumentError.value(parsed.role),
    };

int _expectedVisibleNormalSpan(
  ({String role, String orientation, int variant}) parsed,
) =>
    parsed.role == 'top'
        ? _topVisibleNormalSpans[parsed.variant - 1]
        : _expectedNormalSpan(parsed);

int _expectedSourceColumn(
  ({String role, String orientation, int variant}) parsed,
) =>
    switch (parsed.role) {
      'top' => _topSourceColumns[parsed.variant - 1],
      'face' => _faceSourceColumns[parsed.variant - 1],
      'corner' => _cornerSourceColumns[parsed.variant - 1],
      'cap' => _capSourceColumns[parsed.variant - 1],
      _ => throw ArgumentError.value(parsed.role),
    };

String _expectedProvenanceRole(String family) => switch (family) {
      'corner' => 'lineCorner',
      'cap' => 'lineCap',
      'top' || 'face' => family,
      _ => throw ArgumentError.value(family),
    };

({String role, String orientation, int variant}) _parseName(String name) {
  final parts = p.basenameWithoutExtension(name).split('_');
  if (parts.length != 3) throw StateError('Unexpected V3 source name: $name');
  return (
    role: parts[0],
    orientation: parts[1],
    variant: int.parse(parts[2]),
  );
}

String _orientationName(String wire) => switch (wire) {
      'n' => 'north',
      'e' => 'east',
      's' => 'south',
      'w' => 'west',
      _ => throw ArgumentError.value(wire),
    };

Map<String, int> _expectedAnchor(
  ({String role, String orientation, int variant}) parsed,
) {
  final normal = parsed.role == 'corner'
      ? _cornerAnchorNormalSpans[parsed.variant - 1]
      : parsed.role == 'top'
          ? _expectedVisibleNormalSpan(parsed)
          : _expectedNormalSpan(parsed);
  final isFace = parsed.role == 'face';
  final gap = isFace ? _faceFrontGaps[parsed.variant - 1] : 0;
  final landwardOverlap = parsed.role == 'top' ? _topLandwardOverlapPx : 0;
  final anchor = switch (parsed.orientation) {
    'n' => (
        16,
        isFace ? normal + gap - 1 : normal - landwardOverlap - 1,
      ),
    'e' => (
        isFace ? 32 - normal - gap : 32 - normal + landwardOverlap,
        16,
      ),
    's' => (
        16,
        isFace ? 32 - normal - gap : 32 - normal + landwardOverlap,
      ),
    'w' => (
        isFace ? normal + gap - 1 : normal - landwardOverlap - 1,
        16,
      ),
    _ => throw ArgumentError.value(parsed.orientation),
  };
  return <String, int>{'x': anchor.$1, 'y': anchor.$2};
}

img.Image _decode(List<int> bytes) {
  final decoded = img.decodePng(Uint8List.fromList(bytes));
  if (decoded == null) throw StateError('Expected PNG bytes.');
  return decoded;
}

Set<int> _alphaValues(img.Image image) =>
    <int>{for (final pixel in image) pixel.a.toInt()};

String _alphaFingerprint(img.Image image) => sha256.convert(<int>[
      for (final pixel in image) pixel.a.toInt() == 0 ? 0 : 1,
    ]).toString();

(int, int, int, int) _opaqueBounds(img.Image image) {
  var left = image.width;
  var top = image.height;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      if (image.getPixel(x, y).a.toInt() == 0) continue;
      if (x < left) left = x;
      if (y < top) top = y;
      if (x > right) right = x;
      if (y > bottom) bottom = y;
    }
  }
  if (right < left || bottom < top) return (0, 0, 0, 0);
  return (left, top, right - left + 1, bottom - top + 1);
}

int _opaqueComponentCount(img.Image image) {
  final visited = List<bool>.filled(image.width * image.height, false);
  var components = 0;
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      final index = y * image.width + x;
      if (visited[index] || image.getPixel(x, y).a.toInt() == 0) continue;
      components += 1;
      final pending = <(int, int)>[(x, y)];
      visited[index] = true;
      while (pending.isNotEmpty) {
        final current = pending.removeLast();
        for (final delta in const <(int, int)>[
          (-1, 0),
          (1, 0),
          (0, -1),
          (0, 1),
        ]) {
          final nextX = current.$1 + delta.$1;
          final nextY = current.$2 + delta.$2;
          if (nextX < 0 ||
              nextY < 0 ||
              nextX >= image.width ||
              nextY >= image.height) {
            continue;
          }
          final nextIndex = nextY * image.width + nextX;
          if (visited[nextIndex] ||
              image.getPixel(nextX, nextY).a.toInt() == 0) {
            continue;
          }
          visited[nextIndex] = true;
          pending.add((nextX, nextY));
        }
      }
    }
  }
  return components;
}

double _averageLuminance(img.Image image, {required bool upperLeft}) {
  final bounds = _opaqueBounds(image);
  final diagonalMidpoint = (bounds.$3 - 1 + bounds.$4 - 1) / 2;
  var total = 0.0;
  var count = 0;
  for (final pixel in image) {
    if (pixel.a.toInt() == 0) continue;
    final inUpperLeft =
        pixel.x - bounds.$1 + pixel.y - bounds.$2 < diagonalMidpoint;
    if (inUpperLeft != upperLeft) continue;
    total += pixel.r.toInt() * 0.2126 +
        pixel.g.toInt() * 0.7152 +
        pixel.b.toInt() * 0.0722;
    count += 1;
  }
  return count == 0 ? 0 : total / count;
}

int _rearContactRun(img.Image image, String orientation) {
  final bounds = _opaqueBounds(image);
  return switch (orientation) {
    'n' => _opaqueHorizontalRun(
        image,
        y: bounds.$2 + bounds.$4 - 1,
        fromX: bounds.$1,
        toX: bounds.$1 + bounds.$3 - 1,
      ),
    'e' => _opaqueVerticalRun(
        image,
        x: bounds.$1,
        fromY: bounds.$2,
        toY: bounds.$2 + bounds.$4 - 1,
      ),
    's' => _opaqueHorizontalRun(
        image,
        y: bounds.$2,
        fromX: bounds.$1,
        toX: bounds.$1 + bounds.$3 - 1,
      ),
    'w' => _opaqueVerticalRun(
        image,
        x: bounds.$1 + bounds.$3 - 1,
        fromY: bounds.$2,
        toY: bounds.$2 + bounds.$4 - 1,
      ),
    _ => throw ArgumentError.value(orientation),
  };
}

int _landwardSealPixelCount(
  img.Image image,
  String orientation, {
  required int depthPx,
  required int protrusionPx,
}) {
  final bounds = _opaqueBounds(image);
  final left = bounds.$1;
  final top = bounds.$2;
  final right = left + bounds.$3 - 1;
  final bottom = top + bounds.$4 - 1;
  final sealBounds = switch (orientation) {
    'n' => (
        left,
        bottom - protrusionPx - depthPx + 1,
        right,
        bottom - protrusionPx,
      ),
    'e' => (
        left + protrusionPx,
        top,
        left + protrusionPx + depthPx - 1,
        bottom,
      ),
    's' => (
        left,
        top + protrusionPx,
        right,
        top + protrusionPx + depthPx - 1,
      ),
    'w' => (
        right - protrusionPx - depthPx + 1,
        top,
        right - protrusionPx,
        bottom,
      ),
    _ => throw ArgumentError.value(orientation),
  };
  var count = 0;
  for (var y = sealBounds.$2; y <= sealBounds.$4; y += 1) {
    for (var x = sealBounds.$1; x <= sealBounds.$3; x += 1) {
      if (image.getPixel(x, y).a.toInt() != 0) count += 1;
    }
  }
  return count;
}

int _landwardSealColorCount(
  img.Image image,
  String orientation, {
  required int depthPx,
  required int protrusionPx,
}) {
  final bounds = _opaqueBounds(image);
  final left = bounds.$1;
  final top = bounds.$2;
  final right = left + bounds.$3 - 1;
  final bottom = top + bounds.$4 - 1;
  final sealBounds = switch (orientation) {
    'n' => (
        left,
        bottom - protrusionPx - depthPx + 1,
        right,
        bottom - protrusionPx,
      ),
    'e' => (
        left + protrusionPx,
        top,
        left + protrusionPx + depthPx - 1,
        bottom,
      ),
    's' => (
        left,
        top + protrusionPx,
        right,
        top + protrusionPx + depthPx - 1,
      ),
    'w' => (
        right - protrusionPx - depthPx + 1,
        top,
        right - protrusionPx,
        bottom,
      ),
    _ => throw ArgumentError.value(orientation),
  };
  return <(int, int, int)>{
    for (var y = sealBounds.$2; y <= sealBounds.$4; y += 1)
      for (var x = sealBounds.$1; x <= sealBounds.$3; x += 1)
        (
          image.getPixel(x, y).r.toInt(),
          image.getPixel(x, y).g.toInt(),
          image.getPixel(x, y).b.toInt(),
        ),
  }.length;
}

List<int> _landwardProtrusionDepths(
  img.Image image,
  String orientation, {
  required int protrusionPx,
}) {
  final bounds = _opaqueBounds(image);
  final left = bounds.$1;
  final top = bounds.$2;
  final right = left + bounds.$3 - 1;
  final bottom = top + bounds.$4 - 1;
  return switch (orientation) {
    'n' => <int>[
        for (var x = left; x <= right; x += 1)
          _consecutiveOpaqueRun(
            image,
            points: <(int, int)>[
              for (var step = 1; step <= protrusionPx; step += 1)
                (x, bottom - protrusionPx + step),
            ],
          ),
      ],
    'e' => <int>[
        for (var y = top; y <= bottom; y += 1)
          _consecutiveOpaqueRun(
            image,
            points: <(int, int)>[
              for (var step = 1; step <= protrusionPx; step += 1)
                (left + protrusionPx - step, y),
            ],
          ),
      ],
    's' => <int>[
        for (var x = left; x <= right; x += 1)
          _consecutiveOpaqueRun(
            image,
            points: <(int, int)>[
              for (var step = 1; step <= protrusionPx; step += 1)
                (x, top + protrusionPx - step),
            ],
          ),
      ],
    'w' => <int>[
        for (var y = top; y <= bottom; y += 1)
          _consecutiveOpaqueRun(
            image,
            points: <(int, int)>[
              for (var step = 1; step <= protrusionPx; step += 1)
                (right - protrusionPx + step, y),
            ],
          ),
      ],
    _ => throw ArgumentError.value(orientation),
  };
}

int _consecutiveOpaqueRun(
  img.Image image, {
  required List<(int, int)> points,
}) {
  var run = 0;
  for (final point in points) {
    if (image.getPixel(point.$1, point.$2).a.toInt() == 0) break;
    run += 1;
  }
  return run;
}

int _topSealLandwardEdge(
  (int, int, int, int) bounds,
  String orientation,
) =>
    switch (orientation) {
      'n' => bounds.$2 + bounds.$4 - 1 - _topLandwardProtrusionPx,
      'e' => bounds.$1 + _topLandwardProtrusionPx,
      's' => bounds.$2 + _topLandwardProtrusionPx,
      'w' => bounds.$1 + bounds.$3 - 1 - _topLandwardProtrusionPx,
      _ => throw ArgumentError.value(orientation),
    };

int _topPathCoordinate(Map<String, int> anchor, String orientation) =>
    switch (orientation) {
      'n' => anchor['y']! + _topLandwardOverlapPx,
      'e' => anchor['x']! - _topLandwardOverlapPx,
      's' => anchor['y']! - _topLandwardOverlapPx,
      'w' => anchor['x']! + _topLandwardOverlapPx,
      _ => throw ArgumentError.value(orientation),
    };

int _tangentStartContactRun(img.Image image, String orientation) {
  final bounds = _opaqueBounds(image);
  return orientation == 'n' || orientation == 's'
      ? _opaqueVerticalRun(
          image,
          x: bounds.$1,
          fromY: bounds.$2,
          toY: bounds.$2 + bounds.$4 - 1,
        )
      : _opaqueHorizontalRun(
          image,
          y: bounds.$2,
          fromX: bounds.$1,
          toX: bounds.$1 + bounds.$3 - 1,
        );
}

int _tangentEndContactRun(img.Image image, String orientation) {
  final bounds = _opaqueBounds(image);
  return orientation == 'n' || orientation == 's'
      ? _opaqueVerticalRun(
          image,
          x: bounds.$1 + bounds.$3 - 1,
          fromY: bounds.$2,
          toY: bounds.$2 + bounds.$4 - 1,
        )
      : _opaqueHorizontalRun(
          image,
          y: bounds.$2 + bounds.$4 - 1,
          fromX: bounds.$1,
          toX: bounds.$1 + bounds.$3 - 1,
        );
}

int _opaqueHorizontalRun(
  img.Image image, {
  required int y,
  required int fromX,
  required int toX,
}) =>
    <int>[
      for (var x = fromX; x <= toX; x += 1)
        if (image.getPixel(x, y).a.toInt() != 0) x,
    ].length;

int _opaqueVerticalRun(
  img.Image image, {
  required int x,
  required int fromY,
  required int toY,
}) =>
    <int>[
      for (var y = fromY; y <= toY; y += 1)
        if (image.getPixel(x, y).a.toInt() != 0) y,
    ].length;
