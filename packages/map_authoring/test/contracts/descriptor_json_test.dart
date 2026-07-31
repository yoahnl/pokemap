import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringResourceRef', () {
    test('round-trips a typed resource reference', () {
      final reference = AuthoringResourceRef(
        kind: 'map',
        id: 'bourg-palette',
        revision: 'rev-42',
        extensions: const {
          'vendorHint': {
            'labels': ['outdoor', 'starter'],
          },
        },
      );

      expect(
        AuthoringResourceRef.fromJson(_jsonRoundTrip(reference.toJson()))
            .toJson(),
        reference.toJson(),
      );
      expect(reference.toJson()['kind'], 'map');
    });

    test('rejects malformed identifiers and unknown top-level fields', () {
      expect(
        () => AuthoringResourceRef(kind: '', id: 'map-1'),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResourceRef(kind: 'map', id: ' '),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResourceRef.fromJson({
          'kind': 'map',
          'id': 'map-1',
          'futureField': true,
        }),
        throwsFormatException,
      );
    });
  });

  group('authoring descriptors', () {
    test('round-trips schema and capability descriptors', () {
      final schema = AuthoringSchemaDescriptor(
        id: 'schema.map.create.input',
        version: 1,
        uri: 'pokemap-schema://map/create/input/v1',
        sha256: 'sha256:fixture',
        description: 'Create-map input',
        extensions: const {'vendorRevision': 2},
      );
      final capability = AuthoringCapabilityDescriptor(
        id: 'map.lifecycle',
        version: 1,
        summary: 'Create and manage maps',
        resourceKinds: const ['map', 'project'],
        actionIds: const ['map.inspect', 'map.create'],
        extensions: const {'stability': 'experimental'},
      );

      expect(
        AuthoringSchemaDescriptor.fromJson(
          _jsonRoundTrip(schema.toJson()),
        ).toJson(),
        schema.toJson(),
      );
      expect(
        AuthoringCapabilityDescriptor.fromJson(
          _jsonRoundTrip(capability.toJson()),
        ).toJson(),
        capability.toJson(),
      );
      expect(
        capability.toJson()['resourceKinds'],
        ['map', 'project'],
      );
      expect(
        capability.toJson()['actionIds'],
        ['map.create', 'map.inspect'],
      );
    });

    test('round-trips action risk, permissions, and guarantees', () {
      final descriptor = _actionDescriptor();
      final decoded = AuthoringActionDescriptor.fromJson(
        _jsonRoundTrip(descriptor.toJson()),
      );

      expect(decoded.toJson(), descriptor.toJson());
      expect(decoded.riskLevel, AuthoringRiskLevel.high);
      expect(
        decoded.requiredPermissions,
        [
          AuthoringPermission.projectRead,
          AuthoringPermission.projectWrite,
        ],
      );
      expect(
        decoded.guarantees,
        [
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.revisionChecked,
        ],
      );
    });

    test('preserves safe extension data through JSON', () {
      final descriptor = _actionDescriptor(
        extensions: const {
          'vendor': {
            'priority': 3,
            'flags': [true, false],
          },
        },
      );

      final decoded = AuthoringActionDescriptor.fromJson(
        _jsonRoundTrip(descriptor.toJson()),
      );

      expect(decoded.extensions, descriptor.extensions);
      expect(
        decoded.toJson()['extensions'],
        descriptor.toJson()['extensions'],
      );
    });

    test('rejects reserved extension collisions for every descriptor', () {
      expect(
        () => AuthoringResourceRef(
          kind: 'map',
          id: 'map-1',
          extensions: const {'id': 'override'},
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringSchemaDescriptor(
          id: 'schema.map',
          version: 1,
          uri: 'pokemap-schema://map/v1',
          sha256: 'sha256:fixture',
          extensions: const {'version': 9},
        ),
        throwsArgumentError,
      );
      expect(
        () => _actionDescriptor(
          extensions: const {'riskLevel': 'read_only'},
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid versions, enums, and unknown fields', () {
      expect(
        () => AuthoringSchemaDescriptor(
          id: 'schema.map',
          version: 0,
          uri: 'pokemap-schema://map/v1',
          sha256: 'sha256:fixture',
        ),
        throwsArgumentError,
      );
      final invalidEnum = _actionDescriptor().toJson()
        ..['riskLevel'] = 'impossibly_safe';
      expect(
        () => AuthoringActionDescriptor.fromJson(invalidEnum),
        throwsFormatException,
      );
      final unknownField = _actionDescriptor().toJson()..['surprise'] = true;
      expect(
        () => AuthoringActionDescriptor.fromJson(unknownField),
        throwsFormatException,
      );
      expect(
        () => AuthoringActionDescriptor(
          id: 'map create',
          version: 1,
          summary: 'Invalid action id',
          inputSchemaId: 'schema.map.create.input',
          outputSchemaId: 'schema.map.create.output',
          riskLevel: AuthoringRiskLevel.low,
        ),
        throwsArgumentError,
      );
    });

    test('exposes immutable and deterministically ordered collections', () {
      final descriptor = _actionDescriptor();

      expect(
        () => descriptor.resourceKinds.add('region'),
        throwsUnsupportedError,
      );
      expect(
        () => descriptor.extensions['new'] = true,
        throwsUnsupportedError,
      );
      expect(
        AuthoringActionDescriptor(
          id: descriptor.id,
          version: descriptor.version,
          summary: descriptor.summary,
          inputSchemaId: descriptor.inputSchemaId,
          outputSchemaId: descriptor.outputSchemaId,
          riskLevel: descriptor.riskLevel,
          resourceKinds: descriptor.resourceKinds.reversed,
          capabilityIds: descriptor.capabilityIds.reversed,
          requiredPermissions: descriptor.requiredPermissions.reversed,
          guarantees: descriptor.guarantees.reversed,
        ).toJson(),
        descriptor.toJson()..remove('extensions'),
      );
    });
  });
}

AuthoringActionDescriptor _actionDescriptor({
  Map<String, Object?> extensions = const {},
}) {
  return AuthoringActionDescriptor(
    id: 'map.create',
    version: 1,
    summary: 'Create a map',
    inputSchemaId: 'schema.map.create.input',
    outputSchemaId: 'schema.map.create.output',
    riskLevel: AuthoringRiskLevel.high,
    resourceKinds: const ['project', 'map'],
    capabilityIds: const ['map.lifecycle'],
    requiredPermissions: const [
      AuthoringPermission.projectWrite,
      AuthoringPermission.projectRead,
    ],
    guarantees: const [
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.dryRun,
    ],
    extensions: extensions,
  );
}

Map<String, dynamic> _jsonRoundTrip(Map<String, Object?> value) {
  return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
