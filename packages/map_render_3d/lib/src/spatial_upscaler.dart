import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/graphics.dart';
import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;

enum SpatialUpscaling { nearest, fsr1 }

final class SpatialUpscaler {
  SpatialUpscaler(this.backend);

  static const _bundle =
      'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle';
  static const licenseAsset =
      'packages/map_render_3d/assets/shaders/fsr1-LICENSE.txt';
  static const licensedPackage = 'AMD FidelityFX Super Resolution 1.0';
  static const sharpnessStops = .2;
  static bool _licenseRegistered = false;

  static void registerLicense() {
    if (_licenseRegistered) return;
    _licenseRegistered = true;
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        licensedPackage,
      ], await rootBundle.loadString(licenseAsset));
    });
  }

  final GpuBackend backend;
  GpuRenderTarget? _easuTarget, _rcasTarget;
  (int, int)? _size;
  GpuPipeline? _easu, _rcas;
  GpuShader? _easuFragment, _rcasFragment;
  GpuBuffer? _vertices;
  final _easuUniforms = Float32List(4), _rcasUniforms = Float32List(4);
  late final _easuBytes = _easuUniforms.buffer.asByteData();
  late final _rcasBytes = _rcasUniforms.buffer.asByteData();
  int targetAllocations = 0, passes = 0;

  GpuTexture upscale(GpuTexture input, Size inputSize, Size outputSize) {
    final source = (inputSize.width.toInt(), inputSize.height.toInt());
    final output = (outputSize.width.toInt(), outputSize.height.toInt());
    if (source.$1 <= 0 ||
        source.$2 <= 0 ||
        output.$1 <= source.$1 && output.$2 <= source.$2) {
      return input;
    }
    if (_size != output) {
      _easuTarget = backend.createRenderTarget(
        width: output.$1,
        height: output.$2,
        clearValue: const Color(0x00000000),
      );
      _rcasTarget = backend.createRenderTarget(
        width: output.$1,
        height: output.$2,
        clearValue: const Color(0x00000000),
      );
      _size = output;
      targetAllocations += 2;
    }
    if (_easu == null) {
      final library = backend.loadShaderLibrary(_bundle);
      final vertex = library['DepthOfFieldVertex'];
      final easu = library['FsrEasuFragment'];
      final rcas = library['FsrRcasFragment'];
      final vertices = Float32List.fromList([-1, -1, 3, -1, -1, 3]);
      final buffer = backend.createBuffer(
        storageMode: GpuStorageMode.hostVisible,
        sizeInBytes: vertices.lengthInBytes,
      )..write(vertices.buffer.asByteData());
      _easuFragment = easu;
      _rcasFragment = rcas;
      _vertices = buffer;
      _rcas = backend.createPipeline(
        vertexShader: vertex,
        fragmentShader: rcas,
      );
      _easu = backend.createPipeline(
        vertexShader: vertex,
        fragmentShader: easu,
      );
    }
    _easuUniforms
      ..[0] = source.$1.toDouble()
      ..[1] = source.$2.toDouble()
      ..[2] = output.$1.toDouble()
      ..[3] = output.$2.toDouble();
    _draw(_easu!, _easuFragment!, 'Easu', _easuBytes, input, _easuTarget!);
    _rcasUniforms
      ..[0] = output.$1.toDouble()
      ..[1] = output.$2.toDouble()
      ..[2] = math.pow(2, -sharpnessStops).toDouble()
      ..[3] = 0;
    _draw(
      _rcas!,
      _rcasFragment!,
      'Rcas',
      _rcasBytes,
      _easuTarget!.colorTexture,
      _rcasTarget!,
    );
    return _rcasTarget!.colorTexture;
  }

  void _draw(
    GpuPipeline pipeline,
    GpuShader fragment,
    String block,
    ByteData uniforms,
    GpuTexture input,
    GpuRenderTarget target,
  ) {
    backend.beginFrame().beginRenderPass(
        target,
        blend: BlendState.opaque,
        depthStencil: DepthStencilState.none,
      )
      ..bindPipeline(pipeline, CullMode.none)
      ..bindVertexBuffer(
        GpuBufferView(_vertices!, offsetInBytes: 0, lengthInBytes: 24),
        3,
      )
      ..bindUniform(fragment.getUniformSlot(block), uniforms)
      ..bindTexture(fragment.getUniformSlot('inputTexture'), input)
      ..draw()
      ..submit();
    passes++;
  }
}
