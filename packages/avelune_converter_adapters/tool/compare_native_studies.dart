import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart' as crypto;

import '../test/support/native_reproducibility.dart';

Future<void> main(List<String> arguments) async {
  exitCode =
      await runNativeStudyComparison(arguments, output: stdout, errors: stderr);
}

Future<int> runNativeStudyComparison(List<String> arguments,
    {required StringSink output, required StringSink errors}) async {
  if (arguments.length != 8 ||
      arguments[0] != '--parent' ||
      arguments[2] != '--plan' ||
      arguments[4] != '--expectations' ||
      [
        arguments[1],
        arguments[3],
        arguments[5],
        arguments[6],
        arguments[7]
      ].any((value) => !path.isAbsolute(value) || value.contains('\u0000'))) {
    errors.writeln(
        'Usage: compare-native-studies --parent ABSOLUTE_NARROW_PARENT '
        '--plan ABSOLUTE_RECIPE --expectations ABSOLUTE_CAPTURE LEFT_PROJECT RIGHT_PROJECT');
    return 64;
  }
  try {
    final recipe = await const LocalStudyPlanStore().read(arguments[3]);
    final capture = File(arguments[5]);
    final before = await capture.stat();
    if (before.type != FileSystemEntityType.file ||
        before.size > 1048576 ||
        await FileSystemEntity.type(capture.path, followLinks: false) !=
            FileSystemEntityType.file) {
      throw const FormatException(
          'Expectations require a bounded regular file.');
    }
    final bytes = await capture.readAsBytes();
    final after = await capture.stat();
    if (before.size != after.size ||
        before.modified != after.modified ||
        bytes.length != before.size) {
      throw const FormatException('Expectations changed while being read.');
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    const keys = {
      'kind',
      'version',
      'recipeHash',
      'nativeDraftHash',
      'approvedPlanHash',
      'operationIds'
    };
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.length != keys.length ||
        !decoded.keys.toSet().containsAll(keys) ||
        decoded['kind'] != 'nativeReproducibilityExpectations' ||
        decoded['version'] != 1 ||
        decoded['recipeHash'] != recipe.canonicalHash.value ||
        decoded['nativeDraftHash'] != recipe.nativeDraftHash.value ||
        decoded['approvedPlanHash'] != recipe.approvedPlanHash.value) {
      throw const FormatException(
          'Captured native expectations do not bind the exact recipe.');
    }
    final rawOperations = decoded['operationIds'];
    if (rawOperations is! List ||
        rawOperations.isEmpty ||
        rawOperations.length > 2048 ||
        rawOperations.any((value) => value is! String) ||
        rawOperations.toSet().length != rawOperations.length) {
      throw const FormatException(
          'Captured operation identities must be unique, ordered and bounded.');
    }
    final operations = rawOperations
        .map((value) => ConverterId(value as String).value)
        .toList();
    final comparison = await compareNativeStudyDirectories(
        leftProjectPath: arguments[6],
        rightProjectPath: arguments[7],
        allowedParentPath: arguments[1],
        expectedOperationIds: operations);
    output.writeln(jsonEncode({
      ...comparison.toJson(),
      'recipeHash': recipe.canonicalHash.value,
      'nativeDraftHash': recipe.nativeDraftHash.value,
      'approvedPlanHash': recipe.approvedPlanHash.value,
      'expectedOperationIds': operations,
      'expectationsFingerprint': crypto.sha256.convert(bytes).toString(),
      'proofScope': 'closedNativeOutputEquality',
      'transportsObservedByComparator': false
    }));
    return 0;
  } on ConverterWorkflowFailure catch (error) {
    errors.writeln(jsonEncode(
        {'equal': false, 'code': error.code, 'message': error.message}));
    return 1;
  } on Object catch (error) {
    errors.writeln(jsonEncode({
      'equal': false,
      'code': 'native.comparison.failed',
      'message': error.toString()
    }));
    return 1;
  }
}
