import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../maps/map_catalog_fixture.dart';
import 'element_definition_transaction_test.dart';

void main() {
  test('map dependency changed after initial snapshot refuses under write lock',
      () async {
    final fixture = await registeredFixture();
    addTearDown(fixture.dispose);
    final map = catalogMap('closed');
    final mapFile = File('${fixture.root.path}/maps/closed.json');
    await mapFile.create(recursive: true);
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    final original = await fixture.read();
    final manifest = original.copyWith(maps: const [
      ProjectMapEntry(
          id: 'closed', name: 'Fermée', relativePath: 'maps/closed.json'),
    ]);
    final projectFile = File('${fixture.root.path}/project.json');
    await projectFile.writeAsString(jsonEncode(manifest.toJson()));
    final plan = await fixture.plan('element.delete', {'elementId': 'decor'});
    expect(plan.status, AuthoringResultStatus.success);
    final confirmation = await fixture.command('confirm', {
      'projectHandle': fixture.project,
      'planId': plan.data['planId'],
    });
    expect(confirmation.status, AuthoringResultStatus.success);
    final expectedProject = await projectFile.readAsBytes();
    var initialSnapshotAccepted = false;
    var dependencyChanged = false;
    final operation = fixture.mutations.applyMutation(
      ProjectHandle(fixture.project),
      planId: plan.data['planId'] as String,
      operationId: 'locked-dependency-race',
      confirmationToken: confirmation.data['confirmationToken'] as String,
      precondition: () async {
        initialSnapshotAccepted = true;
        expect((await fixture.read()).elements.single.id, 'decor');
        expect(
            MapData.fromJson(jsonDecode(await mapFile.readAsString()))
                .placedElements,
            isEmpty);
        final changed = map.copyWith(placedElements: const [
          MapPlacedElement(
              id: 'new-reference',
              layerId: 'base',
              elementId: 'decor',
              pos: GridPos(x: 1, y: 1)),
        ]);
        await mapFile.writeAsString(jsonEncode(changed.toJson()));
        dependencyChanged = true;
      },
    );
    await expectLater(
        operation,
        throwsA(isA<AuthoringPlanException>()
            .having((error) => error.code, 'code', 'plan.stale')));
    expect(initialSnapshotAccepted, isTrue);
    expect(dependencyChanged, isTrue);
    expect(await projectFile.readAsBytes(), expectedProject);
    expect(
        MapData.fromJson(jsonDecode(await mapFile.readAsString()))
            .placedElements
            .single
            .elementId,
        'decor');
  });

  test('unchanged locked precondition permits normal canonical deletion',
      () async {
    final fixture = await registeredFixture();
    addTearDown(fixture.dispose);
    final plan = await fixture.plan('element.delete', {'elementId': 'decor'});
    expect(plan.status, AuthoringResultStatus.success);
    final confirmation = await fixture.command('confirm', {
      'projectHandle': fixture.project,
      'planId': plan.data['planId'],
    });
    var guarded = false;
    final result = await fixture.mutations.applyMutation(
      ProjectHandle(fixture.project),
      planId: plan.data['planId'] as String,
      operationId: 'locked-valid',
      confirmationToken: confirmation.data['confirmationToken'] as String,
      precondition: () async {
        guarded = true;
      },
    );
    expect(guarded, isTrue);
    expect(result.receipt.status, AuthoringReceiptStatus.applied);
    expect((await fixture.read()).elements, isEmpty);
  });
}
