import 'dart:io';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import 'ledge_border_metadata_fixture.dart';
export 'ledge_border_metadata_fixture.dart';

void main() {
  test(
    'renaming an imported ledge draft retains every native variant',
    () async {
      final fixture = await NativeLedgeResourceFixture.create();
      addTearDown(fixture.dispose);
      final result = await fixture.resources.createBorder(
        const BorderCreationRequest(
          blueprintId: 'native-ledges',
          name: 'Rebords renommés',
          publish: false,
        ),
      );
      final saved = result.manifest.borderCatalog.records.single;
      expect(
        saved.draft.definition.primitives,
        fixture.record.draft.definition.primitives,
      );
      expect(saved.latestPublished, fixture.record.latestPublished);
      expect(
        saved.draft.definition.template,
        BorderBlueprintTemplate.ledgeLine,
      );
      expect(
        saved.draft.definition.jumpBehavior,
        fixture.record.draft.definition.jumpBehavior,
      );
      expect(await fixture.mapFile.readAsBytes(), fixture.mapBefore);
    },
  );

  test(
    'republishing an imported ledge retains its source frames and anchors',
    () async {
      final fixture = await NativeLedgeResourceFixture.create();
      addTearDown(fixture.dispose);
      final result = await fixture.resources.createBorder(
        const BorderCreationRequest(
          blueprintId: 'native-ledges',
          name: 'Rebords publiés',
        ),
      );
      final saved = result.manifest.borderCatalog.records.single;
      expect(saved.latestPublished!.revision, 2);
      expect(
        saved.latestPublished!.definition.primitives,
        fixture.record.latestPublished!.definition.primitives,
      );
      expect(
        saved.draft.definition.primitives,
        fixture.record.draft.definition.primitives,
      );
      expect(
        saved.latestPublished!.definition.jumpBehavior,
        fixture.record.latestPublished!.definition.jumpBehavior,
      );
      final reopened = await fixture.maps.loadProject(fixture.session);
      expect(reopened.borderCatalog.records.single, saved);
      expect(
        reopened.borderCatalog.visualSnapshots,
        unorderedEquals(fixture.project.borderCatalog.visualSnapshots),
      );
      expect(await fixture.mapFile.readAsBytes(), fixture.mapBefore);
      for (final entry in fixture.mediaBefore.entries) {
        expect(
          await File('${fixture.root.path}/${entry.key}').readAsBytes(),
          entry.value,
        );
      }
    },
  );
  test('changing the jump side preserves every other jump parameter', () async {
    final fixture = await NativeLedgeResourceFixture.create();
    addTearDown(fixture.dispose);
    final result = await fixture.resources.createBorder(
      BorderCreationRequest(
        blueprintId: fixture.record.id,
        name: fixture.record.draft.definition.name,
        jumpSide: BorderLineSide.inverted,
        expectedRecord: fixture.record,
      ),
    );
    final behavior = result
        .manifest
        .borderCatalog
        .records
        .single
        .latestPublished!
        .definition
        .jumpBehavior!;
    expect(behavior.side, BorderLineSide.inverted);
    expect(behavior.durationMs, 500);
    expect(behavior.peakHeightPx, 24);
    expect(
      behavior.distanceCells,
      fixture.record.draft.definition.jumpBehavior!.distanceCells,
    );
    expect(await fixture.mapFile.readAsBytes(), fixture.mapBefore);
  });

  test(
    'changed source pixels are refused before changing the catalog',
    () async {
      final fixture = await NativeLedgeResourceFixture.create();
      addTearDown(fixture.dispose);
      final before = await fixture.base.manifestFile.readAsBytes();
      final atlas = File(
        '${fixture.root.path}/assets/tilesets/native-ledges.png',
      );
      final decoded = image.decodePng(await atlas.readAsBytes())!;
      decoded.setPixelRgba(1, 30, 255, 255, 255, 255);
      await atlas.writeAsBytes(image.encodePng(decoded));
      await expectLater(
        fixture.resources.createBorder(
          BorderCreationRequest(
            blueprintId: fixture.record.id,
            name: 'Rebords modifiés',
            expectedRecord: fixture.record,
          ),
        ),
        throwsA(isA<ResourceFailure>()),
      );
      expect(await fixture.base.manifestFile.readAsBytes(), before);
      expect(await fixture.mapFile.readAsBytes(), fixture.mapBefore);
    },
  );

  test(
    'an editor opened on an older record cannot overwrite a newer draft',
    () async {
      final fixture = await NativeLedgeResourceFixture.create();
      addTearDown(fixture.dispose);
      await fixture.resources.createBorder(
        BorderCreationRequest(
          blueprintId: fixture.record.id,
          name: 'Autre modification',
          publish: false,
          expectedRecord: fixture.record,
        ),
      );
      final before = await fixture.base.manifestFile.readAsBytes();
      await expectLater(
        fixture.resources.createBorder(
          BorderCreationRequest(
            blueprintId: fixture.record.id,
            name: 'Ancien éditeur',
            publish: false,
            expectedRecord: fixture.record,
          ),
        ),
        throwsA(isA<ResourceFailure>()),
      );
      expect(await fixture.base.manifestFile.readAsBytes(), before);
      expect(await fixture.mapFile.readAsBytes(), fixture.mapBefore);
    },
  );

  test('a plain ledge remains without a jump after publication', () async {
    final fixture = await NativeLedgeResourceFixture.create(
      jumpsEnabled: false,
    );
    addTearDown(fixture.dispose);
    final result = await fixture.resources.createBorder(
      BorderCreationRequest(
        blueprintId: fixture.record.id,
        name: 'Rebord sans saut',
        expectedRecord: fixture.record,
      ),
    );
    expect(
      result
          .manifest
          .borderCatalog
          .records
          .single
          .latestPublished!
          .definition
          .jumpBehavior,
      isNull,
    );
    expect(await fixture.mapFile.readAsBytes(), fixture.mapBefore);
  });

  test('a plain ledge refuses a jump side without catalog writes', () async {
    final fixture = await NativeLedgeResourceFixture.create(
      jumpsEnabled: false,
    );
    addTearDown(fixture.dispose);
    final before = await fixture.base.manifestFile.readAsBytes();
    await expectLater(
      fixture.resources.createBorder(
        BorderCreationRequest(
          blueprintId: fixture.record.id,
          name: 'Rebord sans saut',
          expectedRecord: fixture.record,
          jumpSide: BorderLineSide.inverted,
        ),
      ),
      throwsA(isA<ResourceFailure>()),
    );
    expect(await fixture.base.manifestFile.readAsBytes(), before);
    expect(await fixture.mapFile.readAsBytes(), fixture.mapBefore);
  });

  test(
    'publication retains every native animation frame and duration',
    () async {
      final fixture = await NativeLedgeResourceFixture.create(
        animatedFirst: true,
      );
      addTearDown(fixture.dispose);
      final result = await fixture.resources.createBorder(
        BorderCreationRequest(
          blueprintId: fixture.record.id,
          name: 'Rebord animé',
          expectedRecord: fixture.record,
        ),
      );
      expect(
        result.manifest.borderCatalog.visualSnapshots,
        unorderedEquals(fixture.project.borderCatalog.visualSnapshots),
      );
      expect(
        result
            .manifest
            .borderCatalog
            .records
            .single
            .latestPublished!
            .definition
            .primitives,
        fixture.record.latestPublished!.definition.primitives,
      );
      for (final entry in fixture.mediaBefore.entries) {
        expect(
          await File('${fixture.root.path}/${entry.key}').readAsBytes(),
          entry.value,
        );
      }
      expect(await fixture.mapFile.readAsBytes(), fixture.mapBefore);
    },
  );
}
