import 'dart:convert';
import 'dart:io';

Future<void> writeRuntimeJsonAtomically({
  required File destination,
  required Map<String, dynamic> json,
  required void Function(Map<String, dynamic>) validate,
}) async {
  final temporary = File(
    '${destination.path}.tmp.$pid.${DateTime.now().microsecondsSinceEpoch}',
  );
  try {
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
      flush: true,
    );
    validate(jsonDecode(await temporary.readAsString()) as Map<String, dynamic>);
    await temporary.rename(destination.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}
