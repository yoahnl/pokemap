import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'studio_playtest_projection_guard_fixture.dart';

void main() {
  testWidgets('native 3D brush projection reaches hero validation', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(ProjectionGuardFixture.create))!;
    addTearDown(fixture.dispose);
    final bundle = RuntimeMapBundle(
      manifest: fixture.project,
      map: fixture.document.map,
      projectRootDirectory: fixture.directory.path,
      tilesetAbsolutePathsById: const {},
    );
    expect(fixture.document.map.spatialScene!.instances, isEmpty);
    expect(bundle.map.spatialScene!.instances, hasLength(1));
    expect(
      bundle.map.spatialScene!.instances.single.position,
      Model3dVector3(x: 1, y: .5 + spatialSmartTileLayerPaintStep, z: 1),
    );
    expect(bundle.map, isNot(fixture.document.map));

    await fixture.mount(tester);
    await waitForProjection(tester, 'Choisissez un héros animé');
    expect(find.textContaining('Choisissez un héros animé'), findsOneWidget);
    expect(find.textContaining('La carte a changé'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a real change during first spatial load is rejected', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(ProjectionGuardFixture.create))!;
    addTearDown(fixture.dispose);
    await fixture.mount(
      tester,
      port: ChangingPort(fixture.port, fixture.changeMap),
    );
    await waitForProjection(
      tester,
      'La carte a changé pendant la préparation du test',
    );
    expect(
      find.textContaining('La carte a changé pendant la préparation du test'),
      findsOneWidget,
    );
    expect(find.textContaining('Choisissez un héros animé'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a real change during spatial asset preparation is rejected', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => ProjectionGuardFixture.create(withHero: true),
    ))!;
    addTearDown(fixture.dispose);
    var preparationCalls = 0;
    await fixture.mount(
      tester,
      prepare: (_) async {
        preparationCalls++;
        await fixture.changeMap();
      },
    );
    await waitForProjection(
      tester,
      'La carte a changé pendant la préparation du test',
    );
    expect(preparationCalls, 1);
    expect(
      find.textContaining('La carte a changé pendant la préparation du test'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a real change during 2D asset preparation stays rejected', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => ProjectionGuardFixture.create(spatial: false),
    ))!;
    addTearDown(fixture.dispose);
    var preparationCalls = 0;
    await fixture.mount(
      tester,
      prepare: (_) async {
        preparationCalls++;
        await fixture.changeMap();
      },
    );
    await waitForProjection(
      tester,
      'La carte a changé pendant la préparation du test',
    );
    expect(preparationCalls, 1);
    expect(
      find.textContaining('La carte a changé pendant la préparation du test'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
