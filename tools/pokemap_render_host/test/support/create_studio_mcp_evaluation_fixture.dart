import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'minimal_evaluation_project.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1 || !p.isAbsolute(arguments.single)) {
    throw ArgumentError('Provide the owned QA parent directory.');
  }
  final parent = Directory(arguments.single);
  await parent.create(recursive: true);
  final generated = await createMinimalEvaluationProject(parent: parent);
  final project = await generated.rename(
    p.join(parent.path, p.basename(generated.path).toLowerCase()),
  );
  final scenario = File(
    p.join(project.path, 'evaluation/scenarios/native-smoke.json'),
  );
  await scenario.parent.create(recursive: true);
  await scenario.writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'id': 'native-smoke',
      'title': 'Installed Studio evaluation qualification',
      'projectId': p.basename(project.path),
      'policy': 'certify',
      'start': {'newGame': true},
      'steps': [
        {
          'id': 'initial-map',
          'assert': 'state.currentMapId',
          'equals': 'start',
        },
      ],
      'criteria': [
        {
          'id': 'runtime-loaded',
          'stepIds': ['initial-map'],
        },
      ],
    }),
  );
  stdout.writeln(
    jsonEncode({'root': project.path, 'scenarioId': 'native-smoke'}),
  );
}
