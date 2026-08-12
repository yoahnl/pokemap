// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_battle_presentation_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectBattleCommandProfile _$ProjectBattleCommandProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectBattleCommandProfile(
  id: $enumDecode(_$ProjectBattleCommandIdEnumMap, json['id']),
  label: json['label'] as String?,
  icon: $enumDecodeNullable(_$ProjectBattleCommandIconEnumMap, json['icon']),
);

Map<String, dynamic> _$ProjectBattleCommandProfileToJson(
  _ProjectBattleCommandProfile instance,
) => <String, dynamic>{
  'id': _$ProjectBattleCommandIdEnumMap[instance.id]!,
  'label': ?instance.label,
  'icon': ?_$ProjectBattleCommandIconEnumMap[instance.icon],
};

const _$ProjectBattleCommandIdEnumMap = {
  ProjectBattleCommandId.fight: 'fight',
  ProjectBattleCommandId.bag: 'bag',
  ProjectBattleCommandId.party: 'party',
  ProjectBattleCommandId.run: 'run',
};

const _$ProjectBattleCommandIconEnumMap = {
  ProjectBattleCommandIcon.fight: 'fight',
  ProjectBattleCommandIcon.bag: 'bag',
  ProjectBattleCommandIcon.party: 'party',
  ProjectBattleCommandIcon.run: 'run',
};

_ProjectBattlePanelPresentationProfile
_$ProjectBattlePanelPresentationProfileFromJson(Map<String, dynamic> json) =>
    _ProjectBattlePanelPresentationProfile(
      layout:
          $enumDecodeNullable(
            _$ProjectBattleCommandLayoutEnumMap,
            json['layout'],
          ) ??
          ProjectBattleCommandLayout.grid,
      columns: (json['columns'] as num?)?.toInt() ?? 2,
      shape:
          $enumDecodeNullable(_$ProjectWindowShapeEnumMap, json['shape']) ??
          ProjectWindowShape.rounded,
      padding: (json['padding'] as num?)?.toDouble() ?? 12,
      surfaceColor: json['surfaceColor'] as String?,
      borderColor: json['borderColor'] as String?,
      textColor: json['textColor'] as String?,
      selectionColor: json['selectionColor'] as String?,
    );

Map<String, dynamic> _$ProjectBattlePanelPresentationProfileToJson(
  _ProjectBattlePanelPresentationProfile instance,
) => <String, dynamic>{
  'layout': _$ProjectBattleCommandLayoutEnumMap[instance.layout]!,
  'columns': instance.columns,
  'shape': _$ProjectWindowShapeEnumMap[instance.shape]!,
  'padding': instance.padding,
  'surfaceColor': ?instance.surfaceColor,
  'borderColor': ?instance.borderColor,
  'textColor': ?instance.textColor,
  'selectionColor': ?instance.selectionColor,
};

const _$ProjectBattleCommandLayoutEnumMap = {
  ProjectBattleCommandLayout.grid: 'grid',
  ProjectBattleCommandLayout.list: 'list',
  ProjectBattleCommandLayout.radial: 'radial',
};

const _$ProjectWindowShapeEnumMap = {
  ProjectWindowShape.rectangle: 'rectangle',
  ProjectWindowShape.rounded: 'rounded',
  ProjectWindowShape.capsule: 'capsule',
  ProjectWindowShape.cutCorner: 'cutCorner',
  ProjectWindowShape.speech: 'speech',
};

_ProjectBattlePresentationProfile _$ProjectBattlePresentationProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectBattlePresentationProfile(
  commandLayout:
      $enumDecodeNullable(
        _$ProjectBattleCommandLayoutEnumMap,
        json['commandLayout'],
      ) ??
      ProjectBattleCommandLayout.grid,
  commandColumns: (json['commandColumns'] as num?)?.toInt() ?? 2,
  showCommandIcons: json['showCommandIcons'] as bool? ?? true,
  commandShape:
      $enumDecodeNullable(_$ProjectWindowShapeEnumMap, json['commandShape']) ??
      ProjectWindowShape.rounded,
  commandPadding: (json['commandPadding'] as num?)?.toDouble() ?? 12,
  commandSurfaceColor: json['commandSurfaceColor'] as String?,
  commandBorderColor: json['commandBorderColor'] as String?,
  commandTextColor: json['commandTextColor'] as String?,
  commandSelectionColor: json['commandSelectionColor'] as String?,
  commands: (json['commands'] as List<dynamic>?)
      ?.map(
        (e) => ProjectBattleCommandProfile.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  hudShape:
      $enumDecodeNullable(_$ProjectWindowShapeEnumMap, json['hudShape']) ??
      ProjectWindowShape.rounded,
  enemyHudPosition:
      $enumDecodeNullable(
        _$ProjectBattleHudPositionEnumMap,
        json['enemyHudPosition'],
      ) ??
      ProjectBattleHudPosition.topStart,
  playerHudPosition:
      $enumDecodeNullable(
        _$ProjectBattleHudPositionEnumMap,
        json['playerHudPosition'],
      ) ??
      ProjectBattleHudPosition.bottomEnd,
  showOwnerLabel: json['showOwnerLabel'] as bool? ?? true,
  showLevel: json['showLevel'] as bool? ?? true,
  showExactHp: json['showExactHp'] as bool? ?? true,
  hpBarShape:
      $enumDecodeNullable(
        _$ProjectBattleHpBarShapeEnumMap,
        json['hpBarShape'],
      ) ??
      ProjectBattleHpBarShape.rounded,
  hpHealthyColor: json['hpHealthyColor'] as String? ?? '#16794B',
  hpWarningColor: json['hpWarningColor'] as String? ?? '#8A5100',
  hpDangerColor: json['hpDangerColor'] as String? ?? '#B4233C',
  statusColor: json['statusColor'] as String? ?? '#8A5100',
  moves: json['moves'] == null
      ? const ProjectBattlePanelPresentationProfile()
      : ProjectBattlePanelPresentationProfile.fromJson(
          json['moves'] as Map<String, dynamic>,
        ),
  target: json['target'] == null
      ? const ProjectBattlePanelPresentationProfile()
      : ProjectBattlePanelPresentationProfile.fromJson(
          json['target'] as Map<String, dynamic>,
        ),
  message: json['message'] == null
      ? const ProjectBattlePanelPresentationProfile()
      : ProjectBattlePanelPresentationProfile.fromJson(
          json['message'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectBattlePresentationProfileToJson(
  _ProjectBattlePresentationProfile instance,
) => <String, dynamic>{
  'commandLayout': _$ProjectBattleCommandLayoutEnumMap[instance.commandLayout]!,
  'commandColumns': instance.commandColumns,
  'showCommandIcons': instance.showCommandIcons,
  'commandShape': _$ProjectWindowShapeEnumMap[instance.commandShape]!,
  'commandPadding': instance.commandPadding,
  'commandSurfaceColor': ?instance.commandSurfaceColor,
  'commandBorderColor': ?instance.commandBorderColor,
  'commandTextColor': ?instance.commandTextColor,
  'commandSelectionColor': ?instance.commandSelectionColor,
  'commands': ?instance.commands?.map((e) => e.toJson()).toList(),
  'hudShape': _$ProjectWindowShapeEnumMap[instance.hudShape]!,
  'enemyHudPosition':
      _$ProjectBattleHudPositionEnumMap[instance.enemyHudPosition]!,
  'playerHudPosition':
      _$ProjectBattleHudPositionEnumMap[instance.playerHudPosition]!,
  'showOwnerLabel': instance.showOwnerLabel,
  'showLevel': instance.showLevel,
  'showExactHp': instance.showExactHp,
  'hpBarShape': _$ProjectBattleHpBarShapeEnumMap[instance.hpBarShape]!,
  'hpHealthyColor': instance.hpHealthyColor,
  'hpWarningColor': instance.hpWarningColor,
  'hpDangerColor': instance.hpDangerColor,
  'statusColor': instance.statusColor,
  'moves': instance.moves.toJson(),
  'target': instance.target.toJson(),
  'message': instance.message.toJson(),
};

const _$ProjectBattleHudPositionEnumMap = {
  ProjectBattleHudPosition.topStart: 'topStart',
  ProjectBattleHudPosition.topEnd: 'topEnd',
  ProjectBattleHudPosition.bottomStart: 'bottomStart',
  ProjectBattleHudPosition.bottomEnd: 'bottomEnd',
};

const _$ProjectBattleHpBarShapeEnumMap = {
  ProjectBattleHpBarShape.flat: 'flat',
  ProjectBattleHpBarShape.rounded: 'rounded',
  ProjectBattleHpBarShape.segmented: 'segmented',
};
