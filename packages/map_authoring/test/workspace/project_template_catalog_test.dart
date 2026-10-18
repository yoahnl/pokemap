import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> entry(String id) => {
        'id': id,
        'label': 'Template $id',
        'description': 'An independent editable exploration project.',
        'revision': 'fixture-revision-1',
        'projectPaths': [
          'project.json',
          'maps/',
          'dialogues/',
          'assets/',
          'asset-provenance.json'
        ],
        'archive': {
          'uri': 'https://example.test/$id/project.zip',
          'sha256': 'a' * 64
        },
        'preview': {
          'uri': 'https://example.test/$id/preview.png',
          'sha256': 'b' * 64
        },
        'geometry': {'tileSize': 32, 'mapWidth': 32, 'mapHeight': 26},
      };
  ProjectTemplateCatalog catalog(List<Map<String, dynamic>> entries) =>
      ProjectTemplateCatalog.fromJson(
          {'schemaVersion': 1, 'templates': entries});

  test(
      'asset-free templates retain all explicitly declared project directories',
      () async {
    final root =
        await Directory.systemTemp.createTemp('template-project-data-');
    addTearDown(() => root.delete(recursive: true));
    final manifest = ProjectManifest(
        name: 'Source',
        maps: [
          const ProjectMapEntry(
              id: 'start', name: 'Start', relativePath: 'maps/start.json')
        ],
        tilesets: [],
        newGame: const ProjectNewGameConfig(startMapId: 'start'));
    final map = MapData(
        id: 'start', name: 'Start', size: const GridSize(width: 3, height: 3));
    final payloads = <String, List<int>>{
      'project.json': utf8.encode(jsonEncode(manifest.toJson())),
      'maps/start.json': utf8.encode(jsonEncode(map.toJson())),
      'scenes/chapter.json': utf8.encode('{"scene":"independent"}'),
      'catalogs/items.json': utf8.encode('{"items":[]}'),
      'data/flags.json': utf8.encode('{"flags":[]}'),
    };
    final archive = Archive();
    for (final file in payloads.entries) {
      archive.addFile(
          ArchiveFile('source/${file.key}', file.value.length, file.value));
    }
    archive.addFile(
        ArchiveFile.string('source/README.md', 'Excluded documentation'));
    final bytes = ZipEncoder().encode(archive);
    final descriptor = {
      ...entry('independent'),
      'projectPaths': [
        'project.json',
        'maps/',
        'scenes/',
        'catalogs/',
        'data/'
      ],
      'geometry': {'tileSize': 16, 'mapWidth': 3, 'mapHeight': 3},
      'archive': {
        'uri': 'https://example.test/independent.zip',
        'sha256': sha256.convert(bytes).toString()
      },
    };
    final service = LocalProjectCreationService(
        templateCatalog: catalog([descriptor]),
        readTemplate: (_) async => bytes);
    final result = await service.create(ProjectCreationRequest(
        name: 'Copy',
        folderName: 'copy',
        parentPath: root.path,
        template: ProjectCreationTemplate.catalogue,
        templateId: 'independent',
        tileSize: 16,
        mapWidth: 3,
        mapHeight: 3));
    for (final path in payloads.keys.where((path) => path != 'project.json')) {
      expect(await File('${result.projectPath}/$path').readAsBytes(),
          orderedEquals(payloads[path]!),
          reason: path);
    }
    expect(await File('${result.projectPath}/README.md').exists(), isFalse);
    expect(await Directory('${result.projectPath}/assets').exists(), isFalse);
  });

  test('arbitrary catalogue entries preserve identity, geometry and provenance',
      () {
    final source = [entry('alpha'), entry('beta')];
    final decoded = catalog(source);
    expect(decoded.templates.map((value) => value.id), ['alpha', 'beta']);
    expect(decoded.toJson(), {'schemaVersion': 1, 'templates': source});
    expect(decoded.require('beta').mapHeight, 26);
    expect(() => decoded.require('absent'), throwsFormatException);
    expect(() => decoded.templates.clear(), throwsUnsupportedError);
  });

  test('a valid archive checksum cannot bypass the internal asset inventory',
      () async {
    final root =
        await Directory.systemTemp.createTemp('template-asset-integrity-');
    addTearDown(() => root.delete(recursive: true));
    final original = ZipDecoder().decodeBytes(
        await File('test/fixtures/project_creation/clairbois-e3d3766.zip')
            .readAsBytes());
    final corrupt = Archive();
    var changed = false;
    for (final file in original) {
      if (!changed &&
          file.isFile &&
          file.name.contains('/assets/') &&
          file.name.endsWith('.png')) {
        corrupt.addFile(ArchiveFile(file.name, 3, [1, 2, 3]));
        changed = true;
      } else {
        corrupt.addFile(file);
      }
    }
    expect(changed, isTrue);
    final bytes = ZipEncoder().encode(corrupt);
    final descriptor = {
      ...entry('corrupt'),
      'archive': {
        'uri': 'https://example.test/corrupt.zip',
        'sha256': sha256.convert(bytes).toString()
      }
    };
    final service = LocalProjectCreationService(
        templateCatalog: catalog([descriptor]),
        readTemplate: (_) async => bytes);
    await expectLater(
        service.create(ProjectCreationRequest(
            name: 'Safe',
            folderName: 'safe',
            parentPath: root.path,
            template: ProjectCreationTemplate.catalogue,
            templateId: 'corrupt',
            tileSize: 32,
            mapWidth: 32,
            mapHeight: 26)),
        throwsA(isA<ProjectCreationException>().having((error) => error.message,
            'message', contains('Invalid template asset'))));
    expect(await root.list().toList(), isEmpty);
  });

  test(
      'catalogue refuses unknown keys, duplicates, unsafe origins and invalid geometry',
      () {
    for (final value in [
      {...entry('alpha'), 'unknown': true},
      {
        ...entry('alpha'),
        'projectPaths': ['project.json', '../escape/']
      },
      {
        ...entry('alpha'),
        'projectPaths': ['project.json', 'assets/*']
      },
      {
        ...entry('alpha'),
        'projectPaths': ['project.json', '/']
      },
      {
        ...entry('alpha'),
        'projectPaths': ['project.json', 'project.json']
      },
      {
        ...entry('alpha'),
        'projectPaths': ['maps/']
      },
      {
        ...entry('alpha'),
        'geometry': {'tileSize': 32, 'mapWidth': 2, 'mapHeight': 26}
      },
      {
        ...entry('alpha'),
        'archive': {'uri': 'http://example.test/a.zip', 'sha256': 'a' * 64}
      },
      {
        ...entry('alpha'),
        'archive': {
          'uri': 'https://user:secret@example.test/a.zip',
          'sha256': 'a' * 64
        }
      },
      {
        ...entry('alpha'),
        'archive': {
          'uri': 'https://example.test/%2e%2e/a.zip',
          'sha256': 'a' * 64
        }
      },
      {
        ...entry('alpha'),
        'archive': {'uri': 'https://example.test/a.zip', 'sha256': 'wrong'}
      },
    ]) {
      expect(() => catalog([value]), throwsFormatException);
    }
    expect(
        () => catalog([entry('alpha'), entry('alpha')]), throwsFormatException);
  });

  test('selection requires a known explicit catalogue ID and matching geometry',
      () async {
    final root = await Directory.systemTemp.createTemp('template-catalogue-');
    addTearDown(() => root.delete(recursive: true));
    final service =
        LocalProjectCreationService(templateCatalog: catalog([entry('alpha')]));
    ProjectCreationRequest request({String? id, int width = 32}) =>
        ProjectCreationRequest(
          name: 'Independent',
          folderName: 'independent',
          parentPath: root.path,
          template: ProjectCreationTemplate.catalogue,
          templateId: id,
          tileSize: 32,
          mapWidth: width,
          mapHeight: 26,
        );
    for (final request in [
      request(),
      request(id: 'absent'),
      request(id: 'alpha', width: 20)
    ]) {
      await expectLater(
          service.validateDestination(request), throwsFormatException);
    }
    expect(await root.list().toList(), isEmpty);
  });

  test(
      'two explicit descriptors create independently with verified source bytes',
      () async {
    final root = await Directory.systemTemp.createTemp('template-copies-');
    addTearDown(() => root.delete(recursive: true));
    final bytes =
        await File('test/fixtures/project_creation/clairbois-e3d3766.zip')
            .readAsBytes();
    final entries = [
      for (final id in ['alpha', 'beta'])
        {
          ...entry(id),
          'archive': {
            'uri': 'https://example.test/$id/project.zip',
            'sha256': sha256.convert(bytes).toString()
          },
        }
    ];
    final reads = <Uri>[];
    final service = LocalProjectCreationService(
        templateCatalog: catalog(entries),
        readTemplate: (uri) async {
          reads.add(uri);
          return bytes;
        });
    for (final id in ['alpha', 'beta']) {
      final result = await service.create(ProjectCreationRequest(
        name: id,
        folderName: id,
        parentPath: root.path,
        template: ProjectCreationTemplate.catalogue,
        templateId: id,
        tileSize: 32,
        mapWidth: 32,
        mapHeight: 26,
      ));
      expect(result.manifest.name, id);
      expect(result.manifest.maps, isNotEmpty);
      expect(
          jsonDecode(await File('${result.projectPath}/project.json')
              .readAsString())['name'],
          id);
    }
    expect(reads, [
      Uri.parse('https://example.test/alpha/project.zip'),
      Uri.parse('https://example.test/beta/project.zip')
    ]);
  });

  test(
      'verified archives reject traversal and false declared geometry before reservation',
      () async {
    final root = await Directory.systemTemp.createTemp('template-safety-');
    addTearDown(() => root.delete(recursive: true));
    final malicious = ZipEncoder().encode(
        Archive()..addFile(ArchiveFile.string('root/../escape.json', '{}')));
    final valid =
        await File('test/fixtures/project_creation/clairbois-e3d3766.zip')
            .readAsBytes();
    for (final bytes in [malicious, valid]) {
      final descriptor = {
        ...entry('safe'),
        'archive': {
          'uri': 'https://example.test/safe.zip',
          'sha256': sha256.convert(bytes).toString()
        },
        'geometry': {'tileSize': 32, 'mapWidth': 31, 'mapHeight': 26},
      };
      final service = LocalProjectCreationService(
          templateCatalog: catalog([descriptor]),
          readTemplate: (_) async => bytes);
      await expectLater(
          service.create(ProjectCreationRequest(
              name: 'Safe',
              folderName: 'safe',
              parentPath: root.path,
              template: ProjectCreationTemplate.catalogue,
              templateId: 'safe',
              tileSize: 32,
              mapWidth: 31,
              mapHeight: 26)),
          throwsA(isA<ProjectCreationException>()));
      expect(await root.list().toList(), isEmpty);
    }
  });

  test('all declared project paths must exist before creating a destination',
      () async {
    final root =
        await Directory.systemTemp.createTemp('template-declared-paths-');
    addTearDown(() => root.delete(recursive: true));
    final bytes =
        await File('test/fixtures/project_creation/clairbois-e3d3766.zip')
            .readAsBytes();
    final descriptor = {
      ...entry('missing'),
      'projectPaths': [
        ...(entry('missing')['projectPaths'] as List),
        'absent/'
      ],
      'archive': {
        'uri': 'https://example.test/missing.zip',
        'sha256': sha256.convert(bytes).toString()
      },
    };
    final service = LocalProjectCreationService(
        templateCatalog: catalog([descriptor]),
        readTemplate: (_) async => bytes);
    await expectLater(
        service.create(ProjectCreationRequest(
            name: 'Safe',
            folderName: 'safe',
            parentPath: root.path,
            template: ProjectCreationTemplate.catalogue,
            templateId: 'missing',
            tileSize: 32,
            mapWidth: 32,
            mapHeight: 26)),
        throwsA(isA<ProjectCreationException>().having((error) => error.message,
            'message', contains('Missing declared template path'))));
    expect(await root.list().toList(), isEmpty);
  });

  test(
      'confirmation refuses a changed source descriptor with the same template ID',
      () async {
    final root =
        await Directory.systemTemp.createTemp('template-confirmation-');
    addTearDown(() => root.delete(recursive: true));
    final port = _ChangingCatalogPort(catalog([entry('alpha')]));
    final api = ProjectCreationBootstrapApi(
      policy: await WorkspacePolicy.create(
          allowedRootPaths: [root.path],
          fileReader: const LocalProjectFileReader()),
      creation: port,
    );
    final request = {
      'name': 'Independent',
      'folderName': 'independent',
      'parentPath': root.path,
      'template': 'catalogue',
      'templateId': 'alpha'
    };
    final preview = await api.preview(request);
    port.templateCatalog = catalog([
      {
        ...entry('alpha'),
        'revision': 'fixture-revision-2',
        'archive': {
          'uri': 'https://example.test/alpha/project.zip',
          'sha256': 'c' * 64
        }
      }
    ]);
    await expectLater(
        api.create(request, confirmation: preview['confirmation'] as String),
        throwsA(anything));
    expect(port.creations, 0);
    expect(await root.list().toList(), isEmpty);
  });
}

final class _ChangingCatalogPort implements ProjectCreationPort {
  _ChangingCatalogPort(this.templateCatalog);

  @override
  ProjectTemplateCatalog templateCatalog;
  int creations = 0;

  @override
  Future<List<int>?> preview(ProjectCreationRequest request) async => null;

  @override
  Future<String> validateDestination(ProjectCreationRequest request) =>
      LocalProjectCreationService(templateCatalog: templateCatalog)
          .validateDestination(request);

  @override
  Future<ProjectCreationReceipt> create(
    ProjectCreationRequest request, {
    void Function(ProjectCreationPhase)? onPhase,
    bool Function()? isCancelled,
    String? expectedDestination,
  }) async {
    creations++;
    throw StateError('Creation must be refused before reaching the port.');
  }
}
