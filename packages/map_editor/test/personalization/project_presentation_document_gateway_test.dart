import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/infrastructure/repositories/atomic_project_manifest_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/project_presentation_document_gateway.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('ProjectPresentationDocumentGateway', () {
    test('atomically saves only presentation and preserves unknown root data',
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
      final after = before.document.copyWith(presentation: profile);

      final result = await gateway.save(
        expectedRevision: before.revision,
        before: before.document,
        after: after,
        operationId: 'save-presentation-1',
      );

      expect(result, isA<NarrativeDocumentSaved<ProjectManifest>>());
      final durableRoot = jsonDecode(fixture.projectFile.readAsStringSync())
          as Map<String, dynamic>;
      expect(durableRoot['extensionOwned'], <String, dynamic>{'keep': true});
      expect(
        ProjectManifest.fromJson(durableRoot).presentation,
        profile,
      );
      expect(
        fixture.root.listSync().where((entry) => entry.path.endsWith('.tmp')),
        isEmpty,
      );
    });

    test('reports a conflict without replacing an externally changed project',
        () async {
      final fixture = _GatewayFixture.create();
      addTearDown(fixture.dispose);
      final gateway = ProjectPresentationDocumentGateway(
        projectPath: fixture.projectFile.path,
        persistence: const AtomicProjectManifestPersistence(),
      );
      final before = await gateway.read();
      final external = before.document.copyWith(name: 'External edit');
      fixture.writeProject(external);
      final externalBytes = fixture.projectFile.readAsBytesSync();
      final local = before.document.copyWith(
        presentation: const ProjectPresentationProfile(
          branding: ProjectBrandingProfile(accentColor: '#123456'),
        ),
      );

      final result = await gateway.save(
        expectedRevision: before.revision,
        before: before.document,
        after: local,
        operationId: 'stale-presentation-save',
      );

      expect(result, isA<NarrativeDocumentSaveConflicted<ProjectManifest>>());
      expect(fixture.projectFile.readAsBytesSync(), externalBytes);
    });

    test('rejects a mutation outside the presentation profile', () async {
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
        after: before.document.copyWith(name: 'Not a presentation edit'),
        operationId: 'invalid-presentation-save',
      );

      expect(
        result,
        isA<NarrativeDocumentSaveFailed<ProjectManifest>>().having(
            (value) => value.code, 'code', 'unsupportedDocumentMutation'),
      );
      expect(
        (await gateway.read()).document,
        before.document,
      );
    });
  });
}

final class _GatewayFixture {
  _GatewayFixture._({
    required this.root,
    required this.projectFile,
    required this.initialProject,
  });

  factory _GatewayFixture.create() {
    final root =
        Directory.systemTemp.createTempSync('presentation-gateway-test-');
    final projectFile = File('${root.path}/project.json');
    final project = buildShellChromeProject(name: 'Presentation gateway');
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

  void dispose() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
