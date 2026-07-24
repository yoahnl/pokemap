import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/interactive/interactive_evaluation_config.dart';

void main() {
  const strongToken = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('release configuration cannot enable interactive evaluation', () {
    final config = InteractiveEvaluationConfig.resolve(
      isReleaseMode: true,
      enabledDefine: true,
      hostDefine: '127.0.0.1',
      portDefine: '54321',
      tokenDefine: strongToken,
      projectDefine: 'selbrume/project.json',
      playbackRateDefine: '2.0',
    );

    expect(config.enabled, isFalse);
    expect(config.host, isNull);
    expect(config.port, isNull);
    expect(config.token, isNull);
    expect(config.projectFile, isNull);
    expect(config.playbackRate, 1);
  });

  test('host constructs the bridge only behind the resolved dev gate', () {
    final source = File(
      p.join(Directory.current.path, 'lib', 'main.dart'),
    ).readAsStringSync();

    expect(
      source,
      contains('if (interactiveEvaluationConfig.enabled)'),
    );
    expect(
      source,
      isNot(contains('InteractiveEvaluationBridge(')),
    );
    expect(source, isNot(contains("port: 54321")));
    expect(source, isNot(contains(strongToken)));
  });

  test('interactive launch surface has no collision visualization define', () {
    final source = File(
      p.join(
        Directory.current.path,
        'lib',
        'src',
        'evaluation',
        'interactive',
        'interactive_worker_client.dart',
      ),
    ).readAsStringSync();

    expect(source, isNot(contains('POKEMAP_EVAL_COLLISION')));
    expect(source, isNot(contains('SHOW_COLLISION')));
  });
}
