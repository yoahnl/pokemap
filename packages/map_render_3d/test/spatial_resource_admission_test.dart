import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame_3d/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/model_byte_loader.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_resource_admission.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final sample in [
    (name: 'accessor count', count: 1 << 62, copies: 1, instances: 1),
    (name: 'accessor sum', count: 1 << 56, copies: 4, instances: 1),
    (name: 'mesh instance product', count: 1 << 55, copies: 1, instances: 4),
  ]) {
    test(
      'overflowing ${sample.name} is refused before model allocation',
      () async {
        final budget = RuntimeResourceBudget(
          profile: const RuntimeResourceProfile(
            maximumResidentBytes: 0x7fffffffffffffff,
            maximumTransientBytes: 0x7fffffffffffffff,
          ),
        );
        final lease = await budget.acquire();
        await expectLater(
          spatialModelResourceEstimate(
            _model(
              count: sample.count,
              accessorCopies: sample.copies,
              instances: sample.instances,
              accessorType: 'SCALAR',
            ),
            lease,
          ),
          throwsA(isA<RuntimeResourceAdmissionException>()),
        );
        lease.release();
        expect(budget.residentBytes, 0);
        expect(budget.transientBytes, 0);
      },
    );
  }

  test('dense GLB JSON is refused before allocating parsed objects', () async {
    final bytes = _model(instances: 1000);
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumTransientBytes: 500000),
    );
    final lease = await budget.acquire();
    var parses = 0;
    await expectLater(
      spatialModelResourceEstimate(
        bytes,
        lease,
        decodeJson: (source) {
          parses++;
          return jsonDecode(source);
        },
      ),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(parses, 0);
    lease.release();
  });

  test('deep GLB JSON is refused before decoding the document', () async {
    Object nested = 0;
    for (var index = 0; index < 65; index++) {
      nested = [nested];
    }
    final budget = RuntimeResourceBudget();
    final lease = await budget.acquire();
    var parses = 0;
    await expectLater(
      spatialModelResourceEstimate(
        _model(metadata: nested),
        lease,
        decodeJson: (source) {
          parses++;
          return jsonDecode(source);
        },
      ),
      throwsFormatException,
    );
    expect(parses, 0);
    lease.release();
  });

  test(
    'escaped quotes and brackets in GLB strings do not count as nesting',
    () async {
      final model = await ModelByteLoader.load(
        _model(metadata: {'text': '\\"{[[[}'}),
      );
      expect(model.nodes, isNotEmpty);
    },
  );

  test(
    'ground and model sources are not read without resident capacity',
    () async {
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumResidentBytes: 8),
      );
      final live = await budget.acquire(residentBytes: 8);
      live.commit();
      var reads = 0;
      await expectLater(
        loadSpatialGroundTextureFromSource(() async {
          reads++;
          return img.encodePng(img.Image(width: 1, height: 1));
        }, budget: budget),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      await expectLater(
        ModelByteLoader.loadCached({}, 'model', () async {
          reads++;
          return _model();
        }, budget: budget),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      expect(reads, 0);
      expect(budget.residentBytes, 8);
      expect(budget.transientBytes, 0);
      live.release();
    },
  );

  test(
    'ground exact resident admission passes and one byte less never decodes',
    () async {
      final png = img.encodePng(img.Image(width: 2, height: 3));
      var decodes = 0;
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumResidentBytes: 48),
      );
      RuntimeResourceReservation? held;
      await loadSpatialGroundTexture(
        png,
        budget: budget,
        onResident: (lease) => held = lease,
        codecLoader: (bytes) {
          decodes++;
          return ui.instantiateImageCodec(bytes);
        },
      );
      expect(decodes, 1);
      expect(budget.residentBytes, 48);
      expect(budget.activeDecodes, 0);
      held!.release();
      expect(budget.residentBytes, 0);
      final insufficient = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumResidentBytes: 47),
      );
      await expectLater(
        loadSpatialGroundTexture(
          png,
          budget: insufficient,
          codecLoader: (bytes) {
            decodes++;
            return ui.instantiateImageCodec(bytes);
          },
        ),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      expect(decodes, 1);
      expect(insufficient.residentBytes, 0);
      expect(insufficient.transientBytes, 0);
    },
  );

  test(
    'ground codec and source image close after texture conversion',
    () async {
      final png = img.encodePng(img.Image(width: 2, height: 2));
      late _ObservedCodec observed;
      await loadSpatialGroundTexture(
        png,
        codecLoader: (bytes) async {
          return observed = _ObservedCodec(
            await ui.instantiateImageCodec(bytes),
          );
        },
      );
      expect(observed.disposed, isTrue);
      expect(observed.images.single.debugDisposed, isTrue);
    },
  );

  test('embedded GLB image uses owned codec and source image', () async {
    final bytes = _model(
      texture: img.encodePng(img.Image(width: 2, height: 2)),
    );
    late _ObservedCodec observed;
    final budget = RuntimeResourceBudget();
    RuntimeResourceReservation? held;
    final model = await ModelByteLoader.load(
      bytes,
      budget: budget,
      onResident: (lease) => held = lease,
      codecLoader: (bytes) async =>
          observed = _ObservedCodec(await ui.instantiateImageCodec(bytes)),
    );
    expect(model.nodes, isNotEmpty);
    expect(observed.disposed, isTrue);
    expect(observed.images.single.debugDisposed, isTrue);
    expect(budget.residentBytes, greaterThan(0));
    expect(budget.transientBytes, 0);
    held!.release();
    expect(budget.residentBytes, 0);
  });

  test('GLB geometry overflow refuses before texture decode and cleans reservation', () async {
    final bytes = _model(
      texture: img.encodePng(img.Image(width: 2, height: 2)),
    );
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumResidentBytes: 1),
    );
    var decodes = 0;
    await expectLater(
      ModelByteLoader.load(
        bytes,
        budget: budget,
        codecLoader: (bytes) {
          decodes++;
          return ui.instantiateImageCodec(bytes);
        },
      ),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(decodes, 0);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('repeated mesh nodes are admitted before parser allocations', () async {
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumResidentBytes: 10000),
    );
    await expectLater(
      ModelByteLoader.load(_model(instances: 50), budget: budget),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
  });

  test(
    'embedded image header refuses oversized pixels without a codec',
    () async {
      final bytes = _model(
        texture: img.encodePng(img.Image(width: 1024, height: 1024)),
      );
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(
          maximumResidentBytes: 1024 * 1024,
        ),
      );
      var decodes = 0;
      await expectLater(
        ModelByteLoader.load(
          bytes,
          budget: budget,
          codecLoader: (bytes) {
            decodes++;
            return ui.instantiateImageCodec(bytes);
          },
        ),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      expect(decodes, 0);
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
    },
  );

  test(
    'shared model admission bounds reads and drops queued cancelled sources',
    () async {
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumConcurrentDecodes: 1),
      );
      final cache = <String, Future<Model>>{};
      final gate = Completer<Uint8List>();
      final started = <String>[];
      var current = true;
      final loading = ModelByteLoader.preloadCached(
        cache,
        {
          'first': () {
            started.add('first');
            return gate.future;
          },
          'second': () async {
            started.add('second');
            return _model();
          },
        },
        budget: budget,
        isCurrent: () => current,
      );
      await Future<void>.delayed(Duration.zero);
      expect(started, ['first']);
      current = false;
      gate.complete(_model());
      expect(await loading, isFalse);
      expect(started, ['first']);
      expect(cache, isEmpty);
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
      expect(budget.activeDecodes, 0);
      expect(budget.peakConcurrentDecodes, 1);
    },
  );
}

final class _ObservedCodec implements ui.Codec {
  _ObservedCodec(this.delegate);
  final ui.Codec delegate;
  final images = <ui.Image>[];
  var disposed = false;
  @override
  int get frameCount => delegate.frameCount;
  @override
  int get repetitionCount => delegate.repetitionCount;
  @override
  Future<ui.FrameInfo> getNextFrame() async {
    final frame = await delegate.getNextFrame();
    images.add(frame.image);
    return frame;
  }

  @override
  void dispose() {
    disposed = true;
    delegate.dispose();
  }
}

Uint8List _model({
  Uint8List? texture,
  int instances = 1,
  Object? metadata,
  int count = 3,
  int accessorCopies = 1,
  String accessorType = 'VEC3',
}) {
  final positions = ByteData(36);
  for (final (index, value) in [
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
  ].indexed) {
    positions.setFloat32(index * 4, value, Endian.little);
  }
  final binary = Uint8List(36 + (texture?.length ?? 0));
  binary.setRange(0, 36, positions.buffer.asUint8List());
  if (texture != null) binary.setRange(36, binary.length, texture);
  final document = {
    'asset': {'version': '2.0'},
    if (metadata != null) 'extras': metadata,
    'scene': 0,
    'scenes': [
      {
        'nodes': [for (var i = 0; i < instances; i++) i],
      },
    ],
    'nodes': [
      for (var i = 0; i < instances; i++) {'name': 'Triangle $i', 'mesh': 0},
    ],
    'buffers': [
      {'byteLength': binary.length},
    ],
    'bufferViews': [
      {'buffer': 0, 'byteLength': 36},
      if (texture != null)
        {'buffer': 0, 'byteOffset': 36, 'byteLength': texture.length},
    ],
    'accessors': [
      for (var i = 0; i < accessorCopies; i++)
        {
          'bufferView': 0,
          'componentType': 5126,
          'count': count,
          'type': accessorType,
        },
    ],
    'meshes': [
      {
        'primitives': [
          {
            'attributes': {'POSITION': 0},
            if (texture != null) 'material': 0,
          },
        ],
      },
    ],
    if (texture != null) ...{
      'images': [
        {'bufferView': 1, 'mimeType': 'image/png'},
      ],
      'textures': [
        {'source': 0},
      ],
      'materials': [
        {
          'pbrMetallicRoughness': {
            'baseColorTexture': {'index': 0},
          },
        },
      ],
    },
  };
  final json = utf8.encode(jsonEncode(document));
  final jsonSize = (json.length + 3) ~/ 4 * 4;
  final binarySize = (binary.length + 3) ~/ 4 * 4;
  final bytes = Uint8List(28 + jsonSize + binarySize);
  final header = ByteData.sublistView(bytes);
  header.setUint32(0, 0x46546c67, Endian.little);
  header.setUint32(4, 2, Endian.little);
  header.setUint32(8, bytes.length, Endian.little);
  header.setUint32(12, jsonSize, Endian.little);
  header.setUint32(16, 0x4e4f534a, Endian.little);
  bytes.fillRange(20, 20 + jsonSize, 32);
  bytes.setRange(20, 20 + json.length, json);
  header.setUint32(20 + jsonSize, binarySize, Endian.little);
  header.setUint32(24 + jsonSize, 0x004e4942, Endian.little);
  bytes.setRange(28 + jsonSize, 28 + jsonSize + binary.length, binary);
  return bytes;
}
