import 'dart:io';

import 'src/pokemap_eval_cli.dart';

Future<void> main(List<String> arguments) async {
  final result = await PokeMapEvalCli.standard().execute(arguments);
  exitCode = result.exitCode;
}
