import 'package:avelune_studio/features/characters/coordination/character_studio_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';
import 'character_editing_test.dart' show guide;

void main() {
  test('character catalogue filtering and brush selection preserve the map until placement', () {
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    final project = workspaceProject.copyWith(
      characters: [
        guide,
        guide.copyWith(id: 'traveler', name: 'Voyageuse'),
      ],
    );
    final catalogue = CharacterStudioController(
      project: () => project,
      mutate: (_, _) async => project,
    );
    final view = MapEditingViewportSession();
    addTearDown(catalogue.dispose);
    addTearDown(view.dispose);
    expect(catalogue.visibleCharacters.map((entry) => entry.id), [
      guide.id,
      'traveler',
    ]);
    catalogue.setQuery('Voyageuse');
    expect(catalogue.query, 'Voyageuse');
    expect(catalogue.visibleCharacters.single.id, 'traveler');
    view.character = catalogue.visibleCharacters.single;
    view.prepareCharacterPlacement();
    expect(view.character?.id, 'traveler');
    expect(view.tool, StudioMapTool.character);
    expect(document.dirty, isFalse);
    catalogue.setQuery('');
    expect(catalogue.query, isEmpty);
    expect(catalogue.visibleCharacters.map((entry) => entry.id), [
      guide.id,
      'traveler',
    ]);
  });
}
