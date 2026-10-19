import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/working_catalog_controller.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:avelune_studio/presentation/features/resources/working_catalog_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'map workspace is opened explicitly and its exit guard protects the library',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = WorkingCatalogController(_Port());
      addTearDown(controller.dispose);
      var builds = 0;
      var allowMapExit = false;
      await tester.pumpWidget(
        MaterialApp(
          home: WorkingCatalogWorkspace(
            session: const ProjectSession(
              sessionId: 'maps',
              name: 'Projet',
              directoryPath: '/project',
            ),
            controller: controller,
            onClose: () async {},
            registerExitGuard: (_) {},
            mapWorkspaceBuilder: (context, guard) {
              builds++;
              guard(() async => allowMapExit);
              return const Text('Atelier existant');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(builds, 0);
      await tester.tap(find.text('Cartes et ateliers'));
      await tester.pumpAndSettle();
      expect(find.text('Atelier existant'), findsOneWidget);
      await tester.tap(find.text('Retour à la bibliothèque'));
      await tester.pumpAndSettle();
      expect(find.text('Atelier existant'), findsOneWidget);
      allowMapExit = true;
      await tester.tap(find.text('Retour à la bibliothèque'));
      await tester.pumpAndSettle();
      expect(find.text('Bibliothèque du projet'), findsOneWidget);
      expect(find.text('Atelier existant'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

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
      var builds = 0;
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
            mapWorkspaceBuilder: (context, guard) {
              builds++;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('working-catalog-search')),
        findsNothing,
      );
      await tester.tap(find.text('Cartes et ateliers'));
      await tester.pumpAndSettle();
      expect(builds, 0);
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
    );
    return open(entry);
  }

  @override
  Future<void> close() async {}
  @override
  Future<void> recover(String operationId) async {}
}
