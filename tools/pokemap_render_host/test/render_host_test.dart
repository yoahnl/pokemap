import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
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

  group('ScanRequest', () {
    test('defaults to twelve views at magnification four', () {
      final request = ScanRequest.fromJson(const {
        'projectRoot': '/games/jeu',
        'mapId': 'route-32',
        'outputDirectory': '/tmp/scan',
      });
      expect((request.maxViews, request.magnification), (12, 4.0));
    });

    for (final (label, json) in [
      ('a relative output directory', {'projectRoot': '/jeu', 'mapId': 'm', 'outputDirectory': 'scan'}),
      ('too many views', {'projectRoot': '/jeu', 'mapId': 'm', 'outputDirectory': '/tmp/s', 'maxViews': 40}),
      ('a fractional view count', {'projectRoot': '/jeu', 'mapId': 'm', 'outputDirectory': '/tmp/s', 'maxViews': 2.5}),
      ('a wide magnification', {'projectRoot': '/jeu', 'mapId': 'm', 'outputDirectory': '/tmp/s', 'magnification': 1}),
      ('an unknown field', {'projectRoot': '/jeu', 'mapId': 'm', 'outputDirectory': '/tmp/s', 'view': 'top'}),
    ]) {
      test('rejects $label', () {
        expect(() => ScanRequest.fromJson(json), throwsA(isA<RenderRequestException>()));
      });
    }
  });

  test('holes are sentinel patches the scene encloses; edge-connected void is not', () {
    const width = 10, height = 10;
    final rgba = Uint8List(width * height * 4);
    void paint(int x, int y) => rgba.setAll((y * width + x) * 4, const [255, 0, 255, 255]);
    paint(5, 5);
    paint(5, 6);
    for (var y = 0; y < height; y++) {
      paint(0, y);
    }
    paint(1, 4);
    final ratios = seeThroughRatios(rgba, width, height);
    expect(ratios.background, closeTo(.13, 1e-9));
    expect(ratios.holes, closeTo(.02, 1e-9));
  });

  test('the grid covers the whole map including unpainted areas', () {
    const width = 48, depth = 30;
    final map = MapData(
      id: 'm',
      name: 'M',
      size: const GridSize(width: width, height: depth),
      spatialScene: MapSpatialScene(width: width, depth: depth, heightLevels: List.filled(width * depth, 0)),
      layers: [
        SmartTileLayer(
          id: 'ground',
          name: 'Ground',
          presetId: 'grass',
          usage: SmartTileUsage.terrain,
          materialPalette: const ['', 'grass'],
          field: SmartTileField.cell(semanticCells: [
            for (var z = 0; z < depth; z++)
              for (var x = 0; x < width; x++) x >= 8 && x < 40 && z >= 2 ? 1 : 0,
          ]),
        ),
      ],
    );
    final centres = gridViewCenters(map);
    expect(centres, hasLength((width/20).ceil() * (depth/11).ceil()));
    expect(centres.map((c) => c.$1).toSet(), {8.0, 24.0, 40.0});
    expect(centres.every((c) => c.$2 > 0 && c.$2 < depth), isTrue);
    expect(gridViewCenters(map.copyWith(layers:const [])),centres);
    expect(gridViewCenters(map.copyWith(spatialScene: null)), isEmpty);
  });

  group('RenderHost', () {
    test('dispatches scans only when the host provides them', () async {
      final scanned = <ScanRequest>[];
      final host = RenderHost((_) async => const {}, scan: (request) async {
        scanned.add(request);
        return {'viewCount': 0};
      });
      final args = {'projectRoot': '/jeu', 'mapId': 'route-32', 'outputDirectory': '/tmp/s'};
      final responses = await _exchange(host, [
        {'id': 'scan', 'command': 'scan', 'args': args},
      ]);
      expect(responses.single['status'], 'success');
      expect(scanned.single.mapId, 'route-32');
      final plain = await _exchange(RenderHost((_) async => const {}), [
        {'id': 'scan', 'command': 'scan', 'args': args},
      ]);
      expect((plain.single['error'] as Map)['code'], 'render.request_invalid');
    });

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
