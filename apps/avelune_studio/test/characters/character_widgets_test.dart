import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

import '../support/map_workspace_fixture.dart';
import 'character_editing_test.dart' show guide;

void main() {
  for (final spatial in [false, true]) {
    test(
      '2D/3D character instance editing preserves independent identity and history spatial=$spatial',
      () {
        final document = EditableMapDocument(
          MapWorkspaceDocument(
            map: spatial
                ? workspaceMap('a').copyWith(
                    version: ProjectVersion.v9,
                    visualStack: null,
                    layers: const [],
                    spatialScene: MapSpatialScene(
                      width: workspaceMap('a').size.width,
                      depth: workspaceMap('a').size.height,
                    ),
                  )
                : workspaceMap('a'),
            revision: 'base',
            mapId: 'a',
          ),
        );
        final project = workspaceProject.copyWith(
          settings: workspaceProject.settings.copyWith(
            dimension: spatial
                ? ProjectDimension.threeD
                : ProjectDimension.twoD,
          ),
          characters: [
            guide,
            guide.copyWith(id: 'traveler', name: 'Voyageuse'),
          ],
          trainers: [
            const ProjectTrainerEntry(
              id: 'alice',
              name: 'Alice',
              trainerClass: 'Dresseuse',
            ),
          ],
        );

        expect(document.dirty, isFalse);
        final commands = CharacterEditingCommands(document, project);
        final selected = commands
            .place(project.characters.last, const GridPos(x: 3, y: 4))
            .id;
        expect(commands.selected(selected)!.npc!.characterId, 'traveler');
        final before = document.undoCount;
        commands.update(selected, name: 'Voyageuse du quai');
        expect(
          commands.selected(selected)!.npc!.displayName,
          'Voyageuse du quai',
        );
        expect(document.undoCount, before + 1);
        commands.update(selected, blocks: false);
        expect(commands.selected(selected)!.blocksMovement, isFalse);
        commands.assignTrainer(selected, 'alice');
        expect(commands.selected(selected)!.npc!.trainerId, 'alice');
        final beforeCounter = document.current;
        commands.setCounterInteractionSides(selected, const [
          EntityFacing.south,
        ]);
        expect(commands.selected(selected)!.npc!.counterInteractionSides, [
          EntityFacing.south,
        ]);
        document.restore(redo: false);
        expect(document.current, beforeCounter);
        document.restore(redo: true);
        expect(commands.selected(selected)!.npc!.counterInteractionSides, [
          EntityFacing.south,
        ]);
        commands.setCounterInteractionSides(selected, const []);
        expect(
          commands.selected(selected)!.npc!.counterInteractionSides,
          isEmpty,
        );
        final clone = commands.duplicate(selected);
        expect(clone.id, isNot(selected));
        expect(document.current.entities, hasLength(2));
        commands.update(clone.id, name: 'Copie indépendante');
        expect(
          commands.selected(selected)!.npc!.displayName,
          'Voyageuse du quai',
        );
        expect(
          commands.selected(clone.id)!.npc!.displayName,
          'Copie indépendante',
        );
      },
    );
  }
}
