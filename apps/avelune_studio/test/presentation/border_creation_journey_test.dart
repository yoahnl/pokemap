import 'dart:io';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/border_pattern_panel.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart';
import '../support/ui04_terrain_atlas.dart';
import '../support/resource_family_gestures.dart';

void main() {
  testWidgets('Studio publishes a border and offers it to the map tool', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(() => M2UiFixture.create(tester)))!;
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app(tester));
    await pumpIo(tester);
    await tester.tap(find.text('Bordures'));
    await pumpIo(tester);
    await tester.tap(find.text('Créer un modèle'));
    await pumpIo(tester);
    final navigation = tester
        .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
        .navigation;
    await tester.runAsync(() async {
      final source = File('${fixture.directory.path}/border-source.png');
      await source.writeAsBytes(ui04TerrainAtlas());
      final imported = await fixture.resources.importImage(
        ResourceImageImport(
          sourcePath: source.path,
          name: 'Pièces de clôture',
          tileWidth: 24,
          tileHeight: 24,
        ),
      );
      await navigation.accept(imported);
      final tilesetId = imported.createdTilesetId!;
      for (final (id, x) in [('Embout', 0), ('Segment', 1), ('Angle', 2)]) {
        await navigation.accept(
          await fixture.resources.saveElement(
            ProjectElementEntry(
              id: id.toLowerCase(),
              name: id,
              tilesetId: tilesetId,
              categoryId: '',
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: x, y: 0)),
              ],
            ),
          ),
        );
      }
    });
    await pumpIo(tester);
    await selectResourceFamily(tester, ResourceLibraryFamily.borders);
    await tester.tap(find.text('Créer une bordure'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('border-name')),
      'Clôture du jardin',
    );
    final corner = find.byKey(
      const ValueKey('border-pattern-Angle haut gauche'),
    );
    final angle = find.byKey(const ValueKey('border-library-angle'));
    await tester.ensureVisible(angle);
    await tester.drag(
      angle,
      tester.getCenter(corner) - tester.getCenter(angle),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 3 familles de pièces associées'), findsOneWidget);
    for (final (id, slot) in [
      ('embout', 'Extrémité haute'),
      ('segment', 'Bord haut'),
    ]) {
      final source = find.byKey(ValueKey('border-library-$id'));
      await tester.ensureVisible(source);
      await tester.pumpAndSettle();
      await tester.tap(source);
      final target = find.byKey(ValueKey('border-pattern-$slot'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    expect(
      tester
          .widget<BorderPatternPanel>(find.byType(BorderPatternPanel))
          .chosen
          .keys,
      containsAll(['lineCap', 'lineStraight', 'lineCorner']),
    );
    await fixture.capture(tester, 'bordure-choix-des-pieces');
    tester.view.physicalSize = const Size(1024, 640);
    await tester.pumpWidget(fixture.app(tester, textScale: 1.5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('border-publish')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('border-pattern-Extérieur bas droit')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('border-pattern-Extérieur bas droit')),
      findsOneWidget,
    );
    await fixture.capture(tester, 'bordure-compact-150');
    tester.view.physicalSize = const Size(1536, 1024);
    await tester.pumpWidget(fixture.app(tester));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('border-publish')));
    await pumpIo(tester);
    expect(
      fixture.controller.project!.borderCatalog.records,
      hasLength(1),
      reason: navigation.error,
    );
    expect(
      fixture.controller.project!.borderCatalog.records.single.latestPublished,
      isNotNull,
    );
    final borderId =
        fixture.controller.project!.borderCatalog.records.single.id;
    await tester.tap(find.textContaining('Modifier « Clôture du jardin »'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('border-name')),
      'Clôture du jardin ajustée',
    );
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(
      find.text('Abandonner les modifications de la bordure ?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Conserver'));
    await tester.pumpAndSettle();
    expect(find.text('Clôture du jardin ajustée'), findsOneWidget);
    await tester.tap(find.text('Enregistrer le brouillon'));
    await pumpIo(tester);
    final pending = (await tester.runAsync(
      () => LocalMapWorkspaceAdapter().loadProject(fixture.session),
    ))!;
    expect(
      pending.borderCatalog.recordById(borderId)!.latestPublished!.revision,
      1,
    );
    expect(
      pending.borderCatalog.recordById(borderId)!.draft.definition.name,
      'Clôture du jardin ajustée',
    );
    await tester.tap(
      find.textContaining('Modifier « Clôture du jardin ajustée »'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('border-publish')));
    await pumpIo(tester);
    expect(
      fixture.controller.project!.borderCatalog
          .recordById(borderId)!
          .latestPublished!
          .revision,
      2,
    );
    await tester.tap(
      find.textContaining('Modifier « Clôture du jardin ajustée »'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('border-name')),
      'Nom abandonné',
    );
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abandonner'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('border-name')), findsNothing);
    expect(
      fixture.controller.project!.borderCatalog
          .recordById(borderId)!
          .draft
          .definition
          .name,
      'Clôture du jardin ajustée',
    );
    await tester.tap(find.textContaining('Carte :').first);
    await pumpIo(tester);
    await tester.ensureVisible(find.text('Bordures'));
    await tester.tap(find.text('Bordures'));
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('border-model-picker')));
    await pumpIo(tester);
    await tester.tap(find.text('Clôture du jardin ajustée').last);
    await pumpIo(tester);
    expect(find.text('Clôture du jardin ajustée'), findsWidgets);
    await fixture.capture(tester, 'bordure-modele-publie');
    final document = fixture.controller.active!;
    final canvas = tester.getTopLeft(find.byKey(const ValueKey('map-canvas')));
    final cell =
        fixture.controller.project!.settings.tileWidth *
        fixture.controller.project!.settings.displayScale;
    Offset at(int x, int y) =>
        canvas + Offset((x + .5) * cell, (y + .5) * cell);
    await tester.tapAt(at(4, 4));
    await tester.tapAt(at(7, 4));
    await tester.tapAt(at(7, 7));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpIo(tester);
    expect(
      document.current.layers.whereType<BorderLayer>(),
      isNotEmpty,
      reason: document.error,
    );
    await tester.tap(find.byKey(const ValueKey('Enregistrer')));
    await pumpIo(tester);
    final reopened = (await tester.runAsync(() async {
      final adapter = LocalMapWorkspaceAdapter();
      final project = await adapter.loadProject(fixture.session);
      return adapter.loadMap(fixture.session, project.maps.first);
    }))!;
    expect(reopened.map.layers.whereType<BorderLayer>(), isNotEmpty);
    await fixture.capture(tester, 'bordure-tracee');
  });
}
