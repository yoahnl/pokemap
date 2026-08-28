import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('serves authenticated state and session commands on loopback', () async {
    var dashboard = _dashboard();
    List<int>? installedBytes;
    late AveluneControlService service;
    service = AveluneControlService(
      readDashboard: () => dashboard,
      sessionController: HubSessionController(refreshHub: () async {}),
      installPackage: (package) async {
        installedBytes = await package.readAsBytes();
        dashboard = _dashboard(status: HubDashboardStatus.installing);
        service.observeDashboard(dashboard);
        dashboard = _dashboard();
        service.observeDashboard(dashboard);
      },
    )..observeDashboard(dashboard);
    final uploadDirectory = await Directory.systemTemp.createTemp(
      'avelune-control-upload-',
    );
    addTearDown(() => uploadDirectory.delete(recursive: true));
    final server = AveluneControlServer(
      service: service,
      token: 'secret-token',
      port: 0,
      uploadDirectory: uploadDirectory,
    );
    await server.start();
    addTearDown(server.close);

    expect(server.baseUri.host, InternetAddress.loopbackIPv4.address);

    final unauthorized = await _request(server.baseUri.resolve('/v1/state'));
    expect(unauthorized.statusCode, HttpStatus.unauthorized);
    expect(unauthorized.body['code'], 'unauthorized');

    final state = await _request(
      server.baseUri.resolve('/v1/state'),
      token: 'secret-token',
    );
    expect(state.statusCode, HttpStatus.ok);
    expect(state.body['surface'], 'hub');

    final installed = await _request(
      server.baseUri.resolve('/v1/install?filename=controlled.avelunegame'),
      method: 'POST',
      token: 'secret-token',
      bytes: <int>[1, 2, 3, 4],
    );
    expect(installed.statusCode, HttpStatus.ok);
    expect((installed.body['install'] as Map)['status'], 'succeeded');
    expect(installedBytes, <int>[1, 2, 3, 4]);
    expect(uploadDirectory.listSync(), isEmpty);

    final launched = await _request(
      server.baseUri.resolve('/v1/launch'),
      method: 'POST',
      token: 'secret-token',
      body: <String, Object?>{'gameId': 'game.controlled'},
    );
    expect(launched.statusCode, HttpStatus.ok);
    expect(launched.body['surface'], 'player');
    expect(launched.body['activeGameId'], 'game.controlled');

    final returned = await _request(
      server.baseUri.resolve('/v1/hub'),
      method: 'POST',
      token: 'secret-token',
    );
    expect(returned.statusCode, HttpStatus.ok);
    expect(returned.body['surface'], 'hub');
  });

  test('returns stable request and route errors', () async {
    final dashboard = _dashboard();
    final uploadDirectory = await Directory.systemTemp.createTemp(
      'avelune-control-upload-',
    );
    addTearDown(() => uploadDirectory.delete(recursive: true));
    final server = AveluneControlServer(
      service: AveluneControlService(
        readDashboard: () => dashboard,
        sessionController: HubSessionController(refreshHub: () async {}),
        installPackage: (_) async {},
      )..observeDashboard(dashboard),
      token: 'secret-token',
      port: 0,
      uploadDirectory: uploadDirectory,
    );
    await server.start();
    addTearDown(server.close);

    final invalid = await _request(
      server.baseUri.resolve('/v1/launch'),
      method: 'POST',
      token: 'secret-token',
      body: <String, Object?>{'gameId': ''},
    );
    expect(invalid.statusCode, HttpStatus.badRequest);
    expect(invalid.body['code'], 'invalidRequest');

    final missing = await _request(
      server.baseUri.resolve('/v1/missing'),
      token: 'secret-token',
    );
    expect(missing.statusCode, HttpStatus.notFound);
    expect(missing.body['code'], 'routeNotFound');
  });
}

Future<({int statusCode, Map<String, Object?> body})> _request(
  Uri uri, {
  String method = 'GET',
  String? token,
  Map<String, Object?>? body,
  List<int>? bytes,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    } else if (bytes != null) {
      request.headers.contentType = ContentType.binary;
      request.add(bytes);
    }
    final response = await request.close();
    final payload = await utf8.decoder.bind(response).join();
    return (
      statusCode: response.statusCode,
      body: (jsonDecode(payload) as Map).cast<String, Object?>(),
    );
  } finally {
    client.close(force: true);
  }
}

HubDashboardSnapshot _dashboard({
  HubDashboardStatus status = HubDashboardStatus.ready,
}) {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: 'a' * 64,
    installedAt: DateTime.utc(2026, 8, 28),
    receiptFileName: 'receipt.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  final game = InstalledGame(
    gameId: 'game.controlled',
    title: 'Controlled',
    description: '',
    authorName: 'PokeMap',
    defaultLocale: 'fr',
    supportedLocales: const <String>['fr'],
    current: version.pointer,
    versions: <InstalledGameVersion>[version],
  );
  return HubDashboardSnapshot(
    status: status,
    library: GameLibrary(
      revision: 1,
      updatedAt: DateTime.utc(2026, 8, 28),
      games: <InstalledGame>[game],
    ),
    games: <HubGameView>[
      HubGameView(game: game, activity: const HubGameActivity()),
    ],
  );
}
