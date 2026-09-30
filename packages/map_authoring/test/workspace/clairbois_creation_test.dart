import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show
        CanonicalGamePackageExportService,
        GamePackageExportProfile,
        GamePackageExportMode,
        GamePackageExportException;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory parent;
  late List<int> archive;
  setUp(() async {
    parent = await Directory.systemTemp.createTemp('clairbois-creation-');
    archive = await File('test/fixtures/project_creation/clairbois-e3d3766.zip')
        .readAsBytes();
  });
  tearDown(() => parent.delete(recursive: true));
  ProjectCreationRequest request([String folder = 'mon-village']) =>
      ProjectCreationRequest(
        name: 'Mon village indépendant',
        folderName: folder,
        parentPath: parent.path,
        template: ProjectCreationTemplate.clairbois,
        tileSize: 32,
        mapWidth: 32,
        mapHeight: 26,
      );
  LocalProjectCreationService service(Future<List<int>> Function(Uri) read) =>
      LocalProjectCreationService(
          clairbois: ClairboisProjectTemplate(read: read));

  test('verified GitHub archive is copied, renamed and independently reopened',
      () async {
    final phases = <ProjectCreationPhase>[];
    final urls = <Uri>[];
    final creator = service((uri) async {
      urls.add(uri);
      return archive;
    });
    final receipt = await creator.create(request(), onPhase: phases.add);
    expect(urls, [ClairboisProjectTemplate.archiveUri]);
    expect(phases, contains(ProjectCreationPhase.downloading));
    final manifest = ProjectManifest.fromJson(jsonDecode(
            await File('${receipt.projectPath}/project.json').readAsString())
        as Map<String, dynamic>);
    expect(manifest.name, 'Mon village indépendant');
    expect(manifest.settings.tileWidth, 32);
    expect(manifest.maps.map((map) => map.id), ['first-map', 'maison']);
    expect(manifest.newGame.startMapId, 'first-map');
    final source = ZipDecoder().decodeBytes(archive);
    var copied = 0;
    for (final file in source) {
      final relative = file.name.split('/').skip(1).join('/');
      if (!file.isFile || relative == 'project.json') continue;
      if (!relative.startsWith('assets/') &&
          !relative.startsWith('maps/') &&
          !relative.startsWith('dialogues/') &&
          relative != 'asset-provenance.json') {
        continue;
      }
      expect(await File('${receipt.projectPath}/$relative').readAsBytes(),
          orderedEquals(file.content),
          reason: relative);
      copied++;
    }
    expect(copied, 69);
    expect(File('${receipt.projectPath}/README.md').existsSync(), isFalse);
    expect(File('${receipt.projectPath}/preview/village.png').existsSync(),
        isFalse);
  });

  test('bad download writes nothing and retry can succeed', () async {
    var failing = true;
    final creator = service((_) async => failing ? [1, 2, 3] : archive);
    await expectLater(
        creator.create(request()),
        throwsA(isA<ProjectCreationException>()
            .having((e) => e.code, 'code', 'project.template_integrity')));
    expect(await parent.list().toList(), isEmpty);
    failing = false;
    expect((await creator.create(request())).manifest.maps.length, 2);
  });

  test(
      'exploration template exports locally but refuses unfinished publication',
      () async {
    final receipt = await service((_) async => archive).create(request());
    final sourceFile = File('${receipt.projectPath}/project.json');
    final before = await sourceFile.readAsBytes();
    final profile = GamePackageExportProfile(
      gameId: 'games.avelune.clairbois-test',
      gameVersion: '0.1.0',
      title: receipt.manifest.name,
      authorName: 'Avelune',
      defaultLocale: 'fr',
      supportedLocales: const ['fr'],
    );
    const exporter = CanonicalGamePackageExportService();
    await expectLater(
      exporter.build(
          projectRoot: Directory(receipt.projectPath), profile: profile),
      throwsA(isA<GamePackageExportException>()
          .having((error) => error.code, 'code', 'gameplayReadinessFailed')),
    );
    final artifact = await exporter.exportToFile(
      projectRoot: Directory(receipt.projectPath),
      profile: profile,
      mode: GamePackageExportMode.localTest,
      outputFile: File('${parent.path}/clairbois.avelunegame'),
    );
    expect(artifact.certification.isExportable, isTrue);
    final package = ZipDecoder().decodeBytes(artifact.packageBytes);
    final project = package.files
        .singleWhere((file) => file.name.endsWith('/project.json'));
    final exported = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(project.content)) as Map<String, dynamic>);
    expect(exported.settings.tileWidth, 32);
    expect(exported.maps.map((map) => map.id), ['first-map', 'maison']);
    expect(await sourceFile.readAsBytes(), orderedEquals(before));
  });

  test('network failure does not silently create the built-in starter',
      () async {
    final creator =
        service((_) async => throw const SocketException('offline'));
    await expectLater(
        creator.create(request()),
        throwsA(isA<ProjectCreationException>()
            .having((e) => e.code, 'code', 'project.template_download')));
    expect(await parent.list().toList(), isEmpty);
  });

  test('cancel during retained download forbids reservation and writes',
      () async {
    final reached = Completer<void>();
    final release = Completer<List<int>>();
    var cancelled = false;
    final creator = service((_) {
      reached.complete();
      return release.future;
    });
    final result = creator.create(request(), isCancelled: () => cancelled);
    final refused =
        expectLater(result, throwsA(isA<ProjectCreationCancelled>()));
    await reached.future;
    expect(await parent.list().toList(), isEmpty);
    cancelled = true;
    release.complete(archive);
    await refused;
    expect(await parent.list().toList(), isEmpty);
  });

  test('existing destination refuses even before contacting GitHub', () async {
    final existing = await Directory('${parent.path}/mon-village').create();
    final sentinel = File('${existing.path}/important.txt');
    await sentinel.writeAsString('conserver');
    var reads = 0;
    await expectLater(
        service((_) async {
          reads++;
          return archive;
        }).create(request()),
        throwsA(isA<ProjectCreationException>()));
    expect(reads, 0);
    expect(await sentinel.readAsString(), 'conserver');
  });
}
