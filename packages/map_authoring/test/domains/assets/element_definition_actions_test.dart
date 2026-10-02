import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../maps/map_catalog_fixture.dart';
import 'element_definition_fixture.dart';

void main() {
  for (final animated in [false, true]) {
    test(
        'duplicate preserves complete ${animated ? 'animated' : 'static'} definition',
        () {
      final original = elementDefinitionFixture(animated: animated);
      final snapshot = elementSnapshot(original);
      final draft = const ElementActions().build(
          catalogContext(snapshot, 'element.duplicate', duplicateParameters()));
      final after = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
      final copy = after.elements.singleWhere((entry) => entry.id == 'copy');
      expect(
          copy,
          original.elements.single.copyWith(
              id: 'copy', name: 'Décor — copie', categoryId: 'shared'));
      expect(after.elements.singleWhere((entry) => entry.id == 'decor'),
          original.elements.single);
      expect(after.tilesets, original.tilesets);
      expect(draft.changeSet.changes.map((change) => change.storageKey),
          ['project.json']);
      final edited = copy.copyWith(
          frames: [copy.frames.first.copyWith(durationMs: 90)],
          collisionProfile: copy.collisionProfile!.copyWith(cells: []));
      expect(edited.frames, isNot(original.elements.single.frames));
      expect(original.elements.single.collisionProfile!.cells,
          [const GridPos(x: 0, y: 0)]);
    });
  }

  test('duplicate preserves extension fields on source and independent copy',
      () {
    final original = elementDefinitionFixture();
    final raw = original.toJson();
    (raw['elements'] as List).single['extensionData'] = {'author': 'retained'};
    final draft = const ElementActions().build(catalogContext(
        elementSnapshot(original, originalProject: raw),
        'element.duplicate',
        duplicateParameters()));
    final after =
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!));
    for (final element in after['elements'] as List) {
      expect(element['extensionData'], {'author': 'retained'});
    }
  });

  test('duplicate refuses collision absent category source and unknown input',
      () {
    final snapshot = elementSnapshot(elementDefinitionFixture());
    for (final values in [
      duplicateParameters(newId: 'decor'),
      {...duplicateParameters(), 'categoryId': 'absent'},
      {...duplicateParameters(), 'sourceElementId': 'absent'},
      {...duplicateParameters(), 'name': ' '},
      {...duplicateParameters(), 'force': true},
    ]) {
      expect(
          () => const ElementActions()
              .build(catalogContext(snapshot, 'element.duplicate', values)),
          throwsA(
              anyOf(isA<VisualLibraryException>(), isA<FormatException>())));
    }
  });

  test('duplicate refuses uncertified and unsupported source', () {
    final original = elementDefinitionFixture();
    final uncertified = catalogSnapshot([], project: original);
    expect(
        () => const ElementActions().build(catalogContext(
            uncertified, 'element.duplicate', duplicateParameters())),
        throwsA(isA<VisualLibraryException>()));
    final unsupported = original.copyWith(tilesets: [
      original.tilesets.single.copyWith(source: null),
    ]);
    expect(
        () => const ElementActions().build(catalogContext(
            elementSnapshot(unsupported),
            'element.duplicate',
            duplicateParameters())),
        throwsA(isA<VisualLibraryException>()));
  });

  test(
      'duplicate resolves source by logical identity rather than shared digest',
      () {
    final original = elementDefinitionFixture();
    final source =
        original.tilesets.single.source as ProjectRegularAtlasTilesetSource;
    final project = original.copyWith(tilesets: [
      original.tilesets.single.copyWith(
          source: ProjectRegularAtlasTilesetSource(
              assetId: 'other-identity',
              pixelWidth: source.pixelWidth,
              pixelHeight: source.pixelHeight,
              tileWidth: source.tileWidth,
              tileHeight: source.tileHeight))
    ]);
    expect(
        () => const ElementActions().build(catalogContext(
            elementSnapshot(project),
            'element.duplicate',
            duplicateParameters())),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'element.source_unavailable')));
  });

  test('deletion refuses incomplete Pokemon inventory instead of zero uses',
      () {
    final original = elementDefinitionFixture();
    final base = elementSnapshot(original);
    final snapshot = ProjectSnapshot(
        projectHandle: base.projectHandle,
        revision: base.revision,
        manifest: original.copyWith(
            pokemon: original.pokemon.copyWith(enabled: true)),
        maps: base.maps,
        resourceFingerprints: base.resourceFingerprints,
        resourceBytes: {
          for (final key in base.resourceFingerprints.keys)
            key: base.resourceBytes(key)
        });
    expect(
        () => const ElementActions().build(
            catalogContext(snapshot, 'element.delete', {'elementId': 'decor'})),
        throwsA(isA<VisualLibraryException>().having((error) => error.code,
            'code', 'element.usage_inventory_incomplete')));
  });

  test('deletion refuses declared closed map absent from snapshot', () {
    final original = elementDefinitionFixture().copyWith(maps: const [
      ProjectMapEntry(
          id: 'closed', name: 'Fermée', relativePath: 'maps/closed.json'),
    ]);
    expect(
        () => const ElementActions().build(catalogContext(
            elementSnapshot(original),
            'element.delete',
            {'elementId': 'decor'})),
        throwsA(isA<VisualLibraryException>().having((error) => error.code,
            'code', 'element.usage_inventory_incomplete')));
  });

  test('deletion refuses retained source from unplaced border preparation', () {
    final manifest = elementDefinitionFixture()
        .copyWith(borderCatalog: retainedElementBorder());
    expect(
        () => const ElementActions().build(catalogContext(
            elementSnapshot(manifest),
            'element.delete',
            {'elementId': 'decor'})),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'element.references_blocking')));
  });

  test('delete free definition keeps images category and unrelated elements',
      () {
    final original = elementDefinitionFixture();
    final draft = const ElementActions().build(catalogContext(
        elementSnapshot(original), 'element.delete', {'elementId': 'decor'}));
    final after = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
    expect(after, original.copyWith(elements: []));
    expect(draft.changeSet.changes.map((change) => change.storageKey),
        ['project.json']);
  });
}
