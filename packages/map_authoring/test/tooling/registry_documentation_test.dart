import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringRegistryDocumentation', () {
    test('renders deterministic documentation for equivalent registries', () {
      final first = AuthoringActionRegistry([
        _action('map.update'),
        _action('map.create'),
      ]);
      final second = AuthoringActionRegistry([
        _action('map.create'),
        _action('map.update'),
      ]);
      final resourceKinds = AuthoringResourceKindRegistry.canonicalMinimal();

      final firstDocument = AuthoringRegistryDocumentation.render(
        actions: first,
        resourceKinds: resourceKinds,
      );
      final secondDocument = AuthoringRegistryDocumentation.render(
        actions: second,
        resourceKinds: resourceKinds,
      );

      expect(secondDocument, firstDocument);
      expect(firstDocument, startsWith('# PokeMap Authoring API registry\n'));
      expect(firstDocument, contains('## Resource kinds'));
      expect(firstDocument, contains('## Actions'));
      expect(firstDocument, contains('`map.create`'));
      expect(firstDocument, contains('`project.read`'));
      expect(firstDocument, isNot(contains('Generated at')));
    });

    test('escapes Markdown table separators in human-readable text', () {
      final action = AuthoringActionDescriptor(
        id: 'map.inspect',
        version: 1,
        summary: 'Inspect summary | detail',
        inputSchemaId: 'schema.map.inspect.input',
        outputSchemaId: 'schema.map.inspect.output',
        riskLevel: AuthoringRiskLevel.readOnly,
        resourceKinds: const ['map'],
        requiredPermissions: const [AuthoringPermission.projectRead],
      );

      final document = AuthoringRegistryDocumentation.render(
        actions: AuthoringActionRegistry([action]),
        resourceKinds: AuthoringResourceKindRegistry.canonicalMinimal(),
      );

      expect(document, contains(r'Inspect summary \| detail'));
    });
  });
}

AuthoringActionDescriptor _action(String id) {
  return AuthoringActionDescriptor(
    id: id,
    version: 1,
    summary: 'Action $id',
    inputSchemaId: 'schema.$id.input',
    outputSchemaId: 'schema.$id.output',
    riskLevel: AuthoringRiskLevel.readOnly,
    resourceKinds: const ['map'],
    capabilityIds: const ['map.lifecycle'],
    requiredPermissions: const [AuthoringPermission.projectRead],
    guarantees: const [AuthoringGuarantee.dryRun],
  );
}
