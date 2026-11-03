import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_source_program_converter.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = <String, String>{};
    for (var index = 0; index < arguments.length; index += 2) {
      if (index + 1 >= arguments.length ||
          !{'--revision', '--path', '--sha256', '--variant'}
              .contains(arguments[index]) ||
          options.containsKey(arguments[index])) {
        throw const FormatException(
            'Expected --revision, --path, --sha256 and --variant');
      }
      options[arguments[index]] = arguments[index + 1];
    }
    if (options.length != 4) {
      throw const FormatException(
          'Expected --revision, --path, --sha256 and --variant');
    }
    final input = BytesBuilder(copy: false);
    await for (final chunk in stdin) {
      if (input.length + chunk.length > 64 * 1024) {
        throw const FormatException('Battle script exceeds size limit');
      }
      input.add(chunk);
    }
    final result = Gen5SourceProgramConverter.convert(
      input.takeBytes(),
      sourceRevision: options['--revision']!,
      sourcePath: options['--path']!,
      expectedSha256: options['--sha256']!,
      variant: options['--variant']!,
    );
    stdout.writeln(jsonEncode(result));
    if (result['conversion'] != 'supported') exitCode = 2;
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  }
}
