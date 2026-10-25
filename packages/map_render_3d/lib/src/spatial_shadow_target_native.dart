import 'dart:developer' as developer;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;

GpuTexture? multisampleSpatialShadowTarget(
  GpuBackend backend,
  GpuRenderTarget target, {
  required int width,
  required int height,
}) {
  Object? handle;
  try {
    handle = (target as dynamic).raw;
  } on NoSuchMethodError {
    return null;
  }
  if (handle is! gpu.RenderTarget) return null;
  if (!gpu.gpuContext.doesSupportOffscreenMSAA) return null;
  if (!gpu.gpuContext.supportsTextureFormat(
    gpu.PixelFormat.r32g32b32a32Float,
    renderTarget: true,
  ))
    return null;
  final shader = backend.loadShaderLibrary(
    'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle',
  )['ShadowDepthMsaaFragment'];
  if (shader.getUniformSlot('DepthSamples').sizeInBytes == null) return null;
  late final GpuTexture resolved;
  late final gpu.Texture color, depth;
  try {
    resolved = backend.createTexture(
      storageMode: GpuStorageMode.devicePrivate,
      width: width,
      height: height,
      format: GpuPixelFormat.rgbaFloat32,
    );
    color = gpu.gpuContext.createTexture(
      gpu.StorageMode.deviceTransient,
      width,
      height,
      format: gpu.PixelFormat.r32g32b32a32Float,
      sampleCount: 4,
    );
    depth = gpu.gpuContext.createTexture(
      gpu.StorageMode.deviceTransient,
      width,
      height,
      format: gpu.gpuContext.defaultDepthStencilFormat,
      sampleCount: 4,
    );
  } on Exception catch (error) {
    developer.log(
      'Multisampled shadow allocation failed; keeping packed depth.',
      name: 'map_render_3d.shadows',
      error: error,
    );
    return null;
  }
  final resolvedHandle = (resolved as dynamic).raw as gpu.Texture;
  handle.colorAttachments.single
    ..texture = color
    ..resolveTexture = resolvedHandle
    ..clearValue = Vector4.zero()
    ..storeAction = gpu.StoreAction.multisampleResolve;
  handle.depthStencilAttachment!.texture = depth;
  return resolved;
}
