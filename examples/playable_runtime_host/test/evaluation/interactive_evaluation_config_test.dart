import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/interactive/interactive_evaluation_config.dart';

void main() {
  const strongToken = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('release mode always disables the interactive bridge', () {
    final config = InteractiveEvaluationConfig.resolve(
      isReleaseMode: true,
      enabledDefine: true,
      hostDefine: '127.0.0.1',
      portDefine: '54321',
      tokenDefine: strongToken,
      projectDefine: 'selbrume/project.json',
    );

    expect(config.enabled, isFalse);
    expect(config.host, isNull);
    expect(config.port, isNull);
    expect(config.token, isNull);
    expect(config.projectFile, isNull);
  });

  test('disabled debug configuration ignores incomplete bridge defines', () {
    final config = InteractiveEvaluationConfig.resolve(
      isReleaseMode: false,
      enabledDefine: false,
      hostDefine: '',
      portDefine: '',
      tokenDefine: '',
      projectDefine: '',
    );

    expect(config.enabled, isFalse);
  });

  test('debug mode accepts only a complete loopback configuration', () {
    final config = InteractiveEvaluationConfig.resolve(
      isReleaseMode: false,
      enabledDefine: true,
      hostDefine: 'localhost',
      portDefine: '54321',
      tokenDefine: strongToken,
      projectDefine: 'selbrume/project.json',
      playbackRateDefine: '2.0',
    );

    expect(config.enabled, isTrue);
    expect(config.host, 'localhost');
    expect(config.port, 54321);
    expect(config.token, strongToken);
    expect(config.projectFile, 'selbrume/project.json');
    expect(config.playbackRate, 2);
  });

  for (final invalid in <({
    String name,
    String host,
    String port,
    String token,
    String project,
    String playbackRate,
  })>[
    (
      name: 'non-loopback host',
      host: '0.0.0.0',
      port: '54321',
      token: strongToken,
      project: 'selbrume/project.json',
      playbackRate: '1.0',
    ),
    (
      name: 'out-of-range port',
      host: '127.0.0.1',
      port: '65536',
      token: strongToken,
      project: 'selbrume/project.json',
      playbackRate: '1.0',
    ),
    (
      name: 'weak token',
      host: '127.0.0.1',
      port: '54321',
      token: 'short',
      project: 'selbrume/project.json',
      playbackRate: '1.0',
    ),
    (
      name: 'escaping project path',
      host: '127.0.0.1',
      port: '54321',
      token: strongToken,
      project: '../project.json',
      playbackRate: '1.0',
    ),
    (
      name: 'invalid playback rate',
      host: '127.0.0.1',
      port: '54321',
      token: strongToken,
      project: 'selbrume/project.json',
      playbackRate: '0',
    ),
  ]) {
    test('enabled debug configuration rejects ${invalid.name}', () {
      expect(
        () => InteractiveEvaluationConfig.resolve(
          isReleaseMode: false,
          enabledDefine: true,
          hostDefine: invalid.host,
          portDefine: invalid.port,
          tokenDefine: invalid.token,
          projectDefine: invalid.project,
          playbackRateDefine: invalid.playbackRate,
        ),
        throwsA(
          isA<InteractiveEvaluationConfigurationException>(),
        ),
      );
    });
  }
}
