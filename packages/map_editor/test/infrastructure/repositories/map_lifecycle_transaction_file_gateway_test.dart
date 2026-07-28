import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/services/map_lifecycle_transaction_service.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart';
import 'package:path/path.dart' as p;

void main() {
  group('MapLifecycleTransactionFileGateway', () {
    test('commits real files and preserves unknown project root data',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);

      final result = await fixture.coordinator.execute(fixture.createRequest());

      expect(result.project, fixture.after);
      expect(
        (await fixture.mapRepository.loadMapDocument(fixture.targetPath)).map,
        fixture.target,
      );
      expect(
        decodeValidatedNarrativeEventAuthoringProject(
          await fixture.projectFile.readAsBytes(),
        ).manifest,
        fixture.after,
      );
      expect(
        (await fixture.readRoot())['futureRoot'],
        <String, Object?>{'preserved': true},
      );
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        isFalse,
      );
    });

    test('a new gateway instance recovers a crash after target persistence',
        () async {
      final fixture = await _Fixture.create(
        crashAt: MapLifecycleTransactionCheckpoint.afterTargetWritten,
      );
      addTearDown(fixture.dispose);

      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      expect(await File(fixture.targetPath).exists(), isTrue);
      expect(await fixture.readProject(), fixture.before);
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        isTrue,
      );

      final restartedGateway = MapLifecycleTransactionFileGateway(
        mapRepository: FileMapRepository(),
      );
      final recovered =
          await MapLifecycleTransactionCoordinator(restartedGateway).recover(
        fixture.projectPath,
      );

      expect(recovered.status, MapLifecycleRecoveryStatus.recovered);
      expect(await fixture.readProject(), fixture.after);
      expect((await FileMapRepository().loadMap(fixture.targetPath)),
          fixture.target);
      expect(
        await File(restartedGateway.journalPath(fixture.projectPath)).exists(),
        isFalse,
      );
    });

    test('project loading recovers a pending map lifecycle first', () async {
      final fixture = await _Fixture.create(
        crashAt: MapLifecycleTransactionCheckpoint.afterTargetWritten,
      );
      addTearDown(fixture.dispose);
      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      final recoveryCoordinator = MapLifecycleTransactionCoordinator(
        MapLifecycleTransactionFileGateway(
          mapRepository: FileMapRepository(),
        ),
      );
      final projectRepository = FileProjectRepository(
        mapLifecycleTransactions: recoveryCoordinator,
      );

      final loaded = await projectRepository.loadProject(fixture.projectPath);

      expect(loaded, fixture.after);
      expect(await File(fixture.targetPath).exists(), isTrue);
      expect(
        await File(
          recoveryCoordinator.gateway.journalPath(fixture.projectPath),
        ).exists(),
        isFalse,
      );
    });

    test('generic save queued behind recovery cannot overwrite the map delta',
        () async {
      final fixture = await _Fixture.create(
        crashAt: MapLifecycleTransactionCheckpoint.afterTargetWritten,
      );
      addTearDown(fixture.dispose);
      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      final recoveryCoordinator = MapLifecycleTransactionCoordinator(
        MapLifecycleTransactionFileGateway(
          mapRepository: FileMapRepository(),
        ),
      );
      final projectRepository = FileProjectRepository(
        mapLifecycleTransactions: recoveryCoordinator,
      );
      final staleGenericSave = fixture.before.copyWith(name: 'Stale save');

      await expectLater(
        projectRepository.saveProject(staleGenericSave, fixture.projectPath),
        throwsA(isA<EditorConflictException>()),
      );

      expect(await fixture.readProject(), fixture.after);
      expect(await File(fixture.targetPath).exists(), isTrue);
      expect(
        await File(
          recoveryCoordinator.gateway.journalPath(fixture.projectPath),
        ).exists(),
        isFalse,
      );
    });

    test('invalid journal blocks recovery and keeps its evidence', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final journal = File(fixture.gateway.journalPath(fixture.projectPath));
      await journal.parent.create(recursive: true);
      await journal.writeAsString(
        '{"schemaVersion":999,"operation":"create"}',
        flush: true,
      );
      final beforeBytes = await fixture.projectFile.readAsBytes();

      await expectLater(
        fixture.coordinator.recover(fixture.projectPath),
        throwsA(
          isA<ProjectRecoveryBlockedException>().having(
            (error) => error.code,
            'code',
            'mapLifecycleJournalInvalid',
          ),
        ),
      );

      expect(await fixture.projectFile.readAsBytes(), beforeBytes);
      expect(await journal.exists(), isTrue);
      expect(await File(fixture.targetPath).exists(), isFalse);
    });

    test('orphan journal rewrite is discarded without creating an intent',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final rewrite =
          File(fixture.gateway.journalRewritePath(fixture.projectPath));
      await rewrite.parent.create(recursive: true);
      await rewrite.writeAsString('partial', flush: true);

      expect(await fixture.gateway.readJournal(fixture.projectPath), isNull);

      expect(await rewrite.exists(), isFalse);
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        isFalse,
      );
    });

    test('journal paths outside project maps are rejected before durable I/O',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final outsideTarget = p.join(fixture.root.parent.path, 'outside.json');
      final request = MapLifecycleTransactionRequest.create(
        projectPath: fixture.projectPath,
        beforeProject: fixture.before,
        afterProject: fixture.after,
        targetPath: outsideTarget,
        targetMap: fixture.target,
      );

      await expectLater(
        fixture.coordinator.execute(request),
        throwsA(isA<EditorValidationException>()),
      );

      expect(await File(outsideTarget).exists(), isFalse);
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        isFalse,
      );
    });

    test('a symlink journal is blocked instead of following external bytes',
        () async {
      if (Platform.isWindows) return;
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final external = File(p.join(fixture.root.parent.path, 'external.json'));
      await external.writeAsString('external', flush: true);
      addTearDown(() async {
        if (await external.exists()) await external.delete();
      });
      final journalPath = fixture.gateway.journalPath(fixture.projectPath);
      await Directory(p.dirname(journalPath)).create(recursive: true);
      await Link(journalPath).create(external.path);

      await expectLater(
        fixture.coordinator.recover(fixture.projectPath),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );

      expect(await external.readAsString(), 'external');
      expect(
        await FileSystemEntity.type(journalPath, followLinks: false),
        FileSystemEntityType.link,
      );
    });
  });
}

final class _Fixture {
  _Fixture._({
    required this.root,
    required this.projectFile,
    required this.mapRepository,
    required this.gateway,
    required this.coordinator,
  });

  static Future<_Fixture> create({
    MapLifecycleTransactionCheckpoint? crashAt,
  }) async {
    final root = await Directory.systemTemp.createTemp('pokemap_ds05_');
    final projectFile = File(p.join(root.path, 'project.json'));
    await projectFile.writeAsString(
      const JsonEncoder.withIndent(' ').convert(<String, Object?>{
        ..._before.toJson(),
        'futureRoot': <String, Object?>{'preserved': true},
      }),
      flush: true,
    );
    final mapRepository = FileMapRepository();
    final gateway = MapLifecycleTransactionFileGateway(
      mapRepository: mapRepository,
    );
    final coordinator = MapLifecycleTransactionCoordinator(
      gateway,
      faultInjector: crashAt == null
          ? null
          : (checkpoint, _) {
              if (checkpoint == crashAt) {
                throw const MapLifecycleSimulatedCrash();
              }
            },
    );
    return _Fixture._(
      root: root,
      projectFile: projectFile,
      mapRepository: mapRepository,
      gateway: gateway,
      coordinator: coordinator,
    );
  }

  final Directory root;
  final File projectFile;
  final FileMapRepository mapRepository;
  final MapLifecycleTransactionFileGateway gateway;
  final MapLifecycleTransactionCoordinator coordinator;

  String get projectPath => projectFile.path;
  String get targetPath => p.join(root.path, 'maps', 'beta.json');
  ProjectManifest get before => _before;
  ProjectManifest get after => _after;
  MapData get target => _target;

  MapLifecycleTransactionRequest createRequest() {
    return MapLifecycleTransactionRequest.create(
      projectPath: projectPath,
      beforeProject: before,
      afterProject: after,
      targetPath: targetPath,
      targetMap: target,
    );
  }

  Future<Map<String, dynamic>> readRoot() async {
    return Map<String, dynamic>.from(
      jsonDecode(await projectFile.readAsString()) as Map,
    );
  }

  Future<ProjectManifest> readProject() async {
    return decodeValidatedNarrativeEventAuthoringProject(
      await projectFile.readAsBytes(),
    ).manifest;
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

const _before = ProjectManifest(
  name: 'DS-05',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
);

const _after = ProjectManifest(
  name: 'DS-05',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'beta',
      name: 'Beta',
      relativePath: 'maps/beta.json',
    ),
  ],
  tilesets: <ProjectTilesetEntry>[],
);

const _target = MapData(
  id: 'beta',
  name: 'Beta',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[],
);
