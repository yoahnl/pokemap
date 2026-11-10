import 'package:map_core/map_core_domain.dart';

import '../domain/border_sequence_primitives.dart';
import '../domain/resource_port.dart';
import 'resource_catalog.dart';
import 'resource_creation_sources.dart';

class BorderCreationDraft {
  BorderCreationDraft({
    required this.project,
    this.initialRecord,
    required this.unavailableResourceIds,
  }) {
    final record = initialRecord;
    expectedRecord = record;
    jumpSide = record?.draft.definition.jumpBehavior?.side;
    name = record?.draft.definition.name ?? '';
    pendingId = record?.id;
    straightOnly = record?.draft.definition.straightOnly ?? false;
    sequenceLength = record?.draft.definition.sequenceLength ?? 1;
    horizontalFacade =
        record?.draft.definition.template ==
        BorderBlueprintTemplate.horizontalFacade;
    followContourDirection =
        record?.draft.definition.followContourDirection ?? false;
    replacesGround = record?.draft.definition.replacesGround ?? false;
    masksGroundCells = record?.draft.definition.masksGroundCells ?? false;
    groundBaseOffset = record?.draft.definition.groundBaseOffset ?? 0;
    for (final primitive
        in record?.draft.definition.primitives ?? <BorderPrimitiveDraft>[]) {
      final item = resourceCatalog(project)
          .where(
            (candidate) =>
                candidate.canonicalKind ==
                    (primitive.isSpatial ? 'model3d' : 'element') &&
                candidate.id ==
                    (primitive.sourceModelId ?? primitive.sourceElementId),
          )
          .firstOrNull;
      final role = roleKey(primitive);
      if (item != null && !chosen.containsKey(role)) {
        chosen[role] = item;
        if (primitive.isSpatial) selectedPrimitiveIds[role] = primitive.id;
      }
    }
  }

  ProjectManifest project;
  final BorderBlueprintRecord? initialRecord;
  final Set<String> Function() unavailableResourceIds;
  late String name;
  final chosen = <String, ResourceItem>{};
  final modifiedRoles = <String>{};
  final selectedPrimitiveIds = <String, String>{};
  final primitiveModelIds = <String, String>{};
  final primitiveModelSettings = <String, BorderModelSettings>{};
  final sequenceSourceModels = <String, String>{};
  late bool straightOnly,
      horizontalFacade,
      followContourDirection,
      replacesGround,
      masksGroundCells;
  late int sequenceLength;
  late double groundBaseOffset;
  BorderBlueprintRecord? expectedRecord;
  BorderLineSide? jumpSide;
  String? pendingId;
  bool saving = false;
  String? error;
  List<String> warningCodes = const [];

  void updateProject(ProjectManifest value) => project = value;

  bool get nativeLedge =>
      initialRecord != null &&
      !initialRecord!.draft.definition.isSpatial &&
      initialRecord!.draft.definition.template ==
          BorderBlueprintTemplate.ledgeLine;

  bool get hasChanges => nativeLedge
      ? name != expectedRecord?.draft.definition.name ||
            jumpSide != expectedRecord?.draft.definition.jumpBehavior?.side
      : name != (initialRecord?.draft.definition.name ?? '') ||
            horizontalFacade !=
                (initialRecord?.draft.definition.template ==
                    BorderBlueprintTemplate.horizontalFacade) ||
            straightOnly !=
                (initialRecord?.draft.definition.straightOnly ?? false) ||
            sequenceLength !=
                (initialRecord?.draft.definition.sequenceLength ?? 1) ||
            replacesGround !=
                (initialRecord?.draft.definition.replacesGround ?? false) ||
            masksGroundCells !=
                (initialRecord?.draft.definition.masksGroundCells ?? false) ||
            groundBaseOffset !=
                (initialRecord?.draft.definition.groundBaseOffset ?? 0) ||
            followContourDirection !=
                (initialRecord?.draft.definition.followContourDirection ??
                    false) ||
            primitiveModelIds.entries.any(
              (entry) =>
                  initialRecord?.draft.definition.primitives
                      .where((primitive) => primitive.id == entry.key)
                      .firstOrNull
                      ?.sourceModelId !=
                  entry.value,
            ) ||
            primitiveModelSettings.entries.any(
              (entry) => entry.value != initialSettings(entry.key),
            ) ||
            roles.any(
              (role) =>
                  !selectedPrimitiveIds.containsKey(role) &&
                  sourceId(role) !=
                      initialRecord?.draft.definition.primitives
                          .where((primitive) => roleKey(primitive) == role)
                          .map(
                            (primitive) =>
                                primitive.sourceModelId ??
                                primitive.sourceElementId,
                          )
                          .firstOrNull,
            );

  String roleKey(BorderPrimitiveDraft primitive) =>
      primitive.cornerTurn == BorderCornerTurn.left
      ? 'lineCornerLeft'
      : primitive.role.name;

  List<String> get roles => [
    'lineStraight',
    'lineCap',
    if (!straightOnly && !horizontalFacade) 'lineCorner',
    if (!straightOnly && !horizontalFacade && followContourDirection)
      'lineCornerLeft',
  ];

  String? sourceId(String role) => modifiedRoles.contains(role)
      ? chosen[role]?.id
      : chosen[role]?.id ??
            initialRecord?.draft.definition.primitives
                .where((primitive) => roleKey(primitive) == role)
                .map(
                  (primitive) =>
                      primitive.sourceModelId ?? primitive.sourceElementId,
                )
                .firstOrNull;

  bool get complete => baseComplete && sequenceProblem == null;

  String? get sequenceProblem {
    if (sequenceLength == 1) return null;
    final phases = <int, Set<BorderPrimitiveRole>>{};
    for (final primitive in sequencePrimitives) {
      phases.putIfAbsent(primitive.sequenceIndex, () => {}).add(primitive.role);
    }
    if (phases.length != sequenceLength ||
        phases.values.any(
          (roles) => !roles.containsAll({
            BorderPrimitiveRole.lineCap,
            BorderPrimitiveRole.lineStraight,
            if (!straightOnly) BorderPrimitiveRole.lineCorner,
          }),
        )) {
      return straightOnly
          ? 'Chaque étape doit contenir un corps et des extrémités avant publication.'
          : 'Chaque étape doit contenir un corps, des extrémités et des angles avant publication.';
    }
    if (!straightOnly && followContourDirection) {
      for (var phase = 0; phase < sequenceLength; phase++) {
        final turns = sequencePrimitives
            .where(
              (p) =>
                  p.sequenceIndex == phase &&
                  p.role == BorderPrimitiveRole.lineCorner,
            )
            .map((p) => p.cornerTurn)
            .toSet();
        if (!turns.containsAll(BorderCornerTurn.values)) {
          return 'Ajoutez les angles rentrants et sortants à chaque étape du motif.';
        }
      }
    }
    return null;
  }

  bool get baseComplete => nativeLedge
      ? nativeLedgeSourcesAvailable(
          expectedRecord!,
          project,
          unavailableResourceIds: unavailableResourceIds(),
        )
      : sourceId('lineCap') != null &&
            sourceId('lineStraight') != null &&
            (horizontalFacade ||
                straightOnly ||
                (sourceId('lineCorner') != null &&
                    (!followContourDirection ||
                        sourceId('lineCornerLeft') != null)));

  String primitiveId(String role) => selectedPrimitiveIds[role] ?? role;

  List<BorderPrimitiveDraft> get sequencePrimitives => borderSequencePrimitives(
    initialRecord?.draft.definition.primitives ??
        borderSequenceModelPrimitives(
          straightModelId:
              sequenceSourceModels['lineStraight'] ??
              chosen['lineStraight']?.model3d?.id,
          capModelId:
              sequenceSourceModels['lineCap'] ?? chosen['lineCap']?.model3d?.id,
          cornerModelId: straightOnly
              ? null
              : sequenceSourceModels['lineCorner'] ??
                    chosen['lineCorner']?.model3d?.id,
          innerCornerModelId: straightOnly || !followContourDirection
              ? null
              : sequenceSourceModels['lineCornerLeft'] ??
                    chosen['lineCornerLeft']?.model3d?.id,
          directed: followContourDirection,
        ),
    sequenceLength,
    previousLength: initialRecord?.draft.definition.sequenceLength ?? 1,
  );

  BorderModelSettings initialSettings(String id) {
    final primitive =
        (sequenceLength > 1
                ? sequencePrimitives
                : initialRecord?.draft.definition.primitives)
            ?.where((primitive) => primitive.id == id)
            .firstOrNull;
    return BorderModelSettings(
      animationIndex: primitive?.animationIndex,
      animationLoop: primitive?.animationLoop ?? true,
      animationSpeed: primitive?.animationSpeed ?? 1,
      blocksMovement: primitive?.blocksMovement ?? true,
      cornerJoinCells: primitive?.cornerJoinCells ?? 0,
    );
  }

  BorderModelSettings settingsFor(String role) =>
      primitiveModelSettings[primitiveId(role)] ??
      initialSettings(primitiveId(role));

  String? get settingsProblem {
    final primitives =
        (sequenceLength > 1
            ? sequencePrimitives
            : initialRecord?.draft.definition.primitives) ??
        <BorderPrimitiveDraft>[];
    for (final primitive in primitives.where(
      (primitive) => primitive.isSpatial,
    )) {
      final modelId =
          primitiveModelIds[primitive.id] ?? primitive.sourceModelId;
      final model = project.models3d
          .where((model) => model.id == modelId)
          .firstOrNull;
      final settings =
          primitiveModelSettings[primitive.id] ?? initialSettings(primitive.id);
      if (model != null &&
          settings.animationIndex != null &&
          !model.inspection.animations.any(
            (clip) => clip.index == settings.animationIndex,
          )) {
        return 'Le modèle choisi ne contient plus l’animation sélectionnée. Choisissez une animation disponible ou « Aucune ».';
      }
    }
    for (final role in roles) {
      if (primitives.any((primitive) => roleKey(primitive) == role)) continue;
      final settings = settingsFor(role);
      final model = chosen[role]?.model3d;
      if (model != null &&
          settings.animationIndex != null &&
          !model.inspection.animations.any(
            (clip) => clip.index == settings.animationIndex,
          )) {
        return 'Le modèle choisi ne contient plus l’animation sélectionnée. Choisissez une animation disponible ou « Aucune ».';
      }
    }
    return null;
  }

  BorderCreationRequest buildRequest({bool publish = false}) => nativeLedge
      ? BorderCreationRequest(
          name: name.trim(),
          blueprintId: pendingId,
          jumpSide: jumpSide,
          expectedRecord: expectedRecord,
          publish: publish,
          acceptedWarningCodes: List.unmodifiable(warningCodes),
        )
      : BorderCreationRequest(
          name: name.trim(),
          template: horizontalFacade
              ? BorderBlueprintTemplate.horizontalFacade
              : null,
          capElementId: project.settings.dimension == ProjectDimension.twoD
              ? sourceId('lineCap')
              : null,
          straightElementId: project.settings.dimension == ProjectDimension.twoD
              ? sourceId('lineStraight')
              : null,
          cornerElementId:
              project.settings.dimension == ProjectDimension.twoD &&
                  !horizontalFacade
              ? sourceId('lineCorner')
              : null,
          capModelId:
              project.settings.dimension == ProjectDimension.threeD &&
                  (initialRecord == null ||
                      !selectedPrimitiveIds.containsKey('lineCap'))
              ? sequenceSourceModels['lineCap'] ?? sourceId('lineCap')
              : null,
          straightModelId:
              project.settings.dimension == ProjectDimension.threeD &&
                  (initialRecord == null ||
                      !selectedPrimitiveIds.containsKey('lineStraight'))
              ? sequenceSourceModels['lineStraight'] ?? sourceId('lineStraight')
              : null,
          cornerModelId:
              project.settings.dimension == ProjectDimension.threeD &&
                  (initialRecord == null ||
                      !selectedPrimitiveIds.containsKey('lineCorner'))
              ? sourceId('lineCorner')
              : null,
          innerCornerModelId:
              followContourDirection &&
                  (initialRecord == null ||
                      !selectedPrimitiveIds.containsKey('lineCornerLeft'))
              ? sourceId('lineCornerLeft')
              : null,
          blueprintId: pendingId,
          expectedRecord: expectedRecord,
          primitiveModelIds: Map.unmodifiable(primitiveModelIds),
          primitiveModelSettings: Map.unmodifiable(primitiveModelSettings),
          sequenceLength: sequenceLength,
          straightOnly: straightOnly,
          followContourDirection: followContourDirection,
          replacesGround: replacesGround,
          masksGroundCells: masksGroundCells,
          groundBaseOffset: groundBaseOffset,
          publish: publish,
          acceptedWarningCodes: List.unmodifiable(warningCodes),
        );

  bool setSequenceLength(String text) {
    final value = int.tryParse(text.trim());
    if (saving || value == null || value < 1 || value > 64) {
      error = 'Le motif doit contenir de 1 à 64 étapes.';
      return false;
    }
    if (initialRecord == null) {
      if (value == 1) {
        sequenceSourceModels.clear();
      } else {
        for (final role in roles) {
          if (chosen[role]?.model3d?.id case final id?) {
            sequenceSourceModels.putIfAbsent(role, () => id);
          }
        }
      }
    }
    final previousLength = sequenceLength;
    sequenceLength = value;
    for (final primitive in sequencePrimitives.where(
      (p) => p.sequenceIndex >= previousLength,
    )) {
      final prototype = sequencePrimitives
          .where(
            (p) => p.sequenceIndex == 0 && roleKey(p) == roleKey(primitive),
          )
          .firstOrNull;
      final settings = prototype == null
          ? null
          : primitiveModelSettings[prototype.id];
      if (settings != null) {
        primitiveModelSettings.putIfAbsent(primitive.id, () => settings);
      }
    }
    final ids = sequencePrimitives.map((p) => p.id).toSet();
    primitiveModelIds.removeWhere((id, _) => !ids.contains(id));
    primitiveModelSettings.removeWhere((id, _) => !ids.contains(id));
    for (final role in roles) {
      if (ids.contains(selectedPrimitiveIds[role])) continue;
      final first = sequencePrimitives
          .where((p) => roleKey(p) == role)
          .firstOrNull;
      if (first == null) {
        selectedPrimitiveIds.remove(role);
      } else {
        selectedPrimitiveIds[role] = first.id;
        final source = primitiveModelIds[first.id] ?? first.sourceModelId;
        final item = resourceCatalog(project)
            .where((item) => item.id == source && item.model3d != null)
            .firstOrNull;
        if (item != null) chosen[role] = item;
      }
    }
    error = null;
    warningCodes = const [];

    return true;
  }

  void setPrimitiveSource(String id, String modelId) {
    primitiveModelIds[id] = modelId;
    for (final role in roles.where(
      (role) => selectedPrimitiveIds[role] == id,
    )) {
      chosen[role] = resourceCatalog(project)
          .firstWhere((item) => item.id == modelId && item.model3d != null);
    }
    warningCodes = const [];
  }

  void assignRole(String role, ResourceItem element) {
    modifiedRoles.add(role);
    chosen[role] = element;
    if (initialRecord == null &&
        sequenceLength > 1 &&
        element.model3d != null) {
      sequenceSourceModels.putIfAbsent(role, () => element.id);
    }
    final primitiveId = selectedPrimitiveIds[role];
    if (primitiveId != null && element.model3d != null) {
      primitiveModelIds[primitiveId] = element.id;
    }
    warningCodes = const [];
  }

  void selectPrimitive(String role, String id) {
    final variants =
        (sequenceLength > 1
                ? sequencePrimitives
                : initialRecord?.draft.definition.primitives)
            ?.where((primitive) => roleKey(primitive) == role)
            .toList() ??
        [];
    selectedPrimitiveIds[role] = id;
    final primitive = variants.firstWhere((primitive) => primitive.id == id);
    final sourceId = primitiveModelIds[id] ?? primitive.sourceModelId;
    final item = resourceCatalog(project)
        .where((item) => item.id == sourceId && item.canonicalKind == 'model3d')
        .firstOrNull;
    if (item != null) chosen[role] = item;
  }

  void setSettings(String role, BorderModelSettings settings) {
    primitiveModelSettings[primitiveId(role)] = settings;
    warningCodes = const [];
  }

  bool setAnimationSpeed(String role, String text) {
    final speed = double.tryParse(text.trim().replaceAll(',', '.'));
    if (speed == null || !speed.isFinite || speed <= 0 || speed > 16) {
      error = 'La vitesse doit être supérieure à 0 et au maximum égale à 16.';
      return false;
    }
    final settings = settingsFor(role);
    error = null;
    setSettings(
      role,
      BorderModelSettings(
        animationIndex: settings.animationIndex,
        animationLoop: settings.animationLoop,
        animationSpeed: speed,
        blocksMovement: settings.blocksMovement,
        cornerJoinCells: settings.cornerJoinCells,
      ),
    );
    return true;
  }

  bool setCornerJoin(String role, String text) {
    final cells = int.tryParse(text.trim());
    if (cells == null || cells < 0 || cells > 8) {
      error = 'Le raccord doit réserver de 0 à 8 cases de chaque côté.';
      return false;
    }
    final settings = settingsFor(role);
    error = null;
    setSettings(
      role,
      BorderModelSettings(
        animationIndex: settings.animationIndex,
        animationLoop: settings.animationLoop,
        animationSpeed: settings.animationSpeed,
        blocksMovement: settings.blocksMovement,
        cornerJoinCells: cells,
      ),
    );
    return true;
  }

  void setReplacesGround(bool value) {
    replacesGround = value;
    if (!value) groundBaseOffset = 0;
    if (value) masksGroundCells = false;
  }

  void setMasksGroundCells(bool value) {
    masksGroundCells = value;
    if (value) {
      replacesGround = false;
      groundBaseOffset = 0;
    }
  }

  bool setGroundLowering(String text) {
    final amount = double.tryParse(text.trim().replaceAll(',', '.'));
    if (amount == null || !amount.isFinite || amount < 0) {
      error = 'L’abaissement doit être un nombre positif ou nul.';
      return false;
    }
    groundBaseOffset = amount == 0 ? 0 : -amount;
    error = null;
    return true;
  }

  void setStraightOnly(bool value) {
    straightOnly = value;
    error = null;
  }
}
