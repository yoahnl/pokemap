import 'dart:ui' as ui;

import 'package:flame_3d/graphics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/flutter_frame_graphics_device.dart';
import 'package:map_render_3d/src/spatial_actor_visual.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'import conversion and lazy GPU upload are counted separately per device',
    () async {
      final backend = _Backend();
      final first = FlutterFrameGraphicsDevice(backend: backend);
      final second = FlutterFrameGraphicsDevice(backend: backend);
      expect(first.backend, same(second.backend));
      expect(GpuBackend.instance, same(first.backend));
      final image = makeImage();
      final texture = await SpatialActorTexture.fromImage(
        image,
        textureAllocator: first.allocateRgbaTexture,
      );
      image.dispose();
      expect(first.textureAllocations, 0);
      expect(second.textureAllocations, 0);
      final resource = texture.texture.resource;
      expect(first.textureAllocations, 1);
      expect(first.colorTextureAllocationBytes, 8 * 8 * 4);
      expect(backend.uploads, 1);
      expect(second.textureAllocations, 0);
      expect(texture.texture.resource, same(resource));
      expect(first.textureAllocations, 1);
    },
  );

  test('normal output is presented before releasing its temporary image', () {
    final backend = _Backend();
    ui.Image? presented;
    final device = FlutterFrameGraphicsDevice(
      backend: backend,
      presentImage: (image) {
        expect(image.debugDisposed, isFalse);
        presented = image;
        return image.clone();
      },
    );
    final result = render(device);
    expect(device.successfulPresentations, 1);
    expect(presented, same(backend.target.texture.lastImage));
    expect(presented!.debugDisposed, isTrue);
    expect(result.debugDisposed, isFalse);
    result.dispose();
  });

  test('postprocessed output uses the same presentation boundary', () {
    final backend = _Backend();
    final processed = makeImage();
    ui.Image? presented;
    final device = FlutterFrameGraphicsDevice(
      backend: backend,
      presentImage: (image) {
        presented = image;
        return image.clone();
      },
    )..postProcess = (_, _) => processed;
    final result = render(device);
    expect(presented, same(processed));
    expect(processed.debugDisposed, isTrue);
    expect(backend.target.texture.lastImage!.debugDisposed, isTrue);
    expect(result.debugDisposed, isFalse);
    result.dispose();
  });

  test('a failed presentation releases both images and closes the frame', () {
    final backend = _Backend();
    final processed = makeImage();
    var fail = true;
    final device = FlutterFrameGraphicsDevice(
      backend: backend,
      presentImage: (image) {
        if (fail) throw StateError('Presentation failed');
        return image.clone();
      },
    )..postProcess = (_, _) => processed;
    expect(() => render(device), throwsStateError);
    expect(device.successfulPresentations, 0);
    expect(processed.debugDisposed, isTrue);
    expect(backend.target.texture.lastImage!.debugDisposed, isTrue);
    expect(backend.ends, 1);
    fail = false;
    device.postProcess = null;
    render(device).dispose();
    expect(device.successfulPresentations, 1);
    expect(backend.ends, 2);
  });

  test('a failed postprocess releases the source and never presents it', () {
    final backend = _Backend();
    var presentations = 0;
    final device = FlutterFrameGraphicsDevice(
      backend: backend,
      presentImage: (image) {
        presentations++;
        return image.clone();
      },
    )..postProcess = (_, _) => throw StateError('Postprocess failed');
    expect(() => render(device), throwsStateError);
    expect(device.successfulPresentations, 0);
    expect(presentations, 0);
    expect(backend.target.texture.lastImage!.debugDisposed, isTrue);
    expect(backend.ends, 1);
  });

  test('a postprocess returning its source is disposed only once', () {
    final backend = _Backend();
    final device = FlutterFrameGraphicsDevice(
      backend: backend,
      presentImage: (image) => image.clone(),
    )..postProcess = (_, _) => backend.target.texture.lastImage!;
    final result = render(device);
    expect(backend.target.texture.lastImage!.debugDisposed, isTrue);
    expect(result.debugDisposed, isFalse);
    result.dispose();
  });
}

ui.Image render(FlutterFrameGraphicsDevice device) {
  late ui.Image result;
  device.guardFrame(() {
    device.begin();
    device.beginPass(const ui.Size(8, 8));
    result = device.endPass();
  });
  return result;
}

ui.Image makeImage() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(8, 8);
  picture.dispose();
  return image;
}

final class _Backend extends GpuBackend {
  final target = _Target();
  int ends = 0;
  int uploads = 0;

  @override
  GpuTexture createTexture({
    required GpuStorageMode storageMode,
    required int width,
    required int height,
    required GpuPixelFormat format,
  }) => _Texture(onWrite: () => uploads++);

  @override
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required ui.Color clearValue,
    ui.Color? secondaryColorClearValue,
  }) => target;

  @override
  GpuFrame beginFrame() => _Frame(this);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _Target implements GpuRenderTarget {
  final texture = _Texture();

  @override
  GpuTexture get colorTexture => texture;

  @override
  GpuTexture? get secondaryColorTexture => null;
}

final class _Texture implements GpuTexture {
  _Texture({this.onWrite});
  final void Function()? onWrite;

  @override
  void write(dynamic data) => onWrite?.call();
  ui.Image? lastImage;

  @override
  ui.Image asImage() => lastImage = makeImage();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _Frame implements GpuFrame {
  _Frame(this.backend);
  final _Backend backend;

  @override
  GpuRenderPass beginRenderPass(
    GpuRenderTarget target, {
    required BlendState blend,
    required DepthStencilState depthStencil,
  }) => _Pass();

  @override
  void end() => backend.ends++;
}

final class _Pass implements GpuRenderPass {
  @override
  void submit() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
