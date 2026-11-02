import 'dart:ffi';

final class ProbeRequest extends Struct {
  external Pointer<Uint8> tiles;
  @IntPtr()
  external int tileSize;
  external Pointer<Uint8> ncer;
  @IntPtr()
  external int ncerSize;
  external Pointer<Uint8> nanr;
  @IntPtr()
  external int nanrSize;
  external Pointer<Uint8> nmcr;
  @IntPtr()
  external int nmcrSize;
  external Pointer<Uint8> nmar;
  @IntPtr()
  external int nmarSize;
  @Int32()
  external int timeline;
  @Int32()
  external int tick;
  @Int32()
  external int minX;
  @Int32()
  external int minY;
  @Int32()
  external int width;
  @Int32()
  external int height;
  @Int32()
  external int childMode;
  @Int32()
  external int parentCompleted;
}

@Native<Pointer<Void> Function(IntPtr)>(symbol: 'av_probe_alloc')
external Pointer<Void> probeAlloc(int size);

@Native<Void Function(Pointer<Void>)>(symbol: 'av_probe_free')
external void probeFree(Pointer<Void> pointer);

@Native<
  Int32 Function(
    Pointer<Uint8>,
    IntPtr,
    Pointer<Uint8>,
    IntPtr,
    Pointer<IntPtr>,
  )
>(symbol: 'av_api_decompress')
external int apiDecompress(
  Pointer<Uint8> source,
  int sourceSize,
  Pointer<Uint8> output,
  int outputSize,
  Pointer<IntPtr> written,
);

@Native<
  Int32 Function(
    Pointer<ProbeRequest>,
    Pointer<Uint8>,
    IntPtr,
    Pointer<Int32>,
    IntPtr,
  )
>(symbol: 'av_probe_render_sample')
external int probeRender(
  Pointer<ProbeRequest> request,
  Pointer<Uint8> output,
  int outputSize,
  Pointer<Int32> details,
  int detailCount,
);

@Native<
  Int32 Function(
    Pointer<ProbeRequest>,
    Pointer<Uint8>,
    IntPtr,
    Pointer<Int32>,
    IntPtr,
    Pointer<Uint8>,
    IntPtr,
  )
>(symbol: 'av_probe_render_rectangles')
external int probeRenderRectangles(
  Pointer<ProbeRequest> request,
  Pointer<Uint8> output,
  int outputSize,
  Pointer<Int32> details,
  int detailCount,
  Pointer<Uint8> info,
  int infoSize,
);
