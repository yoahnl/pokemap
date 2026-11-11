import 'package:avelune_studio/features/resources/application/resource_border_lifecycle_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_border_lifecycle.dart';
import 'package:avelune_studio/features/resources/coordination/resource_border_management.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_owner_host.dart';

Future<ResourceOwnerHost> _open() async {
  final host = await ResourceOwnerHost.create();
  for (final (id, x) in [('cap', 0), ('straight', 1), ('corner', 2)]) {
    await host.navigation.accept(
      await host.fixture.resources.saveElement(
        host.fixture
            .element(host.item.id, id: id)
            .copyWith(
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: x, y: 0)),
              ],
            ),
      ),
    );
  }
  for (final request in [
    const BorderCreationRequest(
      blueprintId: 'fence',
      name: 'Clôture',
      capElementId: 'cap',
      straightElementId: 'straight',
      cornerElementId: 'corner',
    ),
    const BorderCreationRequest(
      blueprintId: 'draft',
      name: 'Préparation',
      publish: false,
    ),
  ]) {
    await host.navigation.accept(
      await host.fixture.resources.createBorder(request),
    );
  }
  return host;
}

Future<void> _manage(
  ResourceOwnerHost host,
  BorderResourceAction action,
  Future<void> Function(ResourceBorderLifecycleController) present, {
  String id = 'fence',
  Future<void> Function(ResourceUsageTarget, String, List<String> Function())?
  presentUsages,
}) => runBorderResourceManagement(
  navigation: host.navigation,
  record: host.navigation.workspace.project!.borderCatalog.recordById(id)!,
  action: action,
  isActive: () => true,
  present: present,
  presentUsages: presentUsages ?? (_, _, _) async {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unpublished border withdrawal preserves publication and pixels', () async {
    final host = await _open();
    final before = host.workspace.project!;
    expect(before.borderCatalog.records, hasLength(2));
    String? result = 'unset';
    await _manage(host, BorderResourceAction.deleteDraft, (controller) async {
      await controller.prepare();
      controller.confirm(true);
      result = await controller.apply();
    }, id: 'draft');
    expect(result, isNull);
    final after = await host.reopen();
    expect(after.borderCatalog.records, hasLength(1));
    expect(
      after.borderCatalog.records.single,
      before.borderCatalog.recordById('fence'),
    );
    expect(after.borderCatalog.recordById('draft'), isNull);
    expect(after.tilesets, before.tilesets);
    expect(after.elements, before.elements);
  });

  test('a published border has no withdrawal that deletes its publication', () async {
    final host = await _open();
    final before = host.workspace.project!;
    await _manage(host, BorderResourceAction.deleteDraft, (controller) async {
      await controller.prepare();
      controller.confirm(true);
      await controller.apply();
    });
    final after = await host.reopen();
    expect(
      after.borderCatalog.recordById('fence')!.latestPublished,
      before.borderCatalog.recordById('fence')!.latestPublished,
    );
  });

  test('dirty border editor blocks withdrawal without losing focused input', () async {
    final host = await _open();
    final before = await host.fixture.manifestFile.readAsBytes();
    var editorOpen = true;
    host.navigation.borderEditorOwners['draft'] = () => editorOpen;
    expect(
      host.navigation.borderManagementOwners('border.blueprint.delete', {
        'blueprintId': 'draft',
      }),
      isNotEmpty,
    );
    String? refusal;
    await _manage(host, BorderResourceAction.deleteDraft, (controller) async {
      await controller.prepare();
      controller.confirm(true);
      refusal = controller.error;
      expect(controller.canApply, isFalse);
    }, id: 'draft');
    expect(refusal, contains('Préparation'));
    expect(host.navigation.borderEditorOwners.containsKey('draft'), isTrue);
    expect(await host.fixture.manifestFile.readAsBytes(), before);

    editorOpen = false;
    expect(
      host.navigation.borderManagementOwners('border.blueprint.delete', {
        'blueprintId': 'draft',
      }),
      isEmpty,
    );
    String? result = 'unset';
    await _manage(host, BorderResourceAction.deleteDraft, (controller) async {
      await controller.prepare();
      controller.confirm(true);
      result = await controller.apply();
    }, id: 'draft');
    expect(result, isNull);
    expect((await host.reopen()).borderCatalog.recordById('draft'), isNull);
  });

  test('border usage inspection targets the actual blueprint and does not write', () async {
    final host = await _open();
    final before = host.workspace.project!;
    final beforeManifest = await host.fixture.manifestFile.readAsBytes();
    ResourceUsageTarget? target;
    await _manage(
      host,
      BorderResourceAction.usages,
      (_) async => fail('Usages never prepare a mutation'),
      presentUsages: (usageTarget, name, owners) async {
        target = usageTarget;
        expect(name, 'Clôture');
        expect(owners(), isEmpty);
      },
    );
    expect(target!.family, 'borders');
    expect(target!.id, 'fence');
    final report = await host.navigation.usages.analyze(target!);
    expect(report.complete, isTrue);
    expect(report.target.id, 'fence');
    expect((await host.reopen()).borderCatalog, before.borderCatalog);
    expect(await host.fixture.manifestFile.readAsBytes(), beforeManifest);
  });
}
