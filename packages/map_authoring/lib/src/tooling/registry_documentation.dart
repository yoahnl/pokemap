import '../contracts/action_descriptor.dart';
import '../registry/action_registry.dart';
import '../registry/resource_kind_registry.dart';

/// Deterministic Markdown documentation for the public authoring registry.
abstract final class AuthoringRegistryDocumentation {
  static String render({
    required AuthoringActionRegistry actions,
    required AuthoringResourceKindRegistry resourceKinds,
  }) {
    final buffer = StringBuffer()
      ..writeln('# PokeMap Authoring API registry')
      ..writeln()
      ..writeln(
        '> Generated from canonical registries. No timestamp is included so '
        'equivalent registries produce identical bytes.',
      )
      ..writeln()
      ..writeln('## Resource kinds')
      ..writeln()
      ..writeln('| ID | Version | Name | Summary |')
      ..writeln('|---|---:|---|---|');

    for (final descriptor in resourceKinds.resourceKinds) {
      buffer.writeln(
        '| `${_escape(descriptor.id)}` | ${descriptor.version} | '
        '${_escape(descriptor.displayName)} | ${_escape(descriptor.summary)} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## Actions')
      ..writeln()
      ..writeln(
        '| ID | Version | Risk | Summary | Resources | Permissions | '
        'Guarantees | Input schema | Output schema | Capabilities |',
      )
      ..writeln('|---|---:|---|---|---|---|---|---|---|---|');

    for (final descriptor in actions.actions) {
      buffer.writeln(_actionRow(descriptor));
    }
    return buffer.toString();
  }
}

String _actionRow(AuthoringActionDescriptor descriptor) {
  return '| `${_escape(descriptor.id)}` '
      '| ${descriptor.version} '
      '| `${descriptor.riskLevel.wireName}` '
      '| ${_escape(descriptor.summary)} '
      '| ${_codeList(descriptor.resourceKinds)} '
      '| ${_codeList(
    descriptor.requiredPermissions
        .map((permission) => permission.wireName)
        .toList(),
  )} '
      '| ${_codeList(
    descriptor.guarantees.map((guarantee) => guarantee.wireName).toList(),
  )} '
      '| `${_escape(descriptor.inputSchemaId)}` '
      '| `${_escape(descriptor.outputSchemaId)}` '
      '| ${_codeList(descriptor.capabilityIds)} |';
}

String _codeList(List<String> values) {
  if (values.isEmpty) return '—';
  return values.map((value) => '`${_escape(value)}`').join('<br>');
}

String _escape(String value) {
  return value.replaceAll('|', r'\|').replaceAll('\n', '<br>');
}
