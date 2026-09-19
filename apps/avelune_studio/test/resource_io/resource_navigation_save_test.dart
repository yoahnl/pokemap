import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late WorkspaceMemoryPort maps;
  late MapWorkspaceController workspace;
  late _ControlledResources port;
  late ResourceNavigation navigation;

  setUp(() async {
    maps = WorkspaceMemoryPort();
    workspace = MapWorkspaceController(workspaceSession, maps);
    await workspace.initialize();
    port = _ControlledResources();
    navigation = ResourceNavigation(
      workspace: workspace,
      port: port,
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
    );
    navigation.edit(
      const ResourceItem(
        id: 'tree',
        name: 'Arbre',
        kind: ResourceKind.decors,
        element: workspaceElement,
      ),
    );
  });

  tearDown(() {
    navigation.dispose();
    workspace.dispose();
  });

  test(
    'close-save retains concurrent draft changes and refuses completion',
    () async {
      final draft = navigation.decor!..name = 'Version demandée';
      final saving = navigation.saveDrafts();
      expect(navigation.busy, isTrue);
      expect(await navigation.saveDrafts(), isFalse);
      expect(port.saved!.name, 'Version demandée');
      draft.name = 'Version modifiée pendant la sauvegarde';
      port.finish();
      expect(await saving, isFalse);
      expect(navigation.dirty, isTrue);
      expect(navigation.decor, same(draft));
      expect(navigation.decors.values, contains(draft));
      expect(workspace.project!.elements.single.name, 'Version demandée');
      expect(draft.name, 'Version modifiée pendant la sauvegarde');
      expect(navigation.busy, isFalse);
    },
  );

  test(
    'saved draft clears active pointer even when map save subsequently fails',
    () async {
      final document = workspace.active!;
      document.commit(document.current.copyWith(name: 'Carte sale'));
      navigation.decor!.name = 'Décor enregistré';
      final saving = navigation.saveDrafts();
      port.finish();
      expect(await saving, isTrue);
      expect(navigation.decor, isNull);
      expect(navigation.decors, isEmpty);
      expect(navigation.dirty, isFalse);
      maps.failSave = true;
      expect(await workspace.saveAll(), isFalse);
      final saved = workspace.project!.elements.single;
      navigation.edit(
        ResourceItem(
          id: saved.id,
          name: saved.name,
          kind: ResourceKind.decors,
          element: saved,
        ),
      );
      navigation.decor!.name = 'Nouvelle modification après échec carte';
      expect(navigation.dirty, isTrue);
      expect(navigation.decors.values, contains(navigation.decor));
      expect(navigation.decor!.original!.name, 'Décor enregistré');
    },
  );

  test(
    'resource write error preserves draft, active pointer and retry state',
    () async {
      final draft = navigation.decor!..name = 'À conserver';
      final saving = navigation.saveDrafts();
      port.gate.completeError(const ResourceFailure('Écriture indisponible'));
      expect(await saving, isFalse);
      expect(navigation.decor, same(draft));
      expect(navigation.dirty, isTrue);
      expect(navigation.busy, isFalse);
      expect(navigation.error, contains('Écriture indisponible'));
      expect(workspace.project, workspaceProject);
    },
  );
}

final class _ControlledResources implements ResourcePort {
  final gate = Completer<void>();
  ProjectElementEntry? saved;

  void finish() => gate.complete();

  @override
  Future<ResourceMutationReceipt> saveElement(
    ProjectElementEntry element,
  ) async {
    saved = element;
    await gate.future;
    return ResourceMutationReceipt(
      before: workspaceProject,
      manifest: workspaceProject.copyWith(elements: [element]),
      beforeRevision: 'before',
      revision: 'after',
      changedPaths: ['project.json'],
    );
  }

  @override
  Future<ResourceMutationReceipt> importImage(ResourceImageImport request) =>
      throw UnimplementedError();

  @override
  Future<ResourceMutationReceipt> mutate(
    String actionId,
    Map<String, Object?> parameters,
  ) => throw UnimplementedError();

  @override
  Future<void> dispose() async {}
}
