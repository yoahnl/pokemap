import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'narrative_action_support.dart';

final class PresentationCinematicTemplateAuthoringException
    implements Exception {
  PresentationCinematicTemplateAuthoringException(
    this.code,
    this.message, {
    Map<String, Object?> details = const <String, Object?>{},
  }) : details = Map.unmodifiable(details);

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() =>
      'PresentationCinematicTemplateAuthoringException($code): $message';
}

final class PresentationCinematicTemplateActions {
  const PresentationCinematicTemplateActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      AuthoringActionDescriptor(
        id: 'presentationCinematicTemplate.instantiate',
        version: 1,
        summary: 'Instantiate one canonical Presentation cinematic template',
        inputSchemaId:
            'pokemap.authoring/presentationCinematicTemplate.instantiate.input.v1',
        outputSchemaId:
            'pokemap.authoring/presentationCinematicTemplate.instantiate.output.v1',
        riskLevel: AuthoringRiskLevel.low,
        resourceKinds: const <String>[
          'project',
          'presentationCinematic',
          'presentationCinematicTemplate',
        ],
        capabilityIds: const <String>[
          'authoring.cinematic.presentation_templates',
        ],
        requiredPermissions: const <AuthoringPermission>[
          AuthoringPermission.projectWrite,
        ],
        guarantees: const <AuthoringGuarantee>[
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable,
        ],
      ),
    ],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    if (context.request.actionId !=
        'presentationCinematicTemplate.instantiate') {
      throw PresentationCinematicTemplateAuthoringException(
        'presentation_cinematic_template.action_unsupported',
        'The requested Presentation cinematic template action is unsupported.',
      );
    }
    if (context.snapshot.manifest.version != ProjectVersion.v7) {
      throw PresentationCinematicTemplateAuthoringException(
        'presentation_cinematic_template.project_version_unsupported',
        'Presentation cinematic templates require ProjectVersion.v7.',
      );
    }
    final parameters = context.request.parameters;
    _requireExactParameters(parameters);
    final templateId = _string(parameters, 'templateId');
    final templateVersion = _integer(parameters, 'templateVersion');
    final template = _requireTemplate(templateId, templateVersion);
    final cinematicId = _string(parameters, 'cinematicId');
    final project = context.snapshot.manifest;
    if (project.presentationCinematics.any(
      (cinematic) => cinematic.id == cinematicId,
    )) {
      throw PresentationCinematicTemplateAuthoringException(
        'presentation_cinematic_template.cinematic_id_unavailable',
        'The requested Presentation cinematic identity already exists.',
        details: <String, Object?>{'cinematicId': cinematicId},
      );
    }
    final cinematic = instantiatePresentationCinematicTemplate(
      template,
      cinematicId: cinematicId,
      title: _string(parameters, 'title'),
      description: _optionalString(parameters, 'description'),
    );
    final projected = project.copyWith(
      presentationCinematics: <PresentationCinematicAsset>[
        ...project.presentationCinematics,
        cinematic,
      ],
    );
    return narrativeProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/presentationCinematics/$cinematicId',
      after: encodePresentationCinematicAsset(cinematic),
      preview: <String, Object?>{
        'resourceKind': 'presentationCinematic',
        'cinematicId': cinematicId,
        'templateId': template.id,
        'templateVersion': template.version,
      },
    );
  }
}

PresentationCinematicTemplate _requireTemplate(String id, int version) {
  try {
    return PresentationCinematicTemplateCatalog.canonical().require(
      id,
      version: version,
    );
  } on PresentationCinematicTemplateException catch (error) {
    final code = switch (error.code) {
      PresentationCinematicTemplateErrorCode.unknownTemplate =>
        'presentation_cinematic_template.unknown',
      PresentationCinematicTemplateErrorCode.unsupportedVersion =>
        'presentation_cinematic_template.version_unsupported',
    };
    throw PresentationCinematicTemplateAuthoringException(
      code,
      error.message,
      details: <String, Object?>{
        'templateId': id,
        'templateVersion': version,
      },
    );
  }
}

PresentationCinematicAsset instantiatePresentationCinematicTemplate(
  PresentationCinematicTemplate template, {
  required String cinematicId,
  required String title,
  required String? description,
}) {
  final recipe = switch (template.id) {
    'blank' => const _TemplateRecipe(),
    'titleIdentity' => _titleIdentityRecipe(),
    'immersiveOpening' => _immersiveOpeningRecipe(template.defaultDurationUs),
    'stagedStory' => _stagedStoryRecipe(template.defaultDurationUs),
    'interactivePath' => _interactivePathRecipe(
        template.defaultDurationUs,
      ),
    'adaptiveVideo' => _adaptiveVideoRecipe(template.defaultDurationUs),
    _ =>
      throw StateError('Missing recipe for canonical template ${template.id}'),
  };
  return PresentationCinematicAsset(
    id: cinematicId,
    title: title,
    description: description,
    durationUs: template.defaultDurationUs,
    layers: recipe.layers,
    tracks: recipe.tracks,
  );
}

_TemplateRecipe _titleIdentityRecipe() => _TemplateRecipe(
      layers: _layers(<(String, String)>[
        ('background', 'Background'),
        ('identity', 'Identity'),
        ('title', 'Title'),
        ('subtitle', 'Subtitle'),
      ]),
      tracks: _visualTracks(<(String, String)>[
        ('background', 'Background'),
        ('identity', 'Identity'),
        ('title', 'Title'),
        ('subtitle', 'Subtitle'),
      ]),
    );

_TemplateRecipe _immersiveOpeningRecipe(int durationUs) => _TemplateRecipe(
      layers: _layers(<(String, String)>[
        ('background', 'Background'),
        ('atmosphere', 'Atmosphere'),
        ('title', 'Title'),
      ]),
      tracks: <PresentationTrack>[
        ..._visualTracks(<(String, String)>[
          ('background', 'Background'),
          ('atmosphere', 'Atmosphere'),
          ('title', 'Title'),
        ]),
        _emptyTrack('music', 'Music', PresentationTrackKind.audio),
        _markerTrack(<PresentationMarkerClip>[
          _marker('opening', 0, 'Opening'),
          _marker('titleReveal', durationUs ~/ 2, 'Title reveal'),
          _marker('closing', durationUs, 'Closing'),
        ]),
      ],
    );

_TemplateRecipe _stagedStoryRecipe(int durationUs) => _TemplateRecipe(
      layers: _layers(<(String, String)>[
        ('background', 'Background'),
        ('subject', 'Subject'),
        ('text', 'Text'),
      ]),
      tracks: <PresentationTrack>[
        ..._visualTracks(<(String, String)>[
          ('background', 'Background'),
          ('subject', 'Subject'),
          ('text', 'Text'),
        ]),
        _emptyTrack('voice', 'Voice', PresentationTrackKind.audio),
        _emptyTrack('music', 'Music', PresentationTrackKind.audio),
        _emptyTrack('captions', 'Captions', PresentationTrackKind.caption),
        _markerTrack(<PresentationMarkerClip>[
          _marker('opening', 0, 'Opening'),
          _marker('turn', durationUs ~/ 2, 'Story turn'),
          _marker('closing', durationUs, 'Closing'),
        ]),
      ],
    );

_TemplateRecipe _interactivePathRecipe(int durationUs) => _TemplateRecipe(
      layers: _layers(<(String, String)>[
        ('background', 'Background'),
        ('foreground', 'Foreground'),
        ('prompt', 'Prompt'),
      ]),
      tracks: <PresentationTrack>[
        ..._visualTracks(<(String, String)>[
          ('background', 'Background'),
          ('foreground', 'Foreground'),
          ('prompt', 'Prompt'),
        ]),
        _emptyTrack('voice', 'Voice', PresentationTrackKind.audio),
        _emptyTrack('music', 'Music', PresentationTrackKind.audio),
        _markerTrack(<PresentationMarkerClip>[
          PresentationMarkerClip(
            id: 'interaction',
            startUs: durationUs ~/ 2,
            label: 'Interaction',
            markerKind: PresentationMarkerKind.interactionCue,
          ),
        ]),
      ],
    );

_TemplateRecipe _adaptiveVideoRecipe(int durationUs) => _TemplateRecipe(
      layers: _layers(<(String, String)>[
        ('poster', 'Poster'),
        ('video', 'Video'),
      ]),
      tracks: <PresentationTrack>[
        ..._visualTracks(<(String, String)>[
          ('poster', 'Poster'),
          ('video', 'Video'),
        ]),
        _emptyTrack('music', 'Music', PresentationTrackKind.audio),
        _emptyTrack('captions', 'Captions', PresentationTrackKind.caption),
        _markerTrack(<PresentationMarkerClip>[
          _marker('opening', 0, 'Opening'),
          _marker('closing', durationUs, 'Closing'),
        ]),
      ],
    );

List<PresentationLayer> _layers(List<(String, String)> definitions) =>
    <PresentationLayer>[
      for (var index = 0; index < definitions.length; index += 1)
        PresentationLayer(
          id: definitions[index].$1,
          label: definitions[index].$2,
          zIndex: index,
        ),
    ];

List<PresentationTrack> _visualTracks(
  List<(String, String)> definitions,
) =>
    <PresentationTrack>[
      for (final definition in definitions)
        _emptyTrack(definition.$1, definition.$2, PresentationTrackKind.visual),
    ];

PresentationTrack _emptyTrack(
  String id,
  String label,
  PresentationTrackKind kind,
) =>
    PresentationTrack(id: id, label: label, kind: kind);

PresentationTrack _markerTrack(List<PresentationMarkerClip> clips) =>
    PresentationTrack(
      id: 'markers',
      label: 'Markers',
      kind: PresentationTrackKind.marker,
      clips: clips,
    );

PresentationMarkerClip _marker(String id, int startUs, String label) =>
    PresentationMarkerClip(id: id, startUs: startUs, label: label);

void _requireExactParameters(Map<String, Object?> parameters) {
  const expected = <String>{
    'templateId',
    'templateVersion',
    'cinematicId',
    'title',
    'description',
  };
  final actual = parameters.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw PresentationCinematicTemplateAuthoringException(
      'presentation_cinematic_template.parameters_invalid',
      'The Presentation cinematic template parameters do not match the action.',
      details: <String, Object?>{
        'expected': expected.toList()..sort(),
        'actual': actual.toList()..sort(),
      },
    );
  }
}

String _string(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! String || value.isEmpty || value != value.trim()) {
    throw PresentationCinematicTemplateAuthoringException(
      'presentation_cinematic_template.parameter_invalid',
      'Parameter $key must be a nonblank trimmed string.',
    );
  }
  return value;
}

String? _optionalString(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value == null) return null;
  return _string(parameters, key);
}

int _integer(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! int) {
    throw PresentationCinematicTemplateAuthoringException(
      'presentation_cinematic_template.parameter_invalid',
      'Parameter $key must be an integer.',
    );
  }
  return value;
}

final class _TemplateRecipe {
  const _TemplateRecipe({this.layers = const [], this.tracks = const []});

  final List<PresentationLayer> layers;
  final List<PresentationTrack> tracks;
}
