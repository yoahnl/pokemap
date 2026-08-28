import 'dart:convert';
import 'dart:io';
import 'dart:math';

Future<void> main(List<String> arguments) async {
  final sessionFile =
      File(
        arguments.isEmpty
            ? 'build/avelune_control/session.json'
            : arguments.single,
      ).absolute;
  await sessionFile.parent.create(recursive: true);
  final port = await _availablePort();
  final token = _token();
  await sessionFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{'apiUrl': 'http://127.0.0.1:$port', 'token': token, 'bundleId': 'app.pokemap.hub', 'createdAt': DateTime.now().toUtc().toIso8601String()})}\n',
    flush: true,
  );
  final permissionResult = await Process.run('/bin/chmod', <String>[
    '600',
    sessionFile.path,
  ]);
  if (permissionResult.exitCode != 0) {
    await sessionFile.delete();
    throw StateError('Unable to protect the Avelune control session file.');
  }
  var exitCode = 1;
  try {
    stdout.writeln('Avelune control session: ${sessionFile.path}');
    final process = await Process.start('flutter', <String>[
      'run',
      '-d',
      'macos',
      '-t',
      'dev/marionette_main.dart',
      '--dart-define=AVELUNE_CONTROL_PORT=$port',
      '--dart-define=AVELUNE_CONTROL_TOKEN=$token',
    ], mode: ProcessStartMode.inheritStdio);
    exitCode = await process.exitCode;
  } finally {
    if (await sessionFile.exists()) await sessionFile.delete();
  }
  exit(exitCode);
}

Future<int> _availablePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

String _token() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}
