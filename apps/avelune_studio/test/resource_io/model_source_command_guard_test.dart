import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/domain/model_resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';
import 'package:avelune_studio/presentation/features/resources/model_resource_library.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late MapWorkspaceController workspace;
  late ResourceNavigation navigation;
  late _Port port;

  setUp(() async {
    workspace = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
    await workspace.initialize();
    port = _Port();
    navigation = ResourceNavigation(
      workspace: workspace,
      port: port,
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
    );
  });

  tearDown(() {
    navigation.dispose();
    workspace.dispose();
  });

  test(
    'pending publication blocks source picker and repeated mutations',
    () async {
      final receipt = _receipt();
      navigation.pendingReceipt = receipt;
      var picks = 0;
      for (var attempt = 0; attempt < 2; attempt++) {
        expect(
          await replaceStudioModelSource(
            navigation,
            'door',
            picker: () async {
              picks++;
              return null;
            },
          ),
          isNull,
        );
        expect(
          navigation.error,
          'Actualisez la publication précédente avant de remplacer un modèle.',
        );
        expect(navigation.pendingReceipt, same(receipt));
      }
      expect(picks, 0);
      expect(port.mutations, 0);
      expect(navigation.busy, false);
    },
  );

  for (final source in [true, false]) {
    testWidgets(
      '${source ? 'published source permits guarded close' : 'other pending publication blocks close'} without discarding map drafts',
      (tester) async {
        final receipt = _receipt(source: source);
        navigation.pendingReceipt = receipt;
        final document = workspace.active!;
        document.commit(document.current.copyWith(name: 'Brouillon conservé'));
        late WorkspaceActions actions;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                actions = WorkspaceActions(
                  controller: workspace,
                  context: () => context,
                  mounted: () => true,
                  changed: () {},
                  resources: () => navigation,
                  narrative: () => null,
                  runtimeBuilder: (_, _, _) => const SizedBox(),
                );
                return const Scaffold();
              },
            ),
          ),
        );
        final closing = actions.allowClose();
        await tester.pumpAndSettle();
        if (source) {
          expect(find.text('Conserver vos modifications ?'), findsOneWidget);
          await tester.tap(find.text('Annuler'));
          await tester.pumpAndSettle();
        }
        expect(await closing, false);
        expect(document.dirty, true);
        expect(document.current.name, 'Brouillon conservé');
        expect(navigation.pendingReceipt, same(receipt));
        expect(port.mutations, 0);
        if (source) {
          final confirmed = actions.allowClose();
          await tester.pumpAndSettle();
          await tester.tap(find.text('Abandonner'));
          await tester.pumpAndSettle();
          expect(await confirmed, true);
          expect(navigation.pendingReceipt, same(receipt));
          expect(document.current.name, 'Brouillon conservé');
          expect(port.mutations, 0);
        }
      },
    );
  }
}

ResourceMutationReceipt _receipt({bool source = true}) =>
    ResourceMutationReceipt(
      before: workspaceProject,
      manifest: workspaceProject,
      beforeRevision: 'before',
      revision: 'persisted',
      operationId: 'persisted-operation',
      actionId: source ? 'model3d.source.replace' : 'model3d.configure',
      changedPaths: const ['assets/models3d/door.glb'],
      changedModels: {
        'door': ProjectModel3dEntry(
          id: 'door',
          name: 'Porte',
          sourceAssetId: 'source-door',
          relativePath: 'assets/models3d/door.glb',
          inspection: Model3dInspection(
            bounds: Model3dBounds(
              min: Model3dVector3.zero,
              max: Model3dVector3(x: 1, y: 2, z: 1),
            ),
            meshCount: 1,
            triangleCount: 12,
          ),
        ),
      },
    );

final class _Port implements ResourcePort, ModelResourcePort {
  int mutations = 0;
  @override
  Future<ResourceMutationReceipt> replaceModelSource({
    required String modelId,
    required String sourcePath,
  }) async {
    mutations++;
    throw StateError('Unexpected source mutation');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
