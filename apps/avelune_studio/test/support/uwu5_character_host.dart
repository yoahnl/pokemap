import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'uwu4_resource_host.dart';
import 'uwu_resource_host.dart';
import 'm2_ui_fixture.dart';

Future<UwUResourceHost> openUwU5CharacterHost(
  WidgetTester tester, {
  Size size = const Size(1536, 1024),
  double textScale = 1,
  bool referenced = false,
}) async {
  final host = await openUwU4ResourceHost(
    tester,
    size: size,
    textScale: textScale,
    configure: (fixture) async {
      final tilesetId = (await fixture.maps.loadProject(
        fixture.session,
      )).tilesets.single.id;
      for (final name in ['Libre', 'Remplaçant']) {
        await fixture.resources.mutate('characterStudio.character.create', {
          'name': name,
          'tilesetId': tilesetId,
          'frameWidth': 1,
          'frameHeight': 1,
        });
      }
      if (referenced) {
        final project = await fixture.maps.loadProject(fixture.session);
        final loaded = await fixture.loadMap();
        final document = EditableMapDocument(loaded);
        CharacterEditingCommands(
          document,
          project,
        ).place(project.characters.first, const GridPos(x: 1, y: 1));
        await fixture.maps.saveMap(fixture.session, loaded, document.current);
      }
    },
  );
  if (find.text('Personnages').evaluate().isEmpty) {
    await tester.tap(find.text('Actions'));
    await pumpIo(tester);
  }
  await tester.tap(find.text('Personnages').last);
  await pumpIo(tester);
  await tester.tap(find.byKey(const ValueKey('character-studio-libre')));
  await pumpIo(tester);
  return host;
}
