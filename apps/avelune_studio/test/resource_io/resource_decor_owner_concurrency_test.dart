import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'resource_fixture.dart';

void main() {
  test(
    'focused owner save refuses a disk change made after draft opening',
    () async {
      final host = await _DecorOwnerHost.open();
      addTearDown(host.close);
      final draft = host.navigation.decor!..name = 'Saisie à conserver';
      final external = host.workspace.project!.copyWith(
        elements: [host.original.copyWith(name: 'Modification extérieure')],
      );
      await host.fixture.manifestFile.writeAsString(
        jsonEncode(external.toJson()),
      );
      final before = await host.fixture.manifestFile.readAsBytes();

      expect(await host.navigation.saveDecorOwner(host.original.id), isFalse);

      expect(host.navigation.decor, same(draft));
      expect(draft.name, 'Saisie à conserver');
      expect(host.navigation.dirty, isTrue);
      expect(host.navigation.error, isNotNull);
      expect(host.navigation.pendingReceipt, isNull);
      expect(await host.fixture.manifestFile.readAsBytes(), before);
      expect(
        (await host.reopen()).elements.single.name,
        'Modification extérieure',
      );
    },
  );

  test(
    'an editor still holding a removed definition cannot resurrect it',
    () async {
      final host = await _DecorOwnerHost.open();
      addTearDown(host.close);
      final draft = host.navigation.decor!..name = 'Ancienne fiche';
      final preparation = await host.fixture.resources.prepareOperation(
        'element.delete',
        {'elementId': host.original.id},
      );
      final removed = await host.fixture.resources.applyPrepared(
        preparation,
        confirmDestructive: true,
      );
      await host.navigation.accept(removed);
      final before = await host.fixture.manifestFile.readAsBytes();

      await expectLater(
        host.navigation.saveDecor(draft.build()),
        throwsA(isA<ResourceFailure>()),
      );

      expect(host.navigation.decor, same(draft));
      expect(draft.name, 'Ancienne fiche');
      expect(host.navigation.dirty, isTrue);
      expect(await host.fixture.manifestFile.readAsBytes(), before);
      expect((await host.reopen()).elements, isEmpty);
      expect(host.navigation.pendingReceipt, isNull);
    },
  );

  test(
    'unchanged owner saves through its real port and reopens independently',
    () async {
      final host = await _DecorOwnerHost.open();
      addTearDown(host.close);
      host.navigation.decor!.name = 'Arbre enregistré';

      expect(await host.navigation.saveDecorOwner(host.original.id), isTrue);

      expect(host.navigation.dirty, isFalse);
      expect(host.navigation.decor, isNull);
      expect(host.navigation.error, isNull);
      expect((await host.reopen()).elements.single.name, 'Arbre enregistré');
    },
  );
}

class _DecorOwnerHost {
  _DecorOwnerHost(this.fixture, this.workspace, this.navigation, this.original);

  final ResourceFixture fixture;
  final MapWorkspaceController workspace;
  final ResourceNavigation navigation;
  final ProjectElementEntry original;

  static Future<_DecorOwnerHost> open() async {
    final fixture = await ResourceFixture.create();
    final imported = await fixture.import();
    await fixture.resources.mutate('element_category.upsert', {
      'category': {'id': 'nature', 'name': 'Nature'},
    });
    final original = fixture
        .element(imported.createdTilesetId!)
        .copyWith(categoryId: 'nature');
    await fixture.resources.saveElement(original);
    final workspace = MapWorkspaceController(fixture.session, fixture.maps);
    await workspace.initialize();
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: fixture.resources,
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
    );
    navigation.edit(
      ResourceItem(
        id: original.id,
        name: original.name,
        kind: ResourceKind.decors,
        element: original,
      ),
    );
    return _DecorOwnerHost(fixture, workspace, navigation, original);
  }

  Future<ProjectManifest> reopen() =>
      LocalMapWorkspaceAdapter().loadProject(fixture.session);

  Future<void> close() async {
    navigation.dispose();
    workspace.dispose();
    await fixture.dispose();
  }
}
