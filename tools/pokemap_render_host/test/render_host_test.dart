import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_render_host/src/render_host.dart';
import 'package:pokemap_render_host/src/render_request.dart';

void main() {
  group('RenderRequest', () {
    test('defaults the camera to the map centre at midday in game view', () {
      final request = RenderRequest.fromJson(const {
        'projectRoot': '/games/jeu',
        'mapId': 'route-32',
        'outputPath': '/tmp/out.png',
      });
      expect(request.view, MapRenderView.game);
      expect(request.magnification, 2);
      expect(request.minuteOfDay, 720);
      expect(request.centerX, isNull);
    });

    test('reads every optional camera field', () {
      final request = RenderRequest.fromJson(const {
        'projectRoot': '/games/jeu',
        'mapId': 'route-32',
        'outputPath': '/tmp/out.png',
        'center': {'x': 25, 'z': 64.5},
        'magnification': 3,
        'view': 'top',
        'minuteOfDay': 1260,
      });
      expect((request.centerX, request.centerZ), (25.0, 64.5));
      expect(request.magnification, 3);
      expect(request.view, MapRenderView.top);
      expect(request.minuteOfDay, 1260);
    });

    for (final (label, json) in [
      ('a relative project root', {'projectRoot': 'jeu', 'mapId': 'm', 'outputPath': '/tmp/o.png'}),
      ('a non-PNG output', {'projectRoot': '/jeu', 'mapId': 'm', 'outputPath': '/tmp/o.jpg'}),
      ('an empty map id', {'projectRoot': '/jeu', 'mapId': '', 'outputPath': '/tmp/o.png'}),
      ('an unknown field', {'projectRoot': '/jeu', 'mapId': 'm', 'outputPath': '/tmp/o.png', 'zoom': 2}),
      ('an incomplete centre', {'projectRoot': '/jeu', 'mapId': 'm', 'outputPath': '/tmp/o.png', 'center': {'x': 1}}),
      ('an extreme magnification', {'projectRoot': '/jeu', 'mapId': 'm', 'outputPath': '/tmp/o.png', 'magnification': 20}),
      ('a minute past midnight', {'projectRoot': '/jeu', 'mapId': 'm', 'outputPath': '/tmp/o.png', 'minuteOfDay': 1440}),
      ('an unknown view', {'projectRoot': '/jeu', 'mapId': 'm', 'outputPath': '/tmp/o.png', 'view': 'side'}),
    ]) {
      test('rejects $label', () {
        expect(() => RenderRequest.fromJson(json), throwsA(isA<RenderRequestException>()));
      });
    }

    test('project files stay inside the project root', () {
      final request = RenderRequest.fromJson(const {
        'projectRoot': '/games/jeu',
        'mapId': 'm',
        'outputPath': '/tmp/o.png',
      });
      expect(request.projectFile('assets/models/tree.glb'), '/games/jeu/assets/models/tree.glb');
      expect(() => request.projectFile('../secrets/key.glb'), throwsA(isA<RenderRequestException>()));
      expect(() => request.projectFile('/etc/passwd'), throwsA(isA<RenderRequestException>()));
    });
  });

  group('RenderHost', () {
    test('answers each JSON line with the matching id', () async {
      final rendered = <RenderRequest>[];
      final host = RenderHost((request) async {
        rendered.add(request);
        return {'mapId': request.mapId};
      });
      final responses = await _exchange(host, [
        {'id': 'p', 'command': 'ping'},
        {
          'id': 'r',
          'command': 'render',
          'args': {'projectRoot': '/jeu', 'mapId': 'route-32', 'outputPath': '/tmp/o.png'},
        },
        {'id': 's', 'command': 'shutdown'},
        {'id': 'ignored', 'command': 'ping'},
      ]);
      expect(responses.map((response) => response['id']), ['p', 'r', 's']);
      expect(responses.every((response) => response['status'] == 'success'), isTrue);
      expect((responses[1]['data'] as Map)['mapId'], 'route-32');
      expect(rendered.single.mapId, 'route-32');
    });

    test('reports invalid requests and render failures without stopping', () async {
      final host = RenderHost((_) async => throw const RenderFailure('render.map_not_spatial', 'No 3D scene.'));
      final responses = await _exchange(host, [
        {'id': 'bad', 'command': 'render', 'args': {'mapId': 'm'}},
        {'id': 'flat', 'command': 'render', 'args': {'projectRoot': '/jeu', 'mapId': 'm', 'outputPath': '/tmp/o.png'}},
        {'id': 'what', 'command': 'teleport'},
        {'id': 'alive', 'command': 'ping'},
      ]);
      expect(responses.map((response) => (response['error'] as Map?)?['code']),
          ['render.request_invalid', 'render.map_not_spatial', 'render.request_invalid', null]);
      expect(responses.last['status'], 'success');
    });
  });
}

Future<List<Map<String, Object?>>> _exchange(RenderHost host, List<Map<String, Object?>> requests) async {
  final input = Stream<List<int>>.value(utf8.encode('${requests.map(jsonEncode).join('\n')}\n'));
  final output = _MemorySink();
  await host.serve(input, output);
  return const LineSplitter()
      .convert(output.text)
      .map((line) => Map<String, Object?>.from(jsonDecode(line) as Map))
      .toList();
}

final class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  String get text => _buffer.toString();

  @override
  Encoding encoding = utf8;

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  Future<void> flush() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
