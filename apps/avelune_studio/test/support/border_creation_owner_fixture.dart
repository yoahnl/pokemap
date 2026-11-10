import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/application/border_creation_draft.dart';
import 'package:avelune_studio/features/resources/coordination/border_creation_workflow.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'map_workspace_fixture.dart';

class BorderCreationOwnerFixture {
  BorderCreationOwnerFixture({
    required ProjectManifest project,
    BorderBlueprintRecord? initialRecord,
    Future<bool> Function(Map<String, int>)? confirmRepublication,
  }) {
    workspace = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
      ..project = project;
    addTearDown(workspace.dispose);
    navigation = ResourceNavigation(
      workspace: workspace,
      port: port,
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
    );
    addTearDown(navigation.dispose);
    draft = BorderCreationDraft(
      project: project,
      initialRecord: initialRecord,
      unavailableResourceIds: () => const {},
    );
    workflow = BorderCreationWorkflow(
      navigation: navigation,
      draft: draft,
      isActive: () => true,
      confirmDiscard: () async => false,
      confirmRepublication: confirmRepublication ?? (_) async => true,
    );
    addTearDown(workflow.dispose);
  }

  final port = BorderCreationRequestPort();
  late final MapWorkspaceController workspace;
  late final ResourceNavigation navigation;
  late final BorderCreationDraft draft;
  late final BorderCreationWorkflow workflow;
}

class BorderCreationRequestPort implements ResourcePort {
  final requests = <BorderCreationRequest>[];

  @override
  Future<ResourceMutationReceipt> createBorder(
    BorderCreationRequest request,
  ) async {
    requests.add(request);
    throw const ResourceFailure('Requête reçue par le port de test.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
