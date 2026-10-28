import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final action in [
    'presentation.delete',
    'presentation.reset_interface'
  ]) {
    final reads = <int>[];
    for (final unrelated in [0, 128]) {
      test('$action preserves unrelated content with $unrelated records',
          () async {
        final root = Directory(
            '/Users/karim/Library/Caches/AveluneQA/hgss-interface-reset/fixture');
        await root.create(recursive: true);
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        final store = await CatalogStorageStore.open(projectRoot: root.path);
        const profile = ProjectPresentationProfile(
            branding: ProjectBrandingProfile(
                heroPath: 'presentation/shared.png',
                titleMusicPath: 'presentation/shared.m4a',
                accentColor: '#C68D29'),
            title: ProjectTitlePresentationProfile(title: 'Keep startup'),
            intro: ProjectIntroVideoProfile(
                media: ProjectResponsiveVideoProfile(
                    landscape: ProjectVideoVariantProfile(
                        videoPath: 'presentation/intro.mp4',
                        posterPath: 'presentation/shared.png',
                        durationMilliseconds: 5000,
                        width: 1280,
                        height: 720,
                        bitrateKbps: 1000,
                        sizeBytes: 100,
                        videoCodec: 'h264',
                        audioCodec: 'aac'))),
            dialogue:
                ProjectDialoguePresentationProfile(borderColor: '#D7A32C'),
            surfacePalettes: ProjectPresentationSurfacePalettesProfile(
                title: ProjectSurfacePaletteProfile(accent: '#14532D'),
                pauseMenu: ProjectSurfacePaletteProfile(surface: '#FFFDF7')));
        expect(
            validateProjectPresentationProfile(profile)
                .where((d) =>
                    d.severity == ProjectPresentationDiagnosticSeverity.error)
                .map((d) => '${d.code}: ${d.path}'),
            isEmpty);
        final working = await WorkingProjectCatalog.create(
            store: store,
            projectId: 'presentation-reset',
            project: ProjectManifest(
                name: 'Reset',
                version: ProjectVersion.v9,
                settings:
                    const ProjectSettings(dimension: ProjectDimension.threeD),
                presentation: profile,
                maps: const [],
                tilesets: const [
                  ProjectTilesetEntry(
                      id: 'shared',
                      name: 'Shared',
                      relativePath: 'presentation/shared.png')
                ],
                facts: [
                  for (var i = 0; i < unrelated; i++)
                    NarrativeFactDefinition(id: 'fact-$i', label: 'Fact $i')
                ]));
        final image = File('${root.path}/presentation/shared.png');
        await image.parent.create(recursive: true);
        await image.writeAsBytes([1, 2, 3, 4]);
        final entry = (await working.catalog.snapshot.indexEntry(
            CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'shared')))!;
        final unrelatedObject =
            'catalog/objects/${entry.reference.sha256}.json';
        await File('${root.path}/$unrelatedObject')
            .writeAsString('Unrelated object must not be read');
        final reader = _CountingReader();
        final policy = await WorkspacePolicy.create(
            allowedRootPaths: [root.path], fileReader: reader);
        final handles = WorkspaceHandleStore();
        final opener = ProjectOpenService(
            policy: policy,
            fileReader: reader,
            handles: handles,
            catalogMetadataFields: {});
        final opened = await opener.openProject(root.path);
        final api = LocalMapAuthoringMutationApi(
            policy: policy,
            snapshotLoader: ProjectSnapshotLoader(handles: handles),
            catalogFileReader: reader);
        await api.attachProject(
            projectRootPath: root.path,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle);
        addTearDown(() async {
          await api.detachWorkspace(opened.workspaceHandle);
          handles.closeWorkspace(opened.workspaceHandle);
          await root.delete(recursive: true);
        });
        final descriptor =
            await File('${root.path}/project.json').readAsBytes();
        for (var attempt = 0; attempt < 2; attempt++) {
          reader.paths.clear();
          final timer = Stopwatch()..start();
          final scope = await api.readWorkshopSnapshot(opened.projectHandle,
              actionId: action);
          expect(scope.availableProjectSections, {'presentation'});
          expect(scope.manifest.presentation, profile);
          expect(scope.manifest.maps, isEmpty);
          expect(scope.manifest.tilesets, isEmpty);
          final plan = await api.planMutation(
              opened.projectHandle,
              AuthoringRequest(
                  requestId: 'reset-$attempt',
                  actionId: action,
                  actionVersion: 1,
                  workspaceHandle: opened.workspaceHandle.value,
                  expectedRevision: scope.revision,
                  idempotencyKey: 'reset-$attempt',
                  parameters: const {}));
          final confirmation = await api.confirmMutation(opened.projectHandle,
              planId: plan.planId);
          final applied = await api.applyMutation(opened.projectHandle,
              planId: plan.planId,
              operationId: 'reset-$attempt',
              confirmationToken: confirmation.confirmationToken);
          final count = reader.paths.length;
          reads.add(count);
          expect(reader.paths, isNot(contains(unrelatedObject)));
          expect(
              reader.paths.where((p) =>
                  p.startsWith('maps/') ||
                  p.startsWith('presentation/') ||
                  p.startsWith('assets/')),
              isEmpty);
          expect(await image.readAsBytes(), [1, 2, 3, 4]);
          expect(await File('${root.path}/project.json').readAsBytes(),
              descriptor);
          final reopened = await api.readWorkshopSnapshot(opened.projectHandle,
              actionId: action);
          final after = reopened.manifest.presentation;
          if (action == 'presentation.delete') {
            expect(after, isNull);
          } else {
            expect(after!.branding, profile.branding);
            expect(after.title, profile.title);
            expect(after.intro, profile.intro);
            expect(after.titleMotion, profile.titleMotion);
            expect(after.dialogue, isNull);
            expect(after.windows, isNull);
            expect(after.theme, isNull);
            expect(after.pause, isNull);
            expect(after.battle, isNull);
            expect(
                after.surfacePalettes!.title, profile.surfacePalettes!.title);
            expect(after.surfacePalettes!.pauseMenu, isNull);
          }
          final persisted = await WorkingProjectCatalog.open(
              store: store,
              descriptor: WorkingProjectCatalogDescriptor.fromJson(
                  Map<String, dynamic>.from(
                      jsonDecode(utf8.decode(descriptor)))),
              metadataFields: {'presentation', 'settings'});
          expect(persisted.catalog.projectMetadata.settings.dimension,
              ProjectDimension.threeD);
          expect(persisted.catalog.projectMetadata.presentation, after);
          print(jsonEncode({
            'unrelated': unrelated,
            'action': action,
            'attempt': attempt,
            'reads': count,
            'durableMs': timer.elapsedMilliseconds
          }));
          await api.undoMutation(opened.projectHandle,
              entryId: applied.receipt.receiptId,
              idempotencyKey: 'undo-reset-$attempt');
          final restored = await api.readWorkshopSnapshot(opened.projectHandle,
              actionId: action);
          expect(restored.manifest.presentation, profile);
        }
        if (unrelated > 0) {
          expect(
              reads.reduce((a, b) => a > b ? a : b) -
                  reads.reduce((a, b) => a < b ? a : b),
              lessThan(12));
        }
      });
    }
  }
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
}
