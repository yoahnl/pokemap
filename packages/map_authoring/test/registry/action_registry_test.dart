import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringActionRegistry', () {
    test('sorts actions independently of registration order', () {
      final first = AuthoringActionRegistry([
        _action('map.update'),
        _action('map.create'),
      ]);
      final second = AuthoringActionRegistry([
        _action('map.create'),
        _action('map.update'),
      ]);

      expect(
        first.actions.map((action) => action.id),
        ['map.create', 'map.update'],
      );
      expect(first.toJson(), second.toJson());
    });

    test('looks up known actions and distinguishes unknown actions', () {
      final registry = AuthoringActionRegistry([_action('map.create')]);

      expect(registry.find('map.create')?.id, 'map.create');
      expect(registry.find('map.unknown'), isNull);
      expect(
        () => registry.require('map.unknown'),
        throwsA(isA<UnknownAuthoringActionException>()),
      );
    });

    test('rejects a duplicate action id and version', () {
      expect(
        () => AuthoringActionRegistry([
          _action('map.create'),
          _action('map.create'),
        ]),
        throwsA(isA<DuplicateAuthoringActionException>()),
      );
    });

    test('rejects incompatible versions for the same action id', () {
      expect(
        () => AuthoringActionRegistry([
          _action('map.create', version: 1),
          _action('map.create', version: 2),
        ]),
        throwsA(
          isA<IncompatibleAuthoringActionVersionException>().having(
            (error) => error.versions,
            'versions',
            [1, 2],
          ),
        ),
      );
    });

    test('round-trips deterministically through JSON', () {
      final registry = AuthoringActionRegistry([
        _action('map.update'),
        _action('map.create'),
      ]);
      final encoded =
          jsonDecode(jsonEncode(registry.toJson())) as Map<String, dynamic>;

      expect(
        AuthoringActionRegistry.fromJson(encoded).toJson(),
        registry.toJson(),
      );
    });
  });

  group('AuthoringResourceKindRegistry', () {
    test('provides the canonical minimal resource kinds', () {
      final registry = AuthoringResourceKindRegistry.canonicalMinimal();

      expect(
        registry.resourceKinds.map((descriptor) => descriptor.id),
        [
          'asset',
          'assetBlob',
          'assetCatalog',
          'battleProgression',
          'campaignContent',
          'cinematic',
          'dialogue',
          'dialogueSource',
          'elementCategory',
          'eventV2',
          'fact',
          'layer',
          'map',
          'pokemonDocument',
          'project',
          'region',
          'sandboxPlayerState',
          'scenario',
          'scene',
          'script',
          'storyline',
          'tilesetFolder',
          'worldRule',
        ],
      );
      expect(registry.require('map').displayName, 'Map');
      expect(registry.find('unknown'), isNull);
    });

    test('rejects duplicate and incompatible kind versions', () {
      expect(
        () => AuthoringResourceKindRegistry([
          _kind('map'),
          _kind('map'),
        ]),
        throwsA(isA<DuplicateAuthoringResourceKindException>()),
      );
      expect(
        () => AuthoringResourceKindRegistry([
          _kind('map', version: 1),
          _kind('map', version: 2),
        ]),
        throwsA(isA<IncompatibleAuthoringResourceKindVersionException>()),
      );
    });

    test('round-trips deterministically through JSON', () {
      final registry = AuthoringResourceKindRegistry([
        _kind('region'),
        _kind('map'),
      ]);
      final encoded =
          jsonDecode(jsonEncode(registry.toJson())) as Map<String, dynamic>;

      expect(
        AuthoringResourceKindRegistry.fromJson(encoded).toJson(),
        registry.toJson(),
      );
    });
  });
}

AuthoringActionDescriptor _action(String id, {int version = 1}) {
  return AuthoringActionDescriptor(
    id: id,
    version: version,
    summary: 'Action $id',
    inputSchemaId: 'schema.$id.input',
    outputSchemaId: 'schema.$id.output',
    riskLevel: AuthoringRiskLevel.readOnly,
    resourceKinds: const ['map'],
    requiredPermissions: const [AuthoringPermission.projectRead],
  );
}

AuthoringResourceKindDescriptor _kind(String id, {int version = 1}) {
  return AuthoringResourceKindDescriptor(
    id: id,
    version: version,
    displayName: id[0].toUpperCase() + id.substring(1),
    summary: '$id resource',
  );
}
