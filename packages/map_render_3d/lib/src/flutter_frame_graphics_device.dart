import 'dart:ui';

import 'package:flame_3d/graphics.dart';
import 'package:flutter/scheduler.dart';

import 'flutter_image_presenter.dart';

class FlutterFrameGraphicsDevice extends GraphicsDevice {
  FlutterFrameGraphicsDevice({
    GpuBackend? backend,
    Image Function(Image)? presentImage,
    super.clearValue,
  }) : _presentImage = presentImage ?? createFlutterImagePresenter(),
       super(
         backend: _FlutterFrameBackend.shared(backend ?? GpuBackend.instance),
       );

  final Image Function(Image) _presentImage;
  GpuRenderTarget? currentRenderTarget;
  Size renderSize = Size.zero;
  Image Function(GpuRenderTarget, Size)? postProcess;
  bool _frameOpen = false;
  int _successfulPresentations = 0;

  int get successfulPresentations => _successfulPresentations;
  int _textureAllocations = 0;
  int _textureAllocationBytes = 0;
  int get textureAllocations => _textureAllocations;
  int get colorTextureAllocationBytes => _textureAllocationBytes;

  GpuTexture allocateRgbaTexture(int width, int height) {
    final texture = backend.createTexture(
      storageMode: GpuStorageMode.hostVisible,
      width: width,
      height: height,
      format: GpuPixelFormat.rgba8888,
    );
    _textureAllocations++;
    _textureAllocationBytes += width * height * 4;
    return texture;
  }

  @override
  void begin() {
    super.begin();
    _frameOpen = true;
  }

  @override
  void end() {
    if (!_frameOpen) return;
    _frameOpen = false;
    super.end();
  }

  void guardFrame(VoidCallback render) {
    try {
      render();
    } finally {
      end();
    }
  }

  @override
  void beginPass(Size size) {
    super.beginPass(size);
    renderSize = size;
    currentRenderTarget = (backend as _FlutterFrameBackend).currentRenderTarget;
  }

  @override
  Image endPass() {
    final image = super.endPass();
    final process = postProcess;
    final target = currentRenderTarget;
    Image? processed;
    try {
      processed = process == null || target == null
          ? image
          : process(target, renderSize);
      final presented = _presentImage(processed);
      _successfulPresentations++;
      return presented;
    } finally {
      if (processed != null && !identical(processed, image)) {
        processed.dispose();
      }
      image.dispose();
    }
  }
}

final class _FlutterFrameBackend extends GpuBackend {
  _FlutterFrameBackend(this.delegate);

  static final _backends = Expando<_FlutterFrameBackend>();

  static _FlutterFrameBackend shared(GpuBackend backend) {
    if (backend is _FlutterFrameBackend) return backend;
    return _backends[backend] ??= _FlutterFrameBackend(backend);
  }

  final GpuBackend delegate;
  _FlutterFrame? _frame;
  GpuRenderTarget? currentRenderTarget;

  @override
  GpuFrame beginFrame() => _frame ??= _FlutterFrame(
    delegate.beginFrame(),
    () => _frame = null,
    (target) => currentRenderTarget = target,
  );

  @override
  GpuTexture createTexture({
    required GpuStorageMode storageMode,
    required int width,
    required int height,
    required GpuPixelFormat format,
  }) => delegate.createTexture(
    storageMode: storageMode,
    width: width,
    height: height,
    format: format,
  );

  @override
  GpuBuffer createBuffer({
    required GpuStorageMode storageMode,
    required int sizeInBytes,
  }) =>
      delegate.createBuffer(storageMode: storageMode, sizeInBytes: sizeInBytes);

  @override
  GpuShaderLibrary loadShaderLibrary(String assetName) =>
      delegate.loadShaderLibrary(assetName);

  @override
  GpuPipeline createPipeline({
    required GpuShader vertexShader,
    required GpuShader fragmentShader,
  }) => delegate.createPipeline(
    vertexShader: vertexShader,
    fragmentShader: fragmentShader,
  );

  @override
  GpuPipeline? createInstancedPipeline({
    required GpuShader vertexShader,
    required GpuShader fragmentShader,
    required GpuInstanceLayout layout,
  }) => delegate.createInstancedPipeline(
    vertexShader: vertexShader,
    fragmentShader: fragmentShader,
    layout: layout,
  );

  @override
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required Color clearValue,
    Color? secondaryColorClearValue,
  }) => delegate.createRenderTarget(
    width: width,
    height: height,
    clearValue: clearValue,
    secondaryColorClearValue: secondaryColorClearValue,
  );
}

class _FlutterFrame implements GpuFrame {
  _FlutterFrame(this.delegate, this.release, this.onTarget);

  final GpuFrame delegate;
  final VoidCallback release;
  final void Function(GpuRenderTarget) onTarget;
  bool _endScheduled = false;

  @override
  GpuRenderPass beginRenderPass(
    GpuRenderTarget target, {
    required BlendState blend,
    required DepthStencilState depthStencil,
  }) {
    onTarget(target);
    return delegate.beginRenderPass(
      target,
      blend: blend,
      depthStencil: depthStencil,
    );
  }

  @override
  void end() {
    if (_endScheduled) return;
    _endScheduled = true;
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      scheduler.addPostFrameCallback((_) => _finish());
    } else {
      _finish();
    }
  }

  void _finish() {
    release();
    delegate.end();
  }
}
