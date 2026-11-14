import 'dart:convert';

enum StudioMcpState { starting, ready, failed, stopping, stopped }

class StudioMcpConnection {
  const StudioMcpConnection(this.url, this._token, this.protocolVersions);
  final Uri url;
  final String _token;
  final List<String> protocolVersions;

  String get clientConfiguration => const JsonEncoder.withIndent('  ').convert({
    'mcpServers': {
      'avelune-studio': {
        'type': 'http',
        'url': url.toString(),
        'headers': {'Authorization': 'Bearer $_token'},
      },
    },
  });
}

class StudioMcpResource {
  const StudioMcpResource({required this.kind, required this.id});
  final String kind;
  final String id;
}

class StudioMcpMutation {
  const StudioMcpMutation({
    required this.projectRoot,
    required this.resources,
    required this.revision,
    this.operationId,
  });
  final String projectRoot;
  final List<StudioMcpResource> resources;
  final String revision;
  final String? operationId;
}
