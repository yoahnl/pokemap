import 'package:image/image.dart' as image;

List<int> exampleAtlasPng() {
  final atlas = image.Image(width: 160, height: 64, numChannels: 4);
  void rect(int x, int y, int w, int h, int r, int g, int b) => image.fillRect(
    atlas,
    x1: x,
    y1: y,
    x2: x + w - 1,
    y2: y + h - 1,
    color: image.ColorRgba8(r, g, b, 255),
  );
  rect(0, 0, 16, 16, 104, 158, 96);
  for (var y = 1; y < 16; y += 4) {
    for (var x = 1; x < 16; x += 5) {
      rect(x, y, 2, 2, 130, 177, 111);
    }
  }
  rect(16, 0, 16, 16, 191, 166, 112);
  rect(20, 5, 3, 2, 211, 190, 135);
  rect(33, 11, 30, 28, 34, 86, 63);
  rect(37, 5, 22, 26, 44, 110, 73);
  rect(41, 1, 14, 24, 74, 141, 77);
  rect(45, 33, 6, 15, 115, 78, 57);
  rect(48, 35, 3, 12, 149, 100, 68);
  rect(66, 5, 28, 23, 93, 109, 133);
  rect(70, 1, 20, 18, 135, 149, 165);
  rect(72, 3, 13, 6, 166, 180, 189);
  rect(97, 4, 30, 27, 146, 70, 73);
  rect(97, 4, 30, 5, 215, 117, 88);
  rect(100, 11, 24, 3, 190, 106, 83);
  rect(100, 26, 24, 3, 92, 51, 66);
  rect(134, 2, 5, 8, 224, 185, 143);
  rect(133, 0, 7, 4, 66, 49, 70);
  rect(131, 10, 12, 13, 71, 119, 175);
  rect(135, 10, 4, 13, 103, 158, 207);
  rect(132, 23, 4, 8, 54, 60, 90);
  rect(138, 23, 4, 8, 54, 60, 90);
  return image.encodePng(atlas);
}
