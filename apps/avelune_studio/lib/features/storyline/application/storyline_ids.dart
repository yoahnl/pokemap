String storylineItemId(String prefix, String title, Set<String> existing) {
  final buffer = StringBuffer();
  var separated = false;
  for (final unit in title.trim().toLowerCase().codeUnits) {
    final keep = unit >= 48 && unit <= 57 || unit >= 97 && unit <= 122;
    if (keep) {
      buffer.writeCharCode(unit);
      separated = false;
    } else if (!separated && buffer.isNotEmpty) {
      buffer.write('_');
      separated = true;
    }
  }
  final slug = buffer.toString().replaceAll(RegExp(r'_+$'), '');
  final base = '${prefix}_${slug.isEmpty ? 'item' : slug}';
  if (!existing.contains(base)) return base;
  var suffix = 2;
  while (existing.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}
