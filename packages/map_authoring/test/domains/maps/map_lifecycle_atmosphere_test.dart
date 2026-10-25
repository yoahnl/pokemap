import 'dart:convert';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/map_lifecycle_atmosphere.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'map_catalog_fixture.dart';

void main() {
  test('lifecycle catalog declares both map sidecars', () {
    for (final action in MapLifecycleActions.descriptors
        .where((action) => mapAtmosphereLifecycleActions.contains(action.id))) {
      expect(action.resourceKinds, containsAll(['mapAtmosphere', 'mapEditor']));
      expect(action.extensions['associatedDocuments'],
          ['mapAtmosphere', 'mapEditor']);
    }
  });
  for (final unrelated in [0, 2000]) {
    test(
        'duplicate probes only source and destination beside $unrelated unrelated documents',
        () async {
      final snapshot = catalogSnapshot([catalogMap('source')]);
      final context = AuthoringPlanningContext(
          snapshot: snapshot,
          request: AuthoringRequest(
              requestId: 'duplicate',
              actionId: 'map.duplicate',
              actionVersion: 1,
              workspaceHandle: 'fixture',
              parameters: {'sourceMapId': 'source', 'targetMapId': 'target'},
              expectedRevision: snapshot.revision),
          planId: 'plan_duplicate',
          seed: 1);
      final draft = const MapLifecycleActions().build(context);
      final stored = <String, List<int>>{
        'maps/source.atmosphere.json': utf8.encode(jsonEncode(
            SpatialAtmosphereDocument(
                    mapId: 'source',
                    settings: SpatialAtmosphereSettings(fireflies: true))
                .toJson())),
        'maps/source.editor.json': utf8.encode(jsonEncode(MapEditorDocument(
            mapId: 'source',
            state: MapEditorState(
                lockedElements: {'layer:base'},
                hiddenElements: {'layer:base', 'model:wind'},
                hiddenFamilies: {'effect'})).toJson())),
        for (var i = 0; i < unrelated; i++)
          'maps/unrelated_$i.atmosphere.json':
              utf8.encode('invalid and unrelated'),
        for (var i = 0; i < unrelated; i++)
          'maps/unrelated_$i.editor.json': utf8.encode('invalid and unrelated'),
      };
      final probes = <String>[], reads = <String>[];
      final result = await includeMapLifecycleAtmosphere(context, draft,
          readResource: (path) async {
        reads.add(path);
        return stored[path];
      }, probeResource: (path) async {
        probes.add(path);
        final bytes = stored[path];
        return bytes == null
            ? const ProjectResourceProbe.missing()
            : ProjectResourceProbe.exists(ProjectResourceIdentity(
                scope: 'fixture',
                relativePath: path,
                byteLength: bytes.length,
                modifiedAtMicros: 0));
      });
      expect(probes, [
        'maps/source.atmosphere.json',
        'maps/target.atmosphere.json',
        'maps/source.editor.json',
        'maps/target.editor.json'
      ]);
      expect(reads, ['maps/source.atmosphere.json', 'maps/source.editor.json']);
      expect(
          result.changeSet.changes
              .where((change) => change.resource.kind == 'mapAtmosphere'),
          hasLength(1));
      expect(
          result.changeSet.changes
              .where((change) => change.resource.kind == 'mapEditor'),
          hasLength(1));
      final editor = result.changeSet.changes
          .singleWhere((change) => change.resource.kind == 'mapEditor');
      final copied = MapEditorDocument.fromJson(
          jsonDecode(utf8.decode(editor.afterBytes!)) as Map<String, dynamic>);
      expect(copied.mapId, 'target');
      expect(copied.state.isHidden('layer', 'base'), isTrue);
      expect(copied.state.isHidden('model', 'wind'), isTrue);
      expect(copied.state.isHidden('effect', 'fireflies'), isTrue);
      expect(
          result.changeSet.diff.entries.expand((entry) =>
              (entry.extensions[mapAtmosphereGuardsKey] as List?) ?? []),
          hasLength(1));
    });
  }
  test('duplicate atmosphere keys are refused before lifecycle changes',
      () async {
    final snapshot = catalogSnapshot([catalogMap('source')]);
    final context = AuthoringPlanningContext(
        snapshot: snapshot,
        request: AuthoringRequest(
            requestId: 'duplicate',
            actionId: 'map.duplicate',
            actionVersion: 1,
            workspaceHandle: 'fixture',
            parameters: {'sourceMapId': 'source', 'targetMapId': 'target'},
            expectedRevision: snapshot.revision),
        planId: 'plan_duplicate',
        seed: 1);
    final bytes = utf8.encode(
        '{"schemaVersion":1,"mapId":"source","settings":{"fireflies":false,"fireflies":true}}');
    await expectLater(
        includeMapLifecycleAtmosphere(
            context, const MapLifecycleActions().build(context),
            readResource: (_) async => bytes,
            probeResource: (path) async => ProjectResourceProbe.exists(
                ProjectResourceIdentity(
                    scope: 'fixture',
                    relativePath: path,
                    byteLength: bytes.length,
                    modifiedAtMicros: 0))),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'map.atmosphere_invalid')));
  });

  test('an ordinary map property save performs no atmosphere reads or probes',
      () async {
    final snapshot = catalogSnapshot([catalogMap('source')]);
    final context = AuthoringPlanningContext(
        snapshot: snapshot,
        request: AuthoringRequest(
            requestId: 'save',
            actionId: 'map.save',
            actionVersion: 1,
            workspaceHandle: 'fixture',
            parameters: {
              'map': catalogMap('source').copyWith(name: 'Saved').toJson()
            },
            expectedRevision: snapshot.revision),
        planId: 'plan_save',
        seed: 1);
    final draft = const MapLifecycleActions().build(context);
    final result = await includeMapLifecycleAtmosphere(context, draft,
        readResource: (_) async => throw StateError('Unrelated read'),
        probeResource: (_) async => throw StateError('Unrelated probe'));
    expect(result, same(draft));
  });
}
