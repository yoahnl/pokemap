import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../tool/build_selbrume_port_props_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds the props-only pack deterministically and atomically', () async {
    final fixture = _copyFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));
    final sourceHashesBefore = await _sourceHashes(fixture);

    final checkBefore = await buildSelbrumePortPropsPack(
      SelbrumePortPropsPackOptions(projectRoot: fixture),
    );
    expect(checkBefore.exitCode, selbrumePortPropsPackDivergenceExitCode);
    expect(
        checkBefore.divergentRelativePaths, selbrumePortPropsPackOutputPaths);
    expect(checkBefore.outputCount, 10);
    for (final path in selbrumePortPropsPackOutputPaths) {
      expect(File(p.join(fixture.path, path)).existsSync(), isFalse);
    }

    final firstWrite = await buildSelbrumePortPropsPack(
      SelbrumePortPropsPackOptions(projectRoot: fixture, write: true),
    );
    expect(firstWrite.exitCode, 0);
    expect(firstWrite.divergentRelativePaths, isEmpty);
    expect(firstWrite.outputCount, 10);
    _expectOutputDimensions(fixture);
    for (final path in selbrumePortPropsPackOutputPaths.take(9)) {
      final image = _decode(fixture, path);
      expect(_hasTransparentAndOpaquePixels(image), isTrue, reason: path);
      _expectBottomCenterAnchor(image, reason: path);
    }
    expect(
      _decode(fixture, selbrumePortPropsPackContactSheetPath).getPixel(0, 0).a,
      0,
    );

    final firstHashes = await _outputHashes(fixture);
    File(p.join(fixture.path, selbrumePortBarrelPlainPath))
        .writeAsBytesSync(<int>[0, 1, 2, 3]);
    final secondWrite = await buildSelbrumePortPropsPack(
      SelbrumePortPropsPackOptions(projectRoot: fixture, write: true),
    );
    final cleanCheck = await buildSelbrumePortPropsPack(
      SelbrumePortPropsPackOptions(projectRoot: fixture),
    );
    expect(secondWrite.exitCode, 0);
    expect(cleanCheck.exitCode, 0);
    expect(cleanCheck.divergentRelativePaths, isEmpty);
    expect(await _outputHashes(fixture), firstHashes);
    expect(await _sourceHashes(fixture), sourceHashesBefore);

    final temporaryFiles = fixture
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => p.basename(file.path).contains('.props-pack-'));
    expect(temporaryFiles, isEmpty);
  }, skip: _propsSourceCorpusSkipReason());

  test('requires an explicit check or write mode', () {
    expect(
      () => parseSelbrumePortPropsPackOptions(
        <String>['--project-root', '/tmp/project'],
      ),
      throwsFormatException,
    );
    expect(
      () => parseSelbrumePortPropsPackOptions(
        <String>[
          '--project-root',
          '/tmp/project',
          '--check',
          '--write',
        ],
      ),
      throwsFormatException,
    );
  });
}

String? _propsSourceCorpusSkipReason() {
  final repositoryRoot = _findRepositoryRoot();
  const requiredSources = <String>[
    selbrumePortPropsGeneratedSheetPath,
    'assets/sources/v2/props/13_baril_haut.png',
    'assets/sources/v2/port/03_caisses_port.png',
    'assets/tilesets/selbrume_port_props.png',
  ];
  return requiredSources.every(
    (relativePath) => File(
      p.join(repositoryRoot.path, 'selbrume', relativePath),
    ).existsSync(),
  )
      ? null
      : 'Approved user-supplied props source corpus is not versioned.';
}

void _expectOutputDimensions(Directory fixture) {
  const dimensions = <String, (int, int)>{
    selbrumePortBarrelPlainPath: (32, 64),
    selbrumePortBarrelPairPath: (64, 64),
    selbrumePortCargoCratesClosedPath: (64, 64),
    selbrumePortRopeCoilPlainPath: (64, 64),
    selbrumePortGreenNettedBarrelPath: (64, 64),
    selbrumePortGroundNetRopeHeapPath: (96, 64),
    selbrumePortFishingGearBucketPath: (64, 64),
    selbrumePortFishNoticeBoardPath: (64, 64),
    selbrumePortBarrelPlanterPath: (32, 64),
    selbrumePortPropsPackContactSheetPath: (288, 192),
  };
  for (final entry in dimensions.entries) {
    final image = _decode(fixture, entry.key);
    expect((image.width, image.height), entry.value, reason: entry.key);
  }
}

void _expectBottomCenterAnchor(img.Image image, {required String reason}) {
  var left = image.width;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      if (image.getPixel(x, y).a.toInt() == 0) continue;
      left = left < x ? left : x;
      right = right > x ? right : x;
      bottom = bottom > y ? bottom : y;
    }
  }
  expect(bottom, image.height - 1, reason: '$reason must touch the bottom');
  expect(
    (left - (image.width - right - 1)).abs(),
    lessThanOrEqualTo(1),
    reason: '$reason must be centered horizontally',
  );
}

bool _hasTransparentAndOpaquePixels(img.Image image) {
  var transparent = false;
  var opaque = false;
  for (final pixel in image) {
    transparent |= pixel.a.toInt() == 0;
    opaque |= pixel.a.toInt() == 255;
    if (transparent && opaque) return true;
  }
  return false;
}

img.Image _decode(Directory fixture, String relativePath) {
  final decoded = img.decodePng(
    File(p.join(fixture.path, relativePath)).readAsBytesSync(),
  );
  if (decoded == null) throw StateError('Invalid PNG: $relativePath');
  return decoded;
}

Directory _copyFixture() {
  final repositoryRoot = _findRepositoryRoot();
  final parent = Directory.systemTemp.createTempSync('port_props_pack_');
  final fixture = Directory(p.join(parent.path, 'selbrume'))..createSync();
  File(p.join(fixture.path, 'project.json')).writeAsStringSync('{}');

  const sourcePaths = <String>[
    selbrumePortPropsGeneratedSheetPath,
    'assets/sources/v2/props/13_baril_haut.png',
    'assets/sources/v2/port/03_caisses_port.png',
    'assets/tilesets/selbrume_port_props.png',
  ];
  for (final relativePath in sourcePaths) {
    final source = File(
      p.join(repositoryRoot.path, 'selbrume', relativePath),
    );
    final target = File(p.join(fixture.path, relativePath));
    target.parent.createSync(recursive: true);
    source.copySync(target.path);
  }
  return fixture;
}

Future<Map<String, String>> _sourceHashes(Directory fixture) {
  return _hashes(
    fixture,
    const <String>[
      selbrumePortPropsGeneratedSheetPath,
      'assets/sources/v2/props/13_baril_haut.png',
      'assets/sources/v2/port/03_caisses_port.png',
      'assets/tilesets/selbrume_port_props.png',
    ],
  );
}

Future<Map<String, String>> _outputHashes(Directory fixture) {
  return _hashes(fixture, selbrumePortPropsPackOutputPaths);
}

Future<Map<String, String>> _hashes(
  Directory fixture,
  Iterable<String> relativePaths,
) async {
  final result = <String, String>{};
  for (final path in relativePaths) {
    final process = await Process.run(
      'shasum',
      <String>['-a', '256', p.join(fixture.path, path)],
    );
    expect(process.exitCode, 0);
    result[path] = process.stdout.toString().trim().split(RegExp(r'\s+')).first;
  }
  return result;
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        Directory(p.join(current.path, 'selbrume')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('Repository root not found.');
    }
    current = current.parent;
  }
}
