import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_removal_controller.dart';
import 'package:avelune_studio/features/resources/application/resource_usage_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_definition_lifecycle.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_owner_seed.dart';
import '../support/resource_owner_host.dart';

Future<ResourceOwnerHost> _open({int placements = 0}) =>
    ResourceOwnerHost.create(
      configure: (fixture) async {
        await seedFreeDecor(fixture, placed: placements > 0);
        if (placements > 1) {
          final document = await fixture.loadMap();
          await fixture.maps.saveMap(
            fixture.session,
            document,
            document.map.copyWith(
              placedElements: [
                ...document.map.placedElements,
                for (var index = 1; index < placements; index++)
                  MapPlacedElement(
                    id: 'late-tree-$index',
                    layerId: 'ground',
                    elementId: 'tree',
                    pos: index == 1
                        ? const GridPos(x: 2, y: 2)
                        : const GridPos(x: 0, y: 0),
                  ),
              ],
            ),
          );
        }
      },
    );

Future<ResourceRemovalController> _removalOutcome(
  ResourceOwnerHost host,
  ResourceItem item, {
  Future<void> Function(ResourceRemovalController)? after,
}) async {
  late ResourceRemovalController outcome;
  await runResourceDefinitionRemoval(
    navigation: host.navigation,
    item: item,
    isActive: () => true,
    confirmOwnerSave: () async => true,
    present: (controller) async {
      outcome = controller;
      await controller.prepare();
      await after?.call(controller);
    },
  );
  return outcome;
}

ResourceUsageController _usages(
  ResourceOwnerHost host,
  ResourceItem item, {
  ResourceUsagePort? port,
}) {
  final navigation = host.navigation;
  return ResourceUsageController(
    target: resourceUsageTargetFor(item),
    port: port ?? navigation.usages,
    dirtyOwners: () => navigation.usageDraftOwners,
    openOwner: navigation.openUsageOwner,
    canOpenOwner: navigation.canOpenUsageOwner,
    changed: () {},
  );
}

void _dirtyMap(ResourceOwnerHost host) {
  final document = host.workspace.active!;
  MapEditingCommands(
    document,
    host.workspace.project!,
  ).place(host.workspace.project!.elements.first, const GridPos(x: 0, y: 0));
}

class _ObservedUsagePort implements ResourceUsagePort {
  _ObservedUsagePort(this.delegate);
  final ResourceUsagePort delegate;
  int analyses = 0, verifications = 0;
  @override
  Future<ResourceUsageReport> analyze(
    ResourceUsageTarget target, {
    bool Function()? cancelled,
  }) {
    analyses++;
    return delegate.analyze(target, cancelled: cancelled);
  }

  @override
  Future<bool> isCurrent(ResourceUsageReport report) {
    verifications++;
    return delegate.isCurrent(report);
  }

  @override
  Future<void> dispose() => delegate.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unsaved map usage remains explicit and analysis never saves it', () async {
    final host = await _open();
    final document = host.workspace.active!;
    final saved = document.saved;
    final mapBytes = await host.fixture.mapFile.readAsBytes();
    expect(host.navigation.usageDraftOwners, isEmpty);
    _dirtyMap(host);
    expect(document.dirty, isTrue);
    expect(host.navigation.usageDraftOwners, contains('Carte · Jardin'));
    final undo = document.undoCount;
    final controller = _usages(host, host.item);
    await controller.analyze();
    expect(controller.report, isNotNull);
    expect(controller.phase, ResourceUsagePhase.incomplete);
    expect(document.saved, saved);
    expect(document.dirty, isTrue);
    expect(document.undoCount, undo);
    expect(await host.fixture.mapFile.readAsBytes(), mapBytes);
    controller.dispose();
  });

  test('a clean open map leaves the usage analysis complete', () async {
    final host = await _open(placements: 1);
    expect(host.navigation.usageDraftOwners, isEmpty);
    final controller = _usages(host, decorItem(host.workspace.project!));
    await controller.analyze();
    expect(controller.phase, ResourceUsagePhase.complete);
    expect(
      controller.report!.entries.map((entry) => entry.entityId),
      contains('placed-tree'),
    );
    controller.dispose();
  });

  test('draft notifications invalidate usage report without disk scan', () async {
    final host = await _open();
    late _ObservedUsagePort observed;
    observed = _ObservedUsagePort(host.navigation.usages);
    final controller = _usages(host, host.item, port: observed);
    host.navigation.addListener(controller.invalidate);
    addTearDown(() => host.navigation.removeListener(controller.invalidate));
    await controller.analyze();
    expect(controller.phase, ResourceUsagePhase.complete);
    expect(observed.verifications, 1);
    final document = host.workspace.active!;
    final commands = MapEditingCommands(document, host.workspace.project!);
    for (var x = 4; x < 7; x++) {
      commands.place(
        host.workspace.project!.elements.first,
        GridPos(x: x % 4, y: 0),
      );
      host.workspace.notify();
    }
    expect(observed.verifications, 1);
    expect(observed.analyses, 1);
    expect(controller.phase, ResourceUsagePhase.stale);
    expect(host.navigation.usageDraftOwners, contains('Carte · Jardin'));
    expect(document.dirty, isTrue);
    controller.dispose();
  });

  test('a used decor removal is blocked with its usage count and leads to its usages', () async {
    final host = await _open(placements: 1);
    final before = await host.reopen();
    final item = decorItem(host.workspace.project!);
    final removal = await _removalOutcome(host, item);
    final refusal = removal.error!;
    expect(refusal, contains('Ce décor est encore utilisé dans le projet'));
    expect(refusal, contains('(1 usage)'));
    expect(refusal, contains('« Voir les usages dans le projet »'));
    expect(refusal, isNot(contains('VisualLibraryException')));
    expect(removal.preparation, isNull);
    expect(removal.canApply, isFalse);
    expect(await removal.apply(), isNotNull);
    final usages = _usages(host, item);
    expect(usages.phase, ResourceUsagePhase.notAnalyzed);
    await usages.analyze();
    expect(usages.report!.target.id, 'tree');
    expect(
      usages.report!.entries.map((entry) => entry.entityId),
      contains('placed-tree'),
    );
    usages.dispose();
    final after = await host.reopen();
    expect(after.elements, before.elements);
    expect(after.tilesets, before.tilesets);
  });

  test('a used decor removal counts several usages', () async {
    final host = await _open(placements: 3);
    final removal = await _removalOutcome(
      host,
      decorItem(host.workspace.project!),
    );
    expect(removal.error, contains('(3 usages)'));
  });

  test('a planche used by a decor is blocked with the same guidance', () async {
    final host = await _open();
    final before = await host.reopen();
    final removal = await _removalOutcome(host, host.item);
    final refusal = removal.error!;
    expect(refusal, contains('Cette planche est encore utilisée dans le projet'));
    expect(refusal, contains('« Voir les usages dans le projet »'));
    expect(removal.canApply, isFalse);
    expect((await host.reopen()).tilesets, before.tilesets);
  });

  test('an unused decor removal stays available without refusal', () async {
    final host = await _open();
    final removal = await _removalOutcome(
      host,
      decorItem(host.workspace.project!),
      after: (controller) async {
        expect(controller.error, isNull);
        controller.confirm(true);
        expect(controller.confirmed, isTrue);
      },
    );
    expect(removal.error, isNull);
    expect((await host.reopen()).elements.single.id, 'tree');
  });

  test('a removal analysed before the decor was placed is refused at confirmation', () async {
    final host = await _open();
    final item = decorItem(host.workspace.project!);
    List<int>? placedMap;
    String? failure;
    await _removalOutcome(
      host,
      item,
      after: (controller) async {
        expect(controller.preparation, isNotNull);
        final document = await host.fixture.loadMap();
        await host.fixture.maps.saveMap(
          host.fixture.session,
          document,
          document.map.copyWith(
            placedElements: const [
              MapPlacedElement(
                id: 'late-tree',
                layerId: 'ground',
                elementId: 'tree',
                pos: GridPos(x: 2, y: 2),
              ),
            ],
          ),
        );
        placedMap = await host.fixture.mapFile.readAsBytes();
        controller.confirm(true);
        failure = await controller.apply();
      },
    );
    expect(failure, isNotNull);
    expect((await host.reopen()).elements.single.id, 'tree');
    expect(await host.fixture.mapFile.readAsBytes(), placedMap);
  });

  test('an unsaved map draft keeps the replacement unavailable', () async {
    final host = await _open(placements: 1);
    final mapBytes = await host.fixture.mapFile.readAsBytes();
    _dirtyMap(host);
    final item = decorItem(host.workspace.project!);
    final controller = ResourceUsageController(
      target: resourceUsageTargetFor(item),
      port: host.navigation.usages,
      dirtyOwners: () => host.navigation.usageDraftOwners,
      openOwner: host.navigation.openUsageOwner,
      canOpenOwner: host.navigation.canOpenUsageOwner,
      changed: () {},
      replace: (_) async => null,
    );
    await controller.analyze();
    expect(controller.phase, ResourceUsagePhase.incomplete);
    expect(controller.canReplace, isFalse);
    await expectLater(
      host.navigation.prepareOperation('resource.usages.replace', {
        'family': 'decors',
        'resourceId': 'tree',
        'replacementId': 'other',
      }),
      throwsA(
        isA<ResourceFailure>().having(
          (failure) => failure.message,
          'message',
          allOf(
            contains('Enregistrez ou annulez les brouillons'),
            contains('Carte · Jardin'),
          ),
        ),
      ),
    );
    expect(await host.fixture.mapFile.readAsBytes(), mapBytes);
    controller.dispose();
  });
}
