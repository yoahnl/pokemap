import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../avelune_studio/test/support/m2_ui_fixture.dart';
import 'uwu6_resource_host.dart';

Future<void> drawUwu6Border(Uwu6ResourceHost host) async {
  final tester = host.tester;
  await host.go('Carte');
  expect(
    host.fixture.controller.active!.current.layers.whereType<BorderLayer>(),
    isEmpty,
  );
  await host.text('Bordures');
  await host.tap('border-model-picker');
  await host.text('Muret conservé');
  await host.cell(10, 8);
  await host.cell(13, 8);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await pumpIo(tester, frames: 6);
  final map = host.fixture.controller.active!.current;
  final border = map.layers.whereType<BorderLayer>().single;
  expect(border.content.features, hasLength(1));
  expect(
    map.layers.indexOf(border),
    0,
    reason: 'First normal stroke must be above an opaque floor.',
  );
  final blockedCell = 8 * map.size.width + 11;
  expect(
    map.layers.whereType<CollisionLayer>().any(
      (layer) => layer.collisions[blockedCell],
    ),
    false,
  );
  await host.text('Collisions');
  await host.cell(11, 8);
  final painted = host.fixture.controller.active!.current;
  expect(
    painted.layers.whereType<CollisionLayer>().any(
      (layer) => layer.collisions[blockedCell],
    ),
    true,
  );
  expect(
    painted.layers.whereType<BorderLayer>().single.content,
    border.content,
  );
  await host.saveMap();
  await host.fixture.capture(tester, 'uwu6-widget-first-border-stroke');
  print(
    'UWU6_RESOURCE_FIRST_BORDER_UI id=${border.id} features=${border.content.features.length} index=${map.layers.indexOf(border)}',
  );
  print('UWU6_RESOURCE_EXPLICIT_BORDER_COLLISION_UI=11,8 visualOnly=10,8');
}

Future<void> deprecateUwu6Border(Uwu6ResourceHost host) async {
  await host.go('Ressources');
  await host.text('Publiées');
  final before = (await host.reopen()).borderCatalog.records.single;
  await host.tap('border-resource-actions-${before.id}');
  await host.text('Déprécier…');
  await host.tap('resource-border-confirm');
  await host.tap('resource-management-save');
  final deprecated = (await host.reopen()).borderCatalog.records.single;
  expect(deprecated.isDeprecated, true);
  expect(deprecated.draft, before.draft);
  expect(deprecated.latestPublished, before.latestPublished);
  await host.text('Dépréciées');
  await host.tap('border-resource-actions-${before.id}');
  await host.text('Réactiver…');
  await host.tap('resource-border-confirm');
  await host.tap('resource-management-save');
  expect((await host.reopen()).borderCatalog.records.single, before);
  await host.text('Publiées');
  await host.tap('border-resource-actions-${before.id}');
  await host.text('Déprécier…');
  await host.tap('resource-border-confirm');
  await host.tap('resource-management-save');
  expect((await host.reopen()).borderCatalog.records.single.isDeprecated, true);
  await host.fixture.capture(host.tester, 'uwu6-widget-deprecated-border');
  print(
    'UWU6_RESOURCE_BORDER_UI deprecated-reactivated-deprecated=${before.id}',
  );
}
