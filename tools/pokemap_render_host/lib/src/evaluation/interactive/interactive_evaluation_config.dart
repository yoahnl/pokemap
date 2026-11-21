import 'package:flutter/foundation.dart';

/// Fail-closed configuration for the development-only visible evaluator.
///
/// This contract deliberately exposes no collision-visualization switch. The
/// interactive target drives the production game surface and must not enable
/// expensive debug overlays as a side effect of evaluation.
final class InteractiveEvaluationConfig {
  const InteractiveEvaluationConfig._disabled()
      : enabled = false,
        host = null,
        port = null,
        token = null,
        projectFile = null,
        playbackRate = 1;

  const InteractiveEvaluationConfig._enabled({
    required this.host,
    required this.port,
    required this.token,
    required this.projectFile,
    required this.playbackRate,
  }) : enabled = true;

  final bool enabled;
  final String? host;
  final int? port;
  final String? token;
  final String? projectFile;
  final double playbackRate;

  static InteractiveEvaluationConfig resolve({
    required bool isReleaseMode,
    required bool enabledDefine,
    required String hostDefine,
    required String portDefine,
    required String tokenDefine,
    required String projectDefine,
    String playbackRateDefine = '1.0',
  }) {
    // Release builds ignore every evaluation define, even malformed ones.
    // This prevents a build invocation from accidentally shipping the bridge.
    if (isReleaseMode || !enabledDefine) {
      return const InteractiveEvaluationConfig._disabled();
    }

    final host = hostDefine.trim();
    if (!_loopbackHosts.contains(host)) {
      throw const InteractiveEvaluationConfigurationException(
        'POKEMAP_EVAL_HOST must be a loopback host.',
      );
    }

    final port = int.tryParse(portDefine.trim());
    if (port == null || port < 1 || port > 65535) {
      throw const InteractiveEvaluationConfigurationException(
        'POKEMAP_EVAL_PORT must be between 1 and 65535.',
      );
    }

    final token = tokenDefine.trim();
    if (token.length < 32 ||
        token.length > 512 ||
        token.codeUnits.any(_isWhitespace)) {
      throw const InteractiveEvaluationConfigurationException(
        'POKEMAP_EVAL_TOKEN must be a strong token without whitespace.',
      );
    }

    final projectFile = projectDefine.trim();
    final projectSegments = projectFile.split('/');
    if (projectFile.isEmpty ||
        projectFile.startsWith('/') ||
        projectFile.contains(r'\') ||
        projectSegments.any((segment) => segment.isEmpty || segment == '..')) {
      throw const InteractiveEvaluationConfigurationException(
        'POKEMAP_EVAL_PROJECT must be a repository-relative file.',
      );
    }

    final playbackRate = double.tryParse(playbackRateDefine.trim());
    if (playbackRate == null ||
        !playbackRate.isFinite ||
        playbackRate <= 0 ||
        playbackRate > 4) {
      throw const InteractiveEvaluationConfigurationException(
        'POKEMAP_EVAL_PLAYBACK_RATE must be greater than 0 and at most 4.',
      );
    }

    return InteractiveEvaluationConfig._enabled(
      host: host,
      port: port,
      token: token,
      projectFile: projectFile,
      playbackRate: playbackRate,
    );
  }
}

const _loopbackHosts = <String>{'127.0.0.1', '::1', 'localhost'};

bool _isWhitespace(int codeUnit) =>
    codeUnit == 0x20 ||
    codeUnit == 0x09 ||
    codeUnit == 0x0a ||
    codeUnit == 0x0d;

final class InteractiveEvaluationConfigurationException implements Exception {
  const InteractiveEvaluationConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'InteractiveEvaluationConfigurationException: $message';
}

final interactiveEvaluationConfig = InteractiveEvaluationConfig.resolve(
  isReleaseMode: kReleaseMode,
  enabledDefine: const bool.fromEnvironment(
    'POKEMAP_EVAL_INTERACTIVE',
    defaultValue: false,
  ),
  hostDefine: const String.fromEnvironment('POKEMAP_EVAL_HOST'),
  portDefine: const String.fromEnvironment('POKEMAP_EVAL_PORT'),
  tokenDefine: const String.fromEnvironment('POKEMAP_EVAL_TOKEN'),
  projectDefine: const String.fromEnvironment('POKEMAP_EVAL_PROJECT'),
  playbackRateDefine: const String.fromEnvironment(
    'POKEMAP_EVAL_PLAYBACK_RATE',
    defaultValue: '1.0',
  ),
);
