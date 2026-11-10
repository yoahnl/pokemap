import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/coordination/workspace_map_catalog_actions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_catalog_fixture.dart';

void main() {
  late MapCatalogFixture fixture;
  setUp(() async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/t01-map-retirement',
    );
    await parent.create(recursive: true);
    fixture = await MapCatalogFixture.create(parent: parent);
  });
  tearDown(() => fixture.dispose());

  test(
    'resizing uses canonical preparation and integrates new dimensions',
    () async {
      final entry = fixture.controller.project!.maps.first;
      final resizing = WorkspaceMapResize(fixture.controller, entry);
      await resizing.load();
      final width = resizing.source!.size.width + 3;
      final height = resizing.source!.size.height + 2;
      resizing.setWidth('$width');
      resizing.setHeight('$height');
      await resizing.analyze();
      expect(resizing.valid, isTrue);
      expect(await resizing.submit(), isNull);
      expect(resizing.published, isTrue);
      expect(fixture.controller.active!.current.size.width, width);
      expect(fixture.controller.active!.current.size.height, height);
      expect(fixture.catalog.mutations, 1);
    },
  );

  test(
    'dimension edit during analysis discards obsolete preparation',
    () async {
      final entry = fixture.controller.project!.maps.first;
      final resizing = WorkspaceMapResize(fixture.controller, entry);
      await resizing.load();
      final width = resizing.source!.size.width + 3;
      resizing.setWidth('$width');
      fixture.catalog.preparationReady = Completer<void>();
      fixture.catalog.preparationGate = Completer<void>();
      final pending = resizing.analyze();
      await fixture.catalog.preparationReady!.future;
      resizing.setWidth('${width + 1}');
      fixture.catalog.preparationGate!.complete();
      await pending;
      expect(resizing.width, '${width + 1}');
      expect(resizing.preparation, isNull);
      expect(resizing.operation, isNull);
      expect(resizing.valid, isFalse);
      expect(fixture.catalog.mutations, 0);
    },
  );

  test(
    'published resize retains its operation when a caller edits dimensions',
    () async {
      final entry = fixture.controller.project!.maps.first;
      final resizing = WorkspaceMapResize(fixture.controller, entry);
      await resizing.load();
      final width = resizing.source!.size.width + 3;
      resizing.setWidth('$width');
      await resizing.analyze();
      expect(await resizing.submit(), isNull);
      final operation = resizing.operation;
      resizing.setWidth('${width + 1}');
      expect(resizing.width, '$width');
      expect(resizing.operation, same(operation));
      expect(resizing.valid, isTrue);
      expect(fixture.catalog.mutations, 1);
    },
  );
  test(
    'publication in flight preserves the operation for refresh retry',
    () async {
      final entry = fixture.controller.project!.maps.first;
      final resizing = WorkspaceMapResize(fixture.controller, entry);
      await resizing.load();
      final width = resizing.source!.size.width + 3;
      final height = resizing.source!.size.height + 2;
      resizing.setWidth('$width');
      resizing.setHeight('$height');
      await resizing.analyze();
      final operation = resizing.operation;
      fixture.catalog.applicationReady = Completer<void>();
      fixture.catalog.applicationGate = Completer<void>();
      fixture.catalog.failRefresh = true;
      final pending = resizing.submit();
      await fixture.catalog.applicationReady!.future;
    expect(await resizing.submit(), isNotNull);
      resizing.setWidth('${width + 1}');
      resizing.setHeight('${height + 1}');
      fixture.catalog.applicationGate!.complete();
      expect(await pending, contains('enregistrées sur disque'));
      expect(resizing.published, isTrue);
      expect(resizing.width, '$width');
      expect(resizing.height, '$height');
      expect(resizing.operation, same(operation));
      fixture.catalog.failRefresh = false;
      expect(await resizing.submit(), isNull);
      expect(fixture.catalog.mutations, 1);
      expect(fixture.controller.active!.current.size.width, width);
      expect(fixture.controller.active!.current.size.height, height);
    },
  );
}
