import 'package:avelune_studio/features/resources/coordination/resource_replacement_workflow.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_replacement_fixture.dart';

const _target = ResourceUsageTarget(family: 'decors', id: 'tree');

Future<ResourceReplacementFixture> _open({
  Future<void> Function()? beforeReconciliation,
}) async {
  final host = await ResourceReplacementFixture.create(
    beforeReconciliation: beforeReconciliation,
  );
  final source = host.fixture.element(host.item.id);
  for (final element in [
    source,
    source.copyWith(id: 'bush', name: 'Buisson'),
  ]) {
    await host.navigation.accept(
      await host.fixture.resources.saveElement(element),
    );
  }
  final document = await host.fixture.loadMap();
  await host.fixture.maps.saveMap(
    host.fixture.session,
    document,
    document.map.copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'placed-tree',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 1, y: 1),
        ),
      ],
    ),
  );
  return host;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'closing during preparation settles before returning the workflow',
    () async {
      final host = await _open();
      Future<void>? pending;
      var preparationFinished = false;
      final before = await host.fixture.manifestFile.readAsBytes();
      await runResourceUsageReplacement(
        navigation: host.navigation,
        target: _target,
        name: 'Arbre',
        isActive: () => true,
        present: (controller) async {
          pending = controller.choose(controller.choices.single).then((_) {
            preparationFinished = true;
          });
        },
      );
      final settledWhenReturned = preparationFinished;
      await pending;
      expect(settledWhenReturned, isTrue);
      expect(await host.fixture.manifestFile.readAsBytes(), before);
      expect(host.navigation.managementDialogActive, isFalse);
    },
  );

  test(
    'cancelling releases the actual prepared replacement without writes',
    () async {
      final host = await _open();
      final before = await host.fixture.manifestFile.readAsBytes();
      final map = await host.fixture.mapFile.readAsBytes();
      late ResourceMutationPreparation preparation;
      final result = await runResourceUsageReplacement(
        navigation: host.navigation,
        target: _target,
        name: 'Arbre',
        isActive: () => true,
        present: (controller) async {
          await controller.choose(controller.choices.single);
          preparation = controller.preparation!;
        },
      );
      expect(result, isNull);
      await expectLater(
        host.navigation.applyPrepared(preparation, confirmDestructive: true),
        throwsA(isA<ResourceFailure>()),
      );
      expect(await host.fixture.manifestFile.readAsBytes(), before);
      expect(await host.fixture.mapFile.readAsBytes(), map);
    },
  );

  test(
    'a partially published replacement reconciles without replaying it',
    () async {
      var fail = false;
      final host = await _open(
        beforeReconciliation: () async {
          if (fail) throw StateError('Injected refresh failure');
        },
      );
      fail = true;
      final definitions = host.navigation.workspace.project!.elements;
      String? error, replayError;
      bool? retained, recovered;
      List<int>? published, afterReplay;
      await runResourceUsageReplacement(
        navigation: host.navigation,
        target: _target,
        name: 'Arbre',
        isActive: () => true,
        present: (controller) async {
          await controller.choose(controller.choices.single);
          controller.confirm(true);
          error = await controller.apply();
          retained = host.navigation.pendingReceipt != null;
          published = await host.fixture.mapFile.readAsBytes();
          fail = false;
          recovered = await host.navigation.retryReconciliation();
          replayError = await controller.apply();
          afterReplay = await host.fixture.mapFile.readAsBytes();
        },
      );
      expect(error, contains('Publication effectuée'));
      expect(retained, isTrue);
      expect(recovered, isTrue);
      expect(replayError, isNotNull);
      expect(published, isNotNull);
      expect(afterReplay, published);
      final reopened = await host.fixture.loadMap();
      expect(reopened.map.placedElements.single.elementId, 'bush');
      expect((await host.reopen()).elements, definitions);
      expect(host.navigation.managementDialogActive, isFalse);
    },
  );
}
