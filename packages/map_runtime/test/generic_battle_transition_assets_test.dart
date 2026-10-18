import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/battle_transition_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_transition_spec.dart';

import '../tool/import_battle_transition_assets.dart' as importer;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late List<int> png;
  setUp(() {
    root = Directory.systemTemp.createTempSync('generic-transition-assets-');
    png = image.encodePng(image.Image(width: 8, height: 6));
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('two projects render arbitrary sheet definitions with their own images', () async {
    for (final id in ['aurora', 'clockwork']) {
      final project = Directory('${root.path}/$id')..createSync();
      File('${project.path}/atlas.png').writeAsBytesSync(png);
      final definition = BattleTransitionDefinition.fromJson({
        'id': id, 'label': '$id transition', 'usages': ['wild', 'trainer'],
        'phases': [
          {'kind': 'flash', 'durationSeconds': 0.2, 'factor': 3},
          {'kind': 'sheetCells', 'durationSeconds': 0.3,
            'sheetName': 'project:atlas.png', 'columns': 4, 'rows': 3},
          {'kind': 'holdBlack', 'durationSeconds': 0.1},
        ],
      });
      final spec = battleTransitionSpecFromDefinition(definition);
      expect(spec.id, id);
      expect(spec.totalSeconds, closeTo(0.6, 0.00001));
      final phase = spec.phases.whereType<TransitionSheetCellsPhase>().single;
      expect(phase.sheetName, 'project:atlas.png');
      final budget = RuntimeResourceBudget();
      final loaded = await loadProjectBattleTransitionImage(
        phase.sheetName, project.path, resourceBudget: budget,
      );
      expect(loaded, isNotNull);
      expect(loaded!.image.width, 8);
      expect(loaded.image.height, 6);
      expect(budget.residentBytes, 8 * 6 * 4);
      loaded.dispose();
      expect(budget.residentBytes, 0);
    }
  });

  test('transition admission refuses a sheet above its resident budget', () async {
    final file = File('${root.path}/oversized.png')..writeAsBytesSync(png);
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumResidentBytes: 128),
    );
    expect(await loadProjectBattleTransitionImage(
      'project:oversized.png', file.parent.path, resourceBudget: budget,
    ), isNull);
    expect(budget.residentBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('missing images return null and symlink escapes are refused', () async {
    final project = Directory('${root.path}/project')..createSync();
    final outside = File('${root.path}/outside.png')..writeAsBytesSync(png);
    File('${project.path}/corrupted.png').writeAsStringSync('invalid image');
    Link('${project.path}/escape.png').createSync(outside.path);
    expect(await loadProjectBattleTransitionImage('project:missing.png', project.path), isNull);
    expect(await loadProjectBattleTransitionImage('project:corrupted.png', project.path), isNull);
    expect(await loadProjectBattleTransitionImage('embedded:any.png', project.path), isNull);
    await expectLater(loadProjectBattleTransitionImage('project:escape.png', project.path),
      throwsFormatException);
    await expectLater(loadProjectBattleTransitionImage('project:../outside.png', project.path),
      throwsFormatException);
  });

  test('generic asset import verifies two unrelated catalogues before publishing', () {
    for (final id in ['aurora', 'clockwork']) {
      final source = Directory('${root.path}/$id-source')..createSync();
      File('${source.path}/picture.png').writeAsBytesSync(png);
      final catalogue = File('${root.path}/$id.json')..writeAsStringSync(jsonEncode({
        'schemaVersion': 1,
        'definitions': [{
          'id': id, 'label': id, 'usages': ['wild'],
          'phases': [{'kind': 'sheetCells', 'durationSeconds': 0.25,
            'sheetName': 'project:images/$id.png', 'columns': 2, 'rows': 3}],
        }],
        'assets': [{'reference': 'project:images/$id.png',
          'sourceRelativePath': 'picture.png', 'sha256': sha256.convert(png).toString()}],
      }));
      final destination = '${root.path}/$id-output';
      importer.importBattleTransitionAssets(['--source-root', source.path,
        '--catalogue', catalogue.path, '--output-root', destination]);
      expect(File('$destination/images/$id.png').readAsBytesSync(), png);
      expect(File('$destination/import-receipt.json').existsSync(), isTrue);
      expect(File('${source.path}/picture.png').readAsBytesSync(), png);
      expect(() => importer.importBattleTransitionAssets(['--source-root', source.path,
        '--catalogue', catalogue.path, '--output-root', destination]), throwsFormatException);
    }
  });

  test('invalid hash and source escape publish no output', () {
    final source = Directory('${root.path}/source')..createSync();
    final outside = File('${root.path}/outside.png')..writeAsBytesSync(png);
    File('${source.path}/picture.png').writeAsBytesSync(png);
    Link('${source.path}/escape.png').createSync(outside.path);
    final catalogue = File('${root.path}/invalid.json');
    for (final relative in ['picture.png', 'escape.png', '../outside.png']) {
      catalogue.writeAsStringSync(jsonEncode({
        'schemaVersion': 1, 'definitions': [],
        'assets': [{'reference': 'embedded:custom.png', 'sourceRelativePath': relative,
          'sha256': relative == 'picture.png' ? '0' * 64 : sha256.convert(png).toString()}],
      }));
      final destination = '${root.path}/invalid-output';
      expect(() => importer.importBattleTransitionAssets(['--source-root', source.path,
        '--catalogue', catalogue.path, '--output-root', destination]), throwsFormatException);
      expect(Directory(destination).existsSync(), isFalse);
    }
  });
  test('non-regular assets are refused without reading their contents', () async {
    if (Platform.isWindows) return;
    final source = Directory('${root.path}/pipe-source')..createSync();
    final fifo = '${source.path}/pipe.png';
    expect((await Process.run('mkfifo', [fifo])).exitCode, 0);
    expect(await loadProjectBattleTransitionImage('project:pipe.png', source.path), isNull);
    final catalogue = File('${root.path}/pipe.json')..writeAsStringSync(jsonEncode({
      'schemaVersion': 1, 'definitions': [],
      'assets': [{'reference': 'embedded:pipe.png', 'sourceRelativePath': 'pipe.png',
        'sha256': '0' * 64}],
    }));
    expect(() => importer.importBattleTransitionAssets(['--source-root', source.path,
      '--catalogue', catalogue.path, '--output-root', '${root.path}/pipe-output']),
      throwsFormatException);
    expect(Directory('${root.path}/pipe-output').existsSync(), isFalse);
  });
}
