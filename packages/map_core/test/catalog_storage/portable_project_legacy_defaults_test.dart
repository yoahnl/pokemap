import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectManifest _project({bool enabled = false}) => ProjectManifest(
  name: 'Protected project',
  maps: const [],
  tilesets: const [],
  settings: ProjectSettings(actorContactShadowsByDefault: enabled),
  cinematics: [
    CinematicAsset(
      id: 'intro',
      title: 'Intro',
      timeline: CinematicTimeline(),
      allowMobileActorCrossing: enabled,
    ),
  ],
);

PortableCatalogPublicationBuild _base({bool enabled = false}) =>
    PortableCatalogPublication.encodeProject(_project(enabled: enabled));

({Map<String, Object?> descriptor, CatalogStorageBuild storage}) _rewrite(
  PortableCatalogPublicationBuild built,
  CatalogDefinitionUnit Function(CatalogDefinitionUnit) change,
) {
  final received = PortableCatalogPublication.readSync(
    built.descriptor,
    readObject: (r) => built.storage.objects[r.sha256]!,
  );
  final storage = CatalogStorageBuilder().build(received.units.map(change));
  return (
    descriptor: {...built.descriptor, 'root': storage.root.toJson()},
    storage: storage,
  );
}

CatalogDefinitionUnit _change(
  CatalogDefinitionUnit unit,
  void Function(Map<String, dynamic>) edit, {
  bool forgeReference = false,
}) {
  final payload = jsonDecode(jsonEncode(unit.payload)) as Map<String, dynamic>;
  edit(payload);
  return CatalogDefinitionUnit(
    key: unit.key,
    payload: payload,
    references: forgeReference
        ? [
            CatalogDefinitionKey(
              CatalogDefinitionKind.catalogMetadata,
              'publication-shell',
            ),
          ]
        : unit.references,
  );
}

void main() {
  for (final fields in [
    ['settings'],
    ['cinematics'],
    ['settings', 'cinematics'],
  ]) {
    test('protected catalogue accepts omitted false defaults in $fields', () {
      final built = _rewrite(
        _base(),
        (unit) => _change(unit, (payload) {
          final value = payload['value'] as Map;
          if (fields.contains('settings') && payload['section'] == r'$shell') {
            (value['settings'] as Map).remove('actorContactShadowsByDefault');
          }
          if (fields.contains('cinematics') && value['field'] == 'cinematics') {
            (value['definition'] as Map).remove('allowMobileActorCrossing');
          }
        }),
      );
      final project = PortableCatalogPublication.decodeProjectSync(
        built.descriptor,
        readObject: (r) => built.storage.objects[r.sha256]!,
      );
      expect(project.toJson(), _project().toJson());
    });
  }
  for (final enabled in [false, true]) {
    test(
      'explicit $enabled defaults survive without changing their catalogue',
      () {
        final built = _base(enabled: enabled);
        final project = PortableCatalogPublication.decodeProjectSync(
          built.descriptor,
          readObject: (r) => built.storage.objects[r.sha256]!,
        );
        expect(project.settings.actorContactShadowsByDefault, enabled);
        expect(project.cinematics.single.allowMobileActorCrossing, enabled);
        expect(
          PortableCatalogPublication.encodeProject(project).storage.root,
          built.storage.root,
        );
      },
    );
  }
  for (final field in ['unknownFutureDefault', 'allowMobileActorCrossing']) {
    test('unknown or malformed cinematic payload $field is still rejected', () {
      final built = _rewrite(
        _base(),
        (unit) => _change(unit, (payload) {
          final value = payload['value'] as Map;
          if (value['field'] == 'cinematics') {
            final definition = value['definition'] as Map;
            definition.remove('allowMobileActorCrossing');
            definition[field] = field == 'allowMobileActorCrossing'
                ? null
                : false;
          }
        }),
      );
      expect(
        () => PortableCatalogPublication.decodeProjectSync(
          built.descriptor,
          readObject: (r) => built.storage.objects[r.sha256]!,
        ),
        throwsFormatException,
      );
    });
  }
  test('unknown settings and forged typed references remain rejected', () {
    for (final forge in [false, true]) {
      final built = _rewrite(_base(), (unit) {
        if (forge && (unit.payload['value'] as Map)['field'] == 'cinematics') {
          return _change(unit, (payload) {
            ((payload['value'] as Map)['definition'] as Map).remove(
              'allowMobileActorCrossing',
            );
          }, forgeReference: true);
        }
        return _change(unit, (payload) {
          if (!forge && payload['section'] == r'$shell') {
            final settings = (payload['value'] as Map)['settings'] as Map;
            settings.remove('actorContactShadowsByDefault');
            settings['unknownFutureDefault'] = false;
          }
        });
      });
      expect(
        () => PortableCatalogPublication.decodeProjectSync(
          built.descriptor,
          readObject: (r) => built.storage.objects[r.sha256]!,
        ),
        throwsFormatException,
      );
    }
  });
}
