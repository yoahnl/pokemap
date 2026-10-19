import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/resources/application/working_catalog_controller.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';

void main() {
  test(
    'recovery can reopen the session before issuing any content query',
    () async {
      final port = _Port();
      final controller = WorkingCatalogController(
        port,
        recoveryOperationIds: ['interrupted-partition'],
      );
      addTearDown(controller.dispose);
      await controller.recover(refresh: false);
      expect(controller.recoveryOperationIds, isEmpty);
      expect(controller.error, isNull);
      expect(port.pages, isEmpty);
    },
  );

  test('paging retains one page and preserves the selected resource', () async {
    final port = _Port();
    final controller = WorkingCatalogController(port);
    addTearDown(controller.dispose);
    final initial = controller.search('');
    port.pages[0].complete(
      WorkingCatalogPage(
        revision: 'revision-1',
        items: [_entry('premier')],
        total: 2,
        nextCursor: 'second',
      ),
    );
    await initial;
    await controller.select(controller.items.single);
    final next = controller.loadMore();
    port.pages[1].complete(
      WorkingCatalogPage(
        revision: 'revision-1',
        items: [_entry('second')],
        total: 2,
      ),
    );
    await next;
    expect(controller.items.single.id, 'second');
    expect(controller.selected?.id, 'premier');
    expect(controller.pageNumber, 2);
    final previous = controller.previousPage();
    port.pages[2].complete(
      WorkingCatalogPage(
        revision: 'revision-1',
        items: [_entry('premier')],
        total: 2,
        nextCursor: 'second',
      ),
    );
    await previous;
    expect(controller.items.single.id, 'premier');
    expect(controller.pageNumber, 1);
  });

  test('a different root cannot be appended as the next page', () async {
    final port = _Port();
    final controller = WorkingCatalogController(port);
    addTearDown(controller.dispose);
    final initial = controller.search('');
    port.pages[0].complete(
      WorkingCatalogPage(
        revision: 'revision-1',
        items: [_entry('premier')],
        total: 2,
        nextCursor: 'second',
      ),
    );
    await initial;
    final next = controller.loadMore();
    port.pages[1].complete(
      WorkingCatalogPage(
        revision: 'revision-2',
        items: [_entry('intrus')],
        total: 2,
      ),
    );
    await next;
    expect(controller.items.single.id, 'premier');
    expect(controller.pageNumber, 1);
    expect(controller.error, contains('catalogue a changé'));
  });

  test('late query cannot replace a newer global search', () async {
    final port = _Port();
    final controller = WorkingCatalogController(port);
    addTearDown(controller.dispose);
    final first = controller.search('ancien');
    final second = controller.search('récent');
    port.pages[1].complete(_page('récent'));
    await second;
    port.pages[0].complete(_page('ancien'));
    await first;
    expect(controller.items.single.name, 'récent');
    expect(controller.query, 'récent');
  });

  test(
    'selection and draft survive a page that omits the selected item',
    () async {
      final port = _Port();
      final controller = WorkingCatalogController(port);
      addTearDown(controller.dispose);
      await controller.select(_entry('choisi'));
      controller.edit(name: 'Travail conservé');
      final loading = controller.search('ailleurs');
      port.pages.single.complete(_page('ailleurs'));
      await loading;
      expect(controller.selected?.id, 'choisi');
      expect(controller.draft?.name, 'Travail conservé');
      expect(controller.dirty, isTrue);
    },
  );

  test(
    'save uses the selected revision and keeps edits made while saving',
    () async {
      final port = _Port();
      final controller = WorkingCatalogController(port);
      addTearDown(controller.dispose);
      await controller.select(_entry('arbre'));
      controller.edit(name: 'Nom enregistré', description: 'Description');
      final saving = controller.save();
      controller.edit(name: 'Saisie suivante');
      expect(port.saved?.name, 'Nom enregistré');
      expect(port.saved?.description, 'Description');
      expect(port.expectedRevision, 'revision-1');
      port.saving.complete(
        _detail('arbre', name: 'Nom enregistré', revision: 'revision-2'),
      );
      await Future<void>.delayed(Duration.zero);
      port.pages.single.complete(
        WorkingCatalogPage(revision: 'revision-2', items: const [], total: 0),
      );
      await saving;
      expect(controller.draft?.name, 'Saisie suivante');
      expect(controller.detail?.revision, 'revision-2');
      expect(controller.dirty, isTrue);
    },
  );

  test('saving on page two reloads the first page while retaining its selected detail', () async {
    final port = _Port();
    final controller = WorkingCatalogController(port);
    addTearDown(controller.dispose);
    var loading = controller.search('');
    port.pages[0].complete(
      WorkingCatalogPage(
        revision: 'revision-1',
        items: [_entry('first')],
        total: 3,
        nextCursor: 'page2',
      ),
    );
    await loading;
    loading = controller.loadMore();
    port.pages[1].complete(
      WorkingCatalogPage(
        revision: 'revision-1',
        items: [_entry('second')],
        total: 3,
        nextCursor: 'page3',
      ),
    );
    await loading;
    await controller.select(_entry('second'));
    controller.edit(name: 'Renommé');
    final saving = controller.save();
    port.saving.complete(
      _detail('second', name: 'Renommé', revision: 'revision-2'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(port.pages, hasLength(3));
    port.pages[2].complete(
      WorkingCatalogPage(
        revision: 'revision-2',
        items: [_entry('first')],
        total: 3,
        nextCursor: 'fresh-page2',
      ),
    );
    expect(await saving, isTrue);
    expect(controller.items.single.id, 'first');
    expect(controller.selected?.id, 'second');
    expect(controller.draft?.name, 'Renommé');
    expect(controller.pageNumber, 1);
    expect(controller.hasPreviousPage, isFalse);
    expect(controller.nextCursor, 'fresh-page2');
  });

  test(
    'a rename rechecks the global filter without losing the saved detail',
    () async {
      final port = _Port();
      final controller = WorkingCatalogController(port);
      addTearDown(controller.dispose);
      final loading = controller.search('arbre');
      port.pages[0].complete(_page('arbre'));
      await loading;
      await controller.select(_entry('arbre'));
      controller.edit(name: 'Maison');
      final saving = controller.save();
      port.saving.complete(
        _detail('arbre', name: 'Maison', revision: 'revision-2'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(port.pages, hasLength(2));
      port.pages[1].complete(
        WorkingCatalogPage(revision: 'revision-2', items: const [], total: 0),
      );
      expect(await saving, isTrue);
      expect(controller.query, 'arbre');
      expect(controller.items, isEmpty);
      expect(controller.total, 0);
      expect(controller.detail?.entry.name, 'Maison');
      expect(controller.draft?.name, 'Maison');
      expect(controller.dirty, isFalse);
    },
  );

  test('failed save preserves the draft and an unsaved selection cannot be replaced', () async {
    final port = _Port();
    final controller = WorkingCatalogController(port);
    addTearDown(controller.dispose);
    await controller.select(_entry('arbre'));
    controller.edit(name: 'À conserver');
    await controller.select(_entry('autre'));
    expect(controller.selected?.id, 'arbre');
    final saving = controller.save();
    port.saving.completeError(StateError('révision périmée'));
    expect(await saving, isFalse);
    expect(controller.draft?.name, 'À conserver');
    expect(controller.error, contains('révision périmée'));
  });
}

WorkingCatalogEntry _entry(String id, {String? name}) =>
    WorkingCatalogEntry(id: id, kind: 'element', name: name ?? id);

WorkingCatalogPage _page(String id) =>
    WorkingCatalogPage(revision: 'revision-1', items: [_entry(id)], total: 1);

WorkingCatalogDetail _detail(
  String id, {
  String? name,
  String revision = 'revision-1',
}) => WorkingCatalogDetail(
  entry: _entry(id, name: name),
  revision: revision,
  definitions: const ProjectManifest(
    name: 'Projection',
    maps: [],
    tilesets: [],
  ),
);

class _Port implements WorkingCatalogPort {
  final pages = <Completer<WorkingCatalogPage>>[];
  final saving = Completer<WorkingCatalogDetail>();
  WorkingCatalogDraft? saved;
  String? expectedRevision;

  @override
  Future<WorkingCatalogPage> query({
    required String kind,
    required String text,
    String? cursor,
    String? placementContext,
  }) {
    final pending = Completer<WorkingCatalogPage>();
    pages.add(pending);
    return pending.future;
  }

  @override
  Future<WorkingCatalogDetail> open(WorkingCatalogEntry entry) async =>
      _detail(entry.id);

  @override
  Future<WorkingCatalogDetail> save(
    WorkingCatalogEntry entry,
    WorkingCatalogDraft draft, {
    required String revision,
  }) {
    saved = draft;
    expectedRevision = revision;
    return saving.future;
  }

  @override
  Future<void> close() async {}
  @override
  Future<void> recover(String operationId) async {}
}
