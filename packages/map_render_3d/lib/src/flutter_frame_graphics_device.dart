import 'dart:ui';

import 'package:flame_3d/graphics.dart';
import 'package:flutter/scheduler.dart';

class FlutterFrameGraphicsDevice extends GraphicsDevice {
  FlutterFrameGraphicsDevice({GpuBackend? backend, super.clearValue})
    : super(
        backend: _FlutterFrameBackend.shared(backend ?? GpuBackend.instance),
      );

  GpuRenderTarget? currentRenderTarget;
  Size renderSize = Size.zero;
  Image Function(GpuRenderTarget, Size)? postProcess;
  bool _frameOpen = false;

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
    if (process == null || target == null) return image;
    try {
      return process(target, renderSize);
    } finally {
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
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required Color clearValue,
  }) => delegate.createRenderTarget(
    width: width,
    height: height,
    clearValue: clearValue,
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
