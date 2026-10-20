import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../tool/profile_game_package_export.dart' as probe;

void main() {
  late Directory root;
  late Directory project;
  late File profile;
  late File output;
  late File receipt;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('game-export-profile-');
    project = await Directory(p.join(root.path, 'source')).create();
    await _writeProject(project);
    profile = File(p.join(root.path, 'profile.json'));
    await profile.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'gameId': 'games.example.export-probe',
      'gameVersion': '0.1.0',
      'title': 'Export probe',
      'author': {'name': 'PokeMap'},
      'locales': {
        'default': 'fr',
        'supported': ['fr']
      },
      'requiredCapabilities': [],
      'branding': {},
      'legal': {},
    }));
    output = File(p.join(root.path, 'package', 'probe.avelunegame'));
    receipt = File(p.join(root.path, 'export-receipt.json'));
  });

  tearDown(() => root.delete(recursive: true));

  List<String> arguments({List<String> extra = const []}) => [
        '--project-root',
        project.path,
        '--profile',
        profile.path,
        '--output',
        output.path,
        '--receipt',
        receipt.path,
        '--mode',
        'localTest',
        ...extra,
      ];

  test('profiles the canonical export and reopens the written file', () async {
    final before = await _projectFiles(project);
    final audit = await Directory(p.join(root.path, 'original')).create();
    await _writeProject(audit);
    await File(p.join(audit.path, 'project 2.json')).writeAsString('{}');
    await Directory(p.join(audit.path, 'Archived Study')).create();
    await File(p.join(audit.path, 'Archived Study', 'project.json'))
        .writeAsString('{}');
    await Directory(p.join(audit.path, 'backups')).create();
    await File(p.join(audit.path, 'backups', 'ignored.json'))
        .writeAsString('{}');
    await Directory(p.join(audit.path, 'assets')).create();
    await File(p.join(audit.path, 'assets', 'provenance.json'))
        .writeAsString('{}');

    final result = await probe.runProfileGamePackageExport(arguments(extra: [
      '--audit-source-root',
      audit.path,
    ]));

    expect(result, 0);
    final report = await _report(receipt);
    expect(report['status'], 'succeeded');
    expect(report['mode'], 'localTest');
    expect(report['stage'], 'complete');
    expect(report['measurement']['elapsedMicroseconds'], greaterThan(0));
    expect(report['measurement']['maxRssBytes'], greaterThan(0));
    expect(report['measurement']['rssScope'], 'currentProcessLifetime');
    expect(report['source']['fileCount'], 2);
    expect(report['source']['unchangedAfterExport'], isTrue);
    expect(report['source']['projectSha256'], before['project.json']);
    expect(report['inspection']['archiveBytes'], await output.length());
    expect(report['inspection']['packageSha256'],
        (await sha256.bind(output.openRead()).first).toString());
    expect(report['inspection']['treeSha256'],
        report['exportInspection']['treeSha256']);
    expect(report['inspection']['packageSha256'],
        report['exportInspection']['packageSha256']);
    expect(report['collectorAudit']['candidateFileCount'], 3);
    expect(report['collectorAudit']['contentRead'], isFalse);
    expect(report['collectorAudit']['measurement'],
        'physicalCandidateMetadataNotProjectedPayload');
    expect(await _projectFiles(project), before);
    expect(await Directory(p.join(project.path, '.pokemap')).exists(), isFalse);
  });

  test('records canonical readiness refusal and peak RSS without a package',
      () async {
    await _writeProject(project, newGameEnabled: false);
    final before = await _projectFiles(project);
    expect(await probe.runProfileGamePackageExport(arguments()), 1);
    final report = await _report(receipt);
    expect(report['status'], 'failed');
    expect(report['stage'], 'build');
    expect(report['error']['code'], 'gameplayReadinessFailed');
    expect(
        report['error']['diagnosticCodes'], contains('exportNewGameDisabled'));
    expect(report['measurement']['maxRssBytes'], greaterThan(0));
    expect(report['measurement']['elapsedMicroseconds'], greaterThan(0));
    expect(report['source']['unchangedAfterExport'], isTrue);
    expect(report.containsKey('sourceVerificationError'), isFalse);
    expect(await output.exists(), isFalse);
    expect(await _projectFiles(project), before);
  });

  test('refuses source size before invoking the exporter', () async {
    expect(
        await probe.runProfileGamePackageExport(arguments(extra: [
          '--max-source-bytes',
          '1',
        ])),
        1);
    final report = await _report(receipt);
    expect(report['stage'], 'sourceInventory');
    expect(report['error']['code'], 'sourceBudgetExceeded');
    expect(await output.exists(), isFalse);
  });

  test('refuses output within the source without changing it', () async {
    output = File(p.join(project.path, 'probe.avelunegame'));
    final before = await _projectFiles(project);
    expect(await probe.runProfileGamePackageExport(arguments()), 1);
    final report = await _report(receipt);
    expect(report['error']['code'], 'destinationInsideSource');
    expect(await _projectFiles(project), before);
  });

  test('preserves an existing output instead of replacing it', () async {
    await output.parent.create(recursive: true);
    await output.writeAsString('existing package');
    expect(await probe.runProfileGamePackageExport(arguments()), 1);
    final report = await _report(receipt);
    expect(report['error']['code'], 'destinationExists');
    expect(await output.readAsString(), 'existing package');
  });

  test('rejects linked source files and retains a measured refusal', () async {
    await Link(p.join(project.path, 'linked.json'))
        .create(p.join(project.path, 'project.json'));
    expect(await probe.runProfileGamePackageExport(arguments()), 1);
    final report = await _report(receipt);
    expect(report['error']['code'], 'symlinkRejected');
    expect(report['stage'], 'sourceInventory');
    expect(await output.exists(), isFalse);
  });
}

Future<Map<String, dynamic>> _report(File file) async =>
    jsonDecode(await file.readAsString()) as Map<String, dynamic>;

Future<Map<String, String>> _projectFiles(Directory root) async => {
      await for (final entry in root.list(recursive: true))
        if (entry is File)
          p.relative(entry.path, from: root.path):
              (await sha256.bind(entry.openRead()).first).toString(),
    };

Future<void> _writeProject(Directory root, {bool newGameEnabled = true}) async {
  final project = ProjectManifest(
    name: 'Export measurement fixture',
    maps: const [
      ProjectMapEntry(
          id: 'start', name: 'Start', relativePath: 'maps/start.json'),
    ],
    tilesets: const [],
    pokemon: const ProjectPokemonConfig(
        enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
    newGame: ProjectNewGameConfig(
        enabled: newGameEnabled,
        startMapId: 'start',
        startSpawnId: 'player-start'),
  );
  const map = MapData(
      id: 'start',
      name: 'Start',
      size: GridSize(width: 4, height: 4),
      layers: [MapLayer.object(id: 'events', name: 'Events')],
      mapMetadata: MapMetadata(defaultSpawnId: 'player-start'),
      entities: [
        MapEntity(
            id: 'player-start',
            name: 'Player start',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart)),
      ]);
  await File(p.join(root.path, 'project.json'))
      .writeAsString(jsonEncode(project.toJson()));
  final mapFile = File(p.join(root.path, 'maps', 'start.json'));
  await mapFile.parent.create(recursive: true);
  await mapFile.writeAsString(jsonEncode(map.toJson()));
}
