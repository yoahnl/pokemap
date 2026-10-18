import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:image/image.dart' as image;

Map<String, List<int>> nativeMediaSourceFiles(NativePsdkCatalog catalog,
    {Map<String, String> sourceSymbols = const {},
    Map<String, String> extraSpecies = const {}}) {
  final bases = <String>{};
  for (final entry in catalog.mediaBySpeciesId.entries) {
    for (final variant in entry.value.variants.values) {
      for (final target in [variant.frontStatic!, variant.backStatic!]) {
        if (!catalog.fallbackMedia.containsKey(target)) {
          bases.add(catalog.speciesById[entry.key]!.forms.baseFormId);
        }
      }
    }
  }
  final ids = bases.toList()..sort();
  final rows = [
    for (final id in ids)
      (
        symbol: sourceSymbols[id] ?? id.toUpperCase(),
        name: catalog.speciesById[id]!.names['en']!
      ),
    for (final entry in extraSpecies.entries)
      (symbol: entry.key, name: entry.value)
  ];
  var index = 1;
  return {
    'PBS/pokemon.txt': utf8.encode([
      for (final row in rows) '[${row.symbol}]\nName = ${row.name}\n'
    ].join()),
    'Data/species.dat': [
      4,
      8,
      123,
      ..._integer(rows.length),
      for (final row in rows) ...[
        ..._text(row.symbol, 58),
        111,
        ..._text('GameData::Species', 58),
        9,
        ..._text('@id', 58),
        ..._text(row.symbol, 58),
        ..._text('@species', 58),
        ..._text(row.symbol, 58),
        ..._text('@form', 58),
        105,
        0,
        ..._text('@real_name', 58),
        ..._text(row.name, 34),
      ]
    ],
    for (final row in rows)
      for (final side in ['Front', 'Back'])
        'Graphics/Pokemon/$side/${row.symbol}.png': _png(index++),
  };
}

List<int> _png(int value) {
  final raster = image.Image(width: 1, height: 1, numChannels: 4);
  raster.setPixelRgba(0, 0, value & 255, (value >> 8) & 255, 71, 255);
  return image.encodePng(raster);
}

List<int> _integer(int value) => value == 0
    ? [0]
    : value < 123
        ? [value + 5]
        : [2, value & 255, (value >> 8) & 255];

List<int> _text(String value, int marker) {
  final bytes = utf8.encode(value);
  return [marker, ..._integer(bytes.length), ...bytes];
}
