import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPokemonRulesetBootstrapService', () {
    test('previews and repairs only the missing canonical ruleset', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final originalBytes = await fixture.manifest.readAsBytes();

      final preview =
          await fixture.service.inspectProject(fixture.project.path);

      expect(preview.repairRequired, isTrue);
      expect(preview.projectName, 'P3 Narrative Smoke Slice');
      expect(preview.currentRevision, matches(r'^sha256:[0-9a-f]{64}$'));
      expect(
        preview.ruleset,
        PokemonRulesetProfile.pokeMapBetaV1,
      );
      expect(
          preview.toJson().toString(), isNot(contains(fixture.project.path)));

      final receipt = await fixture.service.repairProject(
        projectRootPath: fixture.project.path,
        expectedRevision: preview.currentRevision,
        confirmation: ProjectPokemonRulesetBootstrapService.confirmation,
      );

      expect(receipt.changed, isTrue);
      expect(receipt.beforeRevision, preview.currentRevision);
      expect(receipt.afterRevision, isNot(receipt.beforeRevision));
      final repaired = ProjectManifest.fromJson(
        jsonDecode(await fixture.manifest.readAsString())
            as Map<String, dynamic>,
      );
      expect(repaired.pokemon.ruleset, PokemonRulesetProfile.pokeMapBetaV1);
      final backups = await fixture.backups();
      expect(backups, hasLength(1));
      expect(await File(backups.single.path).readAsBytes(), originalBytes);
      final opened =
          await fixture.openService.openProject(fixture.project.path);
      expect(opened.projectName, 'P3 Narrative Smoke Slice');
    });

    test('rejects missing confirmation without changing project bytes',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final before = await fixture.manifest.readAsBytes();
      final preview =
          await fixture.service.inspectProject(fixture.project.path);

      await expectLater(
        () => fixture.service.repairProject(
          projectRootPath: fixture.project.path,
          expectedRevision: preview.currentRevision,
          confirmation: 'oui',
        ),
        throwsA(
          isA<ProjectPokemonRulesetBootstrapException>().having(
            (error) => error.code,
            'code',
            'project.ruleset_repair_confirmation_required',
          ),
        ),
      );
      expect(await fixture.manifest.readAsBytes(), before);
      expect(await fixture.backups(), isEmpty);
    });

    test('rejects a stale preview without changing project bytes', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final preview =
          await fixture.service.inspectProject(fixture.project.path);
      final decoded = jsonDecode(await fixture.manifest.readAsString())
          as Map<String, dynamic>;
      decoded['name'] = 'Changed elsewhere';
      await fixture.manifest.writeAsString(jsonEncode(decoded));
      final beforeRepair = await fixture.manifest.readAsBytes();

      await expectLater(
        () => fixture.service.repairProject(
          projectRootPath: fixture.project.path,
          expectedRevision: preview.currentRevision,
          confirmation: ProjectPokemonRulesetBootstrapService.confirmation,
        ),
        throwsA(
          isA<ProjectPokemonRulesetBootstrapException>().having(
            (error) => error.code,
            'code',
            'project.ruleset_repair_revision_conflict',
          ),
        ),
      );
      expect(await fixture.manifest.readAsBytes(), beforeRepair);
      expect(await fixture.backups(), isEmpty);
    });

    test('refuses manifests with another validation defect', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final decoded = jsonDecode(await fixture.manifest.readAsString())
          as Map<String, dynamic>;
      decoded.remove('name');
      await fixture.manifest.writeAsString(jsonEncode(decoded));

      await expectLater(
        () => fixture.service.inspectProject(fixture.project.path),
        throwsA(
          isA<ProjectPokemonRulesetBootstrapException>().having(
            (error) => error.code,
            'code',
            'project.manifest_invalid',
          ),
        ),
      );
      expect(await fixture.backups(), isEmpty);
    });

    test('exposes preview and repair through the JSONL boundary', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final worker = JsonlWorker(
        api: fixture.api,
        projectBootstrap: fixture.service,
      );

      final inspected = AuthoringResult.fromJson(
        jsonDecode(
          await worker.processLine(
            jsonEncode({
              'id': 'inspect-ruleset',
              'command': 'project_bootstrap_inspect',
              'args': {'projectRoot': fixture.project.path},
            }),
          ),
        ) as Map<String, dynamic>,
      );
      final repaired = AuthoringResult.fromJson(
        jsonDecode(
          await worker.processLine(
            jsonEncode({
              'id': 'repair-ruleset',
              'command': 'project_bootstrap_repair',
              'args': {
                'projectRoot': fixture.project.path,
                'expectedRevision': inspected.data['currentRevision'],
                'confirmation':
                    ProjectPokemonRulesetBootstrapService.confirmation,
              },
            }),
          ),
        ) as Map<String, dynamic>,
      );

      expect(inspected.status, AuthoringResultStatus.success);
      expect(inspected.data['repairRequired'], isTrue);
      expect(repaired.status, AuthoringResultStatus.success);
      expect(repaired.data['changed'], isTrue);
      expect(
        (await fixture.openService.openProject(fixture.project.path))
            .projectName,
        'P3 Narrative Smoke Slice',
      );
    });
  });
}

final class _Fixture {
  const _Fixture({
    required this.sandbox,
    required this.project,
    required this.manifest,
    required this.service,
    required this.openService,
    required this.api,
  });

  static Future<_Fixture> create() async {
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_ruleset_bootstrap_',
    );
    final project = await Directory('${sandbox.path}/project').create();
    final source = File(
      '${_realFixtureDirectory().path}/project.json',
    );
    final decoded =
        jsonDecode(await source.readAsString()) as Map<String, dynamic>;
    (decoded['pokemon'] as Map<String, dynamic>).remove('ruleset');
    final manifest = File('${project.path}/project.json');
    await manifest.writeAsString(jsonEncode(decoded));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [sandbox.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final openService = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final api = AuthoringReadApi(
      openService: openService,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    return _Fixture(
      sandbox: sandbox,
      project: project,
      manifest: manifest,
      service: ProjectPokemonRulesetBootstrapService(
        policy: policy,
        fileReader: reader,
        writer: const LocalProjectManifestBootstrapWriter(),
      ),
      openService: openService,
      api: api,
    );
  }

  final Directory sandbox;
  final Directory project;
  final File manifest;
  final ProjectPokemonRulesetBootstrapService service;
  final ProjectOpenService openService;
  final AuthoringReadApi api;

  Future<List<FileSystemEntity>> backups() async {
    final directory = Directory('${project.path}/.pokemap/backups');
    if (!await directory.exists()) return const [];
    return directory.list().toList();
  }

  Future<void> dispose() => sandbox.delete(recursive: true);
}

Directory _realFixtureDirectory() {
  return Directory(
    '${Directory.current.parent.parent.path}/examples/playable_runtime_host/p3_narrative_smoke_slice',
  );
}
