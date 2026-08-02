// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'smart_tile.dart';

part 'smart_tile_field.freezed.dart';
part 'smart_tile_field.g.dart';

@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
sealed class SmartTileField with _$SmartTileField {
  const factory SmartTileField.cell({
    @Default(<int>[]) List<int> semanticCells,
  }) = SmartTileCellField;

  const factory SmartTileField.corner({
    @Default(<int>[]) List<int> semanticCells,
    @Default(<int>[]) List<int> corners,
  }) = SmartTileCornerField;

  const factory SmartTileField.edge({
    @Default(<int>[]) List<int> semanticCells,
    @Default(<int>[]) List<int> horizontalEdges,
    @Default(<int>[]) List<int> verticalEdges,
  }) = SmartTileEdgeField;

  const factory SmartTileField.mixed({
    @Default(<int>[]) List<int> semanticCells,
    @Default(<int>[]) List<int> horizontalEdges,
    @Default(<int>[]) List<int> verticalEdges,
    @Default(<int>[]) List<int> corners,
  }) = SmartTileMixedField;

  factory SmartTileField.fromJson(Map<String, dynamic> json) =>
      _$SmartTileFieldFromJson(_validatedSmartTileFieldJson(json));
}

Map<String, dynamic> _validatedSmartTileFieldJson(
  Map<String, dynamic> json,
) {
  _validateSmartTileFieldJson(json);
  return json;
}

void _validateSmartTileFieldJson(Map<String, dynamic> json) {
  final kind = json['kind'];
  final activeLattices = switch (kind) {
    'cell' => const <String>{'semanticCells'},
    'corner' => const <String>{'semanticCells', 'corners'},
    'edge' => const <String>{
        'semanticCells',
        'horizontalEdges',
        'verticalEdges',
      },
    'mixed' => const <String>{
        'semanticCells',
        'horizontalEdges',
        'verticalEdges',
        'corners',
      },
    _ => throw FormatException(
        r'$.field.kind: smart_tile_field_kind_invalid (' '$kind)',
      ),
  };
  for (final lattice in const <String>{
    'semanticCells',
    'horizontalEdges',
    'verticalEdges',
    'corners',
  }) {
    if (!json.containsKey(lattice)) {
      continue;
    }
    if (!activeLattices.contains(lattice)) {
      throw FormatException(
        r'$.field.'
        '$lattice: smart_tile_field_inactive_lattice (kind=$kind)',
      );
    }
    final value = json[lattice];
    if (value is! List || value.any((item) => item is! int)) {
      throw FormatException(
        r'$.field.'
        '$lattice: smart_tile_field_lattice_invalid (kind=$kind)',
      );
    }
  }
}

bool isSmartTileFieldCompatibleWithTopology(
  SmartTileTopology topology,
  SmartTileField field,
) =>
    switch (topology) {
      SmartTileTopology.uniform ||
      SmartTileTopology.cardinal4 ||
      SmartTileTopology.blob8 =>
        field is SmartTileCellField,
      SmartTileTopology.wangEdge4 => field is SmartTileEdgeField,
      SmartTileTopology.wangCorner4 => field is SmartTileCornerField,
      SmartTileTopology.wang8 => field is SmartTileMixedField,
    };
