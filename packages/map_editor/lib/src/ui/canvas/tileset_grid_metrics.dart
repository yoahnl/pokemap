class TilesetGridMetrics {
  const TilesetGridMetrics({
    required this.imageWidth,
    required this.imageHeight,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
  });

  factory TilesetGridMetrics.fromImagePixels({
    required int imageWidth,
    required int imageHeight,
    required int tileWidth,
    required int tileHeight,
  }) {
    final columns = tileWidth > 0 ? imageWidth ~/ tileWidth : 0;
    final rows = tileHeight > 0 ? imageHeight ~/ tileHeight : 0;
    return TilesetGridMetrics(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columns: columns,
      rows: rows,
    );
  }

  final int imageWidth;
  final int imageHeight;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final int rows;

  int get usablePixelWidth => columns * tileWidth;
  int get usablePixelHeight => rows * tileHeight;
  bool get isValid => columns > 0 && rows > 0;

  bool get hasTrailingPixels =>
      usablePixelWidth != imageWidth || usablePixelHeight != imageHeight;
}
