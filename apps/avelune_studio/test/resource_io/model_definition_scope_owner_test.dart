import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/application/model_definition_drafts.dart';
import 'package:avelune_studio/features/resources/coordination/model_resource_workflow.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/model_resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

class _Models implements ResourcePort, ModelResourcePort {
  final mutations = <(String, Map<String, Object?>)>[];
  Completer<ResourceMutationReceipt>? pendingMutation;

  @override
  Future<Uint8List> readModel(String modelId) => Completer<Uint8List>().future;

  @override
  Future<ResourceMutationReceipt> mutate(
    String actionId,
    Map<String, Object?> parameters,
  ) async {
    mutations.add((actionId, parameters));
    if (pendingMutation != null) return pendingMutation!.future;
    throw const ResourceFailure('Écriture simulée.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProjectModel3dEntry _model(String id) {
  final json = spatialEnvironmentProject().models3d.single.toJson();
  return ProjectModel3dEntry.fromJson({
    ...json,
    'id': id,
    'name': 'Modèle $id',
    'relativePath': 'assets/models3d/$id.glb',
  });
}

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

(ModelDefinitionWorkflow, _Models, ProjectModel3dEntry) _open({
  Map<String, EditableMapDocument> documents = const {},
  bool Function()? isActive,
}) {
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
  return (
    ModelDefinitionWorkflow(
      navigation: navigation,
      isActive: isActive ?? () => true,
    ),
    port,
    project.models3d.first,
  );
}

Future<void> _attempt(Future<void> pending) async {
  try {
    await pending;
  } on ResourceFailure {
    return;
  }
}

void main() {
  test('library shadows paint while saving and restore the confirmed value on failure', () async {
    final (workflow, port, model) = _open();
    port.pendingMutation = Completer<ResourceMutationReceipt>();
    final draft = ModelShadowDraft(model);
    expect(draft.value, isFalse);
    final saving = draft.save(
      true,
      (value) => workflow.configure(model, {
        'castsShadowsByDefault': value,
      }, confirmShared: (_) async => true),
      canSave: () => true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(draft.value, isTrue);
    expect(draft.saving, isTrue);
    expect(
      await draft.save(false, (_) async {}, canSave: () => true),
      isFalse,
    );
    expect(port.mutations.single.$1, 'model3d.configure');
    expect(port.mutations.single.$2, {
      'modelId': 'lamp',
      'castsShadowsByDefault': true,
    });
    port.pendingMutation!.completeError(
      const ResourceFailure('Disque indisponible'),
    );
    expect(await saving, isFalse);
    expect(draft.value, isFalse);
    expect(draft.saving, isFalse);
    expect(draft.error, contains('Disque indisponible'));
  });

  test('editing a model placed on two maps asks for a scope review once and keeps its identity', () async {
    final (workflow, port, model) = _open(
      documents: {
        'route': _map('route', 'Route 29', 2),
        'bourg': _map('bourg', 'Bourg Geon', 1),
      },
    );
    final scopes = <Map<String, int>>[];
    var accept = false;
    Future<bool> confirm(Map<String, int> scope) async {
      scopes.add(scope);
      return accept;
    }

    ResourceFailure? refusal;
    try {
      await workflow.configure(model, {'scale': 2.0}, confirmShared: confirm);
    } on ResourceFailure catch (failure) {
      refusal = failure;
    }
    expect(refusal?.message, contains('Modification annulée'));
    expect(scopes.single, {'Route 29': 2, 'Bourg Geon': 1});
    expect(port.mutations, isEmpty);

    accept = true;
    await _attempt(
      workflow.configure(model, {'scale': 2.0}, confirmShared: confirm),
    );
    expect(scopes, hasLength(2));
    expect(port.mutations, hasLength(1));
    expect(port.mutations.single.$1, 'model3d.configure');
    expect(port.mutations.single.$2['modelId'], 'lamp');
    expect(port.mutations.single.$2['scale'], 2.0);

    await _attempt(
      workflow.configure(model, {'scale': 3.0}, confirmShared: confirm),
    );
    expect(scopes, hasLength(2));
    expect(port.mutations, hasLength(2));
    expect(port.mutations.last.$2['modelId'], 'lamp');
  });

  test('an unused model is edited without a scope review', () async {
    final (workflow, port, model) = _open();
    var reviews = 0;
    await _attempt(
      workflow.configure(model, {'scale': 2.0}, confirmShared: (_) async {
        reviews++;
        return true;
      }),
    );
    expect(reviews, 0);
    expect(port.mutations, hasLength(1));
    expect(port.mutations.single.$2['modelId'], 'lamp');
  });

  test('a model without open occurrences is not reviewed because another model is placed', () async {
    final (workflow, port, model) = _open(
      documents: {'route': _map('route', 'Route 29', 1)},
    );
    var reviews = 0;
    await _attempt(
      workflow.configure(
        _model('crate'),
        {'scale': 2.0},
        confirmShared: (_) async {
          reviews++;
          return true;
        },
      ),
    );
    expect(model.id, 'lamp');
    expect(reviews, 0);
    expect(port.mutations.single.$2['modelId'], 'crate');
  });

  test('an inactive workflow never mutates after the scope review', () async {
    var active = true;
    final (workflow, port, model) = _open(
      documents: {'route': _map('route', 'Route 29', 1)},
      isActive: () => active,
    );
    await workflow.configure(model, {'scale': 2.0}, confirmShared: (_) async {
      active = false;
      return true;
    });
    expect(port.mutations, isEmpty);
  });
}
