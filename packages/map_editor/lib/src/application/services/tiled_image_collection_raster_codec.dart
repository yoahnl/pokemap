import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';

/// Desktop adapter for the canonical image-collection packer.
///
/// The authoring package owns packing geometry; this adapter only translates
/// supported raster bytes to and from the stable RGBA8888 boundary.
final class ImagePackageTiledImageCollectionRasterCodec
    implements TiledImageCollectionRasterCodec {
  const ImagePackageTiledImageCollectionRasterCodec();

  @override
  TiledImageCollectionRasterMetadata inspect(List<int> encodedBytes) {
    final bytes = Uint8List.fromList(encodedBytes);
    final decoder = img.findDecoderForData(bytes);
    final info = decoder?.startDecode(bytes);
    if (info == null) {
      throw const FormatException('Unsupported or invalid raster image.');
    }
    return TiledImageCollectionRasterMetadata(
      pixelWidth: info.width,
      pixelHeight: info.height,
    );
  }

  @override
  TiledImageCollectionRgbaImage decode(List<int> encodedBytes) {
    final bytes = Uint8List.fromList(encodedBytes);
    final decoder = img.findDecoderForData(bytes);
    final decoded = decoder?.decode(bytes, frame: 0);
    if (decoded == null) {
      throw const FormatException('Unsupported or invalid raster image.');
    }
    final rgba = decoded.convert(
      format: img.Format.uint8,
      numChannels: 4,
      alpha: decoded.hasAlpha ? null : 255,
    );
    final pixels = Uint8List(rgba.width * rgba.height * 4);
    var target = 0;
    for (var y = 0; y < rgba.height; y += 1) {
      for (var x = 0; x < rgba.width; x += 1) {
        final pixel = rgba.getPixel(x, y);
        pixels[target++] = pixel.r.toInt();
        pixels[target++] = pixel.g.toInt();
        pixels[target++] = pixel.b.toInt();
        pixels[target++] = pixel.a.toInt();
      }
    }
    return TiledImageCollectionRgbaImage(
      pixelWidth: rgba.width,
      pixelHeight: rgba.height,
      rgbaBytes: pixels,
    );
  }

  @override
  List<int> encodePng(TiledImageCollectionRgbaImage image) {
    final output = img.Image(
      width: image.pixelWidth,
      height: image.pixelHeight,
      numChannels: 4,
    );
    var source = 0;
    for (var y = 0; y < image.pixelHeight; y += 1) {
      for (var x = 0; x < image.pixelWidth; x += 1) {
        output.setPixelRgba(
          x,
          y,
          image.rgbaBytes[source++],
          image.rgbaBytes[source++],
          image.rgbaBytes[source++],
          image.rgbaBytes[source++],
        );
      }
    }
    return List<int>.unmodifiable(img.encodePng(output));
  }
}
