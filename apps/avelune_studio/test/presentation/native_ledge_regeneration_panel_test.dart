import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/native_ledge_regeneration_test.dart'
    show nativeLedgeMap, nativeLedgeFeature;
import '../resource_io/ledge_border_metadata_test.dart'
    show NativeLedgeResourceFixture;

void main() {
  testWidgets(
    'a stale 2D ledge prepares qualified regeneration and applies once',
    (tester) async {
      final fixture = (await tester.runAsync(
        NativeLedgeResourceFixture.create,
      ))!;
      addTearDown(fixture.dispose);
      final base = (await tester.runAsync(fixture.base.loadMap))!;
      final map = nativeLedgeMap(base.map, fixture.project);
      final receipt = (await tester.runAsync(
        () => fixture.resources.createBorder(
          BorderCreationRequest(
            blueprintId: fixture.record.id,
            name: 'Rebord republié',
            jumpSide: BorderLineSide.inverted,
            expectedRecord: fixture.record,
          ),
        ),
      ))!;
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'r0', mapId: map.id),
      );
      final commands = MapBorderEditingCommands(document, receipt.manifest);
      final feature = commands.visibleFeatures.single;
      final status = commands.regenerationStatus(
        layerId: feature.layer.id,
        featureId: feature.feature.id,
      );
      expect(status.stale, isTrue);
      expect(status.diagnostic, isNull);
      final preview = commands.prepareExisting(
        layerId: feature.layer.id,
        featureId: feature.feature.id,
      );
      expect(preview.validFor(map, receipt.manifest), isTrue);
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      commands.applyRegeneration(preview);
      expect(document.undoCount, 1);
      expect(
        nativeLedgeFeature(document.current)
            .materialization!
            .receipt
            .blueprintRevision,
        2,
      );
      expect(
        nativeLedgeFeature(document.current).overrides,
        nativeLedgeFeature(map).overrides,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
