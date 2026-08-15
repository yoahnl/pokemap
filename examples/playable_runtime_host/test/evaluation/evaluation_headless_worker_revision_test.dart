import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_headless_worker.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';

void main() {
  test(
    'headless worker refuses a digest mismatch before driver startup',
    () async {
      final root = await Directory.systemTemp.createTemp('headless-digest-');
      addTearDown(() => root.delete(recursive: true));
      final project = Directory(p.join(root.path, 'project'));
      await project.create();
      await File(p.join(project.path, 'project.json')).writeAsString('{}');
      await File(p.join(root.path, 'scenario.json')).writeAsString(
        '{"schemaVersion":1,"id":"project.test","title":"Test",'
        '"projectId":"project","policy":"probe",'
        '"start":{"newGame":true},"steps":[]}',
      );

      final result = await runHeadlessEvaluationRequest(
        EvaluationWorkerRequest.run(
          runId: 'headless-digest-mismatch',
          projectRoot: 'project',
          expectedProjectTreeHash: '0' * 64,
          scenarioPath: 'scenario.json',
          outputDirectory: 'build/run',
        ),
        hostRoot: root,
      );

      expect(result.status, EvaluationRunStatus.infrastructureFailure);
      expect(result.message, contains('digest mismatch'));
    },
  );
}
