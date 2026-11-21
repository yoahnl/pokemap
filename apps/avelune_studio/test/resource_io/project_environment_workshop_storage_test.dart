import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/model_shadow_fixture.dart';

void main() {
  test(
    'successive environment publications stay local and survive reopening',
    () async {
      final fixture = await ModelShadowFixture.create(unrelated: 40);
      addTearDown(fixture.dispose);
      final baseline = await fixture.maps.resourceBaseline(fixture.session);
      final garden = _preset('garden', 'Jardin', weight: 2);
      final forest = _preset('forest', 'Forêt', weight: 5);
      final reads = <String>[];

      final first = await fixture.observe(
        () => fixture.resources.publishEnvironment(
          garden,
          expectedRevision: baseline.revision,
        ),
        reads,
        denyForeign: true,
      );
      final second = await fixture.observe(
        () => fixture.resources.publishEnvironment(
          forest,
          expectedRevision: first.receipt.revision,
        ),
        reads,
        denyForeign: true,
      );

      expect(first.item.identity, 'environmentPreset:garden');
      expect(second.item.compatibleDimensions, {ProjectDimension.threeD});
      expect(second.receipt.manifest.environmentPresets, [garden, forest]);
      expect(second.receipt.changedMaps, isEmpty);
      expect(reads, isEmpty);
      await expectLater(
        fixture.resources.publishEnvironment(
          _preset('garden', 'Ancien écran'),
          expectedRevision: first.receipt.revision,
        ),
        throwsA(
          isA<ResourceFailure>().having(
            (failure) => failure.message,
            'message',
            contains('catalogue a changé'),
          ),
        ),
      );
      final edited = _preset('garden', 'Jardin fleuri', weight: 3);
      final updated = await fixture.observe(
        () => fixture.resources.publishEnvironment(
          edited,
          expectedRevision: second.receipt.revision,
        ),
        reads,
        denyForeign: true,
      );
      expect(updated.item.name, edited.name);
      expect(reads, isEmpty);

      final reopened = LocalMapWorkspaceAdapter();
      await reopened.loadCatalog(fixture.session);
      final actual = await reopened.loadResourceKind(
        fixture.session,
        'environmentPreset',
      );
      expect(
        actual.metadata.environmentPresets,
        unorderedEquals([edited, forest]),
      );
      expect(actual.metadata.models3d.single.id, 'house');
    },
  );

  test(
    'a durable publication can be reread without publishing a second time',
    () async {
      final fixture = await ModelShadowFixture.create(
        beforeReconciliation: () async =>
            throw StateError('interrupted reread'),
      );
      addTearDown(fixture.dispose);
      final before = await fixture.maps.resourceRevision(fixture.session);
      final preset = _preset('garden', 'Jardin');
      ResourceMutationReceipt? pending;
      try {
        await fixture.resources.publishEnvironment(
          preset,
          expectedRevision: before,
        );
      } on ResourceFailure catch (failure) {
        pending = failure.partialReceipt;
      }
      expect(pending, isNotNull);
      final writtenRevision = await fixture.maps.resourceRevision(
        fixture.session,
      );
      final reconciled = await fixture.resources.reconcileEnvironment(
        preset,
        pending!,
      );
      expect(reconciled.item.id, preset.id);
      expect(reconciled.receipt.revision, writtenRevision);
      expect(
        await fixture.maps.resourceRevision(fixture.session),
        writtenRevision,
      );
    },
  );
}

EnvironmentPreset _preset(String id, String name, {int weight = 1}) =>
    EnvironmentPreset(
      id: id,
      name: name,
      templateId: 'manual',
      palette: [EnvironmentPaletteItem(modelId: 'house', weight: weight)],
      defaultParams: EnvironmentGenerationParams.standard(),
      sortOrder: 0,
    );
