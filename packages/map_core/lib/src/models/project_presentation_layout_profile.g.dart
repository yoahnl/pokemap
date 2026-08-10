// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_presentation_layout_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectSurfaceLayoutVariant _$ProjectSurfaceLayoutVariantFromJson(
  Map<String, dynamic> json,
) => _ProjectSurfaceLayoutVariant(
  breakpoint: $enumDecode(
    _$ProjectPresentationBreakpointEnumMap,
    json['breakpoint'],
  ),
  slot: $enumDecode(_$ProjectPresentationLayoutSlotEnumMap, json['slot']),
  width:
      $enumDecodeNullable(
        _$ProjectPresentationContentWidthEnumMap,
        json['width'],
      ) ??
      ProjectPresentationContentWidth.comfortable,
  spacing:
      $enumDecodeNullable(
        _$ProjectPresentationSpacingEnumMap,
        json['spacing'],
      ) ??
      ProjectPresentationSpacing.normal,
  screenMargin:
      $enumDecodeNullable(
        _$ProjectPresentationScreenMarginEnumMap,
        json['screenMargin'],
      ) ??
      ProjectPresentationScreenMargin.compact,
  visibleSecondaryElements:
      (json['visibleSecondaryElements'] as List<dynamic>?)
          ?.map(
            (e) => $enumDecode(_$ProjectPresentationSecondaryElementEnumMap, e),
          )
          .toList() ??
      const <ProjectPresentationSecondaryElement>[],
);

Map<String, dynamic> _$ProjectSurfaceLayoutVariantToJson(
  _ProjectSurfaceLayoutVariant instance,
) => <String, dynamic>{
  'breakpoint': _$ProjectPresentationBreakpointEnumMap[instance.breakpoint]!,
  'slot': _$ProjectPresentationLayoutSlotEnumMap[instance.slot]!,
  'width': _$ProjectPresentationContentWidthEnumMap[instance.width]!,
  'spacing': _$ProjectPresentationSpacingEnumMap[instance.spacing]!,
  'screenMargin':
      _$ProjectPresentationScreenMarginEnumMap[instance.screenMargin]!,
  'visibleSecondaryElements': instance.visibleSecondaryElements
      .map((e) => _$ProjectPresentationSecondaryElementEnumMap[e]!)
      .toList(),
};

const _$ProjectPresentationBreakpointEnumMap = {
  ProjectPresentationBreakpoint.compact: 'compact',
  ProjectPresentationBreakpoint.regular: 'regular',
  ProjectPresentationBreakpoint.expanded: 'expanded',
};

const _$ProjectPresentationLayoutSlotEnumMap = {
  ProjectPresentationLayoutSlot.center: 'center',
  ProjectPresentationLayoutSlot.bottomCenter: 'bottomCenter',
  ProjectPresentationLayoutSlot.bottomLeft: 'bottomLeft',
  ProjectPresentationLayoutSlot.leftPane: 'leftPane',
  ProjectPresentationLayoutSlot.fullScreen: 'fullScreen',
  ProjectPresentationLayoutSlot.left: 'left',
  ProjectPresentationLayoutSlot.right: 'right',
  ProjectPresentationLayoutSlot.topCenter: 'topCenter',
};

const _$ProjectPresentationContentWidthEnumMap = {
  ProjectPresentationContentWidth.narrow: 'narrow',
  ProjectPresentationContentWidth.comfortable: 'comfortable',
  ProjectPresentationContentWidth.wide: 'wide',
};

const _$ProjectPresentationSpacingEnumMap = {
  ProjectPresentationSpacing.compact: 'compact',
  ProjectPresentationSpacing.normal: 'normal',
  ProjectPresentationSpacing.airy: 'airy',
};

const _$ProjectPresentationScreenMarginEnumMap = {
  ProjectPresentationScreenMargin.none: 'none',
  ProjectPresentationScreenMargin.compact: 'compact',
  ProjectPresentationScreenMargin.comfortable: 'comfortable',
};

const _$ProjectPresentationSecondaryElementEnumMap = {
  ProjectPresentationSecondaryElement.titleLogo: 'titleLogo',
  ProjectPresentationSecondaryElement.titleAuthor: 'titleAuthor',
  ProjectPresentationSecondaryElement.titleDescription: 'titleDescription',
  ProjectPresentationSecondaryElement.pauseGameTitle: 'pauseGameTitle',
  ProjectPresentationSecondaryElement.dialoguePortrait: 'dialoguePortrait',
};

_ProjectResponsiveSurfaceLayoutProfile
_$ProjectResponsiveSurfaceLayoutProfileFromJson(Map<String, dynamic> json) =>
    _ProjectResponsiveSurfaceLayoutProfile(
      compact: ProjectSurfaceLayoutVariant.fromJson(
        json['compact'] as Map<String, dynamic>,
      ),
      regular: ProjectSurfaceLayoutVariant.fromJson(
        json['regular'] as Map<String, dynamic>,
      ),
      expanded: ProjectSurfaceLayoutVariant.fromJson(
        json['expanded'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ProjectResponsiveSurfaceLayoutProfileToJson(
  _ProjectResponsiveSurfaceLayoutProfile instance,
) => <String, dynamic>{
  'compact': instance.compact.toJson(),
  'regular': instance.regular.toJson(),
  'expanded': instance.expanded.toJson(),
};

_ProjectPresentationLayoutsProfile _$ProjectPresentationLayoutsProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectPresentationLayoutsProfile(
  title: ProjectResponsiveSurfaceLayoutProfile.fromJson(
    json['title'] as Map<String, dynamic>,
  ),
  pauseMenu: ProjectResponsiveSurfaceLayoutProfile.fromJson(
    json['pauseMenu'] as Map<String, dynamic>,
  ),
  dialogue: ProjectResponsiveSurfaceLayoutProfile.fromJson(
    json['dialogue'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ProjectPresentationLayoutsProfileToJson(
  _ProjectPresentationLayoutsProfile instance,
) => <String, dynamic>{
  'title': instance.title.toJson(),
  'pauseMenu': instance.pauseMenu.toJson(),
  'dialogue': instance.dialogue.toJson(),
};
