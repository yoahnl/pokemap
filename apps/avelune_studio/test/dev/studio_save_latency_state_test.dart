import 'package:avelune_studio/features/characters/coordination/character_studio_controller.dart';
import 'package:avelune_studio/features/resources/application/working_catalog_controller.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../../dev/studio_save_latency.dart';

void main() {
  testWidgets(
    'latency probe observes a character owner through a technical listenable host',
    (tester) async {
      const project = ProjectManifest(
        name: 'Latency',
        maps: [],
        tilesets: [],
        settings: ProjectSettings(actorContactShadowsByDefault: true),
        characters: [
          ProjectCharacterEntry(
            id: 'guide',
            name: 'Guide',
            tilesetId: 'atlas',
            contactShadow: false,
          ),
        ],
      );
      final controller = CharacterStudioController(
        project: () => project,
        mutate: (_, _) async => project,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        AnimatedBuilder(
          animation: controller,
          builder: (_, _) => const SizedBox(),
        ),
      );
      expect(readStudioSaveLatencyState(), {
        'storage': 'manifest',
        'selectedId': 'guide',
        'saving': false,
        'error': null,
        'dirty': false,
        'draftValue': false,
        'savedValue': false,
        'projectDefault': true,
      });
      controller.setContactShadow(null);
      final changed = readStudioSaveLatencyState();
      expect(changed['dirty'], isTrue);
      expect(changed['draftValue'], isNull);
      expect(changed['savedValue'], isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'latency probe observes the original working catalogue controller state',
    (tester) async {
      const entry = WorkingCatalogEntry(
        id: 'guide',
        kind: 'character',
        name: 'Guide',
        contactShadow: true,
      );
      final controller = WorkingCatalogController(_UnusedPort())
        ..selected = entry
        ..detail = const WorkingCatalogDetail(
          entry: entry,
          revision: 'r1',
          definitions: ProjectManifest(name: 'Latency', maps: [], tilesets: []),
        )
        ..draft = WorkingCatalogDraft.fromEntry(entry);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: controller,
          builder: (_, _) => const SizedBox(),
        ),
      );
      final state = readStudioSaveLatencyState();
      expect(state['storage'], 'workingCatalog');
      expect(state['selectedId'], 'guide');
      expect(state['draftValue'], isTrue);
      expect(state['savedValue'], isTrue);
      expect(state['dirty'], isFalse);
      controller.edit(contactShadow: null);
      expect(readStudioSaveLatencyState()['draftValue'], isNull);
      expect(readStudioSaveLatencyState()['dirty'], isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'latency probe clearly refuses a host without an authoring owner',
    (tester) async {
      await tester.pumpWidget(const SizedBox());
      expect(
        readStudioSaveLatencyState,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'A resource editor is required.',
          ),
        ),
      );
    },
  );
}

class _UnusedPort implements WorkingCatalogPort {
  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('No catalogue I/O was requested');
}
