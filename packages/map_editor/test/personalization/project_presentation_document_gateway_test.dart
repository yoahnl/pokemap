import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/features/personalization/application/project_presentation_asset_lifecycle.dart';
import 'package:map_editor/src/infrastructure/repositories/atomic_project_manifest_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/project_presentation_document_gateway.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('ProjectPresentationDocumentGateway', () {
    test(
      'atomically saves only presentation and preserves unknown root data',
      () async {
        final fixture = _GatewayFixture.create();
        addTearDown(fixture.dispose);
        final gateway = ProjectPresentationDocumentGateway(
          projectPath: fixture.projectFile.path,
          persistence: const AtomicProjectManifestPersistence(),
        );
        final before = await gateway.read();
        const profile = ProjectPresentationProfile(
          branding: ProjectBrandingProfile(
            accentColor: '#123456',
            layoutVariant: 'cinematic',
          ),
        );
        final result = await gateway.save(
          expectedRevision: before.revision,
          before: before.document,
          after: profile,
          operationId: 'save-presentation-1',
        );

        expect(
          result,
          isA<NarrativeDocumentSaved<ProjectPresentationProfile>>(),
        );
        final durableRoot =
            jsonDecode(fixture.projectFile.readAsStringSync())
                as Map<String, dynamic>;
        expect(durableRoot['extensionOwned'], <String, dynamic>{'keep': true});
        expect(ProjectManifest.fromJson(durableRoot).presentation, profile);
        expect(
          fixture.root.listSync().where((entry) => entry.path.endsWith('.tmp')),
          isEmpty,
        );
      },
    );

    test(
      'reports a conflict without replacing an externally changed project',
      () async {
        final fixture = _GatewayFixture.create();
        addTearDown(fixture.dispose);
        final gateway = ProjectPresentationDocumentGateway(
          projectPath: fixture.projectFile.path,
          persistence: const AtomicProjectManifestPersistence(),
        );
        final before = await gateway.read();
        final external = fixture.initialProject.copyWith(name: 'External edit');
        fixture.writeProject(external);
        final externalBytes = fixture.projectFile.readAsBytesSync();
        const local = ProjectPresentationProfile(
          branding: ProjectBrandingProfile(accentColor: '#123456'),
        );

        final result = await gateway.save(
          expectedRevision: before.revision,
          before: before.document,
          after: local,
          operationId: 'stale-presentation-save',
        );

        expect(
          result,
          isA<NarrativeDocumentSaveConflicted<ProjectPresentationProfile>>(),
        );
        expect(fixture.projectFile.readAsBytesSync(), externalBytes);
      },
    );

    test('uses the canonical presentation mutation when configured', () async {
      final fixture = _GatewayFixture.create();
      addTearDown(fixture.dispose);
      var canonicalSaveCalls = 0;
      final gateway = ProjectPresentationDocumentGateway(
        projectPath: fixture.projectFile.path,
        canonicalSave:
            ({
              required profile,
              required expectedProjectRevision,
              required operationId,
            }) async {
              canonicalSaveCalls++;
              expect(expectedProjectRevision, isNotEmpty);
              expect(operationId, 'canonical-presentation-save');
              final current = ProjectManifest.fromJson(
                jsonDecode(fixture.projectFile.readAsStringSync())
                    as Map<String, dynamic>,
              );
              fixture.writeProject(current.copyWith(presentation: profile));
            },
      );
      final before = await gateway.read();
      const profile = ProjectPresentationProfile(
        pause: ProjectPausePresentationProfile(
          actions: <ProjectPauseActionProfile>[
            ProjectPauseActionProfile(id: ProjectPauseActionId.resume),
            ProjectPauseActionProfile(
              id: ProjectPauseActionId.pokedex,
              label: 'Carnet',
            ),
          ],
        ),
      );

      final result = await gateway.save(
        expectedRevision: before.revision,
        before: before.document,
        after: profile,
        operationId: 'canonical-presentation-save',
      );

      expect(result, isA<NarrativeDocumentSaved<ProjectPresentationProfile>>());
      expect(canonicalSaveCalls, 1);
      expect((await gateway.read()).document, profile);
    });

    test(
      'reports an explicit failure when the canonical mutation rejects',
      () async {
        final fixture = _GatewayFixture.create();
        addTearDown(fixture.dispose);
        final gateway = ProjectPresentationDocumentGateway(
          projectPath: fixture.projectFile.path,
          canonicalSave:
              ({
                required profile,
                required expectedProjectRevision,
                required operationId,
              }) async {
                throw StateError('validation rejected');
              },
        );
        final before = await gateway.read();

        final result = await gateway.save(
          expectedRevision: before.revision,
          before: before.document,
          after: const ProjectPresentationProfile(
            menuLabels: ProjectMenuLabelsProfile(pokedex: 'Carnet'),
          ),
          operationId: 'rejected-canonical-presentation-save',
        );

        expect(
          result,
          isA<NarrativeDocumentSaveFailed<ProjectPresentationProfile>>()
              .having(
                (value) => value.code,
                'code',
                'canonicalPresentationUpdateFailed',
              )
              .having(
                (value) => value.message,
                'message',
                contains('validation rejected'),
              ),
        );
        expect((await gateway.read()).document, before.document);
      },
    );

    test('preserves project fields outside the presentation profile', () async {
      final fixture = _GatewayFixture.create();
      addTearDown(fixture.dispose);
      final gateway = ProjectPresentationDocumentGateway(
        projectPath: fixture.projectFile.path,
        persistence: const AtomicProjectManifestPersistence(),
      );
      final before = await gateway.read();

      final result = await gateway.save(
        expectedRevision: before.revision,
        before: before.document,
        after: const ProjectPresentationProfile(
          branding: ProjectBrandingProfile(accentColor: '#456789'),
        ),
        operationId: 'profile-only-presentation-save',
      );

      expect(result, isA<NarrativeDocumentSaved<ProjectPresentationProfile>>());
      final durable = ProjectManifest.fromJson(
        jsonDecode(fixture.projectFile.readAsStringSync())
            as Map<String, dynamic>,
      );
      expect(durable.name, fixture.initialProject.name);
      expect(durable.maps, fixture.initialProject.maps);
    });

    test(
      'cleans replaced presentation assets only after a durable save',
      () async {
        final oldProfile = ProjectPresentationProfile(
          intro: ProjectIntroVideoProfile.fromLandscape(
            videoPath: 'assets/presentation/intro/old.mp4',
            posterPath: 'assets/presentation/intro/old.png',
            durationMilliseconds: 1,
            width: 1,
            height: 1,
            bitrateKbps: 1,
            sizeBytes: 1,
            videoCodec: 'h264',
          ),
        );
        final newProfile = ProjectPresentationProfile(
          intro: ProjectIntroVideoProfile.fromLandscape(
            videoPath: 'assets/presentation/intro/new.mp4',
            posterPath: 'assets/presentation/intro/new.png',
            durationMilliseconds: 1,
            width: 1,
            height: 1,
            bitrateKbps: 1,
            sizeBytes: 1,
            videoCodec: 'h264',
          ),
        );
        final fixture = _GatewayFixture.create(presentation: oldProfile);
        addTearDown(fixture.dispose);
        final oldVideo = fixture.writeAsset(
          'assets/presentation/intro/old.mp4',
        );
        final oldPoster = fixture.writeAsset(
          'assets/presentation/intro/old.png',
        );
        final newVideo = fixture.writeAsset(
          'assets/presentation/intro/new.mp4',
        );
        final newPoster = fixture.writeAsset(
          'assets/presentation/intro/new.png',
        );
        final gateway = ProjectPresentationDocumentGateway(
          projectPath: fixture.projectFile.path,
          persistence: const AtomicProjectManifestPersistence(),
        );
        final before = await gateway.read();

        final result = await gateway.save(
          expectedRevision: before.revision,
          before: before.document,
          after: newProfile,
          operationId: 'replace-presentation-assets',
        );

        expect(
          result,
          isA<NarrativeDocumentSaved<ProjectPresentationProfile>>(),
        );
        expect(oldVideo.existsSync(), isFalse);
        expect(oldPoster.existsSync(), isFalse);
        expect(newVideo.existsSync(), isTrue);
        expect(newPoster.existsSync(), isTrue);
        expect(gateway.lastAssetCleanupResult?.deletedPaths, <String>{
          'assets/presentation/intro/old.mp4',
          'assets/presentation/intro/old.png',
        });
      },
    );

    test(
      'cleanup failure never turns a committed save into a failed save',
      () async {
        final fixture = _GatewayFixture.create();
        addTearDown(fixture.dispose);
        final gateway = ProjectPresentationDocumentGateway(
          projectPath: fixture.projectFile.path,
          persistence: const AtomicProjectManifestPersistence(),
          assetCleaner: const _ThrowingAssetCleaner(),
        );
        final before = await gateway.read();

        final result = await gateway.save(
          expectedRevision: before.revision,
          before: before.document,
          after: const ProjectPresentationProfile(
            branding: ProjectBrandingProfile(accentColor: '#123456'),
          ),
          operationId: 'save-despite-cleanup-error',
        );

        expect(
          result,
          isA<NarrativeDocumentSaved<ProjectPresentationProfile>>(),
        );
        expect(gateway.lastAssetCleanupResult?.failures, isNotEmpty);
      },
    );
  });
}

final class _GatewayFixture {
  _GatewayFixture._({
    required this.root,
    required this.projectFile,
    required this.initialProject,
  });

  factory _GatewayFixture.create({ProjectPresentationProfile? presentation}) {
    final root = Directory.systemTemp.createTempSync(
      'presentation-gateway-test-',
    );
    final projectFile = File('${root.path}/project.json');
    final project = buildShellChromeProject(
      name: 'Presentation gateway',
    ).copyWith(presentation: presentation);
    final fixture = _GatewayFixture._(
      root: root,
      projectFile: projectFile,
      initialProject: project,
    );
    fixture.writeProject(project);
    return fixture;
  }

  final Directory root;
  final File projectFile;
  final ProjectManifest initialProject;

  void writeProject(ProjectManifest project) {
    final rootJson = <String, dynamic>{
      ...project.toJson(),
      'extensionOwned': <String, dynamic>{'keep': true},
    };
    projectFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(rootJson),
      flush: true,
    );
  }

  File writeAsset(String relativePath) {
    final file = File('${root.path}/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(relativePath);
    return file;
  }

  void dispose() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}

final class _ThrowingAssetCleaner implements ProjectPresentationAssetCleaner {
  const _ThrowingAssetCleaner();

  @override
  Future<ProjectPresentationAssetCleanupResult> cleanStaleAssets({
    required Directory projectRoot,
    required ProjectPresentationProfile previousProfile,
    required ProjectPresentationProfile currentProfile,
  }) {
    throw StateError('cleanup failed');
  }
}
