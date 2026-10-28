import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/graphics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a secondary attachment is requested only while it is enabled', () {
    final backend = _Backend();
    final device = GraphicsDevice(backend: backend);
    void frame() {
      device
        ..begin()
        ..beginPass(const Size(96, 54));
      device
        ..endPass()
        ..end();
    }

    frame();
    expect(backend.requests, [null]);
    expect(backend.targets.single.secondaryColorTexture, isNull);

    const depth = Color(0xffffffff);
    device.secondaryColorClearValue = depth;
    frame();
    frame();
    expect(backend.requests, [null, depth]);
    expect(backend.targets.last.secondaryColorTexture, isNotNull);
    expect(backend.passTargets.skip(1), everyElement(same(backend.targets[1])));

    device.secondaryColorClearValue = null;
    frame();
    expect(backend.requests, [null, depth, null]);
    expect(backend.passTargets.last.secondaryColorTexture, isNull);
  });
}

final class _Backend extends GpuBackend {
  final requests = <Color?>[];
  final targets = <_Target>[];
  final passTargets = <GpuRenderTarget>[];

  @override
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required Color clearValue,
    Color? secondaryColorClearValue,
  }) {
    requests.add(secondaryColorClearValue);
    final target = _Target(secondaryColorClearValue != null);
    targets.add(target);
    return target;
  }

  @override
  GpuFrame beginFrame() => _Frame(this);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _Target implements GpuRenderTarget {
  _Target(bool secondary)
    : secondaryColorTexture = secondary ? _Texture() : null;

  @override
  final colorTexture = _Texture();

  @override
  final GpuTexture? secondaryColorTexture;
}

final class _Texture implements GpuTexture {
  @override
  void write(ByteData data) {}

  @override
  Image asImage() => _Image();
}

final class _Frame implements GpuFrame {
  _Frame(this.backend);
  final _Backend backend;

  @override
  GpuRenderPass beginRenderPass(
    GpuRenderTarget target, {
    required BlendState blend,
    required DepthStencilState depthStencil,
  }) {
    backend.passTargets.add(target);
    return _Pass();
  }

  @override
  void end() {}
}

final class _Pass implements GpuRenderPass {
  @override
  void submit() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _Image implements Image {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
