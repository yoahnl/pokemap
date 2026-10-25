import 'package:avelune_studio/features/resources/application/working_catalog_controller.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  for (final target in <bool?>[true, false, null]) {
    test(
      'first save of $target preserves the page without querying again',
      () async {
        final port = _Port(initial: target == null ? false : null);
        final controller = WorkingCatalogController(port);
        addTearDown(controller.dispose);
        await controller.search('', kind: 'character');
        await controller.select(controller.items.single);
        final definitions = controller.detail!.definitions;
        controller.edit(contactShadow: target);
        expect(controller.dirty, isTrue);
        expect(await controller.save(), isTrue);
        expect(port.queries, 1);
        expect(port.opens, 1);
        expect(port.saves, 1);
        expect(controller.items.single.contactShadow, target);
        expect(controller.selected!.contactShadow, target);
        expect(controller.detail!.entry.contactShadow, target);
        expect(controller.revision, 'revision-1');
        expect(identical(controller.detail!.definitions, definitions), isTrue);
        expect(controller.dirty, isFalse);
        expect(controller.saving, isFalse);
      },
    );
  }
  test(
    'paging refreshes explicitly after a shadow save without a stale cursor',
    () async {
      final port = _Port(initial: null, paginated: true);
      final controller = WorkingCatalogController(port);
      addTearDown(controller.dispose);
      await controller.search('', kind: 'character');
      await controller.select(controller.items.single);
      controller.edit(contactShadow: true);
      expect(await controller.save(), isTrue);
      expect(port.queries, 1);
      await controller.loadMore();
      expect(port.queries, 2);
      expect(port.cursors.last, isNull);
      expect(controller.revision, 'revision-2');
      expect(controller.error, contains('actualisée après modification'));
      expect(controller.selected!.contactShadow, isTrue);
    },
  );
}

class _Port implements WorkingCatalogPort {
  _Port({required bool? initial, this.paginated = false})
    : entry = WorkingCatalogEntry(
        id: 'guide',
        kind: 'character',
        name: 'Guide',
        contactShadow: initial,
      );
  WorkingCatalogEntry entry;
  final bool paginated;
  final cursors = <String?>[];
  int queries = 0;
  int opens = 0;
  int saves = 0;
  final definitions = const ProjectManifest(
    name: 'Projet',
    maps: [],
    tilesets: [],
  );

  @override
  Future<WorkingCatalogPage> query({
    required String kind,
    required String text,
    String? cursor,
    String? placementContext,
  }) async {
    queries++;
    cursors.add(cursor);
    return WorkingCatalogPage(
      revision: saves == 0 ? 'revision-1' : 'revision-2',
      items: [entry],
      total: paginated ? 2 : 1,
      nextCursor: paginated ? 'page-2' : null,
    );
  }

  @override
  Future<WorkingCatalogDetail> open(WorkingCatalogEntry entry) async {
    opens++;
    return WorkingCatalogDetail(
      entry: entry,
      revision: 'revision-1',
      definitions: definitions,
    );
  }

  @override
  Future<WorkingCatalogDetail> save(
    WorkingCatalogEntry entry,
    WorkingCatalogDraft draft, {
    required String revision,
  }) async {
    saves++;
    this.entry = WorkingCatalogEntry(
      id: entry.id,
      kind: entry.kind,
      name: entry.name,
      contactShadow: draft.contactShadow,
    );
    return WorkingCatalogDetail(
      entry: this.entry,
      revision: 'revision-2',
      definitions: definitions,
    );
  }

  @override
  Future<void> close() async {}
  @override
  Future<void> recover(String operationId) async {}
}
