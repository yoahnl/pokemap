import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/border_creation_dialog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_border_fixture.dart';

class _BorderRequestPort implements ResourcePort {
  _BorderRequestPort(this.project);
  final ProjectManifest project;
  final requests = <BorderCreationRequest>[];

  @override
  Future<ResourceMutationReceipt> createBorder(
    BorderCreationRequest request,
  ) async {
    requests.add(request);
    return ResourceMutationReceipt(
      before: project,
      manifest: project,
      beforeRevision: 'r0',
      revision: 'r0',
      changedPaths: const [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EditableMapDocument _traced(String mapId, String name, String borderId) =>
    EditableMapDocument(
      MapWorkspaceDocument(
        mapId: mapId,
        revision: 'r1',
        map: workspaceMap(mapId).copyWith(
          name: name,
          layers: [
            BorderLayer(
              id: '$mapId-border',
              name: 'Falaises',
              content: BorderLayerContent(
                features: [
                  for (final index in [0, 1])
                    BorderFeature(
                      id: '$mapId-feature-$index',
                      name: 'Falaise $index',
                      blueprintId: borderId,
                      seed: BorderSignedInt64.zero,
                      geometry: BorderRegionGeometry(
                        width: 1,
                        height: 1,
                        cells: [true],
                      ),
                      overrides: const [],
                      keepOutRegions: const [],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

Future<(_BorderRequestPort, String)> _open(
  WidgetTester tester, {
  required bool traced,
}) async {
  tester.view.physicalSize = const Size(1440, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = spatialBorderProject();
  final record = project.borderCatalog.records.single;
  final controller = MapWorkspaceController(
    workspaceSession,
    WorkspaceMemoryPort(),
  )..project = project;
  if (traced) {
    controller.documents['route'] = _traced('route', 'Route 30', record.id);
  }
  final port = _BorderRequestPort(project);
  final navigation = ResourceNavigation(
    workspace: controller,
    port: port,
    visuals: WorkspaceTestVisuals(),
    onUse: (_) {},
  );
  addTearDown(navigation.dispose);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => StudioButton(
            label: 'Modifier',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BorderCreationDialog(
                navigation: navigation,
                project: project,
                visuals: WorkspaceTestVisuals(),
                initialRecord: record,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Modifier'));
  await tester.pumpAndSettle();
  expect(record.latestPublished, isNotNull);
  return (port, record.id);
}

Future<void> _publish(WidgetTester tester) async {
  final publish = find.byKey(const ValueKey('border-publish'));
  await tester.ensureVisible(publish);
  await tester.pumpAndSettle();
  await tester.tap(publish);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'republishing a border traced on an open map asks for a scope review first',
    (tester) async {
      final (port, borderId) = await _open(tester, traced: true);
      await _publish(tester);
      expect(find.byKey(const ValueKey('border-scope-review')), findsOneWidget);
      expect(find.textContaining('2 contours'), findsOneWidget);
      expect(find.textContaining('Route 30'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('border-scope-cancel')));
      await tester.pumpAndSettle();
      expect(port.requests, isEmpty);
      expect(find.byKey(const ValueKey('border-publish')), findsOneWidget);

      await _publish(tester);
      await tester.tap(find.byKey(const ValueKey('border-scope-confirm')));
      await tester.pumpAndSettle();
      expect(port.requests, hasLength(1));
      expect(port.requests.single.publish, isTrue);
      expect(port.requests.single.blueprintId, borderId);
    },
  );

  testWidgets('an untraced border republishes without a scope review', (
    tester,
  ) async {
    final (port, _) = await _open(tester, traced: false);
    await _publish(tester);
    expect(find.byKey(const ValueKey('border-scope-review')), findsNothing);
    expect(port.requests, hasLength(1));
  });
}
