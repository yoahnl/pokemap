import 'dart:io';

import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/characters/application/character_removal_controller.dart';
import 'package:avelune_studio/features/characters/coordination/character_removal_workflow.dart';
import 'package:avelune_studio/features/characters/coordination/character_studio_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/authoring_resource_fixture.dart';

void main() {
  test('a dirty draft of the removed character refuses inspection and keeps the draft', () async {
    final setup = await _CharacterRemovalSetup.create();
    addTearDown(setup.fixture.dispose);
    setup.characters.select(setup.libre.id);
    setup.characters.setName('Nom non enregistré');

    await setup.remove(setup.libre, (controller) async {
      await controller.inspect();
      expect(controller.error, contains('Personnage Libre'));
      expect(controller.inspection, isNull);
      expect(controller.plan, isNull);
    });

    final draft = setup.characters.draftFor(setup.libre.id)!;
    expect(draft.dirty, isTrue);
    expect(draft.name, 'Nom non enregistré');
    expect(await setup.savedNames(), ['Libre', 'Remplaçant']);
  });

  test('a dirty draft of the replacement refuses the replace resolution and keeps the map reference', () async {
    final setup = await _CharacterRemovalSetup.create(referenced: true);
    addTearDown(setup.fixture.dispose);
    final mapsBefore = await setup.fixture.mapFiles();
    setup.characters.select(setup.remplacant.id);
    setup.characters.setName('Remplaçant en cours');
    setup.characters.select(setup.libre.id);

    await setup.remove(setup.libre, (controller) async {
      await controller.inspect();
      expect(controller.error, isNull);
      expect(controller.requiresResolution, isTrue);
      await controller.selectResolution('replace');
      await controller.selectReplacement(setup.remplacant.id);
      expect(controller.error, contains('Personnage Remplaçant'));
      expect(controller.plan, isNull);
      expect(controller.canSubmit, isFalse);
    });

    final draft = setup.characters.draftFor(setup.remplacant.id)!;
    expect(draft.dirty, isTrue);
    expect(draft.name, 'Remplaçant en cours');
    expect(await setup.savedNames(), ['Libre', 'Remplaçant']);
    expect(setup.npcCharacterIds(setup.document), [setup.libre.id]);
    expect(setup.document.dirty, isFalse);
    expect(await setup.fixture.mapFiles(), mapsBefore);
  });

  test('a dirty map that references the character refuses removal and saves nothing', () async {
    final setup = await _CharacterRemovalSetup.create(referenced: true);
    addTearDown(setup.fixture.dispose);
    final mapsBefore = await setup.fixture.mapFiles();
    final document = setup.document;
    document.commit(document.current.copyWith(name: 'Carte en cours'));

    await setup.remove(setup.libre, (controller) async {
      await controller.inspect();
      expect(controller.error, contains('Carte Carte en cours'));
      expect(controller.inspection, isNull);
      expect(controller.plan, isNull);
    });

    expect(document.dirty, isTrue);
    expect(document.current.name, 'Carte en cours');
    expect(setup.npcCharacterIds(document), [setup.libre.id]);
    expect(await setup.savedNames(), ['Libre', 'Remplaçant']);
    expect(await setup.fixture.mapFiles(), mapsBefore);
  });

  test(
    'a dirty map without the character does not block removal and stays dirty',
    () async {
      final setup = await _CharacterRemovalSetup.create();
      addTearDown(setup.fixture.dispose);
      final mapsBefore = await setup.fixture.mapFiles();
      final document = setup.document;
      document.commit(
        document.current.copyWith(name: 'Carte modifiée non concernée'),
      );

      await setup.remove(setup.libre, (controller) async {
        await controller.inspect();
        expect(controller.error, isNull);
        expect(controller.requiresResolution, isFalse);
        expect(controller.plan, isNotNull);
        controller.confirm(true);
        expect(await controller.submit(), isNull);
      });

      expect(document.dirty, isTrue);
      expect(document.current.name, 'Carte modifiée non concernée');
      expect(await setup.savedNames(), ['Remplaçant']);
      expect(await setup.fixture.mapFiles(), mapsBefore);
    },
  );

  test(
    'a removal drops only the removed draft and keeps another dirty draft',
    () async {
      final setup = await _CharacterRemovalSetup.create();
      addTearDown(setup.fixture.dispose);
      setup.characters.select(setup.remplacant.id);
      setup.characters.setName('Autre brouillon');
      setup.characters.select(setup.libre.id);
      expect(setup.characters.selectedDraft!.dirty, isFalse);
      expect(setup.characters.draftFor(setup.libre.id), isNotNull);

      await setup.remove(setup.libre, (controller) async {
        await controller.inspect();
        expect(controller.error, isNull);
        controller.confirm(true);
        expect(await controller.submit(), isNull);
      });

      expect(setup.characters.draftFor(setup.libre.id), isNull);
      final kept = setup.characters.draftFor(setup.remplacant.id)!;
      expect(kept.dirty, isTrue);
      expect(kept.name, 'Autre brouillon');
      expect(setup.characters.dirty, isTrue);
      expect(await setup.savedNames(), ['Remplaçant']);
    },
  );

  test('a replacement keeps the open map history and refuses an undo to the deleted character', () async {
    final setup = await _CharacterRemovalSetup.create(referenced: true);
    addTearDown(setup.fixture.dispose);
    final workspace = setup.fixture.workspace;
    final document = setup.document;
    final initial = document.current;
    document.commit(initial.copyWith(properties: {'ordinary': 'kept'}));
    expect(await workspace.save(document), isTrue);
    final undoCount = document.undoCount;

    await setup.remove(setup.libre, (controller) async {
      await controller.inspect();
      expect(controller.requiresResolution, isTrue);
      await controller.selectResolution('replace');
      await controller.selectReplacement(setup.remplacant.id);
      expect(controller.error, isNull);
      controller.confirm(true);
      expect(await controller.submit(), isNull);
    });

    expect(document.undoCount, undoCount);
    expect(document.dirty, isFalse);
    expect(setup.npcCharacterIds(document), [setup.remplacant.id]);
    final savedMaps = (await setup.fixture.mapFiles()).values;
    expect(
      savedMaps.where((map) => map.contains(setup.remplacant.id)),
      hasLength(1),
    );
    expect(savedMaps.where((map) => map.contains(setup.libre.id)), isEmpty);

    workspace.restore(redo: false);
    expect(document.current.properties, initial.properties);
    expect(setup.npcCharacterIds(document), [setup.remplacant.id]);
    workspace.restore(redo: true);
    expect(document.current.properties['ordinary'], 'kept');
    expect(setup.npcCharacterIds(document), [setup.remplacant.id]);

    document.commit(document.current.copyWith(entities: []));
    workspace.restore(redo: false);
    expect(setup.npcCharacterIds(document), [setup.remplacant.id]);

    final updated = document.current;
    document.commit(updated.copyWith(entities: initial.entities));
    document.commit(updated);
    final retained = document.undoCount;
    workspace.restore(redo: false);
    expect(document.current, updated);
    expect(document.undoCount, retained);
    expect(document.error, contains('personnage supprimé'));
  });

  test('a replace resolution rewrites the reference on disk and in the clean open map', () async {
    final setup = await _CharacterRemovalSetup.create(referenced: true);
    addTearDown(setup.fixture.dispose);
    final document = setup.document;
    final before = document.current;
    final entityId = setup.npcEntityId(before);

    await setup.remove(setup.libre, (controller) async {
      await controller.inspect();
      await controller.selectResolution('replace');
      await controller.selectReplacement(setup.remplacant.id);
      expect(controller.error, isNull);
      controller.confirm(true);
      expect(await controller.submit(), isNull);
    });

    expect(document.dirty, isFalse);
    expect(setup.npcEntityId(document.current), entityId);
    expect(setup.npcCharacterIds(document), [setup.remplacant.id]);
    expect(document.current.layers, before.layers);
    final disk = await setup.loadActiveMap();
    expect(document.base.revision, disk.revision);
    expect(setup.npcEntityId(disk.map), entityId);
    expect(setup.mapNpcCharacterIds(disk.map), [setup.remplacant.id]);
    expect(disk.map.layers, before.layers);
    expect(await setup.savedNames(), ['Remplaçant']);
  });

  test('a clear resolution empties the reference on disk and in the clean open map', () async {
    final setup = await _CharacterRemovalSetup.create(referenced: true);
    addTearDown(setup.fixture.dispose);
    final document = setup.document;
    final before = document.current;
    final entityId = setup.npcEntityId(before);

    await setup.remove(setup.libre, (controller) async {
      await controller.inspect();
      await controller.selectResolution('clear');
      expect(controller.error, isNull);
      controller.confirm(true);
      expect(await controller.submit(), isNull);
    });

    expect(document.dirty, isFalse);
    expect(setup.npcEntityId(document.current), entityId);
    expect(setup.npcCharacterIds(document), [null]);
    expect(document.current.layers, before.layers);
    final disk = await setup.loadActiveMap();
    expect(document.base.revision, disk.revision);
    expect(setup.npcEntityId(disk.map), entityId);
    expect(setup.mapNpcCharacterIds(disk.map), [null]);
    expect(disk.map.layers, before.layers);
    expect(await setup.savedNames(), ['Remplaçant']);
  });

  test('a new inspection revokes the confirmation and deletes nothing until confirmed again', () async {
    final setup = await _CharacterRemovalSetup.create();
    addTearDown(setup.fixture.dispose);

    await setup.remove(setup.libre, (controller) async {
      await controller.inspect();
      controller.confirm(true);
      expect(controller.canSubmit, isTrue);
      await controller.inspect();
      expect(controller.plan, isNotNull);
      expect(controller.confirmed, isFalse);
      expect(controller.canSubmit, isFalse);
      expect(await controller.submit(), isNotNull);
      expect(await setup.savedNames(), ['Libre', 'Remplaçant']);
      controller.confirm(true);
      expect(await controller.submit(), isNull);
    });

    expect(await setup.savedNames(), ['Remplaçant']);
  });

  test('a character changed after the plan was prepared is neither overwritten nor deleted', () async {
    final setup = await _CharacterRemovalSetup.create();
    addTearDown(setup.fixture.dispose);

    await setup.remove(setup.libre, (controller) async {
      await controller.inspect();
      expect(controller.plan, isNotNull);
      await setup.fixture.resources.mutate('characterStudio.character.update', {
        'characterId': setup.libre.id,
        'name': 'Version concurrente',
      });
      controller.confirm(true);
      expect(await controller.submit(), isNotNull);
    });

    expect(setup.fixture.navigation.pendingReceipt, isNull);
    expect(await setup.savedNames(), ['Version concurrente', 'Remplaçant']);
  });

  test('a replacement deleted after the preview leaves the project and the map untouched', () async {
    final setup = await _CharacterRemovalSetup.create(referenced: true);
    addTearDown(setup.fixture.dispose);
    final mapsBefore = await setup.fixture.mapFiles();
    final resources = setup.fixture.resources;

    await setup.remove(setup.libre, (controller) async {
      await controller.inspect();
      await controller.selectResolution('replace');
      await controller.selectReplacement(setup.remplacant.id);
      expect(controller.plan, isNotNull);
      final preparation = await resources.prepareOperation(
        'characterStudio.character.delete',
        {'characterId': setup.remplacant.id},
      );
      try {
        await resources.applyPrepared(preparation, confirmDestructive: true);
      } finally {
        await resources.releasePreparation(preparation);
      }
      controller.confirm(true);
      expect(await controller.submit(), isNotNull);
    });

    expect(setup.fixture.navigation.pendingReceipt, isNull);
    expect(await setup.savedNames(), ['Libre']);
    expect(setup.npcCharacterIds(setup.document), [setup.libre.id]);
    expect(await setup.fixture.mapFiles(), mapsBefore);
  });

  test('a failed reconciliation after publication keeps the receipt and retries without replaying the deletion', () async {
    final setup = await _CharacterRemovalSetup.create();
    addTearDown(setup.fixture.dispose);
    final navigation = setup.fixture.navigation;
    var reconciliations = 0;
    navigation.characterSourcesChanged = (_) {
      reconciliations++;
      throw StateError('Réconciliation injectée');
    };
    setup.characters.select(setup.libre.id);

    await setup.remove(setup.libre, (controller) async {
      await controller.inspect();
      controller.confirm(true);
      expect(await controller.submit(), contains('publié'));
    });

    expect(await setup.savedNames(), ['Remplaçant']);
    expect(
      navigation.pendingReceipt!.actionId,
      'characterStudio.character.delete',
    );
    expect(reconciliations, 1);
    final published = await setup.projectFile();
    navigation.characterSourcesChanged = (_) => reconciliations++;
    expect(
      await navigation.retryReconciliation(),
      isTrue,
      reason: navigation.error,
    );
    expect(navigation.pendingReceipt, isNull);
    expect(reconciliations, 2);
    expect(await setup.projectFile(), published);
    expect(setup.characters.selectedId, isNull);
  });

  test(
    'a free removal deletes only the character and selects no other identity',
    () async {
      final setup = await _CharacterRemovalSetup.create();
      addTearDown(setup.fixture.dispose);
      final before = await setup.fixture.reopen();
      setup.characters.select(setup.libre.id);
      expect(setup.characters.selectedId, setup.libre.id);

      await setup.remove(setup.libre, (controller) async {
        await controller.inspect();
        controller.confirm(true);
        expect(await controller.submit(), isNull);
      });

      expect(setup.characters.selectedId, isNull);
      expect(setup.characters.selectedCharacter, isNull);
      final after = await setup.fixture.reopen();
      expect(after.tilesets, before.tilesets);
      expect(after.elements, before.elements);
      expect(await setup.savedNames(), ['Remplaçant']);
    },
  );
}

final class _CharacterRemovalSetup {
  _CharacterRemovalSetup(this.fixture, this.libre, this.remplacant);

  final AuthoringResourceFixture fixture;
  final ProjectCharacterEntry libre;
  final ProjectCharacterEntry remplacant;

  CharacterStudioController get characters => fixture.navigation.characters;
  EditableMapDocument get document => fixture.workspace.active!;

  static Future<_CharacterRemovalSetup> create({
    bool referenced = false,
  }) async {
    final fixture = await AuthoringResourceFixture.create();
    try {
      final characters = fixture.navigation.characters;
      final tilesetId = fixture.workspace.project!.tilesets.first.id;
      for (final name in ['Libre', 'Remplaçant']) {
        expect(
          await characters.create(
            name,
            tilesetId,
            frameWidth: 1,
            frameHeight: 1,
          ),
          isTrue,
        );
      }
      final project = fixture.workspace.project!;
      final setup = _CharacterRemovalSetup(
        fixture,
        project.characters.singleWhere((entry) => entry.name == 'Libre'),
        project.characters.singleWhere((entry) => entry.name == 'Remplaçant'),
      );
      expect(setup.npcCharacterIds(setup.document), isEmpty);
      if (referenced) {
        CharacterEditingCommands(
          setup.document,
          project,
        ).place(setup.libre, const GridPos(x: 1, y: 1));
        expect(await fixture.workspace.save(setup.document), isTrue);
        expect(setup.document.dirty, isFalse);
      }
      return setup;
    } catch (_) {
      await fixture.dispose();
      rethrow;
    }
  }

  Future<List<String>> savedNames() async => [
    for (final entry in (await fixture.reopen()).characters)
      if (entry.id == libre.id || entry.id == remplacant.id) entry.name,
  ];

  List<String?> npcCharacterIds(EditableMapDocument document) =>
      mapNpcCharacterIds(document.current);

  List<String?> mapNpcCharacterIds(MapData map) => [
    for (final entity in map.entities)
      if (entity.npc != null) entity.npc!.characterId,
  ];

  String npcEntityId(MapData map) =>
      map.entities.singleWhere((entity) => entity.npc != null).id;

  Future<MapWorkspaceDocument> loadActiveMap() async {
    final adapter = LocalMapWorkspaceAdapter();
    final project = await adapter.loadProject(fixture.session);
    return adapter.loadMap(
      fixture.session,
      project.maps.singleWhere((entry) => entry.id == document.base.mapId),
    );
  }

  Future<String> projectFile() =>
      File('${fixture.directory.path}/project.json').readAsString();

  Future<void> remove(
    ProjectCharacterEntry character,
    Future<void> Function(CharacterRemovalController controller) steps,
  ) async {
    Object? failure;
    StackTrace? stack;
    var presented = false;
    await runCharacterRemoval(
      navigation: fixture.navigation,
      character: character,
      present: (controller) async {
        presented = true;
        try {
          await steps(controller);
        } catch (error, trace) {
          failure = error;
          stack = trace;
          rethrow;
        }
      },
    );
    if (failure != null) Error.throwWithStackTrace(failure!, stack!);
    expect(presented, isTrue);
    expect(fixture.navigation.managementDialogActive, isFalse);
  }
}
