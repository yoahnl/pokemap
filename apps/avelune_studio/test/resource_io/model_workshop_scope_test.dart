import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/domain/model_resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/model_resource_library.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

class _Models implements ResourcePort, ModelResourcePort {
  final reads = <String, Completer<Uint8List>>{};
  final mutations = <(String, Map<String, Object?>)>[];

  @override
  Future<Uint8List> readModel(String modelId) =>
      (reads[modelId] ??= Completer<Uint8List>()).future;

  @override
  Future<ResourceMutationReceipt> mutate(
    String actionId,
    Map<String, Object?> parameters,
  ) async {
    mutations.add((actionId, parameters));
    throw const ResourceFailure('Écriture simulée.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProjectModel3dEntry _model(String id) => ProjectModel3dEntry.fromJson({
  ...spatialEnvironmentProject().models3d.single.toJson(),
  'id': id,
  'name': 'Modèle $id',
  'relativePath': 'assets/models3d/$id.glb',
});

EditableMapDocument _map(String id, String name, int instances) =>
    EditableMapDocument(
      MapWorkspaceDocument(
        mapId: id,
        revision: 'r1',
        map: workspaceMap(id).copyWith(
          name: name,
          spatialScene: MapSpatialScene(
            width: 8,
            depth: 8,
            instances: [
              for (var index = 0; index < instances; index++)
                SpatialModelInstance(
                  id: '$id-lamp-$index',
                  modelId: 'lamp',
                  position: Model3dVector3(x: index.toDouble(), y: 0, z: 0),
                ),
            ],
          ),
        ),
      ),
    );

Future<(ResourceNavigation, _Models)> _pump(
  WidgetTester tester, {
  Map<String, EditableMapDocument> documents = const {},
}) async {
  await tester.binding.setSurfaceSize(const Size(1500, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final project = workspaceProject.copyWith(
    models3d: [_model('lamp'), _model('crate')],
  );
  final controller = MapWorkspaceController(
    workspaceSession,
    WorkspaceMemoryPort(),
  )..project = project;
  controller.documents.addAll(documents);
  final port = _Models();
  final navigation = ResourceNavigation(
    workspace: controller,
    port: port,
    visuals: WorkspaceTestVisuals(),
    onUse: (_) {},
  );
  addTearDown(() {
    navigation.dispose();
    controller.dispose();
  });
  final items = [
    for (final model in project.models3d)
      ResourceItem(
        id: model.id,
        name: model.name,
        kind: ResourceKind.decors,
        model3d: model,
      ),
  ];
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: ModelResourceLibrary(
          navigation: navigation,
          items: items,
          previewBuilder: (model, bytes) =>
              Text('Aperçu ${model.id} ${bytes.join(',')}'),
        ),
      ),
    ),
  );
  await tester.pump();
  return (navigation, port);
}

Future<void> _commitScale(WidgetTester tester, String value) async {
  final field = find.descendant(
    of: find.byKey(const ValueKey('scale-lamp')),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets(
    'editing a model placed on two maps asks for a scope review once and keeps its identity',
    (tester) async {
      final (_, port) = await _pump(
        tester,
        documents: {
          'route': _map('route', 'Route 29', 2),
          'bourg': _map('bourg', 'Bourg Geon', 1),
        },
      );
      expect(find.byKey(const ValueKey('model-shared-scope')), findsOne);
      expect(find.textContaining('3 occurrences sur 2 cartes'), findsWidgets);

      await _commitScale(tester, '2');
      expect(find.byKey(const ValueKey('model-scope-review')), findsOne);
      expect(find.textContaining('Route 29 (2)'), findsOne);
      expect(find.textContaining('Bourg Geon (1)'), findsOne);
      await tester.tap(find.byKey(const ValueKey('model-scope-cancel')));
      await _settle(tester);
      expect(port.mutations, isEmpty);

      await _commitScale(tester, '2');
      await tester.tap(find.byKey(const ValueKey('model-scope-confirm')));
      await _settle(tester);
      expect(port.mutations, hasLength(1));
      expect(port.mutations.single.$1, 'model3d.configure');
      expect(port.mutations.single.$2['modelId'], 'lamp');
      expect(port.mutations.single.$2['scale'], 2.0);

      await _commitScale(tester, '3');
      expect(find.byKey(const ValueKey('model-scope-review')), findsNothing);
      expect(port.mutations, hasLength(2));
      expect(port.mutations.last.$2['modelId'], 'lamp');
    },
  );

  testWidgets('an unused model is edited without a scope review', (
    tester,
  ) async {
    final (_, port) = await _pump(tester);
    await _commitScale(tester, '2');
    expect(find.byKey(const ValueKey('model-scope-review')), findsNothing);
    expect(port.mutations, hasLength(1));
  });

  testWidgets(
    'a late preview of the previous model never replaces the new one',
    (tester) async {
      final (_, port) = await _pump(tester);
      port.reads['lamp']!.complete(Uint8List.fromList([1, 2, 3]));
      await tester.pump();
      await tester.pump();
      expect(find.text('Aperçu lamp 1,2,3'), findsOne);
      await tester.tap(find.byKey(const ValueKey('model-resource-crate')));
      await tester.pump();
      expect(find.textContaining('Aperçu lamp'), findsNothing);
      expect(find.textContaining('Aperçu crate'), findsNothing);
      expect(find.byKey(const ValueKey('model-preview-loading')), findsOne);
      port.reads['crate']!.complete(Uint8List.fromList([4, 5, 6]));
      await tester.pump();
      await tester.pump();
      expect(find.text('Aperçu crate 4,5,6'), findsOne);
      expect(find.textContaining('Aperçu lamp'), findsNothing);
    },
  );
}
