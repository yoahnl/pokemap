import 'dart:io';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart';

void main() {
  testWidgets('invalid border keeps its pattern and explains the failed join', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(() => M2UiFixture.create(tester)))!;
    addTearDown(fixture.dispose);
    final resources = _BorderResourcePort(fixture.resources, tester);
    await tester.pumpWidget(fixture.app(tester, resourcePort: resources));
    await pumpIo(tester);
    await tester.tap(find.text('Bordures'));
    await pumpIo(tester);
    await tester.tap(find.text('Créer un modèle'));
    await pumpIo(tester);
    final navigation = tester
        .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
        .navigation;
    await tester.runAsync(() async {
      final pixels = image.Image(width: 48, height: 32, numChannels: 4);
      for (var piece = 0; piece < 3; piece++) {
        image.fillRect(
          pixels,
          x1: piece * 16 + 6,
          y1: 6,
          x2: piece * 16 + 9,
          y2: 9,
          color: image.ColorRgba8(80, 150, 200, 255),
        );
      }
      final source = File('${fixture.directory.path}/disconnected-border.png');
      await source.writeAsBytes(image.encodePng(pixels));
      final imported = await fixture.resources.importImage(
        ResourceImageImport(
          sourcePath: source.path,
          name: 'Pièces séparées',
          tileWidth: 16,
          tileHeight: 16,
        ),
      );
      await navigation.accept(imported);
      for (final (id, x) in [('cap', 0), ('straight', 1), ('corner', 2)]) {
        await navigation.accept(
          await fixture.resources.saveElement(
            ProjectElementEntry(
              id: id,
              name: id,
              tilesetId: imported.createdTilesetId!,
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
    await tester.tap(find.text('Créer une bordure'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('border-name')),
      'Clôture sans raccords',
    );
    for (final (id, slot) in [
      ('cap', 'Extrémité haute'),
      ('straight', 'Bord haut'),
      ('corner', 'Angle haut gauche'),
    ]) {
      final source = find.byKey(ValueKey('border-library-$id'));
      await tester.ensureVisible(source);
      await tester.tap(source);
      await tester.pumpAndSettle();
      final target = find.byKey(ValueKey('border-pattern-$slot'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    expect(find.text('3 / 3 familles de pièces associées'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('border-publish')));
    await pumpIo(tester);
    expect(find.textContaining('Courbe en S'), findsOneWidget);
    expect(find.textContaining('Réassociez'), findsOneWidget);
    expect(find.textContaining('MapAuthoringException'), findsNothing);
    expect(find.text('3 / 3 familles de pièces associées'), findsOneWidget);
    expect(fixture.controller.project!.borderCatalog.records, hasLength(1));
    expect(
      fixture.controller.project!.borderCatalog.records.single.latestPublished,
      isNull,
    );
    tester.view.physicalSize = const Size(1024, 640);
    await tester.pumpWidget(
      fixture.app(tester, textScale: 1.5, resourcePort: resources),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Courbe en S'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('border-publish')));
    await pumpIo(tester);
    expect(fixture.controller.project!.borderCatalog.records, hasLength(1));
  });
}

class _BorderResourcePort extends WidgetResourcePort {
  _BorderResourcePort(super.port, super.tester);

  @override
  Future<ResourceMutationReceipt> run(
    Future<ResourceMutationReceipt> Function() action,
  ) async {
    ResourceMutationReceipt? receipt;
    Object? failure;
    StackTrace? failureStack;
    await WidgetResourcePort.serial(tester, () async {
      try {
        receipt = await action();
      } catch (error, stack) {
        failure = error;
        failureStack = stack;
      }
    });
    if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
    return receipt!;
  }
}
