part of 'studio_mcp_service.dart';

extension _StudioMcpEvents on StudioMcpService {
  void _handleEvent(Map<String, Object?> event, int generation) {
    if (_disposed || generation != _generation) return;
    if (event['type'] == 'failed') {
      final code = event['code'];
      _failReadiness(
        code is String &&
                RegExp(r'^[a-zA-Z][a-zA-Z0-9_.-]{0,96}$').hasMatch(code)
            ? code
            : 'companion.initialization_failed',
      );
      return;
    }
    if (event['type'] == 'ready') {
      try {
        if (_connection != null || event['controlVersion'] != 1) {
          throw const FormatException();
        }
        final url = Uri.parse(event['url'] as String);
        final token = event['token'] as String;
        final protocols = (event['protocolVersions'] as List).cast<String>();
        if (url.scheme != 'http' ||
            !['127.0.0.1', '::1', '[::1]'].contains(url.host) ||
            !url.hasPort ||
            url.port == 0 ||
            url.userInfo.isNotEmpty ||
            url.hasQuery ||
            url.hasFragment ||
            token.isEmpty ||
            protocols.isEmpty) {
          throw const FormatException();
        }
        _connection = StudioMcpConnection(
          url,
          token,
          List.unmodifiable(protocols),
        );
        if (!_ready!.isCompleted) _ready!.complete();
      } on Object {
        _failReadiness();
      }
    } else if (event['type'] == 'response') {
      final pending = _requests.remove(event['id']);
      if (pending == null || pending.isCompleted) return;
      if (event['ok'] == true) {
        pending.complete();
      } else {
        final code = event['code'];
        if (code is String &&
            RegExp(r'^(control\.[a-z_]+|permission\.transfer_failed_[1-5])$')
                .hasMatch(code)) {
          _diagnosticCode = code;
        }
        pending.completeError(StateError('companion.command_failed'));
      }
    } else if (event['type'] == 'mutation' &&
        _state == StudioMcpState.ready &&
        _authorizedRoot != null &&
        event['projectRoot'] == _desiredRoot &&
        event['projectRoot'] == _authorizedRoot) {
      try {
        final resources = (event['resources'] as List)
            .map((resource) {
              final value = resource as Map;
              return StudioMcpResource(
                kind: value['kind'] as String,
                id: value['id'] as String,
              );
            })
            .toList(growable: false);
        _mutations.add(
          StudioMcpMutation(
            projectRoot: _authorizedRoot!,
            resources: resources,
            revision: event['revision'] as String,
            operationId: event['operationId'] as String?,
          ),
        );
      } on Object {
        _error = 'Une modification externe ne peut pas être synchronisée.';
        _publish();
      }
    }
  }
}
