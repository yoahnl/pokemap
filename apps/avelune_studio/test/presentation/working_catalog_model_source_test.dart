import 'dart:async';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/working_catalog_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:avelune_studio/presentation/features/resources/working_catalog_workspace.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'source replacement refreshes only the selected detail and remounts unchanged inspection preview',
    (tester) async {
      final port = _Port();
      final complete = Completer<bool>();
      var calls = 0;
      final fixture = await _mount(tester, port, (_) {
        calls++;
        return complete.future;
      });
      await _tap(tester);
      expect(calls, 1);
      expect(find.text('Remplacement…'), findsOneWidget);
      expect(await fixture.exit!(), false);
      port.color = 'nouvelle couleur';
      complete.complete(true);
      await tester.pumpAndSettle();
      expect(port.opens, 2);
      expect(port.queries, 1);
      expect(fixture.globalRefreshes, 0);
      expect(find.text('nouvelle couleur'), findsOneWidget);
      expect(find.text('Modèle remplacé.'), findsOneWidget);
      expect(await fixture.exit!(), true);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'dirty model metadata blocks replacement without dropping its draft',
    (tester) async {
      final port = _Port();
      var calls = 0;
      final fixture = await _mount(tester, port, (_) async {
        calls++;
        return true;
      });
      fixture.controller.edit(name: 'Mon brouillon');
      await tester.pump();
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('working-model-source-replace')),
            )
            .onPressed,
        isNull,
      );
      expect(calls, 0);
      expect(fixture.controller.draft!.name, 'Mon brouillon');
      expect(port.opens, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final refused in [false, true]) {
    testWidgets(
      'source ${refused ? 'refusal' : 'picker cancellation'} keeps selected detail and preview',
      (tester) async {
        final port = _Port();
        await _mount(tester, port, (_) async {
          if (refused) {
            throw const ResourceFailure(
              'Conservez les deux animations de porte.',
            );
          }
          return false;
        });
        await _tap(tester);
        await tester.pumpAndSettle();
        expect(port.opens, 1);
        expect(port.queries, 1);
        expect(find.text('couleur initiale'), findsOneWidget);
        expect(find.text('Modèle remplacé.'), findsNothing);
        if (refused) {
          expect(
            find.text('Conservez les deux animations de porte.'),
            findsOneWidget,
          );
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'published source reconciliation retries without publishing another source',
    (tester) async {
      final port = _Port();
      var publications = 0, callbacks = 0;
      final fixture = await _mount(tester, port, (_) async {
        callbacks++;
        if (callbacks == 1) {
          publications++;
          throw ResourceFailure(
            'Publication conservée : actualisez le modèle.',
            partialReceipt: ResourceMutationReceipt(
              before: _project,
              manifest: _project,
              beforeRevision: 'a',
              revision: 'b',
              changedPaths: const ['assets/models3d/door.glb'],
            ),
          );
        }
        return true;
      });
      await _tap(tester);
      await tester.pumpAndSettle();
      expect(await fixture.exit!(), true);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('working-resource-model3d:door')),
            )
            .onTap,
        isNull,
      );
      expect(find.text('Actualiser le modèle'), findsOneWidget);
      await _tap(tester);
      await tester.pumpAndSettle();
      expect(publications, 1);
      expect(callbacks, 2);
      expect(port.opens, 2);
      expect(port.queries, 1);
      expect(await fixture.exit!(), true);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'failed detail refresh retries the read without reopening the source picker',
    (tester) async {
      final port = _Port();
      var replacements = 0;
      final fixture = await _mount(tester, port, (_) async {
        replacements++;
        port.failOpen = true;
        return true;
      });
      await _tap(tester);
      await tester.pumpAndSettle();
      expect(find.text('Actualiser le modèle'), findsOneWidget);
      expect(await fixture.exit!(), true);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('working-resource-model3d:door')),
            )
            .onTap,
        isNull,
      );
      await _tap(tester);
      await tester.pumpAndSettle();
      expect(replacements, 1);
      expect(port.opens, 3);
      expect(port.queries, 1);
      expect(await fixture.exit!(), true);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<void> _tap(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('working-model-source-replace'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

final class _Fixture {
  _Fixture(this.controller);
  final WorkingCatalogController controller;
  Future<bool> Function()? exit;
  int globalRefreshes = 0;
}

Future<_Fixture> _mount(
  WidgetTester tester,
  _Port port,
  Future<bool> Function(String) replace,
) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final fixture = _Fixture(WorkingCatalogController(port));
  addTearDown(fixture.controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: WorkingCatalogWorkspace(
        session: const ProjectSession(
          sessionId: 'source',
          name: 'Projet',
          directoryPath: '/project',
          storage: ProjectSessionStorage.workingCatalog,
        ),
        controller: fixture.controller,
        onClose: () async {},
        registerExitGuard: (value) => fixture.exit = value,
        onSaved: () async {
          fixture.globalRefreshes++;
        },
        onReplaceModelSource: replace,
        previewBuilder: (_) => _Preview(port),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await fixture.controller.select(_entry);
  await tester.pumpAndSettle();
  expect(fixture.controller.error, isNull);
  expect(fixture.controller.detail?.definitions.models3d, hasLength(1));
  return fixture;
}

const _entry = WorkingCatalogEntry(id: 'door', kind: 'model3d', name: 'Porte');
final _project = ProjectManifest(
  name: 'Projection',
  maps: const [],
  tilesets: const [],
  models3d: [
    ProjectModel3dEntry(
      id: 'door',
      name: 'Porte',
      sourceAssetId: 'door-source',
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
  ],
);

final class _Port implements WorkingCatalogPort {
  final identity = Object();
  int queries = 0, opens = 0;
  String color = 'couleur initiale';
  bool failOpen = false;
  @override
  Future<WorkingCatalogPage> query({
    required String kind,
    required String text,
    String? cursor,
    String? placementContext,
  }) async {
    queries++;
    return WorkingCatalogPage(revision: 'r', items: const [_entry], total: 1);
  }

  @override
  Future<WorkingCatalogDetail> open(WorkingCatalogEntry entry) async {
    opens++;
    if (failOpen) {
      failOpen = false;
      throw StateError('Lecture momentanément indisponible');
    }
    return WorkingCatalogDetail(
      entry: _entry,
      revision: 'r',
      definitions: _project,
      previewIdentity: identity,
    );
  }

  @override
  Future<void> close() async {}
  @override
  Future<void> recover(String operationId) async {}
  @override
  Future<WorkingCatalogDetail> save(
    WorkingCatalogEntry entry,
    WorkingCatalogDraft draft, {
    required String revision,
  }) => throw StateError('Unexpected metadata save');
}

class _Preview extends StatefulWidget {
  const _Preview(this.port);
  final _Port port;
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  late final color = widget.port.color;
  @override
  Widget build(BuildContext context) => Text(color);
}
