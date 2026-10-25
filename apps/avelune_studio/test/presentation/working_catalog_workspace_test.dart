import 'dart:async';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/working_catalog_controller.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:avelune_studio/presentation/features/resources/working_catalog_workspace.dart';
import 'package:avelune_studio/presentation/shared/widgets/dialogs/studio_review_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'character shadow controls preserve the sprite preview when saved',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final port = _Port()
        ..entry = const WorkingCatalogEntry(
          id: 'guide',
          kind: 'character',
          name: 'Guide',
        );
      final controller = WorkingCatalogController(port);
      addTearDown(controller.dispose);
      var previews = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: WorkingCatalogWorkspace(
            session: const ProjectSession(
              sessionId: 'shadow',
              name: 'Projet',
              directoryPath: '/project',
              storage: ProjectSessionStorage.workingCatalog,
            ),
            controller: controller,
            onClose: () async {},
            registerExitGuard: (_) {},
            previewBuilder: (_) {
              previews++;
              return const Text('Sprite conservé');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await controller.select(port.entry);
      await tester.pumpAndSettle();
      expect(previews, 1);
      expect(find.text('Ombre sous les pieds'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('character-contact-shadow')),
      );
      await tester.tap(find.byKey(const ValueKey('character-contact-shadow')));
      await tester.pumpAndSettle();
      expect(controller.draft!.contactShadow, isTrue);
      await tester.ensureVisible(
        find.byKey(const ValueKey('working-resource-save')),
      );
      await tester.tap(find.byKey(const ValueKey('working-resource-save')));
      await tester.pumpAndSettle();
      expect(port.saved!.contactShadow, isTrue);
      expect(previews, 1);
      await tester.ensureVisible(
        find.byKey(const ValueKey('character-contact-shadow-inherit')),
      );
      await tester.tap(
        find.byKey(const ValueKey('character-contact-shadow-inherit')),
      );
      await tester.pumpAndSettle();
      expect(controller.draft!.contactShadow, isNull);
      expect(previews, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('library keeps edits made while synchronizing a saved resource', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final port = _Port();
    final controller = WorkingCatalogController(port);
    addTearDown(controller.dispose);
    final synchronization = Completer<void>();
    Future<bool> Function()? exit;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkingCatalogWorkspace(
            session: const ProjectSession(
              sessionId: 'sync',
              name: 'Projet',
              directoryPath: '/project',
            ),
            controller: controller,
            onClose: () async {},
            embedded: true,
            onSaved: () => synchronization.future,
            registerExitGuard: (guard) => exit = guard,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await controller.select(port.entry);
    controller.edit(name: 'Première modification');
    final leaving = exit!();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(StudioReviewDialog),
        matching: find.text('Enregistrer'),
      ),
    );
    await tester.pumpAndSettle();
    controller.edit(name: 'Nouvelle saisie conservée');
    synchronization.complete();
    await tester.pumpAndSettle();
    expect(await leaving, isFalse);
    expect(controller.dirty, isTrue);
    expect(controller.draft!.name, 'Nouvelle saisie conservée');
    expect(port.saved!.name, 'Première modification');
    expect(find.text('Ressource enregistrée.'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'interrupted project offers recovery before searching or opening maps',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = WorkingCatalogController(
        _Port(),
        recoveryOperationIds: ['interrupted'],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: WorkingCatalogWorkspace(
            session: const ProjectSession(
              sessionId: 'recovery',
              name: 'Projet',
              directoryPath: '/project',
            ),
            controller: controller,
            onClose: () async {},
            registerExitGuard: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('working-catalog-search')),
        findsNothing,
      );
      expect(find.text('Cartes et ateliers'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('working-catalog-recover')));
      await tester.pumpAndSettle();
      expect(controller.recoveryOperationIds, isEmpty);
      expect(find.text('Bibliothèque du projet'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('workspace supplies its Material scope when hosted directly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = WorkingCatalogController(_Port());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: WorkingCatalogWorkspace(
          session: const ProjectSession(
            sessionId: 'native-host',
            name: 'Projet',
            directoryPath: '/project',
          ),
          controller: controller,
          onClose: () async {},
          registerExitGuard: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('working-catalog-search')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'published projects expose disabled metadata fields and read-only notice',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = WorkingCatalogController(_Port());
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkingCatalogWorkspace(
              session: const ProjectSession(
                sessionId: 'published',
                name: 'Publié',
                directoryPath: '/project',
                storage: ProjectSessionStorage.portableCatalog,
              ),
              controller: controller,
              onClose: () async {},
              registerExitGuard: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await controller.select(
        const WorkingCatalogEntry(
          id: 'decor_124',
          kind: 'element',
          name: 'Décor 124',
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('working-resource-name')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.enabled, isFalse);
      expect(
        find.text('Ce projet publié est disponible en lecture seule.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'library searches globally, edits typed metadata and saves through its port',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final port = _Port();
      final controller = WorkingCatalogController(port);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkingCatalogWorkspace(
              session: const ProjectSession(
                sessionId: 'test',
                name: 'Projet',
                directoryPath: '/project',
              ),
              controller: controller,
              onClose: () async {},
              registerExitGuard: (_) {},
              previewBuilder: (_) => const Text('Aperçu ciblé'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('50 ressources affichées sur 125 résultats'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('working-resource-element:decor_124')),
        findsNothing,
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('working-catalog-search')),
          matching: find.byType(TextField),
        ),
        'Décor 124',
      );
      await tester.pumpAndSettle();
      expect(port.lastQuery, 'Décor 124');
      await tester.tap(
        find.byKey(const ValueKey('working-resource-element:decor_124')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aperçu ciblé'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('working-resource-name')),
          matching: find.byType(TextField),
        ),
        'Bosquet modifié',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('working-resource-description')),
          matching: find.byType(TextField),
        ),
        'Description visible',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('working-resource-tags')),
          matching: find.byType(TextField),
        ),
        'forêt, ombre',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('working-resource-save')),
      );
      await tester.tap(find.byKey(const ValueKey('working-resource-save')));
      await tester.pumpAndSettle();
      expect(port.saved?.name, 'Bosquet modifié');
      expect(port.saved?.description, 'Description visible');
      expect(port.saved?.tags, ['forêt', 'ombre']);
      expect(find.text('Ressource enregistrée.'), findsOneWidget);
      expect(controller.dirty, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _Port implements WorkingCatalogPort {
  String? lastQuery;
  WorkingCatalogDraft? saved;
  WorkingCatalogEntry entry = const WorkingCatalogEntry(
    id: 'decor_124',
    kind: 'element',
    name: 'Décor 124',
  );

  @override
  Future<WorkingCatalogPage> query({
    required String kind,
    required String text,
    String? cursor,
    String? placementContext,
  }) async {
    lastQuery = text;
    return WorkingCatalogPage(
      revision: 'test',
      items: text.isEmpty
          ? [
              for (var index = 0; index < 50; index++)
                WorkingCatalogEntry(
                  id: 'decor_$index',
                  kind: 'element',
                  name: 'Décor $index',
                ),
            ]
          : [entry],
      total: text.isEmpty ? 125 : 1,
      nextCursor: text.isEmpty ? 'next' : null,
    );
  }

  @override
  Future<WorkingCatalogDetail> open(WorkingCatalogEntry selected) async =>
      WorkingCatalogDetail(
        entry: entry,
        revision: 'test',
        definitions: const ProjectManifest(
          name: 'Projection',
          maps: [],
          tilesets: [],
        ),
      );

  @override
  Future<WorkingCatalogDetail> save(
    WorkingCatalogEntry selected,
    WorkingCatalogDraft draft, {
    required String revision,
  }) async {
    saved = draft;
    entry = WorkingCatalogEntry(
      id: selected.id,
      kind: selected.kind,
      name: draft.name,
      description: draft.description,
      tags: draft.tags,
      placementContext: draft.placementContext,
      contactShadow: draft.contactShadow,
    );
    return open(entry);
  }

  @override
  Future<void> close() async {}
  @override
  Future<void> recover(String operationId) async {}
}
