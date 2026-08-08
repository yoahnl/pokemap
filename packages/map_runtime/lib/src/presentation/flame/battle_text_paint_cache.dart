import 'package:flutter/painting.dart';

/// Cache LRU de [TextPainter] déjà mis en page.
///
/// Les HUD et panneaux de commande battle repeignent à 60 Hz des textes qui
/// ne changent que quelques fois par seconde ; re-façonner chaque libellé via
/// `TextPainter.layout` à chaque frame dominait leur coût. Les entrées
/// évincées sont libérées.
final class BattleTextPaintCache {
  BattleTextPaintCache({int capacity = 96}) : _capacity = capacity;

  final int _capacity;
  final Map<String, TextPainter> _painters = <String, TextPainter>{};

  TextPainter painterFor({
    required String text,
    required TextStyle style,
    double maxWidth = double.infinity,
    TextAlign textAlign = TextAlign.left,
    String? ellipsis,
  }) {
    final key = '$text|${style.color?.toARGB32()}|${style.fontSize}|'
        '${style.fontWeight}|${style.letterSpacing}|$textAlign|$ellipsis|'
        '${maxWidth.toStringAsFixed(2)}';
    final cached = _painters.remove(key);
    if (cached != null) {
      _painters[key] = cached;
      return cached;
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      ellipsis: ellipsis,
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    _painters[key] = painter;
    if (_painters.length > _capacity) {
      final oldest = _painters.keys.first;
      _painters.remove(oldest)?.dispose();
    }
    return painter;
  }

  void clear() {
    for (final painter in _painters.values) {
      painter.dispose();
    }
    _painters.clear();
  }
}
