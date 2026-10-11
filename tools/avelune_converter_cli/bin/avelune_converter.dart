import 'dart:io';

import 'package:avelune_converter_cli/avelune_converter_cli.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runConverterCli(arguments);
}
