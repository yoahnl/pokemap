import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/project_model_replacement_port.dart';
import 'package:avelune_studio/features/resources/domain/project_model_workshop_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_page.dart';
import 'package:avelune_studio/presentation/features/resources/project_model_replacement_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'explicit index preparation populates the initially unavailable map usages',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final library = _ReplacementLibrary();
      final editor = _ReplacementEditor();
      final maps = MapWorkspaceController(workspaceSession, library);
      addTearDown(maps.dispose);
      await maps.initialize();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectLibraryPage(
              active: true,
              maps: maps,
              visuals: null,
              management: (editor: editor, pickFile: () async => null),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(library.usageRevisions, ['before']);
      await tester.tap(find.text('Ateliers'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('library-workshop-model3d:tree')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-workshop-replace-usages')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Frêne'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vérifier les usages'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Préparer le catalogue'));
      await tester.pumpAndSettle();
      expect(find.text('Arbre → Frêne'), findsOneWidget);
      expect(library.usageRevisions, ['before', 'indexed']);
      expect(library.libraryReads, 1);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retour à la bibliothèque'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('library-item-model3d:tree')));
      await tester.pumpAndSettle();
      expect(find.text('Utilisation dans les cartes'), findsOneWidget);
    },
  );

  testWidgets(
    'review, publication retry and exact undo are distinct gestures',
    (tester) async {
      final port = _Replacement();
      var rejectPublication = true;
      ModelReplacementPanelStatus? status;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectModelReplacementPanel(
              item: ProjectLibraryItem(
                kind: 'model3d',
                id: 'tree',
                name: 'Arbre',
              ),
              models: [
                ProjectLibraryItem(
                  kind: 'model3d',
                  id: 'alternate',
                  name: 'Frêne',
                ),
              ],
              familyLabels: const {},
              available: true,
              revision: 'before',
              showPreview: false,
              pickFile: () async => null,
              port: port,
              prepareCatalog: () async => 'prepared',
              checkDrafts: (resources, models) => null,
              synchronize: (commit) async {
                if (rejectPublication) {
                  throw const ResourceFailure('Relecture indisponible.');
                }
              },
              onRevision: (_) {},
              onPublished: (_) {},
              onBusyChanged: (_) {},
              onStatusChanged: (value) => status = value,
            ),
          ),
        ),
      );

      Future<void> review() async {
        await tester.tap(
          find.byKey(const ValueKey('model-workshop-replace-usages')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Frêne'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vérifier les usages'));
        await tester.pumpAndSettle();
        expect(find.text('Arbre → Frêne'), findsOneWidget);
        expect(find.text('1 carte · 1 bordure'), findsOneWidget);
        expect(
          find.text('2 placements redirigés · 4 recalculés'),
          findsOneWidget,
        );
        expect(find.text('Bordure · Haie'), findsOneWidget);
      }

      await review();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(port.applications, 0);
      expect(port.releases, 1);
      await review();
      await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
      await tester.pumpAndSettle();
      expect(port.applications, 1);
      expect(status?.pending, isTrue);
      expect(find.text('Relire la publication'), findsOneWidget);

      rejectPublication = false;
      await tester.tap(find.text('Relire la publication'));
      await tester.pumpAndSettle();
      expect(port.applications, 1);
      expect(status?.pending, isFalse);
      expect(find.text('Usages redirigés.'), findsOneWidget);
      final undo = find.byKey(
        const ValueKey('model-workshop-undo-replacement'),
      );
      await tester.tap(undo);
      await tester.pumpAndSettle();
      expect(port.undoneEntry, 'canonical-entry');
      expect(find.text('Usages précédents restaurés.'), findsOneWidget);
      expect(status, isNull);
    },
  );
}

class _Replacement implements ProjectModelReplacementPort {
  var applications = 0;
  var releases = 0;
  String? undoneEntry;
  bool needsPreparation = false;

  @override
  Future<ProjectModelSourceReplacement> prepareSource({
    required String modelId,
    required PickedProjectLibraryFile file,
    required String expectedRevision,
  }) => throw UnimplementedError();

  @override
  Future<ProjectModelUsageReplacement> prepareUsages({
    required String modelId,
    required String replacementId,
    required String expectedRevision,
  }) async => needsPreparation
      ? throw const ProjectLibraryNeedsPreparation()
      : ProjectModelUsageReplacement(
          sourceId: modelId,
          targetId: replacementId,
          affectedMapIds: const {'park'},
          maps: const [
            (id: 'park', name: 'Parc', redirected: 2, recalculated: 4),
          ],
          borders: const {'hedge': 'Haie'},
          redirected: 2,
          recalculated: 4,
          noChange: false,
        );

  ProjectModelReplacementCommit _commit({bool restored = false}) =>
      ProjectModelReplacementCommit(
        entryId: 'canonical-entry',
        restorationOperationId: 'restore-operation',
        publication: _receipt('before', 'after'),
        restoration: _receipt('after', 'before'),
        sourceModelId: 'tree',
        targetModelId: 'alternate',
        resources: const {(kind: 'map', id: 'park')},
        restored: restored,
      );

  ResourceMutationReceipt _receipt(String before, String after) =>
      ResourceMutationReceipt(
        before: workspaceProject,
        manifest: workspaceProject,
        beforeRevision: before,
        revision: after,
        changedPaths: const ['maps/park.json'],
      );

  @override
  Future<ProjectModelReplacementCommit> apply(
    ProjectModelReplacement preparation, {
    required String? Function() checkDrafts,
  }) async {
    applications++;
    return _commit();
  }

  @override
  Future<ProjectModelReplacementCommit> undo(
    ProjectModelReplacementCommit commit, {
    required String? Function() checkDrafts,
  }) async {
    undoneEntry = commit.entryId;
    return _commit(restored: true);
  }

  @override
  Future<void> reconcile(ProjectModelReplacementCommit commit) async {}

  @override
  Future<void> release(ProjectModelReplacement preparation) async => releases++;
}

class _ReplacementLibrary extends WorkspaceMemoryPort
    implements ProjectResourceLibraryPort, ProjectResourceLibraryMapUsagesPort {
  int libraryReads = 0;
  final usageRevisions = <String>[];

  @override
  Future<ProjectResourceLibrary> readResourceLibrary(
    ProjectSession session,
  ) async {
    libraryReads++;
    return ProjectResourceLibrary(ResourceLibraryCatalog(), [
      ProjectLibraryItem(kind: 'model3d', id: 'tree', name: 'Arbre'),
      ProjectLibraryItem(kind: 'model3d', id: 'alternate', name: 'Frêne'),
    ], revision: 'before');
  }

  @override
  Future<Map<String, Set<String>>?> readResourceLibraryMapUsages(
    ProjectSession session, {
    required String revision,
    required Iterable<String> identities,
  }) async {
    usageRevisions.add(revision);
    return revision == 'indexed'
        ? {
            'model3d:tree': {'a'},
          }
        : null;
  }
}

class _ReplacementEditor
    implements
        ProjectLibraryEditor,
        ProjectModelWorkshopPort,
        ProjectModelReplacementProvider {
  @override
  final _Replacement modelReplacement = _Replacement()..needsPreparation = true;

  @override
  Future<ProjectModelWorkshopRead> readWorkshopModel(String modelId) async => (
    model: ProjectModel3dEntry(
      id: modelId,
      name: 'Arbre',
      relativePath: 'assets/models3d/$modelId.glb',
      sourceAssetId: '$modelId-source',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 1, z: 1),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    ),
    revision: 'before',
  );

  @override
  Future<ResourceMutationReceipt> prepareResourceIndexes({
    required String expectedSnapshotRevision,
  }) async {
    modelReplacement.needsPreparation = false;
    return modelReplacement._receipt(expectedSnapshotRevision, 'indexed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
